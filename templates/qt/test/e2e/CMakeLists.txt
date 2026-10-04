# The tests above load the interface in process. This one starts the program,
# which is the only way to check the part that is not a function: that main()
# reaches startup, that the command line is answered, and that the window can be
# put on a screen that is not there.
add_test(NAME myapp.starts
    COMMAND "${CMAKE_CURRENT_LIST_DIR}/run-app.sh"
            "$<TARGET_FILE:myapp>"
            "${CMAKE_CURRENT_BINARY_DIR}/run")

# Longer than it needs, because a sanitizer build is slower than this one.
set_tests_properties(myapp.starts PROPERTIES
    TIMEOUT 120 ENVIRONMENT "${MYAPP_TEST_ENVIRONMENT}")
