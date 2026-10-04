#include "filtered_entries.hpp"

#include <QModelIndex>
#include <QString>
#include <QStringLiteral>
#include <QVariant>

#include <gtest/gtest.h>

// The class QML binds to, tested without QML - and without an application
// object of any kind. A model that needs one to be exercised is a model that
// has grown into the interface.

namespace {

auto label_at(const myapp::FilteredEntries& entries, int row) -> QString
{
    return entries.data(entries.index(row, 0), myapp::FilteredEntries::label_role).toString();
}

}  // namespace

TEST(FilteredEntries, ShowsEverythingBeforeAnythingIsTyped)
{
    const myapp::FilteredEntries entries;
    EXPECT_GT(entries.rowCount(), 0);
    EXPECT_EQ(entries.query(), QString());
}

TEST(FilteredEntries, NarrowsWhenTheQueryIsSet)
{
    myapp::FilteredEntries entries;
    const int everything = entries.rowCount();

    entries.set_query(QStringLiteral("analysis"));
    EXPECT_GT(entries.rowCount(), 0);
    EXPECT_LT(entries.rowCount(), everything);
}

TEST(FilteredEntries, EmptiesWhenNothingMatches)
{
    myapp::FilteredEntries entries;
    entries.set_query(QStringLiteral("fortran"));
    EXPECT_EQ(entries.rowCount(), 0);
    EXPECT_EQ(entries.summary(), QStringLiteral("no match"));
}

TEST(FilteredEntries, FillsUpAgainWhenTheQueryIsCleared)
{
    myapp::FilteredEntries entries;
    const int everything = entries.rowCount();

    entries.set_query(QStringLiteral("fortran"));
    entries.set_query(QString());
    EXPECT_EQ(entries.rowCount(), everything);
}

TEST(FilteredEntries, SaysNothingForARowThatIsNotThere)
{
    // A view asks about rows that have just gone away. Answering with an empty
    // QVariant is the difference between a repaint and a crash.
    const myapp::FilteredEntries entries;
    EXPECT_FALSE(entries.data(QModelIndex(), myapp::FilteredEntries::label_role).isValid());
    EXPECT_FALSE(entries.data(entries.index(entries.rowCount(), 0), myapp::FilteredEntries::label_role).isValid());
}

TEST(FilteredEntries, LabelsRowsThroughPresentation)
{
    const myapp::FilteredEntries entries;
    EXPECT_TRUE(label_at(entries, 0).contains(QStringLiteral("(")));
}

TEST(FilteredEntries, AnnouncesTheChangeSoABindingFollows)
{
    myapp::FilteredEntries entries;
    int announced = 0;
    QObject::connect(&entries, &myapp::FilteredEntries::query_changed, [&announced]() {
        ++announced;
    });

    entries.set_query(QStringLiteral("build"));
    EXPECT_EQ(announced, 1);

    // Setting it to what it already is changes nothing, so it says nothing.
    entries.set_query(QStringLiteral("build"));
    EXPECT_EQ(announced, 1);
}
