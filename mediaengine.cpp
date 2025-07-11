#include "mediaengine.h"

#include <QDebug>
#include <QtMath>
#include <QFileInfo>
#include <QDir>
#include <QRegularExpression>
#include <QStringConverter>
#include <QSize>
#include <QVideoFrame>
#include <QBuffer>
#include <QEventLoop>
#include <QTimer>

extern "C" {
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
}

MediaEngine::MediaEngine(QObject *parent)
    : QObject(parent)
    , m_videoSink{nullptr}
    , m_lastVolume{0.5}
    , m_muted{false}
    , m_hasSubtitle{false}
    , m_subtitleVisible{true}
    , m_userMutedSubtitle{false}
    , m_playbackMode{Sequential}
    , m_playbackFinished{false}
    , m_thumbnailPlayer{nullptr}
    , m_thumbnailSink{nullptr}
    , m_islocal(true)
    , m_coverArtBase64{""}
    , m_pauseTime{0}
    , m_pauseTimeRemaining{0}
{
    m_player = new QMediaPlayer(this);
    m_audioOutput = new QAudioOutput(this);
    m_audioOutput->setVolume(m_lastVolume);
    m_player->setAudioOutput(m_audioOutput);

    // 创建专用缩略图播放器
    m_thumbnailPlayer = new QMediaPlayer(this);
    m_thumbnailSink = new QVideoSink(this);
    m_thumbnailPlayer->setVideoOutput(m_thumbnailSink);
    m_thumbnailPlayer->setAudioOutput(nullptr); // 禁用缩略图播放器的音频输出

    m_timedPause = new QTimer(this);
    m_pauseCountdown = new QTimer(this);
    m_pauseCountdown->setInterval(1000);

    connect(m_player, &QMediaPlayer::playbackStateChanged, this, &MediaEngine::playingChanged);
    connect(m_player, &QMediaPlayer::positionChanged, this, &MediaEngine::positionChanged);
    connect(m_player, &QMediaPlayer::durationChanged, this, &MediaEngine::durationChanged);
    connect(m_player, &QMediaPlayer::mediaStatusChanged, this, [this](QMediaPlayer::MediaStatus status) {
        emit mediaStatusChanged(static_cast<int>(status));
    });
    connect(m_player, &QMediaPlayer::errorOccurred, this, [this](QMediaPlayer::Error error, const QString &errorString) {
        emit errorOccurred(static_cast<int>(error), errorString);
    });

    // 音量变化连接
    connect(m_audioOutput, &QAudioOutput::volumeChanged, this, &MediaEngine::volumeChanged);

    // 音视频播放位置改变,字幕改变
    connect(m_player, &QMediaPlayer::positionChanged, this, &MediaEngine::updateSubtitleState);

    // 连接播放速率信号
    connect(m_player, &QMediaPlayer::playbackRateChanged, this, &MediaEngine::playbackRateChanged);

    // 检查视频是否结束
    connect(m_player, &QMediaPlayer::positionChanged, this, [this](qint64 position) {
        if (position > 0 && position == m_player->duration()) { setPlaybackFinished(true); }
    });

    // 到设定的时间暂停
    connect(m_timedPause, &QTimer::timeout, this, [this]() {
        pause();
        m_timedPause->stop();
        m_pauseTimeRemaining = 0;
        m_pauseTime = 0;
        emit pauseTimeRemainingChanged();
        emit timedPauseFinished(); // 定时暂停倒计时结束信号
    });

    // 暂停倒计时每秒减一
    connect(m_pauseCountdown, &QTimer::timeout, this, &MediaEngine::updatePauseTimeRemaining);
}

QVideoSink *MediaEngine::videoSink() const
{
    return m_videoSink;
}

void MediaEngine::setVideoSink(QVideoSink *sink)
{
    if (m_videoSink != sink) {
        m_videoSink = sink;
        m_player->setVideoOutput(sink);
        emit videoSinkChanged();
    }
}

bool MediaEngine::isPlaying() const
{
    return m_player->playbackState() == QMediaPlayer::PlayingState;
}

qint64 MediaEngine::position() const
{
    return m_player->position();
}

qint64 MediaEngine::duration() const
{
    return m_player->duration();
}

