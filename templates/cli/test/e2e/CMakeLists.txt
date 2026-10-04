# The tests in unit/ prove the pieces work. This one proves the program does: it
# runs the built executable the way somebody at a shell would, and checks what
# comes back on standard output and in the exit status. Nothing else here can
# fail if main() wires the pieces together wrongly.
add_test(NAME mycli.runs COMMAND "${CMAKE_COMMAND}"
    -D "PROGRAM=$<TARGET_FILE:mycli>"
    -D "WORK_DIR=${CMAKE_CURRENT_BINARY_DIR}/run"
    -P "${CMAKE_CURRENT_LIST_DIR}/run-program.cmake")
