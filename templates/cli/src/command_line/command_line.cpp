#include "command_line.hpp"

#include <string>

#include <CLI/CLI.hpp>

#include <mycli/version.hpp>

namespace mycli::command_line {

auto parse(int argc, const char* const* argv) -> Outcome
{
    Options options;

    // Bound to locals that start false, because "not asked for" and "asked
    // against" are different questions and a bool flag can only answer one of
    // them. What to do when nobody asked is decided below, after parsing: it is
    // a decision about this program rather than something the parser knows.
    bool lines = false;
    bool words = false;
    bool bytes = false;

    CLI::App app{"Counts lines, words and bytes.", "mycli"};
    app.add_option("files", options.files, "Files to read; standard input if none")->type_name("FILE");
    app.add_flag("-l,--lines", lines, "Count lines");
    app.add_flag("-w,--words", words, "Count words");
    app.add_flag("-b,--bytes", bytes, "Count bytes");
    app.set_version_flag("-V,--version", app.get_name() + " " + version());

    try {
        app.parse(argc, argv);
    } catch (const CLI::ParseError& error) {
        return {.options = {}, .run = false, .status = app.exit(error)};
    }

    if (lines || words || bytes) {
        options.lines = lines;
        options.words = words;
        options.bytes = bytes;
    }

    return {.options = options, .run = true, .status = 0};
}

}  // namespace mycli::command_line
