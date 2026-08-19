#include <exception>
#include <fstream>
#include <ios>
#include <iostream>

#include "command_line.hpp"
#include "counting.hpp"
#include "report.hpp"

// main() decides nothing. It wires the three pieces together and turns their
// answers into an exit status, which is the one job that cannot live anywhere
// else. Everything above it is in a library, because a function in a library
// can be tested and a function in main() cannot.

int main(int argc, char** argv)
{
    try {
        const auto parsed = mycli::command_line::parse(argc, argv);
        if (! parsed.run) {
            return parsed.status;
        }
        const auto& options = parsed.options;

        // No file names means standard input, the way every other filter behaves,
        // so that this can sit in the middle of a pipeline. The loop below then
        // has nothing to do.
        mycli::counting::Counts total;
        if (options.files.empty()) {
            total += mycli::counting::count(std::cin);
        }

        for (const auto& name : options.files) {
            std::ifstream file(name, std::ios::binary);
            if (! file) {
                std::cerr << "mycli: cannot read " << name << '\n';
                return 1;
            }
            total += mycli::counting::count(file);
        }

        std::cout << mycli::report::format(total, options) << '\n';
        return 0;
    } catch (const std::exception& error) {
        // A command line program that ends in an unhandled exception prints a
        // runtime's idea of a message and dies on a signal. This is the last
        // place it can still say something a user can act on.
        std::cerr << "mycli: " << error.what() << '\n';
        return 1;
    }
}
