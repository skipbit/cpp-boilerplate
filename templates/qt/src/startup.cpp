#include "startup.hpp"

#include <QCommandLineOption>
#include <QCommandLineParser>
#include <QCoreApplication>
#include <QGuiApplication>
#include <QObject>
#include <QQmlApplicationEngine>
#include <QString>
#include <QStringLiteral>
#include <QTimer>
#include <QUrl>

#include <myapp/version.hpp>

namespace myapp::startup {

auto run(int argc, char** argv) -> int
{
    QGuiApplication application(argc, argv);
    QCoreApplication::setApplicationName(QStringLiteral("myapp"));
    QCoreApplication::setApplicationVersion(QString::fromLatin1(version()));

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("Filters a list. Replace the list with yours."));
    parser.addHelpOption();
    parser.addVersionOption();
    const QCommandLineOption self_check(
        QStringLiteral("self-check"),
        QStringLiteral("Load the interface, draw once and exit. This is what the tests run."));
    parser.addOption(self_check);
    parser.process(application);

    QQmlApplicationEngine engine;

    // A QML file that does not parse is a runtime failure, and without this it
    // is a silent one: the process would keep running with no window.
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &application,
        []() {
            QCoreApplication::exit(1);
        },
        Qt::QueuedConnection);

    // By URL rather than loadFromModule(), which arrived in Qt 6.5 and is not
    // in the 6.4 that Ubuntu 24.04 ships. See README.md.
    engine.load(QUrl(QStringLiteral("qrc:/myapp/qml/Main.qml")));
    if (engine.rootObjects().isEmpty()) {
        return 1;
    }

    if (parser.isSet(self_check)) {
        QTimer::singleShot(0, &application, &QCoreApplication::quit);
    }

    return QGuiApplication::exec();
}

}  // namespace myapp::startup