qreal MediaEngine::volume() const
{
    return m_audioOutput->volume();
}

bool MediaEngine::isMuted() const
{
    return m_muted;
}

void MediaEngine::setVolume(qreal volume)
{
    if (qFuzzyIsNull(qAbs(volume - m_audioOutput->volume()))) return;

    if (!m_muted) {
        m_audioOutput->setVolume(volume);
        m_lastVolume = volume;
        emit volumeChanged();
    }
}

void MediaEngine::setMuted(bool muted)
{
    if (m_muted == muted) return;
    m_muted = muted;
    if (m_muted) {
        m_lastVolume = m_audioOutput->volume();
        m_audioOutput->setVolume(0.0);
    } else {
        m_audioOutput->setVolume(m_lastVolume);
    }
    emit mutedChanged();
    emit volumeChanged();
}

QUrl MediaEngine::currentMedia() const
{
    return m_player->source();
}

void MediaEngine::play()
{
    m_player->play();
}

void MediaEngine::pause()
{
    m_player->pause();
    emit videoPause();
}

void MediaEngine::stop()
{
    m_player->stop();
}

void MediaEngine::setPosition(qint64 position)
{
    m_player->setPosition(position);
}

void MediaEngine::setMedia(const QUrl &url)
{
    m_subtitles.clear();
    m_hasSubtitle = false;
    m_subtitleText = "";
    m_coverArtBase64 = "";
    emit coverImageChanged();
    emit hasSubtitleChanged();
    emit subtitleTextChanged();

    m_player->setSource(url);
    emit currentMediaChanged();

    if (url.isEmpty()) return;

    bool wasLocal = m_islocal;
    m_islocal = url.isLocalFile();

    // 检查URL类型
    if (url.isLocalFile()) {
        // 本地文件 - 加载字幕
        loadSubtitle(url);

        // 如果是音频文件，尝试提取封面
        if (isAudioFile(url)) { extractCoverArt(url); }
    }

    if (url.isLocalFile() != wasLocal) emit localChanged();

    emit subtitleVisibleChanged();
}

void MediaEngine::loadSubtitle(const QUrl &mediaUrl)
{
    if (!mediaUrl.isValid()) return;

    m_subtitles.clear();
    m_hasSubtitle = false;
    m_subtitleText = "";
    emit hasSubtitleChanged();
    emit subtitleTextChanged();

    QString mediaPath = mediaUrl.toLocalFile();
    QFileInfo mediaFileInfo(mediaPath);
    QString baseName = mediaFileInfo.completeBaseName();
    QString path = mediaFileInfo.absolutePath();

    QStringList subtitleExts = {".lrc", ".srt", ".ass", ".ssa", ".sub", ".txt"};
    QDir dir(path);

    // 尝试所有可能的字幕扩展名
    for (const QString &ext : subtitleExts) {
        QStringList files = dir.entryList(QStringList() << baseName + ext, QDir::Files);
        if (!files.isEmpty()) {
            QString subtitlePath = path + "/" + files.first();
            if (ext == ".lrc") {
                parseLrcFile(subtitlePath);
            } else {
                parseSrtFile(subtitlePath);
            }
            break;
        }
    }

    if (!m_subtitles.isEmpty()) {
        m_hasSubtitle = true;
        if (!m_userMutedSubtitle) { m_subtitleVisible = true; }
    }

    emit hasSubtitleChanged();
    emit subtitleVisibleChanged();
    emit subtitleTextChanged();
}

