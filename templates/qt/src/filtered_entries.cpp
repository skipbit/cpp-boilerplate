#include "filtered_entries.hpp"

#include <cstddef>

#include <QByteArray>
#include <QHash>
#include <QModelIndex>
#include <QObject>
#include <QString>
#include <QVariant>

#include "catalogue.hpp"
#include "presentation.hpp"

namespace myapp {

FilteredEntries::FilteredEntries(QObject* parent)
    : QAbstractListModel(parent), all_(catalogue::everything()), shown_(all_)
{
}

auto FilteredEntries::rowCount(const QModelIndex& parent) const -> int
{
    // A list has no children, and a view asks about them anyway.
    return parent.isValid() ? 0 : static_cast<int>(shown_.size());
}

auto FilteredEntries::data(const QModelIndex& index, int role) const -> QVariant
{
    if (! index.isValid() || index.row() < 0 || index.row() >= rowCount()) {
        return {};
    }
    if (role != label_role && role != Qt::DisplayRole) {
        return {};
    }
    return QString::fromStdString(presentation::row(shown_.at(static_cast<std::size_t>(index.row()))));
}

auto FilteredEntries::roleNames() const -> QHash<int, QByteArray>
{
    return {{label_role, QByteArrayLiteral("label")}};
}

auto FilteredEntries::query() const -> QString
{
    return query_;
}

void FilteredEntries::set_query(const QString& wanted)
{
    if (wanted == query_) {
        return;
    }
    query_ = wanted;

    // Every row can change, and working out which ones did would be this class
    // deciding something. beginResetModel is the honest answer for a list this
    // size; a longer one is where a QSortFilterProxyModel starts to pay.
    beginResetModel();
    shown_ = catalogue::matching(all_, query_.toStdString());
    endResetModel();

    emit query_changed();
}

auto FilteredEntries::summary() const -> QString
{
    return QString::fromStdString(presentation::summary(shown_.size(), all_.size()));
}

}  // namespace myapp
