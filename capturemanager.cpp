#include "capturemanager.h"

#include <QQuickWindow>
#include <QGuiApplication>
#include <QScreen>
#include <QStandardPaths>
#include <QDir>
#include <QDateTime>
#include <QTemporaryFile>
#include <QFile>
#include <QPainter>
#include <QMediaFormat>
#include <QScreenCapture>
#include <QAudioFormat>
#include <QMediaDevices>
#include <QAudioDevice>

CaptureManager::CaptureManager(QObject *parent)
    : QObject{parent}
    , m_recordState{Stopped}
    , m_recordTimer{new QTimer(this)}
    , m_recordingSeconds{0}
    , m_screenCapture{nullptr}
    , m_audioInput{nullptr}
    , m_mediaRecorder{nullptr}
    , m_recordAudio{true}
    , m_camera{nullptr}
    , m_imageCapture{nullptr}
    , m_cameraRecorder{nullptr}
    , m_cameraTimer{new QTimer(this)}
    , m_cameraRecordingSeconds{0}
    , m_cameraState{CameraStopped}
    , m_cameraSession{nullptr}
    , m_cameraAudio{true}
    , m_cameraAudioInput{nullptr}
{
    connect(m_recordTimer, &QTimer::timeout, this, &CaptureManager::updateRecordingTime);
    connect(m_cameraTimer, &QTimer::timeout, this, &CaptureManager::updateCameraTime);

    if (QMediaDevices::defaultAudioInput().isNull()) {
        qWarning() << "No audio input device available";
        m_recordAudio = false; // 无设备时禁用录音
        m_cameraAudio = false;
    }
}

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

QString CaptureManager::generateFilePath(Type type) const
{
    QString dirPath;
    if (type == Screenshot) {
        dirPath = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation);
    } else if (type == Record) {
        dirPath = QStandardPaths::writableLocation(QStandardPaths::MoviesLocation);
    }
    if (dirPath.isEmpty()) { dirPath = QDir::currentPath(); }

    dirPath = QDir::cleanPath(dirPath);

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

void CaptureManager::startRecording()
{
    if (m_recordState != Stopped) return;

    // 清理之前的录制资源
    cleanupRecorder();

    // 创建视频文件路径
    QString dirPath = generateFilePath(Record);
    QDir dir(dirPath);
    if (!dir.exists()) dir.mkpath(".");
    QString fileName = dirPath + QDir::separator() + "recording_"
                       + QDateTime::currentDateTime().toString("yyyyMMdd_HHmmss") + ".mp4";

    // 设置录制参数
    setupScreenRecorder();

    m_mediaRecorder->setOutputLocation(QUrl::fromLocalFile(fileName));

    // 设置捕获源
    QScreen *screen = QGuiApplication::primaryScreen();
    if (!screen) {
        emit errorOccurred(tr("No primary screen found"));
        return;
    }
    m_screenCapture = new QScreenCapture(this);
    m_screenCapture->setScreen(screen);
    m_captureSession.setScreenCapture(m_screenCapture);

    if (m_recordAudio) {
        m_audioInput = new QAudioInput(this);

        // 使用默认音频输入设备
        QAudioDevice inputDevice = QMediaDevices::defaultAudioInput();
        if (inputDevice.isNull()) {
            emit errorOccurred(tr("No audio input device found"));
            return;
        }

        m_audioInput->setDevice(inputDevice);

        m_audioInput->setVolume(0.8);
        m_captureSession.setAudioInput(m_audioInput);
    }

    // 设置录制器
    m_captureSession.setRecorder(m_mediaRecorder);

    // 开始捕获
    if (m_screenCapture) { m_screenCapture->start(); }
    m_mediaRecorder->record();

    m_recordState = Recording;
    emit recordStateChanged();

    // 开始计时
    m_recordingSeconds = 0;
    emit recordingTimeChanged();
    m_recordTimer->start(1000);
}

void CaptureManager::setupScreenRecorder()
{
    cleanupRecorder();

    m_mediaRecorder = new QMediaRecorder(this);

    // 初始化媒体格式
    QMediaFormat format;
    format.setFileFormat(QMediaFormat::MPEG4);
    format.setVideoCodec(QMediaFormat::VideoCodec::H265);
    format.setAudioCodec(QMediaFormat::AudioCodec::AAC);
    m_mediaRecorder->setMediaFormat(format);
    // 设置分辨率
    m_mediaRecorder->setVideoResolution(QGuiApplication::primaryScreen()->size());
    // 设置比特率
    m_mediaRecorder->setVideoBitRate(8000000);
    // 设置帧率
    m_mediaRecorder->setVideoFrameRate(60);

    m_mediaRecorder->setQuality(QMediaRecorder::HighQuality);
}

