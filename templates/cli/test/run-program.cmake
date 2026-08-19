# Driver for the mycli.runs test. Runs in CMake script mode.
#
# Everything else in test/ calls functions. This one starts the built program,
# which is the only way to check the part of it that is not a function: that
# main() reads the files it was given, prints what was asked for, and answers
# with an exit status a shell can branch on.

file(REMOVE_RECURSE "${WORK_DIR}")
file(MAKE_DIRECTORY "${WORK_DIR}")

set(sample "${WORK_DIR}/sample.txt")
file(WRITE "${sample}" "one two\nthree\n")

function(expect description expected_status expected_output)
    execute_process(COMMAND "${PROGRAM}" ${ARGN}
        RESULT_VARIABLE status OUTPUT_VARIABLE output ERROR_VARIABLE errors)
    string(STRIP "${output}" output)
    if(NOT status STREQUAL expected_status)
        message(FATAL_ERROR
            "${description}: expected exit ${expected_status}, got ${status}\n${errors}")
    endif()
    if(NOT output STREQUAL expected_output)
        message(FATAL_ERROR
            "${description}: expected '${expected_output}', got '${output}'")
    endif()
endfunction()

expect("counting a file" 0 "2 3 14" "${sample}")
expect("counting only words" 0 "3" --words "${sample}")
expect("counting two files together" 0 "4 6 28" "${sample}" "${sample}")

# A missing file is the ordinary failure of a program that takes file names, so
# it is the one worth pinning down: a message on standard error, nothing on
# standard output, and a status that stops a shell script.
expect("refusing a file that is not there" 1 "" "${WORK_DIR}/absent.txt")
