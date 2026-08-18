# clang-tidy runs as part of the compile step, so a violation fails the build the
# same way a compile error does. It is opt-in: a contributor without clang-tidy
# installed can still build, while pr-check.yml always turns it on.

if(NOT CPPBP_ENABLE_CLANG_TIDY)
    return()
endif()

find_program(CPPBP_CLANG_TIDY_EXE NAMES clang-tidy)

if(NOT CPPBP_CLANG_TIDY_EXE)
    message(FATAL_ERROR "CPPBP_ENABLE_CLANG_TIDY is ON but clang-tidy was not found")
endif()

message(STATUS "clang-tidy: ${CPPBP_CLANG_TIDY_EXE}")

# --warnings-as-errors is intentional: a warning nobody has to fix is a warning
# everybody learns to ignore.
set(CMAKE_CXX_CLANG_TIDY "${CPPBP_CLANG_TIDY_EXE};--warnings-as-errors=*"
    CACHE STRING "clang-tidy command line" FORCE)