void MediaEngine::parseLrcFile(const QString &filePath)
{
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "Failed to open subtitle file:" << filePath;
        return;
    }

    QTextStream in(&file);
    in.setEncoding(QStringConverter::Utf8);
    static const QRegularExpression timeRegex(R"(\[(\d+):(\d+)(?:\.|:)?(\d*)\])");

    // 临时存储所有字幕条目
    QList<QPair<qint64, QString>> tempSubtitles;

    while (!in.atEnd()) {
        QString line = in.readLine().trimmed();
        if (line.isEmpty()) continue;

        // 处理歌词行
        QRegularExpressionMatchIterator matches = timeRegex.globalMatch(line);
        while (matches.hasNext()) {
            QRegularExpressionMatch match = matches.next();
            if (match.hasMatch()) {
                int minutes = match.captured(1).toInt();
                int seconds = match.captured(2).toInt();
                QString millisStr = match.captured(3);
                int milliseconds = 0;
                // 处理不同的毫秒
                if (!millisStr.isEmpty()) {
                    if (millisStr.length() == 2) {
                        milliseconds = millisStr.toInt() * 10; // 两位数毫秒
                    } else if (millisStr.length() == 3) {
                        milliseconds = millisStr.toInt(); // 三位数毫秒
                    } else if (millisStr.length() > 3) {
                        milliseconds = QStringView(millisStr).left(3).toInt(); // 取前三位
                    }
                }
                qint64 timeMs = minutes * 60000 + seconds * 1000 + milliseconds;

                // 提取歌词文本
                QString text = line.mid(match.capturedEnd()).trimmed();
                if (!text.isEmpty()) { tempSubtitles.append(qMakePair(timeMs, text)); }
            }
        }
    }

    file.close();

    // 按时间排序
    std::sort(tempSubtitles.begin(),
              tempSubtitles.end(),
              [](const QPair<qint64, QString> &a, const QPair<qint64, QString> &b) { return a.first < b.first; });

    // 计算结束时间（下一句的开始时间）
    for (int i = 0; i < tempSubtitles.size(); ++i) {
        qint64 endTime = (i < tempSubtitles.size() - 1) ? tempSubtitles[i + 1].first
                                                        : tempSubtitles[i].first + 5000; // 默认5秒

        m_subtitles.insert(tempSubtitles[i].first, QPair<qint64, QString>(endTime, tempSubtitles[i].second));
    }
}

void MediaEngine::parseSrtFile(const QString &filePath)
{
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "Failed to open subtitle file:" << filePath;
        return;
    }

    QTextStream in(&file);
    in.setEncoding(QStringConverter::Utf8);
    static const QRegularExpression timeRegex(R"((\d{1,2}):(\d{2}):(\d{2})[,.](\d{3}))");

    while (!in.atEnd()) {
        QString line = in.readLine().trimmed();
        if (line.isEmpty()) continue;

        // 跳过序号行
        bool isNumber = false;
        line.toInt(&isNumber);
        if (!isNumber) continue;

        // 读取时间轴
        QString timeLine = in.readLine().trimmed();
        if (timeLine.isEmpty()) continue;

        // 分割开始和结束时间
        QStringList times = timeLine.split("-->");
        if (times.size() < 2) {
            times = timeLine.split("->");
            if (times.size() < 2) continue;
        }

        // 解析开始时间
        QRegularExpressionMatch startMatch = timeRegex.match(times[0].trimmed());
        if (!startMatch.hasMatch()) continue;

        int hours = startMatch.captured(1).toInt();
        int minutes = startMatch.captured(2).toInt();
        int seconds = startMatch.captured(3).toInt();
        int milliseconds = startMatch.captured(4).toInt();
        qint64 startTime = hours * 3600000 + minutes * 60000 + seconds * 1000 + milliseconds;

        // 解析结束时间
        QRegularExpressionMatch endMatch = timeRegex.match(times[1].trimmed());
        if (!endMatch.hasMatch()) continue;

        hours = endMatch.captured(1).toInt();
        minutes = endMatch.captured(2).toInt();
        seconds = endMatch.captured(3).toInt();
        milliseconds = endMatch.captured(4).toInt();
        qint64 endTime = hours * 3600000 + minutes * 60000 + seconds * 1000 + milliseconds;

        // 读取字幕文本
        QString text;
        while (!in.atEnd()) {
            QString line = in.readLine().trimmed();
            if (line.isEmpty()) break;
            if (!text.isEmpty()) text += "<br>";
            text += line;
        }

        if (!text.isEmpty()) { m_subtitles.insert(startTime, QPair<qint64, QString>(endTime, text)); }
    }

    file.close();
}

