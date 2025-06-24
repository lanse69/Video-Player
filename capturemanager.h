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
    Q_PROPERTY(RecordState recordState READ recordState NOTIFY recordStateChanged)                 // 录屏状态
    Q_PROPERTY(int recordingTime READ recordingTime NOTIFY recordingTimeChanged)                   // 录屏时间
    Q_PROPERTY(bool recordAudio READ recordAudio WRITE setRecordAudio NOTIFY recordAudioChanged)   // 录屏录音
    Q_PROPERTY(QVariantList availableCameras READ availableCameras NOTIFY availableCamerasChanged) // 摄像头列表
    Q_PROPERTY(CameraState cameraState READ cameraState NOTIFY cameraStateChanged)                 // 拍摄状态
    Q_PROPERTY(int cameraRecordingTime READ cameraRecordingTime NOTIFY cameraRecordingTimeChanged) // 拍摄时间
    Q_PROPERTY(bool hasCamera READ hasCamera NOTIFY hasCameraChanged)                              // 是否有摄像头
    Q_PROPERTY(QMediaCaptureSession *cameraSession READ cameraSession NOTIFY cameraSessionChanged) // 拍摄管理
    Q_PROPERTY(bool cameraAudio READ cameraAudio WRITE setCameraAudio NOTIFY cameraAudioChanged)   // 拍摄录音
    Q_PROPERTY(
        CameraLayout playerLayout READ playerLayout WRITE setPlayerLayout NOTIFY playerLayoutChanged) // 播放器布局方式
public:
    explicit CaptureManager(QObject *parent = nullptr);

    enum Type { Screenshot, Record }; // 截图，录制
    Q_ENUM(Type)

    enum CaptureType { WindowCapture, FullScreenCapture }; // 窗口，全屏
    Q_ENUM(CaptureType)

    Q_INVOKABLE bool captureScreenshot(CaptureType type);     //截图
    Q_INVOKABLE bool saveScreenshot(const QUrl &destination); // 保存截图
    Q_INVOKABLE QString generateFilePath(Type type) const;    // 获取默认保存位置
    Q_INVOKABLE QUrl previewUrl() const;                      // 预览图
    Q_INVOKABLE void removePreviewFile();                     // 删除预览图

    enum RecordState { Stopped, Recording, Paused }; // 停止，继续，暂停
    Q_ENUM(RecordState)

    RecordState recordState() const;
    int recordingTime() const;
    void setRecordAudio(bool enable);
    bool recordAudio() const;
    Q_INVOKABLE void startRecording();  // 开始录制
    Q_INVOKABLE void pauseRecording();  // 暂停录制
    Q_INVOKABLE void resumeRecording(); // 继续录制
    Q_INVOKABLE void stopRecording();   // 停止录制

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
    Q_INVOKABLE void selectCamera(const QString &deviceId); // 选择摄像头
    Q_INVOKABLE void setVideoSink(QVideoSink *sink);        // 设置拍摄预览视频流
    Q_INVOKABLE bool setCamera();                           // 是否已设置摄像头

    enum CameraLayout { NotVideo, SideBySide, TopBottom, Pip, LayoutNull };
    Q_ENUM(CameraLayout)

    CameraLayout playerLayout() const;
    void setPlayerLayout(CameraLayout layout);

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
    void playerLayoutChanged();

private slots:
    // 更新录制时间
    void updateRecordingTime();
    void updateCameraTime();

private:
    // 设置录制格式
    void setupScreenRecorder();
    void setupCameraRecorder();
    // 清理录制管理
    void cleanupRecorder();
    void cleanupCameraRecorder();

    QImage m_capturedImage; // 存储捕获的图像
    QUrl m_previewUrl;      // 预览URL

    QMediaCaptureSession m_captureSession; // 管理
    QScreenCapture *m_screenCapture;       // 屏幕
    QAudioInput *m_audioInput;             // 声音
    QMediaRecorder *m_mediaRecorder;       // 录制

    RecordState m_recordState; // 状态
    QTimer *m_recordTimer;     // 计时器
    int m_recordingSeconds;    // 录制时间
    bool m_recordAudio;

    QCamera *m_camera; // 摄像头
    QMediaCaptureSession *m_cameraSession;
    QImageCapture *m_imageCapture; // 图像捕捉
    QMediaRecorder *m_cameraRecorder;
    QAudioInput *m_cameraAudioInput;
    QTimer *m_cameraTimer;
    int m_cameraRecordingSeconds;
    CameraState m_cameraState;
    QList<QCameraDevice> m_availableCameras;
    bool m_cameraAudio;

    CameraLayout m_playerLayout;      // 播放器布局方式
};
