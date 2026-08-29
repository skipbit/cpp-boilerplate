include(TestDependencies)
include(GoogleTest)

# One executable for every test file in the program's library. The library is
# what makes this possible: linking main.cpp here would mean two entry points,
# so a program whose logic lives in main() gets tested by running it, or not at
# all.
add_executable(mycli_test
    command_line_test.cpp
    counting_test.cpp
    report_test.cpp)
target_link_libraries(mycli_test PRIVATE mycli_lib GTest::gtest_main)
cppbp_set_warnings(mycli_test PRIVATE)
cppbp_set_sanitizers(mycli_test PRIVATE)
cppbp_enable_clang_tidy(mycli_test)

gtest_discover_tests(mycli_test)

# The tests above prove the pieces work. This one proves the program does: it
# runs the built executable the way somebody at a shell would, and checks what
# comes back on standard output and in the exit status. Nothing else here can
# fail if main() wires the pieces together wrongly.
add_test(NAME mycli.runs COMMAND "${CMAKE_COMMAND}"
    -D "PROGRAM=$<TARGET_FILE:mycli>"
    -D "WORK_DIR=${CMAKE_CURRENT_BINARY_DIR}/run"
    -P "${CMAKE_CURRENT_LIST_DIR}/run-program.cmake")

# The shared check on cppbp_require_std_feature, which the CMake modules bring
# with them. It is registered by whoever is the top of the build: in this
# repository that is the file that adds every template, so this condition is
# false and nothing here runs twice; in the published copy of this template
# there is no such file, cmake/test is a real directory rather than a symlink,
# and this is what puts the tests in ctest.
if(PROJECT_IS_TOP_LEVEL)
    add_subdirectory("${CMAKE_CURRENT_LIST_DIR}/../cmake/test" cmake-test)
endif()
