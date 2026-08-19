#include "report.hpp"

#include <cstddef>
#include <string>

#include "command_line.hpp"
#include "counting.hpp"

namespace mycli::report {

namespace {

void append(std::string& line, std::size_t value)
{
    if (! line.empty()) {
        line += ' ';
    }
    line += std::to_string(value);
}

}  // namespace

auto format(const counting::Counts& counts, const command_line::Options& requested) -> std::string
{
    std::string line;
    if (requested.lines) {
        append(line, counts.lines);
    }
    if (requested.words) {
        append(line, counts.words);
    }
    if (requested.bytes) {
        append(line, counts.bytes);
    }
    return line;
}

}  // namespace mycli::report
