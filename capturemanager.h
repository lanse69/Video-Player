#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QUrl>
#include <QImage>
#include <QString>
#include <QTimer>
#include <QMediaCaptureSession>
#include <QScreenCapture>
#include <QAudioInput>
#include <QMediaRecorder>
#include <QWindowCapture>
#include <QCamera>
#include <QImageCapture>
#include <QCameraDevice>
#include <QVideoSink>

class CaptureManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(RecordState recordState READ recordState NOTIFY recordStateChanged)
    Q_PROPERTY(int recordingTime READ recordingTime NOTIFY recordingTimeChanged)
    Q_PROPERTY(bool recordAudio READ recordAudio WRITE setRecordAudio NOTIFY recordAudioChanged)
    Q_PROPERTY(QVariantList availableCameras READ availableCameras NOTIFY availableCamerasChanged)
    Q_PROPERTY(CameraState cameraState READ cameraState NOTIFY cameraStateChanged)
    Q_PROPERTY(int cameraRecordingTime READ cameraRecordingTime NOTIFY cameraRecordingTimeChanged)
    Q_PROPERTY(bool hasCamera READ hasCamera NOTIFY hasCameraChanged)
    Q_PROPERTY(QMediaCaptureSession *cameraSession READ cameraSession NOTIFY cameraSessionChanged)
    Q_PROPERTY(bool cameraAudio READ cameraAudio WRITE setCameraAudio NOTIFY cameraAudioChanged)
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
    void setRecordAudio(bool enable);
    bool recordAudio() const;
    Q_INVOKABLE void startRecording();
    Q_INVOKABLE void pauseRecording();
    Q_INVOKABLE void resumeRecording();
    Q_INVOKABLE void stopRecording();

    enum CameraState { CameraStopped, CameraRecording, CameraPaused };
    Q_ENUM(CameraState)

    QVariantList availableCameras();
    CameraState cameraState() const;
    int cameraRecordingTime() const;
    bool hasCamera() const;
    QMediaCaptureSession *cameraSession() const;
    void setCameraAudio(bool enable);
    bool cameraAudio() const;
    Q_INVOKABLE void startCameraRecording();
    Q_INVOKABLE void pauseCameraRecording();
    Q_INVOKABLE void resumeCameraRecording();
    Q_INVOKABLE void stopCameraRecording();
    Q_INVOKABLE void selectCamera(const QString &deviceId);
    Q_INVOKABLE void setVideoSink(QVideoSink *sink);
    Q_INVOKABLE bool setCamera();

signals:
    void screenshotCaptured();
    void errorOccurred(const QString &error);
    void recordStateChanged();
    void recordingTimeChanged();
    void recordAudioChanged();
    void availableCamerasChanged();
    void cameraSessionChanged();
    void cameraChanged();
    void cameraStateChanged();
    void cameraRecordingTimeChanged();
    void hasCameraChanged();
    void cameraAudioChanged();

private slots:
    void updateRecordingTime();
    void updateCameraTime();

private:
    void setupScreenRecorder();
    void cleanupRecorder();
    void setupCameraRecorder();
    void cleanupCameraRecorder();

    QImage m_capturedImage; // 存储捕获的图像
    QUrl m_previewUrl;      // 预览URL

    QMediaCaptureSession m_captureSession;
    QScreenCapture *m_screenCapture;
    QAudioInput *m_audioInput;
    QMediaRecorder *m_mediaRecorder;

    RecordState m_recordState;
    QTimer *m_recordTimer;
    int m_recordingSeconds;
    bool m_recordAudio;

    QCamera *m_camera;
    QMediaCaptureSession *m_cameraSession;
    QImageCapture *m_imageCapture;
    QMediaRecorder *m_cameraRecorder;
    QAudioInput *m_cameraAudioInput;
    QTimer *m_cameraTimer;
    int m_cameraRecordingSeconds;
    CameraState m_cameraState;
    QList<QCameraDevice> m_availableCameras;
    bool m_cameraAudio;
};
