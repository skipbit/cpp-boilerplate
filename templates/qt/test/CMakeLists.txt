include(TestDependencies)
include(GoogleTest)

# Two executables, because there are two libraries. This one links myapp_model
# and nothing else: if a Qt type ever reaches the model, this stops linking,
# which is a firmer answer than a review comment. Nothing in it constructs a
# QApplication, and it does not need one.
add_executable(myapp_model_test
    catalogue_test.cpp
    presentation_test.cpp)
target_link_libraries(myapp_model_test PRIVATE myapp_model GTest::gtest_main)
cppbp_set_warnings(myapp_model_test PRIVATE)
cppbp_set_sanitizers(myapp_model_test PRIVATE)
cppbp_enable_clang_tidy(myapp_model_test)

gtest_discover_tests(myapp_model_test)

# And this one builds real widgets. It brings its own main(), because a QWidget
# needs a QApplication to exist before it does, and gtest_main knows nothing
# about that.
add_executable(myapp_ui_test window_test.cpp)
target_link_libraries(myapp_ui_test PRIVATE myapp_ui GTest::gtest)
cppbp_set_warnings(myapp_ui_test PRIVATE)
cppbp_set_sanitizers(myapp_ui_test PRIVATE)
cppbp_enable_clang_tidy(myapp_ui_test)

gtest_discover_tests(myapp_ui_test)

# The tests above build widgets. This one starts the program, which is the only
# way to check the part that is not a function: that main() reaches startup,
# that the command line is answered, and that the window can be put on a screen.
add_test(NAME myapp.starts
    COMMAND "${CMAKE_CURRENT_LIST_DIR}/run-app.sh"
            "$<TARGET_FILE:myapp>"
            "${CMAKE_CURRENT_BINARY_DIR}/run")

set_tests_properties(myapp.starts PROPERTIES TIMEOUT 120)
