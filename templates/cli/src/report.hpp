#pragma once

#include <string>

#include "command_line.hpp"
#include "counting.hpp"

// What the program prints, separated from what it computes and from what it was
// asked for. Returning a string rather than writing to a stream is what makes
// the output testable without capturing anything.

namespace mycli::report {

/// Formats the numbers `requested` asked for, in a fixed order, separated by
/// single spaces. Returns an empty string when nothing was asked for.
[[nodiscard]] auto format(const counting::Counts& counts, const command_line::Options& requested) -> std::string;

}  // namespace mycli::report
