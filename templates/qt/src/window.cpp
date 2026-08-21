#include "window.hpp"

#include <utility>
#include <vector>

#include <QLabel>
#include <QLineEdit>
#include <QListWidget>
#include <QString>
#include <QVBoxLayout>

#include "catalogue.hpp"
#include "presentation.hpp"

namespace myapp {

Window::Window(std::vector<catalogue::Entry> entries, QWidget* parent)
    : QWidget(parent),
      entries_(std::move(entries)),
      query_(new QLineEdit(this)),
      summary_(new QLabel(this)),
      matches_(new QListWidget(this))
{
    // new with no delete, deliberately. A QObject given a parent is destroyed by
    // that parent, so these are owned; holding them in a unique_ptr as well
    // would be a double free rather than an improvement.
    auto* layout = new QVBoxLayout(this);
    layout->addWidget(query_);
    layout->addWidget(summary_);
    layout->addWidget(matches_);

    setWindowTitle(QStringLiteral("myapp"));
    query_->setPlaceholderText(QStringLiteral("filter"));
    connect(query_, &QLineEdit::textChanged, this, &Window::refresh);

    refresh();
}

void Window::refresh()
{
    const auto found = catalogue::matching(entries_, query_->text().toStdString());

    summary_->setText(QString::fromStdString(presentation::summary(found.size(), entries_.size())));

    matches_->clear();
    for (const auto& entry : found) {
        matches_->addItem(QString::fromStdString(presentation::row(entry)));
    }
}

}  // namespace myapp
