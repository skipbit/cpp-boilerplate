# The tests in unit/ prove the pieces work. This one proves the program does: it
# runs the built executable the way somebody at a shell would, and checks what
# comes back on standard output and in the exit status. Nothing else here can
# fail if main() wires the pieces together wrongly.
add_test(NAME mycli.runs COMMAND "${CMAKE_COMMAND}"
    -D "PROGRAM=$<TARGET_FILE:mycli>"
    -D "WORK_DIR=${CMAKE_CURRENT_BINARY_DIR}/run"
    -P "${CMAKE_CURRENT_LIST_DIR}/run-program.cmake")

# add_test expands the path and checks nothing. In a build directory where only
# a test was built, this would start a program that is not there and fail inside
# it; REQUIRED_FILES makes ctest say NOT RUN instead.
set_tests_properties(mycli.runs PROPERTIES REQUIRED_FILES "$<TARGET_FILE:mycli>")
