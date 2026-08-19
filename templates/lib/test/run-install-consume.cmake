# Driver for the mylib.install-consume test. Runs in CMake script mode.
#
# Each step is checked, because a silent failure here would look like a pass:
# an unbuilt consumer runs no assertions.

set(prefix "${WORK_DIR}/prefix")
set(build "${WORK_DIR}/build")

file(REMOVE_RECURSE "${prefix}" "${build}")

function(run_step description)
    execute_process(COMMAND ${ARGN} RESULT_VARIABLE result OUTPUT_VARIABLE out ERROR_VARIABLE err)
    if(NOT result EQUAL 0)
        message(FATAL_ERROR "${description} failed (${result})\n--- stdout ---\n${out}\n--- stderr ---\n${err}")
    endif()
endfunction()

run_step("installing the library"
    "${CMAKE_COMMAND}" --install "${LIBRARY_BUILD_DIR}" --prefix "${prefix}" --config "${BUILD_TYPE}")

# The consumer is configured with the same compiler and flags as the library.
# Without this it would pick the system default, and a library built with
# libc++ would fail to link against a consumer built with libstdc++ - an ABI
# mismatch reported as an undefined reference, which says nothing about whether
# the package itself is correct. Sanitizers are part of that agreement: the
# runtime lives in the executable, so the consumer has to be linked with them
# too or the library's instrumentation has nothing to call.
run_step("configuring the consumer"
    "${CMAKE_COMMAND}" -S "${SOURCE_DIR}" -B "${build}" -G "${GENERATOR}"
    "-DCMAKE_PREFIX_PATH=${prefix}"
    "-DCMAKE_BUILD_TYPE=${BUILD_TYPE}"
    "-DCMAKE_C_COMPILER=${C_COMPILER}"
    "-DCMAKE_CXX_COMPILER=${CXX_COMPILER}"
    "-DCMAKE_CXX_FLAGS=${CXX_FLAGS}"
    "-DCMAKE_EXE_LINKER_FLAGS=${LINKER_FLAGS}")

run_step("building the consumer"
    "${CMAKE_COMMAND}" --build "${build}" --config "${BUILD_TYPE}")

# The consumer asserts on the library's behaviour and returns non-zero on
# mismatch, so running it checks the linked artifact, not just the link.
find_program(consumer NAMES consumer PATHS "${build}" "${build}/${BUILD_TYPE}" NO_DEFAULT_PATH REQUIRED)
run_step("running the consumer" "${consumer}")
