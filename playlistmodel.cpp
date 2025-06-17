#include "playlistmodel.h"

PlaylistModel::PlaylistModel(QObject *parent) : QAbstractListModel(parent) {}

int PlaylistModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) return 0;
    return m_mediaList.size();
}

QVariant PlaylistModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_mediaList.size()) return QVariant();

    const QUrl &url = m_mediaList.at(index.row());

    switch (role) {
    case UrlRole:
        return url;
    case TitleRole:
        return url.fileName();
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> PlaylistModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[UrlRole] = "url";
    roles[TitleRole] = "title";
    return roles;
}

void PlaylistModel::addMedia(const QUrl &url)
{
    beginInsertRows(QModelIndex(), m_mediaList.size(), m_mediaList.size());
    m_mediaList.append(url);
    endInsertRows();

    if (m_currentIndex == -1) { setCurrentIndex(0); }
}

void PlaylistModel::addMedias(const QList<QUrl> &urls)
{
    if (urls.isEmpty()) return;

    beginInsertRows(QModelIndex(), m_mediaList.size(), m_mediaList.size() + urls.size() - 1);
    m_mediaList.append(urls);
    endInsertRows();

    if (m_currentIndex == -1) { setCurrentIndex(0); }
}

void PlaylistModel::removeMedia(int index)
{
    if (index < 0 || index >= m_mediaList.size()) return;

    beginRemoveRows(QModelIndex(), index, index);
    m_mediaList.removeAt(index);
    endRemoveRows();

    if (m_mediaList.isEmpty()) {
        setCurrentIndex(-1);
    } else if (index <= m_currentIndex) {
        setCurrentIndex(qMax(0, m_currentIndex - 1));
    }
}

void PlaylistModel::clear()
{
    beginResetModel();
    m_mediaList.clear();
    endResetModel();
    setCurrentIndex(-1);
}

int PlaylistModel::currentIndex() const
{
    return m_currentIndex;
}

void PlaylistModel::setCurrentIndex(int index)
{
    if (index < -1 || index >= m_mediaList.size() || index == m_currentIndex) return;

    m_currentIndex = index;
    emit currentIndexChanged(m_currentIndex);
}
