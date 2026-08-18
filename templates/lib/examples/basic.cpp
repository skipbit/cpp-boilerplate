#include <cstdio>

#include <mylib/text.hpp>
#include <mylib/version.hpp>

int main()
{
    std::printf("mylib %s\n", mylib::version());
    std::printf("[%s]\n", mylib::text::squeeze("  keep   it    tidy  ").c_str());
    return 0;
}
