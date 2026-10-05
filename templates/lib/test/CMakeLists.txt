# Three levels, and the directory a test sits in is what says which one it is:
#
#   unit/         one public header, called directly
#   integration/  more than one of the public headers, used together
#   e2e/          the installed package, found with find_package and linked
#
# The split is not filing. A failing unit test names the function that is wrong;
# a failing e2e test says only that the package is, and leaves the finding to a
# person. Keeping them apart is what lets the first kind stay the common one.
#
# Both included here rather than in each subdirectory: TestDependencies fetches
# once either way, and a test level that could be configured without a test
# framework is not one of the things worth allowing.
include(TestDependencies)
include(GoogleTest)

add_subdirectory(unit)
add_subdirectory(integration)
add_subdirectory(e2e)

# The shared check on cppbp_require_std_feature, which the CMake modules bring
# with them. It is registered by whoever is the top of the build: in this
# repository that is the file that adds every template, so this condition is
# false and nothing here runs twice; in the published copy of this template
# there is no such file, cmake/test is a real directory rather than a symlink,
# and this is what puts the tests in ctest.
if(PROJECT_IS_TOP_LEVEL)
    add_subdirectory("${CMAKE_CURRENT_LIST_DIR}/../cmake/test" cmake-test)
endif()
