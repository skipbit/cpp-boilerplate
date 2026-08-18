#pragma once

// Anything under src/ is private: it is not installed, so no consumer can
// include it, so changing it is never a breaking change. Put helpers here
// rather than in the public headers.

namespace mylib::detail {

/// std::isspace takes an int and has undefined behaviour for negative values
/// other than EOF, which is exactly what a `char` gives you on most platforms.
/// Wrapping it once is cheaper than remembering that at every call site.
[[nodiscard]] constexpr auto is_space(char c) noexcept -> bool
{
    return c == ' ' || c == '\t' || c == '\n' || c == '\v' || c == '\f' || c == '\r';
}

}  // namespace mylib::detail