void CaptureManager::pauseRecording()
{
    if (m_recordState != Recording) return;

    m_mediaRecorder->pause();

    m_recordState = Paused;
    emit recordStateChanged();
    m_recordTimer->stop();
}

void CaptureManager::resumeRecording()
{
    if (m_recordState != Paused) return;

    m_mediaRecorder->record();

    m_recordState = Recording;
    emit recordStateChanged();
    m_recordTimer->start();
}

void CaptureManager::stopRecording()
{
    if (m_recordState == Stopped) return;

    if (m_screenCapture) { m_screenCapture->stop(); }

    if (m_mediaRecorder) { m_mediaRecorder->stop(); }

    m_recordState = Stopped;
    emit recordStateChanged();
    m_recordTimer->stop();

    m_recordingSeconds = 0;
    emit recordingTimeChanged();

    cleanupRecorder();
}

void CaptureManager::cleanupRecorder()
{
    if (m_mediaRecorder) {
        m_mediaRecorder->stop();
        m_captureSession.setRecorder(nullptr);
        delete m_mediaRecorder;
        m_mediaRecorder = nullptr;
    }

    if (m_screenCapture) {
        m_screenCapture->stop();
        m_captureSession.setScreenCapture(nullptr);
        delete m_screenCapture;
        m_screenCapture = nullptr;
    }

    if (m_audioInput) {
        m_captureSession.setAudioInput(nullptr);
        delete m_audioInput;
        m_audioInput = nullptr;
    }
}

int CaptureManager::recordingTime() const
{
    return m_recordingSeconds;
}

void CaptureManager::updateRecordingTime()
{
    m_recordingSeconds++;
    emit recordingTimeChanged();
}

CaptureManager::RecordState CaptureManager::recordState() const
{
    return m_recordState;
}

bool CaptureManager::recordAudio() const
{
    return m_recordAudio;
}

void CaptureManager::setRecordAudio(bool enable)
{
    if (m_recordAudio != enable) {
        m_recordAudio = enable;
        emit recordAudioChanged();
    }
}

void CaptureManager::updateCameraTime()
{
    m_cameraRecordingSeconds++;
    emit cameraRecordingTimeChanged();
}

bool CaptureManager::hasCamera() const
{
    return !m_availableCameras.isEmpty();
}

QMediaCaptureSession *CaptureManager::cameraSession() const
{
    return m_cameraSession;
}

QVariantList CaptureManager::availableCameras()
{
    m_availableCameras = QMediaDevices::videoInputs();
    emit availableCamerasChanged();
    emit hasCameraChanged();

    QVariantList list;
    for (auto &device : m_availableCameras) {
        QVariantMap map;
        map["id"] = device.id();
        map["description"] = device.description();
        list.append(map);
    }
    return list;
}

void CaptureManager::setVideoSink(QVideoSink *sink)
{
    if (m_cameraSession) { m_cameraSession->setVideoSink(sink); }
}

bool CaptureManager::setCamera()
{
    return m_camera;
}

void CaptureManager::selectCamera(const QString &deviceId)
{
    if (m_camera) { cleanupCameraRecorder(); }

    if (m_availableCameras.isEmpty()) {
        m_availableCameras = QMediaDevices::videoInputs();
        emit availableCamerasChanged();
        emit hasCameraChanged();
    }

    auto it = std::find_if(m_availableCameras.begin(), m_availableCameras.end(), [&](const QCameraDevice &device) {
        return device.id() == deviceId;
    });

    if (it != m_availableCameras.end()) {
        m_camera = new QCamera(*it, this);
        setupCameraRecorder();
        emit cameraChanged();
    }
}

