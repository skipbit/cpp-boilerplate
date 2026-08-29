include(TestDependencies)
include(GoogleTest)

add_executable(mylib_test text_test.cpp)
target_link_libraries(mylib_test PRIVATE mylib::mylib GTest::gtest_main)
cppbp_set_warnings(mylib_test PRIVATE)
cppbp_set_sanitizers(mylib_test PRIVATE)
cppbp_enable_clang_tidy(mylib_test)

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
#
# The sanitizer flags go with them for the same reason. They are added per
# target rather than through CMAKE_CXX_FLAGS, so the consumer cannot see them
# unless they are handed over here - and a consumer that links a sanitized
# static library without them fails on missing __asan_* symbols.
cppbp_sanitizer_flags(mylib_sanitizer_flags)
list(JOIN mylib_sanitizer_flags " " mylib_sanitizer_flags)

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
            -D "CXX_FLAGS=${CMAKE_CXX_FLAGS} ${mylib_sanitizer_flags}"
            -D "LINKER_FLAGS=${mylib_sanitizer_flags}"
            -P "${CMAKE_CURRENT_LIST_DIR}/run-install-consume.cmake")

# The shared check on cppbp_require_std_feature, which the CMake modules bring
# with them. It is registered by whoever is the top of the build: in this
# repository that is the file that adds every template, so this condition is
# false and nothing here runs twice; in the published copy of this template
# there is no such file, cmake/test is a real directory rather than a symlink,
# and this is what puts the tests in ctest.
if(PROJECT_IS_TOP_LEVEL)
    add_subdirectory("${CMAKE_CURRENT_LIST_DIR}/../cmake/test" cmake-test)
endif()
