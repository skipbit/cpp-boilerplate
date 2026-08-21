#pragma once

#include <vector>

#include <QAbstractListModel>
#include <QHash>
#include <QModelIndex>
#include <QObject>
#include <QString>
#include <QVariant>
#include <QtQmlIntegration>

#include "catalogue.hpp"

namespace myapp {

/// What the interface binds to, and the only class here that Qt knows about.
///
/// It answers no questions of its own: the query goes to catalogue, the strings
/// come from presentation, and what is left is turning their answers into the
/// shape a view expects. Methods are named the way the rest of this project
/// names them rather than the way Qt names its own, because .clang-tidy checks
/// one of those and nothing checks the other.
class FilteredEntries : public QAbstractListModel {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString query READ query WRITE set_query NOTIFY query_changed)
    Q_PROPERTY(QString summary READ summary NOTIFY query_changed)

public:
    explicit FilteredEntries(QObject* parent = nullptr);

    /// The one role a view asks for. Qt reserves every number below UserRole.
    static constexpr int label_role = Qt::UserRole + 1;

    [[nodiscard]] auto rowCount(const QModelIndex& parent = QModelIndex()) const -> int override;
    [[nodiscard]] auto data(const QModelIndex& index, int role) const -> QVariant override;
    [[nodiscard]] auto roleNames() const -> QHash<int, QByteArray> override;

    [[nodiscard]] auto query() const -> QString;
    void set_query(const QString& wanted);

    [[nodiscard]] auto summary() const -> QString;

signals:
    void query_changed();

private:
    std::vector<catalogue::Entry> all_;
    std::vector<catalogue::Entry> shown_;
    QString query_;
};

}  // namespace myapp
