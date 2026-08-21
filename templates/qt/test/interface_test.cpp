#include <QGuiApplication>
#include <QObject>
#include <QQmlApplicationEngine>
#include <QString>
#include <QStringLiteral>
#include <QUrl>
#include <QVariant>

#include <gtest/gtest.h>

// The interface, loaded and driven. This is the only file here that needs a
// QGuiApplication, and everything it checks is a binding: typing into the field
// has to reach the model, and what the model answers has to reach the labels.
// Nothing in this file knows what "matching" means.

namespace {

class Interface : public ::testing::Test {
protected:
    void SetUp() override
    {
        engine_.load(QUrl(QStringLiteral("qrc:/myapp/qml/Main.qml")));
        ASSERT_FALSE(engine_.rootObjects().isEmpty()) << "Main.qml did not load";
    }

    [[nodiscard]] auto named(const char* name) const -> QObject*
    {
        return engine_.rootObjects().first()->findChild<QObject*>(QString::fromLatin1(name));
    }

    void type(const QString& text)
    {
        named("query")->setProperty("text", text);
    }

    [[nodiscard]] auto summary() const -> QString
    {
        return named("summary")->property("text").toString();
    }

    [[nodiscard]] auto rows() const -> int
    {
        return named("matches")->property("count").toInt();
    }

private:
    QQmlApplicationEngine engine_;
};

}  // namespace

TEST_F(Interface, ShowsEverythingBeforeAnythingIsTyped)
{
    EXPECT_GT(rows(), 0);
    EXPECT_EQ(summary(), QStringLiteral("8 of 8"));
}

TEST_F(Interface, NarrowsAsTheQueryIsTyped)
{
    type(QStringLiteral("build"));
    EXPECT_EQ(rows(), 2);
    EXPECT_EQ(summary(), QStringLiteral("2 of 8"));
}

TEST_F(Interface, SaysWhenNothingMatches)
{
    type(QStringLiteral("fortran"));
    EXPECT_EQ(rows(), 0);
    EXPECT_EQ(summary(), QStringLiteral("no match"));
}

int main(int argc, char** argv)
{
    // Offscreen, so this runs where there is no display and puts no windows on
    // one where there is. Set here rather than in the environment, so that
    // running the binary by hand behaves the way the test does.
    qputenv("QT_QPA_PLATFORM", "offscreen");

    const QGuiApplication application(argc, argv);
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
