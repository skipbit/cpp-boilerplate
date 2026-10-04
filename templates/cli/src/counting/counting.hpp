#pragma once

#include <cstddef>
#include <iosfwd>

// One feature, one header, one implementation, one test. Nothing here is
// installed - a program publishes a command, not an API - so every header in
// this directory is private and changing one breaks nobody.
//
// This is the part that does the work, and it takes a stream rather than a file
// name: a function that opens files can only be tested with files, and a
// function that takes a stream can be tested with a string.

namespace mycli::counting {

struct Counts {
    std::size_t lines = 0;
    std::size_t words = 0;
    std::size_t bytes = 0;
};

/// Counts lines, whitespace-separated words and bytes in `input`.
///
/// A line is a `\n`; text that does not end in one still counts as a line, the
/// way an editor shows it rather than the way `wc` counts it.
[[nodiscard]] auto count(std::istream& input) -> Counts;

auto operator+=(Counts& lhs, const Counts& rhs) noexcept -> Counts&;

}  // namespace mycli::counting
