#include "mylib/text.hpp"

#include <string>
#include <string_view>

#include "detail/character.hpp"

namespace mylib::text {

auto squeeze(std::string_view input) -> std::string
{
    std::string result;
    result.reserve(input.size());

    bool pending_space = false;
    for (const char c : input) {
        if (detail::is_space(c)) {
            pending_space = ! result.empty();
            continue;
        }
        if (pending_space) {
            result.push_back(' ');
            pending_space = false;
        }
        result.push_back(c);
    }

    return result;
}

}  // namespace mylib::text
