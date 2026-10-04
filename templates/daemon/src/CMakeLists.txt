# The program. One directory per module, and this file is the whole of what
# each one may use.
#
# A module is a directory, a static library, and the header named after it. Its
# include path is its own directory plus the directories of the modules named in
# its target_link_libraries, so reaching for one that is not named there does not
# compile:
#
#   fatal error: 'task.hpp' file not found
#
# That is what the extra targets buy. One library over the whole of src/ puts
# every header on every file's include path, and the dependencies between the
# pieces become whatever the code happens to do rather than something anybody
# decided.
#
# PUBLIC or PRIVATE says whether a module is part of what this one offers.
# service's header names options::Options, so options is PUBLIC and reaches
# whoever links service; task is called by the loop and named in no header, so
# it is PRIVATE and stops here.
#
# One hole is left, because the preprocessor resolves a quoted include relative
# to the file that writes it before it consults any include path at all:
# "../task/task.hpp" would reach past everything above and still link, since all
# of these end up in the same program. scripts/check-module-includes.sh is what
# closes it.

add_library(mydaemon_options STATIC options/options.cpp)
target_include_directories(mydaemon_options
    PUBLIC "${CMAKE_CURRENT_LIST_DIR}/options"
    # <mydaemon/version.hpp>, which --version prints. PRIVATE, like CLI11 below:
    # it is read by the implementation and named in no header.
    PRIVATE "${MYDAEMON_GENERATED_DIR}")
# Raise this to cxx_std_26 and the CI matrix will tell you what breaks. Every
# module says it, because the standard a module is compiled with is part of what
# it hands to whatever links it.
target_compile_features(mydaemon_options PUBLIC cxx_std_23)
# Swapping the argument parser is a change to options.cpp and to
# cmake/modules/CommandLineDependencies.cmake. Nothing else names CLI11.
target_link_libraries(mydaemon_options PRIVATE CLI11::CLI11)
cppbp_set_warnings(mydaemon_options PRIVATE)
cppbp_set_sanitizers(mydaemon_options PUBLIC)
cppbp_enable_clang_tidy(mydaemon_options)

add_library(mydaemon_task STATIC task/task.cpp)
target_include_directories(mydaemon_task PUBLIC "${CMAKE_CURRENT_LIST_DIR}/task")
target_compile_features(mydaemon_task PUBLIC cxx_std_23)
cppbp_set_warnings(mydaemon_task PRIVATE)
cppbp_set_sanitizers(mydaemon_task PUBLIC)
cppbp_enable_clang_tidy(mydaemon_task)

add_library(mydaemon_unique_fd STATIC unique_fd/unique_fd.cpp)
target_include_directories(mydaemon_unique_fd PUBLIC "${CMAKE_CURRENT_LIST_DIR}/unique_fd")
target_compile_features(mydaemon_unique_fd PUBLIC cxx_std_23)
cppbp_set_warnings(mydaemon_unique_fd PRIVATE)
cppbp_set_sanitizers(mydaemon_unique_fd PUBLIC)
cppbp_enable_clang_tidy(mydaemon_unique_fd)

add_library(mydaemon_service STATIC service/service.cpp)
target_include_directories(mydaemon_service PUBLIC "${CMAKE_CURRENT_LIST_DIR}/service")
target_compile_features(mydaemon_service PUBLIC cxx_std_23)
target_link_libraries(mydaemon_service PUBLIC mydaemon_options PRIVATE mydaemon_task)
cppbp_set_warnings(mydaemon_service PRIVATE)
cppbp_set_sanitizers(mydaemon_service PUBLIC)
cppbp_enable_clang_tidy(mydaemon_service)

add_library(mydaemon_shutdown STATIC shutdown/shutdown.cpp)
target_include_directories(mydaemon_shutdown PUBLIC "${CMAKE_CURRENT_LIST_DIR}/shutdown")
target_compile_features(mydaemon_shutdown PUBLIC cxx_std_23)
# Both PUBLIC, and for the two reasons a header can need a module: Watcher::wait
# returns service::Wakeup, and UniqueFd is a data member, which a header needs
# complete even though it is private.
#
# Threads for pthread_sigmask, the one signal call whose behaviour is defined
# once a process has more than one thread. PRIVATE: the call is in the .cpp, and
# a static library carries it to whatever links this anyway.
target_link_libraries(mydaemon_shutdown
    PUBLIC mydaemon_service mydaemon_unique_fd
    PRIVATE Threads::Threads)
cppbp_set_warnings(mydaemon_shutdown PRIVATE)
cppbp_set_sanitizers(mydaemon_shutdown PUBLIC)
cppbp_enable_clang_tidy(mydaemon_shutdown)

# main.cpp is the only file here that is not in a module, and the only one no
# test links: a function in a library can be called by a test, and a loop in
# main() can only be checked by starting the process and sending it signals.
# That is the whole reason the modules above are libraries.
#
# It links three of them because it is the place they meet. Nothing else does.
add_executable(mydaemon main.cpp)
target_link_libraries(mydaemon PRIVATE mydaemon_options mydaemon_service mydaemon_shutdown)

# Built at the top of the build directory rather than under src/, so that the
# path README.md tells a reader to type is still the path:
#
#   ./build/debug/mydaemon --interval 1 --label hello
#
# PROJECT_BINARY_DIR rather than CMAKE_BINARY_DIR: in a build that adds this
# project as a subdirectory, the top of the tree belongs to whoever is above.
set_target_properties(mydaemon PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}")

cppbp_set_warnings(mydaemon PRIVATE)
cppbp_set_sanitizers(mydaemon PRIVATE)
cppbp_enable_clang_tidy(mydaemon)