QString MediaEngine::subtitleText() const
{
    if (!m_player || m_subtitles.isEmpty()) return "";

    qint64 position = m_player->position();
    auto it = m_subtitles.lowerBound(position);

    // 如果没有找到匹配的字幕，返回空字符串
    if (it == m_subtitles.begin() && position < it.key()) { return ""; }

    // 如果当前位置大于所有字幕时间点
    if (it == m_subtitles.end()) {
        --it;
        if (position >= it.key() && position < it.value().first) { return it.value().second; }
        return "";
    }

    if (position >= it.key() && position < it.value().first) { return it.value().second; }

    if (it != m_subtitles.begin()) {
        --it;
        if (position >= it.key() && position < it.value().first) { return it.value().second; }
    }

    return "";
}

bool MediaEngine::hasSubtitle() const
{
    return !m_subtitles.isEmpty();
}

bool MediaEngine::subtitleVisible() const
{
    return m_subtitleVisible;
}

void MediaEngine::setSubtitleVisible(bool visible)
{
    if (m_subtitleVisible != visible) {
        m_subtitleVisible = visible;
        if (!visible) { setUserMutedSubtitle(true); }
        emit subtitleVisibleChanged();
    }
}

bool MediaEngine::userMutedSubtitle() const
{
    return m_userMutedSubtitle;
}

void MediaEngine::setUserMutedSubtitle(bool muted)
{
    if (m_userMutedSubtitle != muted) {
        m_userMutedSubtitle = muted;
        emit userMutedSubtitleChanged();
    }
}

void MediaEngine::updateSubtitleState()
{
    QString newText = subtitleText();

    // 更新字幕文本
    if (m_subtitleText != newText) {
        m_subtitleText = newText;
        emit subtitleTextChanged();
    }
}

qreal MediaEngine::playbackRate() const
{
    return m_player->playbackRate();
}

void MediaEngine::setPlaybackRate(qreal rate)
{
    m_player->setPlaybackRate(rate);
    emit playbackRateChanged();
}

qreal MediaEngine::videoAspectRatio() const
{
    if (m_player->videoOutput()) {
        QVideoSink videoSink = m_player->videoOutput();
        QSize size = videoSink.videoSize();
        if (size.isValid()) return qreal(size.width() / size.height());
    }
    return 0;
}

bool MediaEngine::isLocal()
{
    m_islocal = currentMedia().isLocalFile();
    return m_islocal;
}

MediaEngine::PlaybackMode MediaEngine::playbackMode() const
{
    return m_playbackMode;
}

void MediaEngine::setPlaybackMode(PlaybackMode mode)
{
    if (mode != m_playbackMode) {
        m_playbackMode = mode;
        emit playbackModeChanged();
    }
}

bool MediaEngine::playbackFinished() const
{
    return m_playbackFinished;
}

void MediaEngine::setPlaybackFinished(bool finished)
{
    if (m_playbackFinished != finished) {
        m_playbackFinished = finished;
        emit playbackFinishedChanged();
    }
}

QString MediaEngine::getFrameAtPosition(qint64 position)
{
    if (!m_player->hasVideo()) return ""; // 检查是否有视频流
    if (!isLocal()) return "";            // 检查是否是本地视频

    // 设置缩略图播放器的源
    m_thumbnailPlayer->setSource(m_player->source());

    QEventLoop loop;
    QTimer::singleShot(100, &loop, &QEventLoop::quit); // 超时保护，防止等待帧的时间过长而导致界面卡死
    QObject::connect(m_thumbnailSink, &QVideoSink::videoFrameChanged, &loop, &QEventLoop::quit); // 连接信号以等待帧可用
    m_thumbnailPlayer->setPosition(position);
    m_thumbnailPlayer->play();
    loop.exec(QEventLoop::ExcludeUserInputEvents); // 非阻塞式等待
    QObject::disconnect(m_thumbnailSink, &QVideoSink::videoFrameChanged, &loop, &QEventLoop::quit);
    QVideoFrame frame = m_thumbnailSink->videoFrame(); // 读取当前帧
    m_thumbnailPlayer->pause();

    if (!frame.isValid()) {
        m_thumbnailPlayer->setSource(QUrl());
        return "";
    }

    // 确保帧已映射
    if (!frame.map(QVideoFrame::ReadOnly)) {
        m_thumbnailPlayer->setSource(QUrl());
        return "";
    }

    QImage image = frame.toImage(); // 转换为图像
    frame.unmap();
    if (image.isNull()) {
        m_thumbnailPlayer->setSource(QUrl());
        return "";
    }

    // 转换为Base64字符串
    QByteArray byteArray;
    QBuffer buffer(&byteArray);
    buffer.open(QIODevice::WriteOnly);
    if (!image.save(&buffer, "JPEG")) {
        m_thumbnailPlayer->setSource(QUrl());
        return "";
    }

    return "data:image/jpeg;base64," + byteArray.toBase64();
}

