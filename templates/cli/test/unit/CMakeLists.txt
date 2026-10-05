# One executable per module, and the link line is half the check.
#
# mycli_counting_test links mycli_counting and nothing else. The day counting
# starts using a function of another module, this stops linking - which is an
# answer from the build rather than from whoever is reading the includes. That
# holds for what has external linkage; a struct used from a header costs no
# symbol, and scripts/check-module-includes.sh and the include path are what
# answer for those.
#
# A single test executable over the whole program cannot say that: every module
# is on its link line already, so a dependency nobody declared resolves and the
# test passes.
#
# Nor can it for a module that has dependencies of its own: a static library
# carries what it links privately to whoever links it, so mycli_report_test has
# counting on its link line whether or not report named it. The answer the link
# line gives is a firm one for a leaf, and the include path and
# scripts/check-module-includes.sh are what answer above that.
#
# TEST_PREFIX puts the module in front of every test name, so that ctest output
# and a failing run say which module is wrong without opening the file.
#
# A test that needs something else - a fixture target, a thread library - names
# it in its own target_link_libraries after the call, the way a module with a
# second source file adds it with target_sources.
function(mycli_add_unit_test module)
    add_executable(mycli_${module}_test ${module}_test.cpp)
    target_link_libraries(mycli_${module}_test PRIVATE mycli_${module} GTest::gtest_main)
    cppbp_set_warnings(mycli_${module}_test PRIVATE)
    cppbp_set_sanitizers(mycli_${module}_test PRIVATE)
    cppbp_enable_clang_tidy(mycli_${module}_test)
    gtest_discover_tests(mycli_${module}_test TEST_PREFIX "${module}.")
endfunction()

mycli_add_unit_test(command_line)
mycli_add_unit_test(counting)

# This one names counting as well, and is still a unit test: report::format
# takes counting's types, so they are part of calling it rather than a second
# thing under test. It links only mycli_report, which hands counting over
# because report declared it PUBLIC. The argument parser is not among them:
# report knows nothing of it.
mycli_add_unit_test(report)
