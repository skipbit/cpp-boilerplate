# Where a test goes when it needs more than one of the public headers and no
# installed package.
#
# This template ships one feature, so there is nothing yet to use together.
# The day two of them only break when combined - a type from one header passed
# to a function in another, a sequence that leaves something behind - that test
# belongs here rather than in unit/, where it would make a single header's
# failure look like two:
#
#   add_executable(mylib_integration_test pipeline_test.cpp)
#   target_link_libraries(mylib_integration_test PRIVATE mylib::mylib GTest::gtest_main)
#   cppbp_set_warnings(mylib_integration_test PRIVATE)
#   cppbp_set_sanitizers(mylib_integration_test PRIVATE)
#   cppbp_enable_clang_tidy(mylib_integration_test)
#   gtest_discover_tests(mylib_integration_test TEST_PREFIX "integration.")
#
# The directory is here rather than added when it is first needed, because a
# level that has to be invented under pressure is a level that gets skipped.
