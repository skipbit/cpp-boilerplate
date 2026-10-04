# One executable per public header, which is the unit this library is written
# in: one feature is one header, one implementation and one test. A failure
# names the header it came from before anybody opens the log.
#
# They all link mylib::mylib, because that is what this project publishes -
# one library, and the only thing a consumer can link. The library templates in
# this repository for programs give each module its own target and let the link
# line do some of the checking; here the single target is the product.
add_executable(mylib_text_test text_test.cpp)
target_link_libraries(mylib_text_test PRIVATE mylib::mylib GTest::gtest_main)
cppbp_set_warnings(mylib_text_test PRIVATE)
cppbp_set_sanitizers(mylib_text_test PRIVATE)
cppbp_enable_clang_tidy(mylib_text_test)

gtest_discover_tests(mylib_text_test)
