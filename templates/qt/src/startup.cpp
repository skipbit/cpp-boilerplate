#include "startup.hpp"

#include <QApplication>
#include <QCommandLineOption>
#include <QCommandLineParser>
#include <QString>
#include <QTimer>

#include <myapp/version.hpp>

#include "catalogue.hpp"
#include "window.hpp"

namespace myapp::startup {

auto run(int argc, char** argv) -> int
{
    QApplication application(argc, argv);
    QCoreApplication::setApplicationName(QStringLiteral("myapp"));
    QCoreApplication::setApplicationVersion(QString::fromLatin1(version()));

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("Filters a list. Replace the list with yours."));
    parser.addHelpOption();
    parser.addVersionOption();
    const QCommandLineOption self_check(QStringLiteral("self-check"),
                                        QStringLiteral("Start, draw once and exit. This is what the tests run."));
    parser.addOption(self_check);
    parser.process(application);

    Window window(catalogue::everything());
    window.show();

    if (parser.isSet(self_check)) {
        QTimer::singleShot(0, &application, &QCoreApplication::quit);
    }

    return QApplication::exec();
}

}  // namespace myapp::startup
