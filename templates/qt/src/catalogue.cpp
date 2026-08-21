#include "catalogue.hpp"

#include <algorithm>
#include <string_view>
#include <vector>

namespace myapp::catalogue {

namespace {

/// ASCII only. Matching the way a reader expects in every language needs
/// QString::compare or ICU, and that decision belongs with real data.
[[nodiscard]] constexpr auto folded(char c) noexcept -> char
{
    return (c >= 'A' && c <= 'Z') ? static_cast<char>(c - 'A' + 'a') : c;
}

[[nodiscard]] auto contains(std::string_view haystack, std::string_view needle) -> bool
{
    if (needle.empty()) {
        return true;
    }
    const auto found = std::ranges::search(haystack, needle, [](char left, char right) {
        return folded(left) == folded(right);
    });
    return ! found.empty();
}

}  // namespace

auto everything() -> std::vector<Entry>
{
    return {
        {.name = "cmake", .kind = "build"},
        {.name = "ninja", .kind = "build"},
        {.name = "clang-tidy", .kind = "analysis"},
        {.name = "clang-format", .kind = "formatting"},
        {.name = "shellcheck", .kind = "analysis"},
        {.name = "actionlint", .kind = "analysis"},
        {.name = "googletest", .kind = "testing"},
        {.name = "qt", .kind = "user interface"},
    };
}

auto matching(const std::vector<Entry>& entries, std::string_view query) -> std::vector<Entry>
{
    std::vector<Entry> found;
    for (const auto& entry : entries) {
        if (contains(entry.name, query) || contains(entry.kind, query)) {
            found.push_back(entry);
        }
    }
    return found;
}

}  // namespace myapp::catalogue
