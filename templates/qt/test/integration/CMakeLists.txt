# More than one module, wired together inside this process and no process
# started. This is where the interface is loaded: the QML module, the plugin
# that registers its types and the C++ the QML binds to, in a real engine.
#
# It brings its own main(), because the engine needs a QGuiApplication to exist
# before it does and gtest_main knows nothing about that. GTest::gtest rather
# than GTest::gtest_main for the same reason.
#
# Nothing here says whether main() reaches startup, or whether the window can be
# put on a screen that is not there. e2e/ is what says that.
add_executable(myapp_interface_test interface_test.cpp)
target_link_libraries(myapp_interface_test PRIVATE myapp_ui myapp_uiplugin GTest::gtest)
cppbp_set_warnings(myapp_interface_test PRIVATE)
cppbp_set_sanitizers(myapp_interface_test PRIVATE)
cppbp_enable_clang_tidy(myapp_interface_test)

gtest_discover_tests(myapp_interface_test PROPERTIES ENVIRONMENT "${MYAPP_TEST_ENVIRONMENT}")
