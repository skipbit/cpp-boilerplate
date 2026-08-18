#pragma once

#include <string>
#include <string_view>

#include "mylib/export.hpp"

// One feature, one header. There is no umbrella <mylib/mylib.hpp>: a header that
// pulls in everything becomes a header that everything depends on, and the
// compile times and the rebuild graph both pay for it.
//
// Declarations only. The implementation lives in src/text.cpp, so that changing
// it does not force every consumer to recompile.

namespace mylib::text {

/// Collapses each run of whitespace into a single space and trims both ends.
///
/// `squeeze("  a \t\n b  ")` returns `"a b"`.
[[nodiscard]] MYLIB_EXPORT auto squeeze(std::string_view input) -> std::string;

}  // namespace mylib::text
