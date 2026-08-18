#include <cstdio>
#include <string>

#include <mylib/text.hpp>
#include <mylib/version.hpp>

// Returns non-zero on mismatch: the driver treats that as a failed test.
int main()
{
    const std::string squeezed = mylib::text::squeeze("  a \t\n b  ");
    if (squeezed != "a b") {
        std::fprintf(stderr, "squeeze returned \"%s\"\n", squeezed.c_str());
        return 1;
    }

    if (std::string(mylib::version()).empty()) {
        std::fprintf(stderr, "version() is empty\n");
        return 1;
    }

    std::printf("consumed mylib %s\n", mylib::version());
    return 0;
}
