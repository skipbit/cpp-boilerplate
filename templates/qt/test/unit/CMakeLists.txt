# One executable per module, and the link line is half the check.
#
# myapp_catalogue_test links myapp_catalogue and nothing else, so a Qt type that
# ever reaches the catalogue stops it linking - a firmer answer than a review
# comment. The day catalogue starts using a piece of another module, the same
# thing happens.
#
# A single test executable over the whole program cannot say that: every module
# is on its link line already, so a dependency nobody declared resolves and the
# test passes.
#
# None of these needs a QGuiApplication. That is what "the logic is not in the
# interface" has to mean if it is to mean anything, and it is checked here by
# the two below that run without one.

add_executable(myapp_catalogue_test catalogue_test.cpp)
target_link_libraries(myapp_catalogue_test PRIVATE myapp_catalogue GTest::gtest_main)
cppbp_set_warnings(myapp_catalogue_test PRIVATE)
cppbp_set_sanitizers(myapp_catalogue_test PRIVATE)
cppbp_enable_clang_tidy(myapp_catalogue_test)
gtest_discover_tests(myapp_catalogue_test)

add_executable(myapp_presentation_test presentation_test.cpp)
target_link_libraries(myapp_presentation_test PRIVATE myapp_presentation GTest::gtest_main)
cppbp_set_warnings(myapp_presentation_test PRIVATE)
cppbp_set_sanitizers(myapp_presentation_test PRIVATE)
cppbp_enable_clang_tidy(myapp_presentation_test)
gtest_discover_tests(myapp_presentation_test)

# The class QML binds to. It links Qt, and still needs no application object -
# which is why it is here rather than in integration/.
add_executable(myapp_filtered_entries_test filtered_entries_test.cpp)
target_link_libraries(myapp_filtered_entries_test
    PRIVATE myapp_filtered_entries GTest::gtest_main)
cppbp_set_warnings(myapp_filtered_entries_test PRIVATE)
cppbp_set_sanitizers(myapp_filtered_entries_test PRIVATE)
cppbp_enable_clang_tidy(myapp_filtered_entries_test)
gtest_discover_tests(myapp_filtered_entries_test)
