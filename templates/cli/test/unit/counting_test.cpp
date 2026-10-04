#include "counting.hpp"

#include <sstream>
#include <string>

#include <gtest/gtest.h>

// One header, one implementation, one test file. Adding a feature means adding
// all three, which is the point: a feature without a test is not finished.
//
// count() takes a stream, so none of this needs a file on disk.

namespace {

auto count_of(const std::string& text) -> mycli::counting::Counts
{
    std::istringstream input(text);
    return mycli::counting::count(input);
}

}  // namespace

TEST(Count, CountsNothingInAnEmptyStream)
{
    const auto counts = count_of("");
    EXPECT_EQ(counts.lines, 0U);
    EXPECT_EQ(counts.words, 0U);
    EXPECT_EQ(counts.bytes, 0U);
}

TEST(Count, CountsWordsSeparatedByAnyWhitespace)
{
    const auto counts = count_of("one two\tthree\nfour");
    EXPECT_EQ(counts.words, 4U);
}

TEST(Count, CountsTheLastLineEvenWithoutItsNewline)
{
    EXPECT_EQ(count_of("a\nb\n").lines, 2U);
    EXPECT_EQ(count_of("a\nb").lines, 2U);
}

TEST(Count, CountsBytesRatherThanCharacters)
{
    // Three characters, nine bytes: this counts what is in the stream, not what
    // it means. Say so here rather than discovering it in a bug report.
    const auto counts = count_of("日本語");
    EXPECT_EQ(counts.bytes, 9U);
    EXPECT_EQ(counts.words, 1U);
}

TEST(Count, AddsUpAcrossStreams)
{
    auto total = count_of("a b\n");
    total += count_of("c\n");
    EXPECT_EQ(total.lines, 2U);
    EXPECT_EQ(total.words, 3U);
}
