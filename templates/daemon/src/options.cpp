#include "options.hpp"

#include <chrono>
#include <string>

#include <CLI/CLI.hpp>

#include <mydaemon/version.hpp>

namespace mydaemon::options {

auto parse(int argc, const char* const* argv) -> Outcome
{
    Options options;
    double interval_seconds = std::chrono::duration<double>(options.interval).count();

    CLI::App app{"Does a small piece of work every interval, until asked to stop.", "mydaemon"};
    app.add_option("-i,--interval", interval_seconds, "Seconds between runs")
        ->check(CLI::PositiveNumber)
        ->capture_default_str();
    app.add_option("-l,--label", options.label, "Prefix for every line this writes");
    app.set_config("-c,--config", "", "Read the options above from this file, and re-read it on SIGHUP");

    // CLI11 ignores an entry it does not recognise by default. A file re-read
    // while nobody is watching is exactly where a misspelled key should not be
    // met with silence, so it is an error here instead.
    app.allow_config_extras(CLI::config_extras_mode::error);
    app.set_version_flag("-V,--version", app.get_name() + " " + version());

    try {
        app.parse(argc, argv);
    } catch (const CLI::ParseError& error) {
        return {.options = {}, .run = false, .status = app.exit(error)};
    }

    // Rounded up rather than down, so that an interval too small to express in
    // milliseconds becomes the smallest one there is instead of none at all.
    options.interval = std::chrono::ceil<std::chrono::milliseconds>(std::chrono::duration<double>(interval_seconds));

    return {.options = options, .run = true, .status = 0};
}

}  // namespace mydaemon::options
