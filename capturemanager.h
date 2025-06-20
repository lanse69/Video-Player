#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QUrl>
#include <QImage>
#include <QString>

class CaptureManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
public:
    explicit CaptureManager(QObject *parent = nullptr);

    enum CaptureType { WindowCapture, FullScreenCapture };
    Q_ENUM(CaptureType)

    Q_INVOKABLE bool captureScreenshot(CaptureType type);
    Q_INVOKABLE bool saveScreenshot(const QUrl &destination);
    Q_INVOKABLE QString generateFilePath() const;
    Q_INVOKABLE QUrl previewUrl() const;
    Q_INVOKABLE void removePreviewFile();

signals:
    void screenshotCaptured();
    void errorOccurred(const QString &error);

private:
    QImage m_capturedImage; // 存储捕获的图像
    QUrl m_previewUrl;      // 预览URL
};