void CaptureManager::setupCameraRecorder()
{
    if (!m_camera) return;

    m_cameraSession = new QMediaCaptureSession(this);

    m_cameraSession->setCamera(m_camera);

    // 设置图像捕捉
    m_imageCapture = new QImageCapture(this);
    m_cameraSession->setImageCapture(m_imageCapture);

    // 设置视频录制
    m_cameraRecorder = new QMediaRecorder(this);
    m_cameraSession->setRecorder(m_cameraRecorder);

    // 配置录制格式
    QMediaFormat format;
    format.setFileFormat(QMediaFormat::MPEG4);
    format.setVideoCodec(QMediaFormat::VideoCodec::H265);
    format.setAudioCodec(QMediaFormat::AudioCodec::AAC);
    m_cameraRecorder->setMediaFormat(format);
    m_cameraRecorder->setVideoResolution(QGuiApplication::primaryScreen()->size());
    m_cameraRecorder->setQuality(QMediaRecorder::HighQuality);

    connect(m_cameraRecorder,
            &QMediaRecorder::errorOccurred,
            this,
            [this](QMediaRecorder::Error error, const QString &errorString) { emit errorOccurred(errorString); });

    connect(m_camera, &QCamera::errorOccurred, this, [this](QCamera::Error error, const QString &errorString) {
        emit errorOccurred(errorString);
    });

    emit cameraSessionChanged();
}

void CaptureManager::startCameraRecording()
{
    if (m_cameraState != CameraStopped || !m_camera) return;

    // 创建保存路径
    QString dirPath = generateFilePath(Record);
    QDir dir(dirPath);
    if (!dir.exists()) dir.mkpath(".");
    QString fileName = dirPath + QDir::separator() + "camera_"
                       + QDateTime::currentDateTime().toString("yyyyMMdd_HHmmss") + ".mp4";

    m_cameraRecorder->setOutputLocation(QUrl::fromLocalFile(fileName));

    if (m_cameraAudio) {
        m_cameraAudioInput = new QAudioInput(this);

        // 使用默认音频输入设备
        QAudioDevice inputDevice = QMediaDevices::defaultAudioInput();
        if (inputDevice.isNull()) {
            emit errorOccurred(tr("No audio input device found"));
            return;
        }

        m_cameraAudioInput->setDevice(inputDevice);

        m_cameraAudioInput->setVolume(0.8);
        m_cameraSession->setAudioInput(m_cameraAudioInput);
    }

    m_camera->start();
    m_cameraState = CameraRecording;
    emit cameraStateChanged();

    m_cameraRecorder->record();
    // 开始计时
    m_cameraRecordingSeconds = 0;
    emit cameraRecordingTimeChanged();
    m_cameraTimer->start(1000);
}

void CaptureManager::pauseCameraRecording()
{
    if (m_cameraState != CameraRecording) return;

    m_cameraRecorder->pause();
    m_cameraState = CameraPaused;
    emit cameraStateChanged();
    m_cameraTimer->stop();
}

void CaptureManager::resumeCameraRecording()
{
    if (m_cameraState != CameraPaused) return;

    m_cameraRecorder->record();
    m_cameraState = CameraRecording;
    emit cameraStateChanged();
    m_cameraTimer->start();
}

void CaptureManager::stopCameraRecording()
{
    if (m_cameraState == CameraStopped) return;

    m_cameraRecorder->stop();
    m_camera->stop();
    m_cameraState = CameraStopped;
    emit cameraStateChanged();
    m_cameraTimer->stop();

    m_cameraRecordingSeconds = 0;
    emit cameraRecordingTimeChanged();

    cleanupCameraRecorder();
}

void CaptureManager::cleanupCameraRecorder()
{
    if (m_cameraRecorder) {
        m_cameraRecorder->stop();
        m_cameraSession->setRecorder(nullptr);
        delete m_cameraRecorder;
        m_cameraRecorder = nullptr;
    }

    if (m_imageCapture) {
        m_cameraSession->setImageCapture(nullptr);
        delete m_imageCapture;
        m_imageCapture = nullptr;
    }

    if (m_camera) {
        m_camera->stop();
        m_cameraSession->setCamera(nullptr);
        delete m_camera;
        m_camera = nullptr;
    }

    if (m_cameraAudioInput) {
        m_cameraSession->setAudioInput(nullptr);
        delete m_cameraAudioInput;
        m_cameraAudioInput = nullptr;
    }

    m_cameraState = CameraStopped;
    emit cameraStateChanged();
}

CaptureManager::CameraState CaptureManager::cameraState() const
{
    return m_cameraState;
}

int CaptureManager::cameraRecordingTime() const
{
    return m_cameraRecordingSeconds;
}

bool CaptureManager::cameraAudio() const
{
    return m_cameraAudio;
}

void CaptureManager::setCameraAudio(bool enable)
{
    if (m_cameraAudio != enable) {
        m_cameraAudio = enable;
        emit cameraAudioChanged();
    }
}
