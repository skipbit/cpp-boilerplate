#include "counting.hpp"

#include <istream>

namespace mycli::counting {

namespace {

/// std::isspace takes an int and has undefined behaviour for negative values
/// other than EOF, which is exactly what a `char` gives you on most platforms.
[[nodiscard]] constexpr auto is_space(char c) noexcept -> bool
{
    return c == ' ' || c == '\t' || c == '\n' || c == '\v' || c == '\f' || c == '\r';
}

}  // namespace

auto count(std::istream& input) -> Counts
{
    Counts result;

    bool inside_word = false;
    bool saw_anything = false;
    char c = '\0';

    while (input.get(c)) {
        saw_anything = true;
        ++result.bytes;

        if (c == '\n') {
            ++result.lines;
        }

        if (is_space(c)) {
            inside_word = false;
        } else if (! inside_word) {
            inside_word = true;
            ++result.words;
        }
    }

    // A final line without its newline is still a line to everyone except wc.
    if (saw_anything && c != '\n') {
        ++result.lines;
    }

    return result;
}

auto operator+=(Counts& lhs, const Counts& rhs) noexcept -> Counts&
{
    lhs.lines += rhs.lines;
    lhs.words += rhs.words;
    lhs.bytes += rhs.bytes;
    return lhs;
}

}  // namespace mycli::counting
