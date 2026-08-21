include(TestDependencies)
include(GoogleTest)

# The tests that start a QML engine run threads this project did not write, in a
# Qt that was not built with a sanitizer. tsan-suppressions.txt says which
# libraries that covers, and why it is not the same as switching the check off.
set(MYAPP_TEST_ENVIRONMENT
    "TSAN_OPTIONS=suppressions=${CMAKE_CURRENT_LIST_DIR}/tsan-suppressions.txt")

# Three executables, and the split is the design rather than an accident of
# size. This one links myapp_core and nothing else: if a Qt type ever reaches
# the core, it stops linking, which is a firmer answer than a review comment.
add_executable(myapp_core_test
    catalogue_test.cpp
    presentation_test.cpp)
target_link_libraries(myapp_core_test PRIVATE myapp_core GTest::gtest_main)
cppbp_set_warnings(myapp_core_test PRIVATE)
cppbp_set_sanitizers(myapp_core_test PRIVATE)
cppbp_enable_clang_tidy(myapp_core_test)

gtest_discover_tests(myapp_core_test)

# The class QML binds to. It links Qt, and still needs no application object -
# which is why it is here rather than in the file below.
add_executable(myapp_bridge_test filtered_entries_test.cpp)
target_link_libraries(myapp_bridge_test PRIVATE myapp_bridge GTest::gtest_main)
cppbp_set_warnings(myapp_bridge_test PRIVATE)
cppbp_set_sanitizers(myapp_bridge_test PRIVATE)
cppbp_enable_clang_tidy(myapp_bridge_test)

gtest_discover_tests(myapp_bridge_test)

# And this one loads the QML. It brings its own main(), because the engine needs
# a QGuiApplication to exist before it does, and gtest_main knows nothing about
# that.
add_executable(myapp_interface_test interface_test.cpp)
target_link_libraries(myapp_interface_test PRIVATE myapp_ui myapp_uiplugin GTest::gtest)
cppbp_set_warnings(myapp_interface_test PRIVATE)
cppbp_set_sanitizers(myapp_interface_test PRIVATE)
cppbp_enable_clang_tidy(myapp_interface_test)

gtest_discover_tests(myapp_interface_test PROPERTIES ENVIRONMENT "${MYAPP_TEST_ENVIRONMENT}")

# qmllint is to QML what clang-tidy is to the C++, and nothing else here reads
# the .qml files at all - to the compiler they are bytes in a resource.
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

# The tests above load the interface in process. This one starts the program,
# which is the only way to check the part that is not a function: that main()
# reaches startup, that the command line is answered, and that the window can be
# put on a screen that is not there.
add_test(NAME myapp.starts
    COMMAND "${CMAKE_CURRENT_LIST_DIR}/run-app.sh"
            "$<TARGET_FILE:myapp>"
            "${CMAKE_CURRENT_BINARY_DIR}/run")

set_tests_properties(myapp.starts PROPERTIES TIMEOUT 120 ENVIRONMENT "${MYAPP_TEST_ENVIRONMENT}")
