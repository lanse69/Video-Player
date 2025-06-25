#include "dragdropmanager.h"

#include <QDebug>
#include <QMimeData>
#include <QFileInfo>
#include <QDropEvent>
#include <QDragEnterEvent>
#include <QGuiApplication>

DragDropManager::DragDropManager(QObject *parent) : QObject(parent), m_dragActive{false}, m_window{nullptr} {}

bool DragDropManager::dragActive() const
{
    return m_dragActive;
}

void DragDropManager::setWindow(QWindow *window)
{
    if (m_window) { m_window->removeEventFilter(this); }

    m_window = window;
    if (m_window) {
        m_window->installEventFilter(this);
        m_window->setFlag(Qt::WindowDoesNotAcceptFocus, false);
        m_window->setProperty("acceptDrops", true);
    }
}

bool DragDropManager::eventFilter(QObject *watched, QEvent *event)
{
    if (!m_window || watched != m_window) return false;

    switch (event->type()) {
    // 拖动进入
    case QEvent::DragEnter: {
        QDragEnterEvent *dragEvent = static_cast<QDragEnterEvent *>(event);
        const QMimeData *mimeData = dragEvent->mimeData();

        if (mimeData->hasUrls()) {
            bool hasSupported = false;
            const auto urls = mimeData->urls();
            for (const QUrl &url : urls) {
                // 检查是否是网络URL
                if (url.scheme().startsWith("http")) {
                    hasSupported = true;
                    continue;
                }

                QString localPath = url.toLocalFile();
                if (localPath.isEmpty()) continue;

                QFileInfo fileInfo(localPath);
                if (!fileInfo.exists() || !fileInfo.isFile()) continue;

                QString ext = fileInfo.suffix().toLower();
                static const QStringList supportedFormats{"mp4", "avi", "mkv", "mov", "wmv", "ogg", "mp3", "wav", "flac"};

                if (supportedFormats.contains(ext)) {
                    hasSupported = true;
                    break;
                }
            }

            if (hasSupported) {
                dragEvent->acceptProposedAction();
                m_dragActive = true;
                emit dragActiveChanged();
                return true;
            }
        }
        break;
    }

    // 拖动释放
    case QEvent::Drop: {
        QDropEvent *dropEvent = static_cast<QDropEvent *>(event);
        const QMimeData *mimeData = dropEvent->mimeData();

        if (mimeData->hasUrls()) {
            QList<QUrl> supportedUrls;
            const auto urls = mimeData->urls();
            for (const QUrl &url : urls) {
                // 检查是否是网络URL
                if (url.scheme().startsWith("http")) {
                    supportedUrls.append(url);
                    continue;
                }

                QString localPath = url.toLocalFile();
                if (localPath.isEmpty()) continue;

                QFileInfo fileInfo(localPath);
                if (!fileInfo.exists() || !fileInfo.isFile()) continue;

                QString ext = fileInfo.suffix().toLower();
                static const QStringList supportedFormats{"mp4", "avi", "mkv", "mov", "wmv", "ogg", "mp3", "wav", "flac"};

                if (supportedFormats.contains(ext)) { supportedUrls.append(url); }
            }

            if (!supportedUrls.isEmpty()) {
                dropEvent->acceptProposedAction();
                emit filesDropped(supportedUrls);
            }
        }

        m_dragActive = false;
        emit dragActiveChanged();
        return true;
    }

    // 拖动移动
    case QEvent::DragMove: {
        QDragMoveEvent *dragMoveEvent = static_cast<QDragMoveEvent *>(event);
        dragMoveEvent->accept();
        return true;
    }

    // 拖动离开
    case QEvent::DragLeave: {
        m_dragActive = false;
        emit dragActiveChanged();
        event->accept();
        return true;
    }

    default:
        break;
    }

    return QObject::eventFilter(watched, event);
}
