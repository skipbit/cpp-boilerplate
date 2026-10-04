#include "command_line.hpp"

#include <string>

#include <CLI/CLI.hpp>

#include <mycli/version.hpp>

namespace mycli::command_line {

auto parse(int argc, const char* const* argv) -> Outcome
{
    // The counts start false, against the defaults Options declares: CLI11
    // writes to a bound bool when its flag appears and leaves it alone
    // otherwise, so false is what keeps "nobody asked for a count" a question
    // this function can still answer after parsing. It answers it below.
    // `.files` is spelled out because -Wextra counts a skipped designator as a
    // missing initializer.
    Options options{.files = {}, .lines = false, .words = false, .bytes = false};

    CLI::App app{"Counts lines, words and bytes.", "mycli"};
    app.add_option("files", options.files, "Files to read; standard input if none")->type_name("FILE");
    app.add_flag("-l,--lines", options.lines, "Count lines");
    app.add_flag("-w,--words", options.words, "Count words");
    app.add_flag("-b,--bytes", options.bytes, "Count bytes");
    app.set_version_flag("-V,--version", app.get_name() + " " + version());

    try {
        app.parse(argc, argv);
    } catch (const CLI::ParseError& error) {
        return {.options = {}, .run = false, .status = app.exit(error)};
    }

    if (! (options.lines || options.words || options.bytes)) {
        options.lines = true;
        options.words = true;
        options.bytes = true;
    }

    return {.options = options, .run = true, .status = 0};
}

}  // namespace mycli::command_line
