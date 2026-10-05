#include <iostream>
#include <string>

#include <mylib/text.hpp>
#include <mylib/version.hpp>

// Returns non-zero on mismatch: the driver treats that as a failed test.
int main()
{
    const std::string squeezed = mylib::text::squeeze("  a \t\n b  ");
    if (squeezed != "a b") {
        std::cerr << "squeeze returned \"" << squeezed << "\"\n";
        return 1;
    }

    if (std::string(mylib::version()).empty()) {
        std::cerr << "version() is empty\n";
        return 1;
    }

    std::cout << "consumed mylib " << mylib::version() << '\n';
    return 0;
}
