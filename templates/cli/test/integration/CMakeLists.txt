# Where a test goes when it needs more than one module and no process.
#
# This template ships none, and the reason is a fact about this program rather
# than an omission: its three modules meet in exactly one place, main(), and
# main() is not in a library, so there is nothing to link. e2e/ is what checks
# that wiring here.
#
# Your program will have somewhere they meet that is not main() - a module that
# drives two others, a pipeline assembled from parts - and that is what belongs
# here:
#
#   add_executable(mycli_integration_test pipeline_test.cpp)
#   target_link_libraries(mycli_integration_test PRIVATE mycli_report GTest::gtest_main)
#   cppbp_set_warnings(mycli_integration_test PRIVATE)
#   cppbp_set_sanitizers(mycli_integration_test PRIVATE)
#   cppbp_enable_clang_tidy(mycli_integration_test)
#   gtest_discover_tests(mycli_integration_test)
#
# The directory is here rather than added when it is first needed, because a
# level that has to be invented under pressure is a level that gets skipped: the
# test ends up in unit/ linking three modules, or in e2e/ starting a process to
# check something that is not about processes.
