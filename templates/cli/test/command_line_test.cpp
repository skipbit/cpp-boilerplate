#include "command_line.hpp"

#include <array>
#include <cstddef>
#include <expected>

#include <gtest/gtest.h>

// Parsing is a function, so these tests are ordinary function calls: no process
// is started, no output is captured, nothing is mocked.

namespace {

template <std::size_t N>
auto parse(const std::array<const char*, N>& argv) -> std::expected<mycli::command_line::Options, int>
{
    return mycli::command_line::parse(static_cast<int>(N), argv.data());
}

}  // namespace

TEST(Parse, AsksForEverythingWhenAskedForNothing)
{
    const auto options = parse(std::array{"mycli"});
    ASSERT_TRUE(options.has_value());
    EXPECT_TRUE(options->lines);
    EXPECT_TRUE(options->words);
    EXPECT_TRUE(options->bytes);
    EXPECT_TRUE(options->files.empty());
}

TEST(Parse, OneFlagTurnsTheOthersOff)
{
    const auto options = parse(std::array{"mycli", "-w"});
    ASSERT_TRUE(options.has_value());
    EXPECT_FALSE(options->lines);
    EXPECT_TRUE(options->words);
    EXPECT_FALSE(options->bytes);
}

TEST(Parse, CollectsFileNamesInOrder)
{
    const auto options = parse(std::array{"mycli", "first.txt", "second.txt"});
    ASSERT_TRUE(options.has_value());
    ASSERT_EQ(options->files.size(), 2U);
    EXPECT_EQ(options->files.at(0), "first.txt");
    EXPECT_EQ(options->files.at(1), "second.txt");
}

TEST(Parse, ReportsAnExitCodeForAnUnknownOption)
{
    // The usage message this prints on standard error belongs to the run: the
    // parser has already said what was wrong, which is why the error carried
    // back here is a status and not a string.
    const auto options = parse(std::array{"mycli", "--nonsense"});
    ASSERT_FALSE(options.has_value());
    EXPECT_NE(options.error(), 0);
}
