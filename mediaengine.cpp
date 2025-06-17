#include "mediaengine.h"

#include <QDebug>
#include <QtMath>

MediaEngine::MediaEngine(QObject *parent) : QObject(parent), m_videoSink{nullptr}, m_lastVolume{0.5}, m_muted{false}
{
    m_player = new QMediaPlayer(this);
    m_audioOutput = new QAudioOutput(this);
    m_audioOutput->setVolume(m_lastVolume);
    m_player->setAudioOutput(m_audioOutput);

    connect(m_player, &QMediaPlayer::playbackStateChanged, this, [this]() { emit playingChanged(); });
    connect(m_player, &QMediaPlayer::positionChanged, this, [this]() { emit positionChanged(); });
    connect(m_player, &QMediaPlayer::durationChanged, this, [this]() { emit durationChanged(); });
    connect(m_player, &QMediaPlayer::mediaStatusChanged, this, [this](QMediaPlayer::MediaStatus status) {
        emit mediaStatusChanged(static_cast<int>(status));
    });
    connect(m_player, &QMediaPlayer::errorOccurred, this, [this](QMediaPlayer::Error error, const QString &errorString) {
        emit errorOccurred(static_cast<int>(error), errorString);
    });

    // connect(m_player, &QMediaPlayer::videoAvailableChanged, this, [this](bool available) {
    //     if (available) {
    //         auto tracks = m_player->videoTracks();
    //         if (!tracks.isEmpty()) { emit videoSizeChanged(tracks.first().resolution()); }
    //     }
    // });

    // 音量变化连接
    connect(m_audioOutput, &QAudioOutput::volumeChanged, this, &MediaEngine::volumeChanged);
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
    if (url.isEmpty()) return;
    qDebug() << "Setting media:" << url;

    m_player->setSource(url);
    emit currentMediaChanged();

    // 连接错误信号
    connect(m_player,
            &QMediaPlayer::errorOccurred,
            this,
            [=, this](QMediaPlayer::Error error, const QString &errorString) {
                qWarning() << "Media error:" << errorString;
                emit errorOccurred(static_cast<int>(error), errorString);
            });
}
