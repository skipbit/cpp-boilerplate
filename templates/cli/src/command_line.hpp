#pragma once

#include <expected>
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

/// Parses `argv`, or reports the exit code the program should end with.
///
/// The error is an exit status rather than a message because the message has
/// already been printed: `--help` and `--version` are successful requests that
/// end the program, and a usage error prints what was wrong. Both are things
/// the parser knows how to say better than a caller would.
[[nodiscard]] auto parse(int argc, const char* const* argv) -> std::expected<Options, int>;

}  // namespace mycli::command_line
