#include "command_line.hpp"

#include <array>
#include <cstddef>

#include <gtest/gtest.h>

// Parsing is a function, so these tests are ordinary function calls: no process
// is started, no output is captured, nothing is mocked.

namespace {

template <std::size_t N> auto parse(const std::array<const char*, N>& argv) -> mycli::command_line::Outcome
{
    return mycli::command_line::parse(static_cast<int>(N), argv.data());
}

}  // namespace

TEST(Parse, AsksForEverythingWhenAskedForNothing)
{
    const auto parsed = parse(std::array{"mycli"});
    ASSERT_TRUE(parsed.run);
    const auto& options = parsed.options;
    EXPECT_TRUE(options.lines);
    EXPECT_TRUE(options.words);
    EXPECT_TRUE(options.bytes);
    EXPECT_TRUE(options.files.empty());
}

TEST(Parse, OneFlagTurnsTheOthersOff)
{
    const auto parsed = parse(std::array{"mycli", "-w"});
    ASSERT_TRUE(parsed.run);
    const auto& options = parsed.options;
    EXPECT_FALSE(options.lines);
    EXPECT_TRUE(options.words);
    EXPECT_FALSE(options.bytes);
}

TEST(Parse, CollectsFileNamesInOrder)
{
    const auto parsed = parse(std::array{"mycli", "first.txt", "second.txt"});
    ASSERT_TRUE(parsed.run);
    const auto& files = parsed.options.files;
    ASSERT_EQ(files.size(), 2U);
    EXPECT_EQ(files.at(0), "first.txt");
    EXPECT_EQ(files.at(1), "second.txt");
}

TEST(Parse, ReportsAnExitCodeForAnUnknownOption)
{
    // The usage message this prints on standard error belongs to the run: the
    // parser has already said what was wrong, which is why what comes back here
    // is a status and not a string.
    const auto parsed = parse(std::array{"mycli", "--nonsense"});
    EXPECT_FALSE(parsed.run);
    EXPECT_NE(parsed.status, 0);
}
