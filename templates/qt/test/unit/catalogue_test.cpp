#include "catalogue.hpp"

#include <string>
#include <vector>

#include <gtest/gtest.h>

// There is no QApplication in this file, and no Qt in the library it links. A
// model that needs a running application to be tested is a model that has grown
// into the window, and this is where that would first stop compiling.

namespace {

auto sample() -> std::vector<myapp::catalogue::Entry>
{
    return {
        {.name = "cmake", .kind = "build"},
        {.name = "Ninja", .kind = "build"},
        {.name = "clang-tidy", .kind = "analysis"},
    };
}

auto names(const std::vector<myapp::catalogue::Entry>& entries) -> std::vector<std::string>
{
    std::vector<std::string> found;
    found.reserve(entries.size());
    for (const auto& entry : entries) {
        found.push_back(entry.name);
    }
    return found;
}

}  // namespace

TEST(Matching, ReturnsEverythingForAnEmptyQuery)
{
    EXPECT_EQ(myapp::catalogue::matching(sample(), "").size(), sample().size());
}

TEST(Matching, IgnoresCase)
{
    EXPECT_EQ(names(myapp::catalogue::matching(sample(), "NINJA")), (std::vector<std::string>{"Ninja"}));
}

TEST(Matching, LooksAtTheKindAsWellAsTheName)
{
    EXPECT_EQ(names(myapp::catalogue::matching(sample(), "build")), (std::vector<std::string>{"cmake", "Ninja"}));
}

TEST(Matching, ReturnsNothingWhenNothingMatches)
{
    EXPECT_TRUE(myapp::catalogue::matching(sample(), "fortran").empty());
}

TEST(Matching, KeepsTheOrderItWasGiven)
{
    EXPECT_EQ(names(myapp::catalogue::matching(sample(), "a")),
              (std::vector<std::string>{"cmake", "Ninja", "clang-tidy"}));
}

TEST(Everything, HasSomethingInIt)
{
    // The window is empty without it, and an empty window looks broken rather
    // than like an example waiting to be replaced.
    EXPECT_FALSE(myapp::catalogue::everything().empty());
}
