# Three levels, and the directory a test sits in is what says which one it is:
#
#   unit/         one module, called directly
#   integration/  more than one module, wired together inside this process
#   e2e/          the program, started as a process
#
# The split is not filing. A failing unit test names the module that is wrong; a
# failing e2e test says only that the program is, and leaves the finding to a
# person. Keeping them apart is what lets the first kind stay the common one.
#
# Both included here rather than in each subdirectory: TestDependencies fetches
# once either way, and a test level that could be configured without a test
# framework is not one of the things worth allowing.
include(TestDependencies)
include(GoogleTest)

# The tests that start a QML engine run threads this project did not write, in a
# Qt that was not built with a sanitizer. tsan-suppressions.txt says which
# libraries that covers, and why it is not the same as switching the check off.
# Named here because two of the levels below need it.
set(MYAPP_TEST_ENVIRONMENT
    "TSAN_OPTIONS=suppressions=${CMAKE_CURRENT_LIST_DIR}/tsan-suppressions.txt")

add_subdirectory(unit)
add_subdirectory(integration)
add_subdirectory(e2e)

# qmllint is to QML what clang-tidy is to the C++, and nothing else here reads
# the .qml files at all - to the compiler they are bytes in a resource. It is in
# none of the three directories above because it is a lint rather than a level:
# it starts nothing and calls nothing.
#
# qt_add_qml_module generates the target that runs it; this asks for that target
# rather than for the tool, so finding it is Qt's problem and not this file's.
#
# Not on Qt 6.4, which is what Ubuntu 24.04 ships. Its qmllint cannot resolve a
# C++ type registered with QML_ELEMENT - it reports FilteredEntries as
# unresolved and QAbstractItemModel as missing - so running it there would mean
# either ignoring its answer or writing the QML around a blind spot. 6.5 and
# newer resolve both, and the CI runs this on 26.04.
if(Qt6_VERSION VERSION_LESS 6.5)
    message(STATUS "qmllint: Qt ${Qt6_VERSION} cannot resolve QML_ELEMENT types; myapp.qmllint will not run")
else()
    add_test(NAME myapp.qmllint
        COMMAND "${CMAKE_COMMAND}" --build "${CMAKE_BINARY_DIR}" --target all_qmllint)
endif()

# The shared check on cppbp_require_std_feature, which the CMake modules bring
# with them. It is registered by whoever is the top of the build: in this
# repository that is the file that adds every template, so this condition is
# false and nothing here runs twice; in the published copy of this template
# there is no such file, cmake/test is a real directory rather than a symlink,
# and this is what puts the tests in ctest.
if(PROJECT_IS_TOP_LEVEL)
    add_subdirectory("${CMAKE_CURRENT_LIST_DIR}/../cmake/test" cmake-test)
endif()
