# A consumer of the installed package. It deliberately knows nothing about the
# library's source tree: only find_package() and the imported target.
cmake_minimum_required(VERSION 3.28)
project(mylib-consumer LANGUAGES CXX)

find_package(mylib REQUIRED)

add_executable(consumer main.cpp)
target_link_libraries(consumer PRIVATE mylib::mylib)
