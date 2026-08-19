# This file builds on its own and as part of the monorepo. Nothing here assumes
# a parent project, which is why the distributed copy needs no edits.
cmake_minimum_required(VERSION 3.28)

project(mylib
    VERSION 0.1.0
    DESCRIPTION "A C++ library — replace this line with what yours does"
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
include(CMakePackageConfigHelpers)
include(GenerateExportHeader)
include(CompilerWarnings)
include(StandardLibraryFeatures)
include(Sanitizers)
include(ClangTidy)

# Defaults follow PROJECT_IS_TOP_LEVEL: consumed as a subdirectory, this library
# should not drag its tests, examples or install rules into the parent build.
option(MYLIB_BUILD_TESTING "Build the test suite" ${PROJECT_IS_TOP_LEVEL})
option(MYLIB_BUILD_EXAMPLES "Build the examples" ${PROJECT_IS_TOP_LEVEL})
option(MYLIB_INSTALL "Generate the install rules" ${PROJECT_IS_TOP_LEVEL})
option(MYLIB_GENERATE_SBOM "Write an SPDX 3.0 SBOM on install (needs CMake 4.3+)" OFF)

set(MYLIB_GENERATED_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated")
configure_file(cmake/version.hpp.in "${MYLIB_GENERATED_DIR}/mylib/version.hpp" @ONLY)

add_library(mylib)
add_library(mylib::mylib ALIAS mylib)

# Hide everything by default and export deliberately. Without this the export
# macros below are decoration: every symbol would be visible anyway, and the
# ABI would grow by accident.
set_target_properties(mylib PROPERTIES
    CXX_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN ON
    VERSION ${PROJECT_VERSION}
    SOVERSION ${PROJECT_VERSION_MAJOR})

generate_export_header(mylib
    BASE_NAME MYLIB
    EXPORT_FILE_NAME "${MYLIB_GENERATED_DIR}/mylib/export.hpp")

target_sources(mylib
    PRIVATE
        src/text.cpp
    PUBLIC
        FILE_SET HEADERS
        BASE_DIRS "${CMAKE_CURRENT_LIST_DIR}/include"
        FILES
            "${CMAKE_CURRENT_LIST_DIR}/include/mylib/text.hpp"
    PUBLIC
        FILE_SET generated_headers TYPE HEADERS
        BASE_DIRS "${MYLIB_GENERATED_DIR}"
        FILES
            "${MYLIB_GENERATED_DIR}/mylib/version.hpp"
            "${MYLIB_GENERATED_DIR}/mylib/export.hpp")

# src/ is on the include path for this target only: consumers get include/ and
# the generated headers through the FILE_SETs above, and nothing else.
target_include_directories(mylib PRIVATE "${CMAKE_CURRENT_LIST_DIR}/src")

# Raise this to cxx_std_26 and the CI matrix will tell you what breaks. It is
# PUBLIC because the public headers use the standard the library is built with.
target_compile_features(mylib PUBLIC cxx_std_23)

cppbp_set_warnings(mylib PRIVATE)
cppbp_set_sanitizers(mylib PRIVATE)
cppbp_enable_clang_tidy(mylib)

if(NOT BUILD_SHARED_LIBS)
    target_compile_definitions(mylib PUBLIC MYLIB_STATIC_DEFINE)
endif()

if(MYLIB_BUILD_TESTING)
    enable_testing()
    add_subdirectory(test)
endif()

if(MYLIB_BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()

if(NOT MYLIB_INSTALL)
    return()
endif()

install(TARGETS mylib
    EXPORT mylib-targets
    RUNTIME COMPONENT mylib_runtime
    LIBRARY COMPONENT mylib_runtime NAMELINK_COMPONENT mylib_development
    ARCHIVE COMPONENT mylib_development
    FILE_SET HEADERS COMPONENT mylib_development
    FILE_SET generated_headers COMPONENT mylib_development)

install(EXPORT mylib-targets
    FILE mylib-targets.cmake
    NAMESPACE mylib::
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/mylib"
    COMPONENT mylib_development)

# Semantic versioning puts breaking changes in the minor slot while the major
# version is 0, so SameMajorVersion would let find_package(mylib 0.1) accept an
# installed 0.9 - a different library under that rule. See docs/versioning.md.
if(PROJECT_VERSION_MAJOR EQUAL 0)
    set(mylib_compatibility SameMinorVersion)
else()
    set(mylib_compatibility SameMajorVersion)
endif()

write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/mylib-config-version.cmake"
    COMPATIBILITY ${mylib_compatibility})

configure_package_config_file(
    cmake/mylib-config.cmake.in
    "${CMAKE_CURRENT_BINARY_DIR}/mylib-config.cmake"
    INSTALL_DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/mylib")

install(FILES
        "${CMAKE_CURRENT_BINARY_DIR}/mylib-config.cmake"
        "${CMAKE_CURRENT_BINARY_DIR}/mylib-config-version.cmake"
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/mylib"
    COMPONENT mylib_development)

# pkg-config, for consumers that are not CMake projects.
configure_file(cmake/mylib.pc.in "${CMAKE_CURRENT_BINARY_DIR}/mylib.pc" @ONLY)
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/mylib.pc"
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/pkgconfig"
    COMPONENT mylib_development)

if(MYLIB_GENERATE_SBOM)
    # install(SBOM) is experimental. It is opt-in and CI exercises it, so that a
    # changed gate is a failing job rather than a silently missing document.
    if(CMAKE_VERSION VERSION_LESS 4.3)
        message(FATAL_ERROR
            "MYLIB_GENERATE_SBOM needs CMake 4.3 or newer (found ${CMAKE_VERSION})")
    endif()
    set(CMAKE_EXPERIMENTAL_GENERATE_SBOM "2d856d6d-53e8-488b-a17f-d486d2cac317")
    install(SBOM mylib
        EXPORTS mylib-targets
        LICENSE "0BSD"
        COMPONENT mylib_development)
endif()