void MediaEngine::timedPauseStart(int minutes)
{
    if (minutes == 0) {
        m_pauseTime = 0;
        m_pauseTimeRemaining = 0;
        m_timedPause->stop();
        m_pauseCountdown->stop();
    } else {
        m_pauseTime = minutes;
        m_timedPause->start(minutes * 60 * 1000);
        m_pauseTimeRemaining = minutes * 60;
        m_pauseCountdown->start();
    }
    emit pauseTimeRemainingChanged();
}

int MediaEngine::pauseTime()
{
    return m_pauseTime;
}

int MediaEngine::pauseTimeRemaining() const
{
    return m_pauseTimeRemaining;
}

QString MediaEngine::coverArtBase64() const
{
    return m_coverArtBase64;
}

bool MediaEngine::isAudioFile(const QUrl &url)
{
    QStringList audioExts = {".mp3", ".wav", ".ogg", ".flac", ".m4a", ".aac"};
    QString path = url.toLocalFile();
    for (const QString &ext : audioExts) {
        if (path.endsWith(ext, Qt::CaseInsensitive)) return true;
    }
    return false;
}

void MediaEngine::extractCoverArt(const QUrl &mediaUrl)
{
    QString mediaPath = mediaUrl.toLocalFile();
    if (mediaPath.isEmpty()) return;

    // 使用FFmpeg提取封面
    AVFormatContext *fmt_ctx = NULL;
    if (avformat_open_input(&fmt_ctx, mediaPath.toUtf8().constData(), NULL, NULL) < 0) {
        qWarning() << "Failed to open file for cover art extraction";
        return;
    }

    if (avformat_find_stream_info(fmt_ctx, NULL) < 0) {
        qWarning() << "Failed to find stream information";
        avformat_close_input(&fmt_ctx);
        return;
    }

    // 查找封面数据
    bool coverFound = false;
    for (unsigned int i = 0; i < fmt_ctx->nb_streams; i++) {
        AVStream *stream = fmt_ctx->streams[i];
        if (stream->disposition & AV_DISPOSITION_ATTACHED_PIC) {
            // 找到封面数据
            AVPacket cover = stream->attached_pic;
            QImage image;
            if (image.loadFromData(cover.data, cover.size)) {
                // 转换为base64
                QByteArray byteArray;
                QBuffer buffer(&byteArray);
                buffer.open(QIODevice::WriteOnly);
                if (image.save(&buffer, "PNG")) {
                    m_coverArtBase64 = QString::fromLatin1(byteArray.toBase64().data());
                    coverFound = true;
                }
            }
            break;
        }
    }

    // 如果没有找到封面，确保设置为空字符串
    if (!coverFound) { m_coverArtBase64 = ""; }

    avformat_close_input(&fmt_ctx);
    emit coverImageChanged();
}

QString MediaEngine::pauseCountdown()
{
    if (m_pauseTimeRemaining > 0) {
        int hours = m_pauseTimeRemaining / 3600;
        int minutes = (m_pauseTimeRemaining % 3600) / 60;
        int seconds = (m_pauseTimeRemaining % 3600) % 60;
        return QString("%1:%2:%3")
            .arg(hours, 2, 10, QLatin1Char('0'))
            .arg(minutes, 2, 10, QLatin1Char('0'))
            .arg(seconds, 2, 10, QLatin1Char('0'));
    } else {
        return "00:00:00";
    }
}

void MediaEngine::updatePauseTimeRemaining()
{
    if (m_pauseTimeRemaining == 0) {
        m_pauseCountdown->stop();
        m_timedPause->stop();
    } else {
        --m_pauseTimeRemaining;
        emit pauseTimeRemainingChanged();
    }
}
