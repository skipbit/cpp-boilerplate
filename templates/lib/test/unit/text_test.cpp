#include <mylib/text.hpp>

#include <gtest/gtest.h>

// A feature is a header, an implementation and this file, plus entries in
// CMakeLists.txt and test/unit/CMakeLists.txt. A feature without a test is not
// finished.

TEST(Squeeze, CollapsesRunsOfWhitespace)
{
    EXPECT_EQ(mylib::text::squeeze("a  b"), "a b");
    EXPECT_EQ(mylib::text::squeeze("a \t\n\v\f\r b"), "a b");
}

TEST(Squeeze, TrimsBothEnds)
{
    EXPECT_EQ(mylib::text::squeeze("  a b  "), "a b");
    EXPECT_EQ(mylib::text::squeeze("\t\na\n\t"), "a");
}

TEST(Squeeze, LeavesSingleSpacesAlone)
{
    EXPECT_EQ(mylib::text::squeeze("a b c"), "a b c");
}

TEST(Squeeze, HandlesEmptyAndWhitespaceOnlyInput)
{
    EXPECT_EQ(mylib::text::squeeze(""), "");
    EXPECT_EQ(mylib::text::squeeze("   "), "");
}

TEST(Squeeze, DoesNotTouchNonAsciiBytes)
{
    // squeeze works on bytes, not on characters. Multi-byte sequences pass
    // through untouched because none of their bytes is an ASCII space.
    EXPECT_EQ(mylib::text::squeeze("  日本語  テキスト  "), "日本語 テキスト");
}
