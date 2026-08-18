#include <iostream>

#include <mylib/text.hpp>
#include <mylib/version.hpp>

int main()
{
    std::cout << "mylib " << mylib::version() << '\n';
    std::cout << '[' << mylib::text::squeeze("  keep   it    tidy  ") << "]\n";
}
