#include "command_line.hpp"

#include <string>

#include <CLI/CLI.hpp>

#include <mycli/version.hpp>

namespace mycli::command_line {

auto parse(int argc, const char* const* argv) -> Outcome
{
    // The counts start false, against the defaults Selection declares: CLI11
    // writes to a bound bool when its flag appears and leaves it alone
    // otherwise, so false is what keeps "nobody asked for a count" a question
    // this function can still answer after parsing. It answers it below.
    // `.files` and `.selection` are spelled out because -Wextra counts a skipped
    // designator as a missing initializer.
    Options options{.files = {}, .selection = {.lines = false, .words = false, .bytes = false}};

    CLI::App app{"Counts lines, words and bytes.", "mycli"};
    app.add_option("files", options.files, "Files to read; standard input if none")->type_name("FILE");
    app.add_flag("-l,--lines", options.selection.lines, "Count lines");
    app.add_flag("-w,--words", options.selection.words, "Count words");
    app.add_flag("-b,--bytes", options.selection.bytes, "Count bytes");
    app.set_version_flag("-V,--version", app.get_name() + " " + version());

    try {
        app.parse(argc, argv);
    } catch (const CLI::ParseError& error) {
        return {.options = {}, .run = false, .status = app.exit(error)};
    }

    if (! (options.selection.lines || options.selection.words || options.selection.bytes)) {
        // Written out rather than left to Selection's declared defaults: what
        // this program does when nobody asks for a count is this function's
        // answer, and it should not change because another module's header did.
        options.selection = {.lines = true, .words = true, .bytes = true};
    }

    return {.options = options, .run = true, .status = 0};
}

}  // namespace mycli::command_line
