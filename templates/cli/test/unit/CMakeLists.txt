# One executable per module, and the link line is half the check.
#
# mycli_counting_test links mycli_counting and nothing else. The day counting
# starts using a piece of another module, this stops linking - which is an
# answer from the build rather than from whoever is reading the includes.
#
# A single test executable over the whole program cannot say that: every module
# is on its link line already, so a dependency nobody declared resolves and the
# test passes.

add_executable(mycli_command_line_test command_line_test.cpp)
target_link_libraries(mycli_command_line_test PRIVATE mycli_command_line GTest::gtest_main)
cppbp_set_warnings(mycli_command_line_test PRIVATE)
cppbp_set_sanitizers(mycli_command_line_test PRIVATE)
cppbp_enable_clang_tidy(mycli_command_line_test)
gtest_discover_tests(mycli_command_line_test)

add_executable(mycli_counting_test counting_test.cpp)
target_link_libraries(mycli_counting_test PRIVATE mycli_counting GTest::gtest_main)
cppbp_set_warnings(mycli_counting_test PRIVATE)
cppbp_set_sanitizers(mycli_counting_test PRIVATE)
cppbp_enable_clang_tidy(mycli_counting_test)
gtest_discover_tests(mycli_counting_test)

# This one names command_line and counting as well, and is still a unit test:
# report::format takes their types, so they are part of calling it rather than
# a second thing under test. It links only mycli_report, which hands over both
# because report declared them PUBLIC.
add_executable(mycli_report_test report_test.cpp)
target_link_libraries(mycli_report_test PRIVATE mycli_report GTest::gtest_main)
cppbp_set_warnings(mycli_report_test PRIVATE)
cppbp_set_sanitizers(mycli_report_test PRIVATE)
cppbp_enable_clang_tidy(mycli_report_test)
gtest_discover_tests(mycli_report_test)
