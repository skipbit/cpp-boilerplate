# The program. One directory per module, and this file is the whole of what
# each one may use.
#
# A module is a directory, a static library, and the header named after it. Its
# include path is its own directory plus the directories of the modules named in
# its target_link_libraries, so reaching for one that is not named there does not
# compile:
#
#   fatal error: counting.hpp: No such file or directory
#
# That is what the extra targets buy. One library over the whole of src/ puts
# every header on every file's include path, and the dependencies between the
# pieces become whatever the code happens to do rather than something anybody
# decided.
#
# PUBLIC or PRIVATE says whether a module is part of what this one offers.
# command_line's header names counting::Selection, so counting is PUBLIC and
# reaches whoever links command_line; CLI11 appears in one .cpp file and no
# header, so it is PRIVATE and stops here.
#
# One hole is left: an include can name a path rather than a name -
# "../counting/counting.hpp" - and reach a header this include path never
# offered, since all of these end up in the same program. Which paths are
# refused, and why each one, is in scripts/check-module-includes.sh.

# What every module is, so that a module is a name and not six lines to keep in
# step with the others. A module that leaves out cppbp_enable_clang_tidy would
# be unchecked and nothing would say so; here it cannot.
#
# CMAKE_CURRENT_SOURCE_DIR rather than CMAKE_CURRENT_LIST_DIR: inside a function
# the latter is the file being processed when the function is called.
#
# A module with a second source file adds it after the call with
# target_sources. One with no source file at all is not this function's shape:
# an INTERFACE library is, and it is three lines written out.
function(mycli_add_module name)
    add_library(mycli_${name} STATIC ${name}/${name}.cpp)
    target_include_directories(mycli_${name} PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/${name}")
    # Raise this to cxx_std_26 and the CI matrix will tell you what breaks. Every
    # module says it, because the standard a module is compiled with is part of
    # what it hands to whatever links it.
    target_compile_features(mycli_${name} PUBLIC cxx_std_23)
    cppbp_set_warnings(mycli_${name} PRIVATE)
    cppbp_set_sanitizers(mycli_${name} PUBLIC)
    cppbp_enable_clang_tidy(mycli_${name})
endfunction()

# What each module may use is below, and it is the whole of the graph.
mycli_add_module(counting)

mycli_add_module(command_line)
target_include_directories(mycli_command_line
    # <mycli/version.hpp>, which --version prints. PRIVATE, like CLI11 below:
    # it is read by the implementation and named in no header.
    PRIVATE "${MYCLI_GENERATED_DIR}")
# Swapping the argument parser is a change to command_line.cpp and to
# cmake/modules/CommandLineDependencies.cmake. Nothing else names CLI11.
target_link_libraries(mycli_command_line
    PUBLIC mycli_counting
    PRIVATE CLI11::CLI11)

mycli_add_module(report)
target_link_libraries(mycli_report PUBLIC mycli_counting)

# main.cpp is the only file here that is not in a module, and the only one no
# test links: a function in a library can be called by a test, and a function in
# main() can only be checked by starting a process. That is the whole reason the
# modules above are libraries.
#
# It links all three because it is the place they meet. Nothing else does:
# command_line and report each name counting and neither names the other.
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
