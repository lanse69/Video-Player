#include "mediaengine.h"

MediaEngine::MediaEngine(QObject *parent) : QObject(parent)
{
    m_player = new QMediaPlayer(this);
    m_audioOutput = new QAudioOutput(this);
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
    // 音量变化连接
    connect(m_audioOutput, &QAudioOutput::volumeChanged, this, &MediaEngine::volumeChanged);
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

void MediaEngine::setVolume(qreal volume)
{
    m_audioOutput->setVolume(volume);
    emit volumeChanged();
}

void MediaEngine::setMedia(const QUrl &url)
{
    m_player->setSource(url);
    emit currentMediaChanged();
}
