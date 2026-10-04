# One executable per module, and the link line is half the check.
#
# mydaemon_task_test links mydaemon_task and nothing else. The day task starts
# using a piece of another module, this stops linking - which is an answer from
# the build rather than from whoever is reading the includes.
#
# A single test executable over the whole program cannot say that: every module
# is on its link line already, so a dependency nobody declared resolves and the
# test passes.

add_executable(mydaemon_options_test options_test.cpp)
target_link_libraries(mydaemon_options_test PRIVATE mydaemon_options GTest::gtest_main)
cppbp_set_warnings(mydaemon_options_test PRIVATE)
cppbp_set_sanitizers(mydaemon_options_test PRIVATE)
cppbp_enable_clang_tidy(mydaemon_options_test)
gtest_discover_tests(mydaemon_options_test)

add_executable(mydaemon_task_test task_test.cpp)
target_link_libraries(mydaemon_task_test PRIVATE mydaemon_task GTest::gtest_main)
cppbp_set_warnings(mydaemon_task_test PRIVATE)
cppbp_set_sanitizers(mydaemon_task_test PRIVATE)
cppbp_enable_clang_tidy(mydaemon_task_test)
gtest_discover_tests(mydaemon_task_test)

add_executable(mydaemon_unique_fd_test unique_fd_test.cpp)
target_link_libraries(mydaemon_unique_fd_test PRIVATE mydaemon_unique_fd GTest::gtest_main)
cppbp_set_warnings(mydaemon_unique_fd_test PRIVATE)
cppbp_set_sanitizers(mydaemon_unique_fd_test PRIVATE)
cppbp_enable_clang_tidy(mydaemon_unique_fd_test)
gtest_discover_tests(mydaemon_unique_fd_test)

# This one names options as well, and is still a unit test: the loop takes an
# options::Options, so it is part of calling the loop rather than a second thing
# under test. It links only mydaemon_service, which hands options over because
# service declared it PUBLIC.
add_executable(mydaemon_service_test service_test.cpp)
target_link_libraries(mydaemon_service_test PRIVATE mydaemon_service GTest::gtest_main)
cppbp_set_warnings(mydaemon_service_test PRIVATE)
cppbp_set_sanitizers(mydaemon_service_test PRIVATE)
cppbp_enable_clang_tidy(mydaemon_service_test)
gtest_discover_tests(mydaemon_service_test)

# Threads because this test starts one and signals it by hand. mydaemon_shutdown
# links Threads privately and the test framework is meant to be swappable, so
# neither can be relied on to carry it here.
add_executable(mydaemon_shutdown_test shutdown_test.cpp)
target_link_libraries(mydaemon_shutdown_test
    PRIVATE mydaemon_shutdown GTest::gtest_main Threads::Threads)
cppbp_set_warnings(mydaemon_shutdown_test PRIVATE)
cppbp_set_sanitizers(mydaemon_shutdown_test PRIVATE)
cppbp_enable_clang_tidy(mydaemon_shutdown_test)
gtest_discover_tests(mydaemon_shutdown_test)
