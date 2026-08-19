# This file builds on its own and as part of the monorepo. Nothing here assumes
# a parent project, which is why the distributed copy needs no edits.
cmake_minimum_required(VERSION 3.28)

project(mycli
    VERSION 0.1.0
    DESCRIPTION "A C++ command line program — replace this line with what yours does"
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
include(CommandLineDependencies)

option(MYCLI_BUILD_TESTING "Build the test suite" ${PROJECT_IS_TOP_LEVEL})
option(MYCLI_INSTALL "Generate the install rules" ${PROJECT_IS_TOP_LEVEL})

set(MYCLI_GENERATED_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated")
configure_file(cmake/version.hpp.in "${MYCLI_GENERATED_DIR}/mycli/version.hpp" @ONLY)

# Two targets, and the split is the point. Everything the program does is in a
# library the tests can link; the executable is main.cpp and nothing else. A
# program written the other way round can only be tested by starting a process
# and reading its output, which is why so few of them are.
#
# The library is static and is never installed: it is an arrangement for testing
# this program, not an API for anyone else. A library meant for other people to
# link is a different template.
add_library(mycli_lib STATIC
    src/command_line.cpp
    src/counting.cpp
    src/report.cpp)

target_include_directories(mycli_lib PUBLIC
    "${CMAKE_CURRENT_LIST_DIR}/src"
    "${MYCLI_GENERATED_DIR}")

# Raise this to cxx_std_26 and the CI matrix will tell you what breaks.
target_compile_features(mycli_lib PUBLIC cxx_std_23)

# PRIVATE: CLI11 is used by one source file and named in no header, so nothing
# that links this library has to know it exists. Swapping the parser is then a
# change to command_line.cpp and to cmake/modules/CommandLineDependencies.cmake.
target_link_libraries(mycli_lib PRIVATE CLI11::CLI11)

cppbp_set_warnings(mycli_lib PRIVATE)
cppbp_set_sanitizers(mycli_lib PUBLIC)
cppbp_enable_clang_tidy(mycli_lib)

add_executable(mycli src/main.cpp)
target_link_libraries(mycli PRIVATE mycli_lib)
cppbp_set_warnings(mycli PRIVATE)
cppbp_set_sanitizers(mycli PRIVATE)
cppbp_enable_clang_tidy(mycli)

if(MYCLI_BUILD_TESTING)
    enable_testing()
    add_subdirectory(test)
endif()

if(NOT MYCLI_INSTALL)
    return()
endif()

# A program installs one thing: the program. There is no export set, no config
# file and no pkg-config file, because nothing finds a command with
# find_package() - it is found on PATH.
#
# There is no SBOM either, which is a limitation rather than a decision. CMake's
# install(SBOM) refuses to describe a target that links one it cannot attribute,
# and a dependency brought in by FetchContent is never installed or exported, so
# it can never be attributed. Measured with CMake 4.4.2: the generate step fails
# with "references target CLI11 which has no install(EXPORT)/export(EXPORT)
# namespace and is not covered by any SBOM". The feature is experimental; this
# is a thing to try again rather than to work around by exporting a dependency
# nobody consumes.
install(TARGETS mycli
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}" COMPONENT mycli_runtime)
