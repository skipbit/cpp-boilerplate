# The program. One directory per module, and this file is the whole of what
# each one may use.
#
# A module is a directory, a static library, and the header named after it. Its
# include path is its own directory plus the directories of the modules named in
# its target_link_libraries, so reaching for one that is not named there does not
# compile:
#
#   fatal error: 'counting.hpp' file not found
#
# That is what the extra targets buy. One library over the whole of src/ puts
# every header on every file's include path, and the dependencies between the
# pieces become whatever the code happens to do rather than something anybody
# decided.
#
# PUBLIC or PRIVATE says whether a module is part of what this one offers.
# report's header names counting::Counts, so counting is PUBLIC and reaches
# whoever links report; CLI11 appears in one .cpp file and no header, so it is
# PRIVATE and stops here.
#
# One hole is left, because the preprocessor resolves a quoted include relative
# to the file that writes it before it consults any include path at all:
# "../counting/counting.hpp" would reach past everything above and still link,
# since all of these end up in the same program. scripts/check-module-includes.sh
# is what closes it.

add_library(mycli_command_line STATIC command_line/command_line.cpp)
target_include_directories(mycli_command_line
    PUBLIC "${CMAKE_CURRENT_LIST_DIR}/command_line"
    # <mycli/version.hpp>, which --version prints. PRIVATE, like CLI11 below:
    # it is read by the implementation and named in no header.
    PRIVATE "${MYCLI_GENERATED_DIR}")
# Raise this to cxx_std_26 and the CI matrix will tell you what breaks. Every
# module says it, because the standard a module is compiled with is part of what
# it hands to whatever links it.
target_compile_features(mycli_command_line PUBLIC cxx_std_23)
# Swapping the argument parser is a change to command_line.cpp and to
# cmake/modules/CommandLineDependencies.cmake. Nothing else names CLI11.
target_link_libraries(mycli_command_line PRIVATE CLI11::CLI11)
cppbp_set_warnings(mycli_command_line PRIVATE)
cppbp_set_sanitizers(mycli_command_line PUBLIC)
cppbp_enable_clang_tidy(mycli_command_line)

add_library(mycli_counting STATIC counting/counting.cpp)
target_include_directories(mycli_counting PUBLIC "${CMAKE_CURRENT_LIST_DIR}/counting")
target_compile_features(mycli_counting PUBLIC cxx_std_23)
cppbp_set_warnings(mycli_counting PRIVATE)
cppbp_set_sanitizers(mycli_counting PUBLIC)
cppbp_enable_clang_tidy(mycli_counting)

add_library(mycli_report STATIC report/report.cpp)
target_include_directories(mycli_report PUBLIC "${CMAKE_CURRENT_LIST_DIR}/report")
target_compile_features(mycli_report PUBLIC cxx_std_23)
target_link_libraries(mycli_report PUBLIC mycli_command_line mycli_counting)
cppbp_set_warnings(mycli_report PRIVATE)
cppbp_set_sanitizers(mycli_report PUBLIC)
cppbp_enable_clang_tidy(mycli_report)

# main.cpp is the only file here that is not in a module, and the only one no
# test links: a function in a library can be called by a test, and a function in
# main() can only be checked by starting a process. That is the whole reason the
# modules above are libraries.
#
# It links all three because it is the place they meet. Nothing else does.
add_executable(mycli main.cpp)
target_link_libraries(mycli PRIVATE mycli_command_line mycli_counting mycli_report)

# Built at the top of the build directory rather than under src/, so that the
# path README.md tells a reader to type is still the path:
#
#   ./build/debug/mycli
#
# PROJECT_BINARY_DIR rather than CMAKE_BINARY_DIR: in a build that adds this
# project as a subdirectory, the top of the tree belongs to whoever is above.
set_target_properties(mycli PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}")

cppbp_set_warnings(mycli PRIVATE)
cppbp_set_sanitizers(mycli PRIVATE)
cppbp_enable_clang_tidy(mycli)
