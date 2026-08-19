# What the standard library in front of this compiler actually has.
#
# "C++23" is not one thing, and not one thing per compiler either: it is a
# compiler and a standard library, and the two disagree. Measured on a stock
# Ubuntu 24.04, all three with -std=gnu++23:
#
#   GCC 13.3   + libstdc++ 13   std::expected yes   std::print no
#   Clang 18.1 + libstdc++ 13   std::expected NO    std::print no
#   Clang 18.1 + libc++ 18      std::expected yes   std::print yes
#
# The same compiler, a different answer, depending on a library nobody chose on
# purpose. Which is why nothing here is decided by comparing a version number:
# each answer below comes from compiling the feature and seeing what happened.
#
# Two results, both cached and usable from any template:
#
#   CPPBP_HAS_STD_EXPECTED
#   CPPBP_HAS_STD_PRINT
#
# and one command for code that wants to insist on one:
#
#   cppbp_require_std_feature(EXPECTED)
#
# which stops configuration on the environments that do not have it, naming the
# environment and the way out - instead of a compile error a hundred lines into
# a build, or in somebody else's clone of your repository.
#
# The code this template ships uses neither, on purpose: it stays inside what
# every environment in the CI matrix provides, so that the presets it advertises
# work on a stock machine. These exist for the code that replaces it.
# docs/standard-library.md has the reasoning.

# include_guard() alone does not hold here: the monorepo reaches this file
# through a per-template symlink, so each template includes it under a different
# path, the guard sees two different files, and the summary below is printed
# once per template. A global property is keyed by nothing but itself.
include_guard(GLOBAL)

get_property(cppbp_std_features_done GLOBAL PROPERTY CPPBP_STD_FEATURES_DONE)
if(cppbp_std_features_done)
    return()
endif()
set_property(GLOBAL PROPERTY CPPBP_STD_FEATURES_DONE TRUE)

include(CheckCXXSourceCompiles)

# One row per feature: a name, and a program that uses it. Adding a feature
# means adding a row and a paragraph in cppbp_require_std_feature below, and
# nothing else; removing one means deleting them.
#
# Compiled, not included. <expected> exists in every environment above; in the
# one that lacks the feature it is an empty file, because the library declares
# its contents only under a condition that compiler does not satisfy. A check
# that asks whether the header can be found answers yes there, and is wrong.
set(CPPBP_STD_FEATURES EXPECTED PRINT CACHE INTERNAL "Standard library features this project can check for")

set(cppbp_probe_EXPECTED "
    #include <expected>
    int main() { std::expected<int, int> value{1}; return value.value_or(0); }
")
set(cppbp_probe_PRINT "
    #include <print>
    int main() { std::print(\"{}\", 0); }
")

# The standard is set here because this project sets it per target, with
# target_compile_features, and check_cxx_source_compiles knows nothing about
# targets: left alone it compiles with the compiler's default standard, which is
# not C++23, and every check below would fail for a reason that is not the one
# being asked about.
block(SCOPE_FOR VARIABLES)
    set(CMAKE_CXX_STANDARD 23)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)

    foreach(feature IN LISTS CPPBP_STD_FEATURES)
        check_cxx_source_compiles("${cppbp_probe_${feature}}" CPPBP_HAS_STD_${feature})
    endforeach()

    # Which library, for the message only. Every decision above is a compile.
    check_cxx_source_compiles("
        #include <version>
        #ifndef __GLIBCXX__
        #error not libstdc++
        #endif
        int main() {}
    " CPPBP_STANDARD_LIBRARY_IS_LIBSTDCXX)

    check_cxx_source_compiles("
        #include <version>
        #ifndef _LIBCPP_VERSION
        #error not libc++
        #endif
        int main() {}
    " CPPBP_STANDARD_LIBRARY_IS_LIBCXX)
endblock()

# Cached rather than set here: include_guard(GLOBAL) means the second template
# to include this file gets none of it, so anything a later scope reads has to
# outlive this one.
if(CPPBP_STANDARD_LIBRARY_IS_LIBSTDCXX)
    set(CPPBP_STANDARD_LIBRARY "libstdc++" CACHE INTERNAL "The C++ standard library in use")
elseif(CPPBP_STANDARD_LIBRARY_IS_LIBCXX)
    set(CPPBP_STANDARD_LIBRARY "libc++" CACHE INTERNAL "The C++ standard library in use")
else()
    set(CPPBP_STANDARD_LIBRARY "unrecognised" CACHE INTERNAL "The C++ standard library in use")
endif()

# Said out loud at configuration time. A check whose answer nobody sees is a
# check that gets contradicted by a comment six months later.
function(_cppbp_report_std_features)
    set(report "")
    foreach(feature IN LISTS CPPBP_STD_FEATURES)
        string(TOLOWER "${feature}" spelling)
        if(CPPBP_HAS_STD_${feature})
            string(APPEND report ", std::${spelling} yes")
        else()
            string(APPEND report ", std::${spelling} no")
        endif()
    endforeach()
    message(STATUS
        "Standard library: ${CPPBP_STANDARD_LIBRARY}"
        " (${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}${report})")
endfunction()

_cppbp_report_std_features()

# Refuses to configure when a feature this project depends on is not there.
#
#   cppbp_require_std_feature(EXPECTED)
#
# Put it next to the code that needs it, in CMakeLists.txt. Deleting the line is
# one of the answers the failure offers, and the honest one when the dependency
# turns out to be a preference.
function(cppbp_require_std_feature name)
    # An unknown name has to be an error rather than a pass. CPPBP_HAS_STD_TYPO
    # is empty, so the obvious spelling of this check would let a misspelled
    # feature through on every machine, and the gate would protect nothing.
    if(NOT name IN_LIST CPPBP_STD_FEATURES)
        message(FATAL_ERROR
            "cppbp_require_std_feature(${name}): no such feature."
            " Known: ${CPPBP_STD_FEATURES}.\n"
            "Add a check for it in cmake/modules/StandardLibraryFeatures.cmake first;"
            " a name nothing tests would pass here everywhere.")
    endif()

    if(CPPBP_HAS_STD_${name})
        return()
    endif()

    if(name STREQUAL "EXPECTED")
        set(spelling "std::expected")
        set(cause
"libstdc++ declares std::expected only when the compiler reports
__cpp_concepts >= 202002L. The clang Ubuntu 24.04 ships reports 201907L, so
<expected> is there and empty. The same compiler against libc++ has it.")
        set(ways
"Build with libc++:   cmake --preset clang-libc++
or with GCC:         cmake --preset debug")
    else()
        set(spelling "std::print")
        set(cause
"GCC 13, which Ubuntu 24.04 ships, has no <print> at all; it arrived in GCC 14.
Clang 18 has it against libc++ and does not against libstdc++ 13.")
        set(ways
"Build with libc++:   cmake --preset clang-libc++
GCC 13 has no way to this one. GCC 14, or Ubuntu 26.04, does.")
    endif()

    # Printed rather than passed to FATAL_ERROR, which rewraps what it is given
    # and would turn the commands below into prose. The point of naming a preset
    # is that it can be copied.
    message(NOTICE "
${spelling} is not available here.

  compiler:         ${CMAKE_CXX_COMPILER_ID} ${CMAKE_CXX_COMPILER_VERSION}
  standard library: ${CPPBP_STANDARD_LIBRARY}

${cause}

${ways}
or remove            cppbp_require_std_feature(${name})   from CMakeLists.txt.

docs/standard-library.md has the rest.
")
    message(FATAL_ERROR "${spelling} is missing from this toolchain; see above.")
endfunction()
