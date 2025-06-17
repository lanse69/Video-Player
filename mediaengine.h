#pragma once

#include <QObject>
#include <QMediaPlayer>
#include <QAudioOutput>
#include <QUrl>
#include <qqmlintegration.h>
#include <QVideoSink>

class MediaEngine : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QVideoSink *videoSink READ videoSink NOTIFY videoSinkChanged)
    Q_PROPERTY(bool playing READ isPlaying NOTIFY playingChanged)                      // 播放状态
    Q_PROPERTY(qint64 position READ position WRITE setPosition NOTIFY positionChanged) // 播放位置
    Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)                   // 总时长
    Q_PROPERTY(qreal volume READ volume WRITE setVolume NOTIFY volumeChanged)          // 音量
    Q_PROPERTY(bool muted READ isMuted WRITE setMuted NOTIFY mutedChanged)
    Q_PROPERTY(QUrl currentMedia READ currentMedia NOTIFY currentMediaChanged)         // 当前URL

public:
    explicit MediaEngine(QObject *parent = nullptr);

    QVideoSink *videoSink() const;
    bool isPlaying() const;
    qint64 position() const;
    qint64 duration() const;
    qreal volume() const;
    bool isMuted() const;
    QUrl currentMedia() const;

    Q_INVOKABLE void play();
    Q_INVOKABLE void pause();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void setPosition(qint64 position);
    Q_INVOKABLE void setVolume(qreal volume);
    Q_INVOKABLE void setMedia(const QUrl &url);
    Q_INVOKABLE void setMuted(bool muted);
    Q_INVOKABLE void setVideoSink(QVideoSink *sink);

signals:
    void videoSinkChanged();
    void playingChanged();
    void positionChanged();
    void durationChanged();
    void volumeChanged();
    void mutedChanged();
    void currentMediaChanged();
    void mediaStatusChanged(int status);
    void errorOccurred(int error, const QString &errorString);
    // void videoSizeChanged(QSize size);
    // void playbackRateChanged(qreal rate);

private:
    QMediaPlayer *m_player;
    QAudioOutput *m_audioOutput;
    QVideoSink *m_videoSink;
    qreal m_lastVolume;
    bool m_muted;
};
