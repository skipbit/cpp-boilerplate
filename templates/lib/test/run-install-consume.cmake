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

run_step("configuring the consumer"
    "${CMAKE_COMMAND}" -S "${SOURCE_DIR}" -B "${build}" -G "${GENERATOR}"
    "-DCMAKE_PREFIX_PATH=${prefix}" "-DCMAKE_BUILD_TYPE=${BUILD_TYPE}")

run_step("building the consumer"
    "${CMAKE_COMMAND}" --build "${build}" --config "${BUILD_TYPE}")

# The consumer asserts on the library's behaviour and returns non-zero on
# mismatch, so running it checks the linked artifact, not just the link.
find_program(consumer NAMES consumer PATHS "${build}" "${build}/${BUILD_TYPE}" NO_DEFAULT_PATH REQUIRED)
run_step("running the consumer" "${consumer}")
