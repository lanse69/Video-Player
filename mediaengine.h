#pragma once

#include <QObject>
#include <QMediaPlayer>
#include <QAudioOutput>
#include <QUrl>
#include <qqmlintegration.h>
#include <QVideoSink>
#include <QMap>
#include <QPair>

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
    Q_PROPERTY(QUrl currentMedia READ currentMedia NOTIFY currentMediaChanged) // 当前URL
    Q_PROPERTY(QString subtitleText READ subtitleText NOTIFY subtitleTextChanged) // 字幕内容
    Q_PROPERTY(bool hasSubtitle READ hasSubtitle NOTIFY hasSubtitleChanged)       // 是否具有字幕
    Q_PROPERTY(bool subtitleVisible READ subtitleVisible WRITE setSubtitleVisible NOTIFY
                   subtitleVisibleChanged) // 是否展示字幕
    Q_PROPERTY(bool userMutedSubtitle READ userMutedSubtitle WRITE setUserMutedSubtitle NOTIFY
                   userMutedSubtitleChanged) //用户对字幕的开关
    Q_PROPERTY(qreal playbackRate READ playbackRate WRITE setPlaybackRate NOTIFY playbackRateChanged) // 播放速率
    Q_PROPERTY(int loops READ loops WRITE setLoops NOTIFY loopsChanged FINAL)                         // 循环播放
    Q_PROPERTY(qreal videoAspectRatio READ videoAspectRatio NOTIFY videoAspectRatioChanged)           // 视频宽高比

public:
    explicit MediaEngine(QObject *parent = nullptr);

    QVideoSink *videoSink() const;
    bool isPlaying() const;
    qint64 position() const;
    qint64 duration() const;
    qreal volume() const;
    bool isMuted() const;
    QUrl currentMedia() const;
    QString subtitleText() const;
    bool hasSubtitle() const;
    bool subtitleVisible() const;
    bool userMutedSubtitle() const;
    void setUserMutedSubtitle(bool muted);
    void updateSubtitleState();
    qreal playbackRate() const; // 返回播放速率
    int loops() const;          // 返回1播放一次，返回-1循环播放
    qreal videoAspectRatio() const; // 返回视频的宽高比

    Q_INVOKABLE void play();
    Q_INVOKABLE void pause();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void setPosition(qint64 position);
    Q_INVOKABLE void setVolume(qreal volume);
    Q_INVOKABLE void setMedia(const QUrl &url);
    Q_INVOKABLE void setMuted(bool muted);
    Q_INVOKABLE void setVideoSink(QVideoSink *sink);
    Q_INVOKABLE void loadSubtitle(const QUrl &mediaUrl);
    Q_INVOKABLE void setSubtitleVisible(bool visible);
    Q_INVOKABLE void setPlaybackRate(qreal rate); // 设置播放速率
    Q_INVOKABLE void setLoops(int loops);         // 设置循环播放

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
    void subtitleTextChanged();      // 字幕内容变
    void hasSubtitleChanged();       // 是否具有字幕变
    void subtitleVisibleChanged();   // 字幕可见性变化
    void userMutedSubtitleChanged(); // 用户改变字幕出现
    void playbackRateChanged();      // 播放速率变化
    void loopsChanged();             // 循环状态变化
    void videoAspectRatioChanged();  // 视频宽高比变化

private:
    void parseLrcFile(const QString &filePath);
    void parseSrtFile(const QString &filePath);

    QMediaPlayer *m_player;
    QAudioOutput *m_audioOutput;
    QVideoSink *m_videoSink;
    qreal m_lastVolume;
    bool m_muted;
    QString m_subtitleText;
    bool m_hasSubtitle;
    bool m_subtitleVisible;
    QMap<qint64, QPair<qint64, QString>> m_subtitles;
    bool m_userMutedSubtitle;
};
