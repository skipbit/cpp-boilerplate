#pragma once

#include <vector>

#include <QWidget>

#include "catalogue.hpp"

class QLabel;
class QLineEdit;
class QListWidget;

namespace myapp {

/// The window, and as little else as possible. It builds the widgets, listens
/// to the one that changes, and asks catalogue and presentation what to show.
///
/// Nothing here decides what matches or how a row reads. That is the point of
/// the class rather than an accident of its size: a decision written here can
/// only be tested by building a window, and everything those two answer is
/// tested by calling a function.
class Window : public QWidget {
    Q_OBJECT

public:
    explicit Window(std::vector<catalogue::Entry> entries, QWidget* parent = nullptr);

private:
    void refresh();

    std::vector<catalogue::Entry> entries_;
    QLineEdit* query_;
    QLabel* summary_;
    QListWidget* matches_;
};

}  // namespace myapp
