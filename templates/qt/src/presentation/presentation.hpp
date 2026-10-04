#pragma once

#include <cstddef>
#include <string>

#include "catalogue.hpp"

// What the window says, worked out where it can be tested. Returning strings
// rather than setting labels is what makes that possible.

namespace myapp::presentation {

/// The line above the list.
[[nodiscard]] auto summary(std::size_t shown, std::size_t total) -> std::string;

/// One row of the list.
[[nodiscard]] auto row(const catalogue::Entry& entry) -> std::string;

}  // namespace myapp::presentation
