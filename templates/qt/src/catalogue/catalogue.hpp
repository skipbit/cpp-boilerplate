#pragma once

#include <string>
#include <string_view>
#include <vector>

// What the program is about, and nothing about how it is shown. No Qt type
// appears here or in catalogue.cpp, and the build enforces that: this file is
// part of a library that does not link Qt at all.

namespace myapp::catalogue {

struct Entry {
    std::string name;
    std::string kind;
};

/// The rows the window starts with. Replace them with yours.
[[nodiscard]] auto everything() -> std::vector<Entry>;

/// The entries whose name or kind contains `query`, ignoring case. An empty
/// query matches everything.
[[nodiscard]] auto matching(const std::vector<Entry>& entries, std::string_view query) -> std::vector<Entry>;

}  // namespace myapp::catalogue
