#include "window.hpp"

#include <vector>

#include <QApplication>
#include <QByteArray>
#include <QLabel>
#include <QLineEdit>
#include <QListWidget>
#include <QString>

#include <gtest/gtest.h>

#include "catalogue.hpp"

// The widgets, checked by building them. This is the only file here that needs
// a QApplication - which is the measurement, not the inconvenience: everything
// the program decides is tested in the file next to this one, without one.

namespace {

auto sample() -> std::vector<myapp::catalogue::Entry>
{
    return {
        {.name = "cmake", .kind = "build"},
        {.name = "ninja", .kind = "build"},
        {.name = "clang-tidy", .kind = "analysis"},
    };
}

auto rows(const myapp::Window& window) -> int
{
    return window.findChild<QListWidget*>()->count();
}

auto summary(const myapp::Window& window) -> QString
{
    return window.findChild<QLabel*>()->text();
}

void type(const myapp::Window& window, const QString& text)
{
    window.findChild<QLineEdit*>()->setText(text);
}

}  // namespace

TEST(Window, ShowsEverythingBeforeAnythingIsTyped)
{
    const myapp::Window window{sample()};
    EXPECT_EQ(rows(window), 3);
    EXPECT_EQ(summary(window), QStringLiteral("3 of 3"));
}

TEST(Window, NarrowsTheListAsTheQueryChanges)
{
    const myapp::Window window{sample()};
    type(window, QStringLiteral("build"));
    EXPECT_EQ(rows(window), 2);
    EXPECT_EQ(summary(window), QStringLiteral("2 of 3"));
}

TEST(Window, EmptiesTheListWhenNothingMatches)
{
    const myapp::Window window{sample()};
    type(window, QStringLiteral("fortran"));
    EXPECT_EQ(rows(window), 0);
    EXPECT_EQ(summary(window), QStringLiteral("no match"));
}

TEST(Window, FillsTheListAgainWhenTheQueryIsCleared)
{
    const myapp::Window window{sample()};
    type(window, QStringLiteral("fortran"));
    type(window, QString());
    EXPECT_EQ(rows(window), 3);
}

int main(int argc, char** argv)
{
    // Offscreen, so this runs where there is no display and puts no windows on
    // one where there is. Set here rather than in the environment, so that
    // running the binary by hand behaves the same way the test does.
    qputenv("QT_QPA_PLATFORM", "offscreen");

    const QApplication application(argc, argv);
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
