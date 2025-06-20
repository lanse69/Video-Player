#include "capturemanager.h"

#include <QQuickWindow>
#include <QGuiApplication>
#include <QScreen>
#include <QDateTime>
#include <QStandardPaths>
#include <QDir>
#include <QTemporaryFile>
#include <QFile>
#include <QCoreApplication>

CaptureManager::CaptureManager(QObject *parent) : QObject{parent} {}

bool CaptureManager::captureScreenshot(CaptureType type)
{
    try {
        removePreviewFile(); // 捕获前先删除旧的预览文件

        QGuiApplication::setOverrideCursor(Qt::BlankCursor);
        QCoreApplication::processEvents();

        if (type == WindowCapture) {
            QQuickWindow *window = qobject_cast<QQuickWindow *>(QGuiApplication::focusWindow());
            if (!window) {
                emit errorOccurred(tr("No active window found"));
                QGuiApplication::restoreOverrideCursor(); // 恢复光标
                return false;
            }
            m_capturedImage = window->grabWindow();
        } else {
            QScreen *screen = QGuiApplication::primaryScreen();
            if (!screen) {
                emit errorOccurred(tr("No primary screen found"));
                QGuiApplication::restoreOverrideCursor(); // 恢复光标
                return false;
            }
            m_capturedImage = screen->grabWindow(0).toImage();
        }

        // 截屏后恢复鼠标指针
        QGuiApplication::restoreOverrideCursor();

        if (m_capturedImage.isNull()) {
            emit errorOccurred(tr("Failed to capture image"));
            return false;
        }

        // 保存到临时文件用于预览
        QString tempDir = QDir::tempPath();
        if (!tempDir.endsWith("/")) tempDir += "/";
        QTemporaryFile tempFile(tempDir + "XXXXXX.png");
        if (tempFile.open()) {
            if (m_capturedImage.save(&tempFile, "PNG")) {
                tempFile.close();
                QString tempFilePath = tempFile.fileName();
                QFile::setPermissions(tempFilePath,
                                      QFile::ReadOwner | QFile::WriteOwner | QFile::ReadUser | QFile::ReadGroup
                                          | QFile::ReadOther);
                m_previewUrl = QUrl::fromLocalFile(tempFilePath);
                tempFile.setAutoRemove(false);
                emit screenshotCaptured();
                return true;
            } else {
                emit errorOccurred(tr("Failed to write preview image"));
                return false;
            }
        } else {
            emit errorOccurred(tr("Failed to create preview image"));
            return false;
        }
    } catch (...) {
        QGuiApplication::restoreOverrideCursor(); // 确保异常情况下也恢复光标
        emit errorOccurred(tr("Unknown error occurred during capture"));
        return false;
    }
}

QUrl CaptureManager::previewUrl() const
{
    return m_previewUrl;
}

bool CaptureManager::saveScreenshot(const QUrl &destination)
{
    QString destPath = destination.toLocalFile();
    return m_capturedImage.save(destPath, "PNG");
}

QString CaptureManager::generateFilePath() const
{
    QString dirPath = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation);
    if (dirPath.isEmpty()) { dirPath = QDir::currentPath(); }

    if (!dirPath.endsWith(QDir::separator())) { dirPath += QDir::separator(); }

    dirPath += "Video-Player_Capture";
    QDir dir(dirPath);
    if (!dir.exists()) { dir.mkpath("."); }

    return dirPath;
}

void CaptureManager::removePreviewFile()
{
    if (!m_previewUrl.isEmpty()) {
        QString filePath = m_previewUrl.toLocalFile();
        QFile file(filePath);
        if (file.exists()) { file.remove(); }
        m_previewUrl = QUrl(); // 重置预览URL
    }
}
