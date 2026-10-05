# The tests in unit/ prove the code works. This one proves the package works.
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
            # PROJECT_BINARY_DIR, not CMAKE_BINARY_DIR: in the monorepo that
            # builds every template, the top of the tree installs all four, so a
            # broken install rule in another one would turn this test red and
            # name mylib.
            -D "LIBRARY_BUILD_DIR=${PROJECT_BINARY_DIR}"
            -D "WORK_DIR=${CMAKE_CURRENT_BINARY_DIR}/install-consume"
            -D "GENERATOR=${CMAKE_GENERATOR}"
            -D "BUILD_TYPE=$<CONFIG>"
            -D "C_COMPILER=${CMAKE_C_COMPILER}"
            -D "CXX_COMPILER=${CMAKE_CXX_COMPILER}"
            -D "CXX_FLAGS=${CMAKE_CXX_FLAGS} ${mylib_sanitizer_flags}"
            -D "LINKER_FLAGS=${mylib_sanitizer_flags}"
            -P "${CMAKE_CURRENT_LIST_DIR}/run-install-consume.cmake")

# add_test expands the paths and checks nothing. In a build directory where only
# a test was built, the install step would fail on a library that was never
# built; REQUIRED_FILES makes ctest say NOT RUN instead.
set_tests_properties(mylib.install-consume PROPERTIES
    REQUIRED_FILES "$<TARGET_FILE:mylib>")
