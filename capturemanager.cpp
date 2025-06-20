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

CaptureManager::CaptureManager(QObject *parent)
    : QObject{parent}
    , m_recordState{Stopped}
    , m_recordTimer{new QTimer(this)}
    , m_recordingSeconds{0}
    , m_windowToRecord{nullptr}
    , m_screenCapture{nullptr}
    , m_audioInput{nullptr}
    , m_mediaRecorder{nullptr}
{
    connect(m_recordTimer, &QTimer::timeout, this, &CaptureManager::updateRecordingTime);
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

void CaptureManager::startRecording(CaptureType type)
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
    if (type == WindowCapture) {
        if (!m_windowToRecord) {
            emit errorOccurred(tr("No window set for recording"));
            return;
        }
        QScreen *screen = m_windowToRecord->screen();
        if (!screen) {
            emit errorOccurred(tr("Window's screen not found"));
            return;
        }
        m_screenCapture = new QScreenCapture(this);
        m_screenCapture->setScreen(screen);
        m_captureSession.setScreenCapture(m_screenCapture);
    } else {
        QScreen *screen = QGuiApplication::primaryScreen();
        if (!screen) {
            emit errorOccurred(tr("No primary screen found"));
            return;
        }
        m_screenCapture = new QScreenCapture(this);
        m_screenCapture->setScreen(screen);
        m_captureSession.setScreenCapture(m_screenCapture);
    }

    // 设置音频输入
    m_audioInput = new QAudioInput(this);
    m_captureSession.setAudioInput(m_audioInput);

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
    format.setVideoCodec(QMediaFormat::VideoCodec::H264);
    format.setAudioCodec(QMediaFormat::AudioCodec::AAC);
    m_mediaRecorder->setMediaFormat(format);
    m_mediaRecorder->setVideoResolution(1920, 1080);
    m_mediaRecorder->setVideoFrameRate(30);
    m_mediaRecorder->setQuality(QMediaRecorder::HighQuality);
}

void CaptureManager::pauseRecording()
{
    if (m_recordState != Recording) return;

    m_mediaRecorder->pause();
    if (m_screenCapture) { m_screenCapture->stop(); }

    m_recordState = Paused;
    emit recordStateChanged();
    m_recordTimer->stop();
}

void CaptureManager::resumeRecording()
{
    if (m_recordState != Paused) return;

    if (m_screenCapture) { m_screenCapture->start(); }
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

void CaptureManager::setWindowToRecord(QWindow *window)
{
    m_windowToRecord = window;
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
