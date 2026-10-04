#include "report.hpp"

#include <gtest/gtest.h>

#include "command_line.hpp"
#include "counting.hpp"

namespace {

constexpr mycli::counting::Counts sample{.lines = 2, .words = 5, .bytes = 30};

auto only_words() -> mycli::command_line::Options
{
    return {.files = {}, .lines = false, .words = true, .bytes = false};
}

}  // namespace

TEST(Format, PrintsEveryNumberByDefault)
{
    EXPECT_EQ(mycli::report::format(sample, {}), "2 5 30");
}

TEST(Format, PrintsOnlyWhatWasAskedFor)
{
    EXPECT_EQ(mycli::report::format(sample, only_words()), "5");
}

TEST(Format, KeepsTheOrderRegardlessOfHowItWasAsked)
{
    mycli::command_line::Options requested;
    requested.words = false;
    EXPECT_EQ(mycli::report::format(sample, requested), "2 30");
}
