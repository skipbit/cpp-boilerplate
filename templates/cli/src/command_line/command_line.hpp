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
/// Not `std::expected`. Three named fields say more here than a value and an
/// error would: `--help` is not a failure, and the status to exit with is not
/// an error code. Putting the first two in the error channel of an expected
/// would be a smaller type saying a less true thing.
///
/// There is a portability reason as well, and it is in
/// docs/standard-library.md rather than here, because it is about the
/// toolchain and not about this function.
struct Outcome {
    Options options;
    bool run = true;
    int status = 0;
};

[[nodiscard]] auto parse(int argc, const char* const* argv) -> Outcome;

}  // namespace mycli::command_line
