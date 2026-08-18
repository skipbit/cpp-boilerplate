include(TestDependencies)
include(GoogleTest)

add_executable(mylib_test text_test.cpp)
target_link_libraries(mylib_test PRIVATE mylib::mylib GTest::gtest_main)
cppbp_set_warnings(mylib_test PRIVATE)
cppbp_set_sanitizers(mylib_test PRIVATE)

gtest_discover_tests(mylib_test)

# The test above proves the code works. It does not prove the package works.
#
# A library that builds and passes its own tests can still be unusable: the
# export set may miss a target, the config file may reference a path that only
# exists in the build tree, the include directories may leak absolute paths.
# None of that shows up until something consumes the installed package.
#
# So: install into a scratch prefix, then configure and build a separate
# project that finds it with find_package() and links mylib::mylib. This is the
# check that disappears if each template is developed in isolation.
#
# The compiler and flags are passed through deliberately. A consumer built with
# a different standard library links against different symbol names, so leaving
# it to default would turn a real ABI question into an unrelated link error.
add_test(
    NAME mylib.install-consume
    COMMAND "${CMAKE_COMMAND}"
            -D "SOURCE_DIR=${CMAKE_CURRENT_LIST_DIR}/install-consume"
            -D "LIBRARY_BUILD_DIR=${CMAKE_BINARY_DIR}"
            -D "WORK_DIR=${CMAKE_CURRENT_BINARY_DIR}/install-consume"
            -D "GENERATOR=${CMAKE_GENERATOR}"
            -D "BUILD_TYPE=$<CONFIG>"
            -D "C_COMPILER=${CMAKE_C_COMPILER}"
            -D "CXX_COMPILER=${CMAKE_CXX_COMPILER}"
            -D "CXX_FLAGS=${CMAKE_CXX_FLAGS}"
            -P "${CMAKE_CURRENT_LIST_DIR}/run-install-consume.cmake")
