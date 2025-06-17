#pragma once

#include <QAbstractListModel>
#include <QList>
#include <QUrl>
#include <qqmlintegration.h>

class PlaylistModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(int currentIndex READ currentIndex WRITE setCurrentIndex NOTIFY currentIndexChanged)
    Q_PROPERTY(int rowCount READ rowCount NOTIFY rowCountChanged)
    Q_ENUMS(Roles)

public:
    enum Roles { UrlRole = Qt::UserRole + 1, TitleRole };

    explicit PlaylistModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void addMedia(const QUrl &url);
    Q_INVOKABLE void addMedias(const QList<QUrl> &urls);
    Q_INVOKABLE void removeMedia(int index);
    Q_INVOKABLE void clear();
    Q_INVOKABLE QUrl getUrl(int index) const;

    int currentIndex() const;
    void setCurrentIndex(int index);

signals:
    void currentIndexChanged(int index);
    void rowCountChanged();

private:
    QList<QUrl> m_mediaList;
    int m_currentIndex = -1;
};
