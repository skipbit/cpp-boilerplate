# The monorepo build. Each template under templates/ is a standalone project;
# this file exists so that one build configures, compiles and tests all of them.
#
# That matters for more than convenience: the application templates consume the
# library template through find_package(), so building them together is what
# proves the installed package actually works.
cmake_minimum_required(VERSION 3.28)

project(cpp-boilerplate
    VERSION 0.1.0
    DESCRIPTION "Starting points for C++ projects: library, CLI, daemon, Qt desktop"
    HOMEPAGE_URL "https://github.com/skipbit/cpp-boilerplate"
    LANGUAGES CXX)

option(CPPBP_BUILD_LIB "Build the library template" ON)
option(CPPBP_BUILD_TESTING "Build the tests of every enabled template" ON)
option(CPPBP_BUILD_EXAMPLES "Build the examples of every enabled template" ON)

# Qt is off by default: it is a heavy dependency, and the templates that do not
# use it should not pay for its installation in CI.
option(CPPBP_BUILD_QT "Build the Qt desktop template" OFF)

if(CPPBP_BUILD_TESTING)
    enable_testing()
endif()

# Set as normal variables before add_subdirectory: under CMP0077 (NEW since
# 3.13) the option() calls inside each template will not override these.
set(MYLIB_BUILD_TESTING ${CPPBP_BUILD_TESTING})
set(MYLIB_BUILD_EXAMPLES ${CPPBP_BUILD_EXAMPLES})
set(MYLIB_INSTALL ON)

if(CPPBP_BUILD_LIB)
    add_subdirectory(templates/lib)
endif()
