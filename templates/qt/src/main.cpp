#include "startup.hpp"

// main() creates nothing and decides nothing - no window, no layout, no
// QApplication. Everything that would otherwise be written here is in a
// function, because a function can be called and main() cannot.

int main(int argc, char** argv)
{
    return myapp::startup::run(argc, argv);
}
