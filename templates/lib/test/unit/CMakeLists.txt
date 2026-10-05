# One executable per public header, which is the unit this library is written
# in: one feature is one header, one implementation and one test. A failure
# names the header it came from before anybody opens the log, which is what
# TEST_PREFIX is for: ctest says text.Squeeze.TrimsBothEnds.
#
# They all link mylib::mylib, because that is what this project publishes -
# one library, and the only thing a consumer can link. The templates in this
# repository for programs give each module its own target and let the link line
# do some of the checking; here the single target is the product, so the link
# line says nothing and the header a test covers is in its name instead.
#
# A function, so that a second header is a line rather than six to keep in step
# with this one: a test that left out cppbp_set_sanitizers would build, pass,
# and run unsanitized in the asan and tsan presets with nothing to say so. A
# test that needs something else names it in its own target_link_libraries
# after the call.
function(mylib_add_unit_test name)
    add_executable(mylib_${name}_test ${name}_test.cpp)
    target_link_libraries(mylib_${name}_test PRIVATE mylib::mylib GTest::gtest_main)
    cppbp_set_warnings(mylib_${name}_test PRIVATE)
    cppbp_set_sanitizers(mylib_${name}_test PRIVATE)
    cppbp_enable_clang_tidy(mylib_${name}_test)
    gtest_discover_tests(mylib_${name}_test TEST_PREFIX "${name}.")
endfunction()

mylib_add_unit_test(text)
