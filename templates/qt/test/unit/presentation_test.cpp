#include "presentation.hpp"

#include <gtest/gtest.h>

#include "catalogue.hpp"

TEST(Summary, SaysSoWhenThereIsNothingAtAll)
{
    EXPECT_EQ(myapp::presentation::summary(0, 0), "nothing to show");
}

TEST(Summary, SaysSoWhenNothingMatches)
{
    // Different from having nothing: one is a filter that found none, the other
    // is a program with no data, and telling a user they are the same is a bug.
    EXPECT_EQ(myapp::presentation::summary(0, 8), "no match");
}

TEST(Summary, CountsWhatIsShownAgainstWhatThereIs)
{
    EXPECT_EQ(myapp::presentation::summary(3, 8), "3 of 8");
    EXPECT_EQ(myapp::presentation::summary(8, 8), "8 of 8");
}

TEST(Row, PutsTheKindAfterTheName)
{
    const myapp::catalogue::Entry entry{.name = "ninja", .kind = "build"};
    EXPECT_EQ(myapp::presentation::row(entry), "ninja (build)");
}

TEST(Row, LeavesOutAnEmptyKindRatherThanShowingEmptyBrackets)
{
    const myapp::catalogue::Entry entry{.name = "ninja", .kind = ""};
    EXPECT_EQ(myapp::presentation::row(entry), "ninja");
}
