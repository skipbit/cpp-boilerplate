# The tests in integration/ load the interface in process. This one starts the program,
# which is the only way to check the part that is not a function: that main()
# reaches startup, that the command line is answered, and that the window can be
# put on a screen that is not there.
add_test(NAME myapp.starts
    COMMAND "${CMAKE_CURRENT_LIST_DIR}/run-app.sh"
            "$<TARGET_FILE:myapp>"
            "${CMAKE_CURRENT_BINARY_DIR}/run")

# Longer than it needs, because a sanitizer build is slower than this one.
#
# REQUIRED_FILES because add_test expands the path and checks nothing: in a
# build directory where only a test was built, this would start a program that
# is not there and fail inside it. ctest says NOT RUN instead.
set_tests_properties(myapp.starts PROPERTIES
    TIMEOUT 120 ENVIRONMENT "${MYAPP_TEST_ENVIRONMENT}"
    REQUIRED_FILES "$<TARGET_FILE:myapp>")
