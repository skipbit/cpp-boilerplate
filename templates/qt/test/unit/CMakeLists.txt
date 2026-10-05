# One executable per module, and the link line is half the check.
#
# myapp_catalogue_test links myapp_catalogue and nothing else, so a Qt type that
# ever reaches the catalogue stops it linking - a firmer answer than a review
# comment. The day catalogue starts using a function of another module, the same
# thing happens. That holds for what has external linkage; a struct used from a
# header costs no symbol, and scripts/check-module-includes.sh and the include
# path are what answer for those.
#
# A single test executable over the whole program cannot say that: every module
# is on its link line already, so a dependency nobody declared resolves and the
# test passes.
#
# Nor can it for a module that has dependencies of its own: a static library
# carries what it links privately to whoever links it, so myapp_filtered_entries_test has presentation on
# its link line whether or not filtered_entries named it. The answer the link line
# gives is a firm one for a leaf, and the include path and
# scripts/check-module-includes.sh are what answer above that.
#
# TEST_PREFIX puts the module in front of every test name, so that ctest output
# and a failing run say which module is wrong without opening the file.
#
# A test that needs something else - a fixture target, a thread library - names
# it in its own target_link_libraries after the call, the way a module with a
# second source file adds it with target_sources.
#
# None of these needs a QGuiApplication. That is what "the logic is not in the
# interface" has to mean if it is to mean anything, and it is checked here by
# the two below that run without one.
function(myapp_add_unit_test module)
    add_executable(myapp_${module}_test ${module}_test.cpp)
    target_link_libraries(myapp_${module}_test PRIVATE myapp_${module} GTest::gtest_main)
    cppbp_set_warnings(myapp_${module}_test PRIVATE)
    cppbp_set_sanitizers(myapp_${module}_test PRIVATE)
    cppbp_enable_clang_tidy(myapp_${module}_test)
    gtest_discover_tests(myapp_${module}_test TEST_PREFIX "${module}.")
endfunction()

myapp_add_unit_test(catalogue)
myapp_add_unit_test(presentation)

# The class QML binds to. It links Qt, and still needs no application object -
# which is why it is here rather than in integration/.
myapp_add_unit_test(filtered_entries)
