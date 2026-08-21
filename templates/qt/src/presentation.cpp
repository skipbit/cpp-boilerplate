#include "presentation.hpp"

#include <cstddef>
#include <string>

#include "catalogue.hpp"

namespace myapp::presentation {

auto summary(std::size_t shown, std::size_t total) -> std::string
{
    if (total == 0) {
        return "nothing to show";
    }
    if (shown == 0) {
        return "no match";
    }
    return std::to_string(shown) + " of " + std::to_string(total);
}

auto row(const catalogue::Entry& entry) -> std::string
{
    if (entry.kind.empty()) {
        return entry.name;
    }
    return entry.name + " (" + entry.kind + ")";
}

}  // namespace myapp::presentation
