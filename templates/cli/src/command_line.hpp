#pragma once

#include <string>
#include <vector>

// Argument parsing, kept out of main() so that it can be tested. A program
// whose parsing lives in main() can only be checked by running the program and
// reading its output; this one is checked by calling a function.
//
// CLI11 does not appear in this header, deliberately. It is an implementation
// detail of one .cpp file, and the rest of the program sees a plain struct -
// which is also what makes replacing the parser a change to one file.

namespace mycli::command_line {

struct Options {
    /// Empty means standard input.
    std::vector<std::string> files;
    bool lines = true;
    bool words = true;
    bool bytes = true;
};

/// What reading the command line produced. The three fields are read together.
///
/// `run` is false when the parser has already answered and the program should
/// end: `--help` and `--version` are requests it satisfies itself, and a usage
/// error has already been printed. `status` is what to exit with then - zero
/// for the first two, non-zero for the third. Nothing here carries a message,
/// because the parser says what went wrong better than a caller repeating it.
///
/// Not `std::expected`, which would say all of this in one type. libstdc++
/// declares it only when the compiler reports `__cpp_concepts >= 202002L`, and
/// Clang 18 - the clang Ubuntu 24.04 ships - does not. It compiles with GCC 13,
/// and with that same Clang against libc++, and fails on the third combination
/// in the matrix. A standard is not one thing, and finding that out here rather
/// than from a user is what the matrix is for.
struct Outcome {
    Options options;
    bool run = true;
    int status = 0;
};

[[nodiscard]] auto parse(int argc, const char* const* argv) -> Outcome;

}  // namespace mycli::command_line
