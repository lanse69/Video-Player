#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QUrl>
#include <QImage>
#include <QString>
#include <QTimer>
#include <QWindow>
#include <QMediaCaptureSession>
#include <QScreenCapture>
#include <QAudioInput>
#include <QMediaRecorder>

class CaptureManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(RecordState recordState READ recordState NOTIFY recordStateChanged)
    Q_PROPERTY(int recordingTime READ recordingTime NOTIFY recordingTimeChanged)
public:
    explicit CaptureManager(QObject *parent = nullptr);

    enum Type { Screenshot, Record };
    Q_ENUM(Type)

    enum CaptureType { WindowCapture, FullScreenCapture };
    Q_ENUM(CaptureType)

    Q_INVOKABLE bool captureScreenshot(CaptureType type);
    Q_INVOKABLE bool saveScreenshot(const QUrl &destination);
    Q_INVOKABLE QString generateFilePath(Type type) const;
    Q_INVOKABLE QUrl previewUrl() const;
    Q_INVOKABLE void removePreviewFile();

    enum RecordState { Stopped, Recording, Paused };
    Q_ENUM(RecordState)

    RecordState recordState() const;
    int recordingTime() const;
    Q_INVOKABLE void startRecording(CaptureType type);
    Q_INVOKABLE void pauseRecording();
    Q_INVOKABLE void resumeRecording();
    Q_INVOKABLE void stopRecording();
    Q_INVOKABLE void setWindowToRecord(QWindow *window);

signals:
    void screenshotCaptured();
    void errorOccurred(const QString &error);
    void recordStateChanged();
    void recordingTimeChanged();

private slots:
    void updateRecordingTime();

private:
    void setupScreenRecorder();
    void cleanupRecorder();

    QImage m_capturedImage; // 存储捕获的图像
    QUrl m_previewUrl;      // 预览URL

    QMediaCaptureSession m_captureSession;
    QScreenCapture *m_screenCapture;
    QAudioInput *m_audioInput;
    QMediaRecorder *m_mediaRecorder;

    RecordState m_recordState;
    QTimer *m_recordTimer;
    int m_recordingSeconds;
    QWindow *m_windowToRecord;
};
