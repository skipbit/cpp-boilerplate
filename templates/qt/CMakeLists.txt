# This file builds on its own and as part of the monorepo. Nothing here assumes
# a parent project, which is why the distributed copy needs no edits.
cmake_minimum_required(VERSION 3.28)

project(myapp
    VERSION 0.1.0
    DESCRIPTION "A C++ desktop application — replace this line with what yours does"
    HOMEPAGE_URL "https://github.com/skipbit/cpp-boilerplate"
    LANGUAGES CXX)

# clangd, clang-tidy and everything else that reads the code without building it
# need the compile database, and its absence is the usual reason a fresh clone
# has no working "go to definition". The presets ask for it; this covers a build
# configured without them, which is what most people type first. An explicit
# -DCMAKE_EXPORT_COMPILE_COMMANDS still wins - and it is tested for emptiness,
# not for DEFINED, because CMake creates the cache entry itself and leaves it
# empty, so DEFINED is true even when nobody has asked for anything.
if(PROJECT_IS_TOP_LEVEL AND CMAKE_EXPORT_COMPILE_COMMANDS STREQUAL "")
    set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
endif()

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/cmake/modules")

include(GNUInstallDirs)
include(CompilerWarnings)
include(StandardLibraryFeatures)
include(Sanitizers)
include(ClangTidy)

# The one place this template supports less than its siblings do, said out loud
# at the earliest moment it can be said.
if(CPPBP_STANDARD_LIBRARY STREQUAL "libc++")
    message(NOTICE "
This template cannot be built against libc++.

The Qt that a distribution ships is built against libstdc++, and some of its
functions take or return a standard library type. Those are exported by the
shared library under a mangled name that contains the library they were built
with, so an application compiled against libc++ asks for a symbol that is not
there. Measured on Ubuntu 24.04 (Qt 6.4.2) and 26.04 (Qt 6.10.2):

  undefined reference to `QString::toStdString() const'
  undefined reference to `QTimer::singleShotImpl(std::__1::chrono::duration<...>)'

There is no safe subset to keep to. Which functions are affected depends on
which of them your Qt happens to define inline, and that changes between Qt
releases - the second one above links on 6.4.2 and fails on 6.10.2.

Two ways out:

  cmake --preset debug     build against libstdc++, like the Qt you have

or build Qt itself against libc++ and point CMAKE_PREFIX_PATH at that one.

The other templates here support both. This one supports four environments
rather than six, and README.md says so where somebody choosing a template
will read it.
")
    message(FATAL_ERROR "Qt from a distribution cannot be linked against libc++; see above.")
endif()

find_package(Qt6 REQUIRED COMPONENTS Quick)
qt_standard_project_setup(REQUIRES 6.4)

option(MYAPP_BUILD_TESTING "Build the test suite" ${PROJECT_IS_TOP_LEVEL})
option(MYAPP_INSTALL "Generate the install rules" ${PROJECT_IS_TOP_LEVEL})

set(MYAPP_GENERATED_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated")
configure_file(cmake/version.hpp.in "${MYAPP_GENERATED_DIR}/myapp/version.hpp" @ONLY)

# Two libraries, and the line between them is the whole design. myapp_core holds
# what the program knows and is not linked against Qt at all, so a QString in it
# is a compile error rather than a review comment - and its tests run with no
# QGuiApplication, which is what "the logic is not in the interface" has to mean
# if it is to mean anything.
#
# Neither is installed. An application publishes a command and a desktop entry,
# not an API; these exist so the tests have something to link.
add_library(myapp_core STATIC
    src/catalogue.cpp
    src/presentation.cpp)

target_include_directories(myapp_core PUBLIC
    "${CMAKE_CURRENT_LIST_DIR}/src"
    "${MYAPP_GENERATED_DIR}")

# Raise this to cxx_std_26 and the CI matrix will tell you what breaks.
target_compile_features(myapp_core PUBLIC cxx_std_23)

cppbp_set_warnings(myapp_core PRIVATE)
cppbp_set_sanitizers(myapp_core PUBLIC)
cppbp_enable_clang_tidy(myapp_core)

# myapp_ui is the QML module: the .qml files and the one C++ class they bind to,
# compiled into the binary as resources rather than read from disk, so the
# installed program is one file.
qt_add_library(myapp_ui STATIC)

qt_add_qml_module(myapp_ui
    URI myapp
    VERSION 1.0
    # Has to end in the URI, or the tooling that reads a built module - qmllint
    # among it - looks in the wrong place and says so. Not the binary directory
    # itself: the executable is called myapp too, and one of them would be a
    # directory the other could not be written to.
    OUTPUT_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/qml/myapp"
    SOURCES
        src/filtered_entries.cpp
        src/filtered_entries.hpp
        src/startup.cpp
        src/startup.hpp
    QML_FILES
        qml/Main.qml)

target_link_libraries(myapp_ui PUBLIC myapp_core Qt6::Quick)

cppbp_set_warnings(myapp_ui PRIVATE)
cppbp_set_sanitizers(myapp_ui PUBLIC)
cppbp_enable_clang_tidy(myapp_ui)

# Two things judge code, and neither can tell what was written from what was
# generated. CMake already excludes what AUTOMOC produces; Qt's QML compiler and
# resource writer put their output under .rcc/, and nothing excludes that.
#
# clang-tidy reads the nearest .clang-tidy walking up from the file it is
# analysing. Everything under the build directory is generated and nothing else
# is, so one placed at the top of it switches every check off for exactly the
# files nobody can fix - the compiled QML, the resource loaders and the type
# registrations - and for nothing that was written by hand.
#
# Not "-*" on its own: clang-tidy 18 answers "no checks enabled" and exits with
# a usage message. llvm-header-guard is a check that only ever looks at headers,
# so it is one that is on and can never fire on what is here.
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/.clang-tidy" "Checks: '-*,llvm-header-guard'\n")

# The compiler has no such mechanism. Qt 6.4's QML compiler writes code that
# shadows its own parameters; 6.10 does not, so this stops applying by itself
# once 24.04 is no longer a floor.
if(Qt6_VERSION VERSION_LESS 6.5 AND NOT MSVC)
    target_compile_options(myapp_ui PRIVATE -Wno-shadow)
endif()

qt_add_executable(myapp src/main.cpp)
target_link_libraries(myapp PRIVATE myapp_ui myapp_uiplugin)
cppbp_set_warnings(myapp PRIVATE)
cppbp_set_sanitizers(myapp PRIVATE)
cppbp_enable_clang_tidy(myapp)

# The desktop entry names the program and the path it was installed to, so it is
# generated rather than shipped. Unlike a systemd unit, this one does belong
# under CMAKE_INSTALL_DATADIR: share/applications is where it is looked for.
configure_file(desktop/myapp.desktop.in
    "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.desktop" @ONLY)

if(MYAPP_BUILD_TESTING)
    enable_testing()
    add_subdirectory(test)
endif()

if(NOT MYAPP_INSTALL)
    return()
endif()

# An application installs two things: the program, and the entry that lets a
# launcher find it. No export set and no config file, because nothing finds an
# application with find_package().
#
# No SBOM either. install(SBOM) refuses a target that references one it cannot
# attribute, and the two static libraries above are never installed - measured
# with CMake 4.4.2: "references target myapp_ui which has no install(EXPORT)".
# The same limitation the other application templates have.
install(TARGETS myapp
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}" COMPONENT myapp_runtime)

install(FILES "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.desktop"
    DESTINATION "${CMAKE_INSTALL_DATADIR}/applications" COMPONENT myapp_runtime)
