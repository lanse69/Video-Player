#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QMediaPlayer>
#include <QAudioOutput>
#include <QUrl>
#include <QVideoSink>
#include <QMap>
#include <QPair>
#include <playlistmodel.h>

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

    // 播放速率
    Q_PROPERTY(qreal playbackRate READ playbackRate WRITE setPlaybackRate NOTIFY playbackRateChanged)
    Q_PROPERTY(qreal videoAspectRatio READ videoAspectRatio NOTIFY videoAspectRatioChanged) // 视频宽高比
    // 视频播放模式
    Q_PROPERTY(PlaybackMode playbackMode READ playbackMode WRITE setPlaybackMode NOTIFY playbackModeChanged)
    // 视频是否结束
    Q_PROPERTY(bool playbackFinished READ playbackFinished WRITE setPlaybackFinished NOTIFY playbackFinishedChanged)

    Q_PROPERTY(bool isLocal READ isLocal NOTIFY localChanged)
    Q_PROPERTY(int pauseTimeRemaining READ pauseTimeRemaining NOTIFY pauseTimeRemainingChanged) // 定时暂停倒计时
    Q_PROPERTY(QString coverArtBase64 READ coverArtBase64 NOTIFY coverImageChanged)             // 封面图片的base64数据
    Q_PROPERTY(bool hasVideo READ hasVideo NOTIFY hasVideoChanged)                              // 是否有视频流

public:
    explicit MediaEngine(QObject *parent = nullptr);

    enum PlaybackMode {
        Sequential, // 顺序播放
        Loop,       // 循环播放
        Random      // 随机播放
    };
    Q_ENUM(PlaybackMode)

    bool hasVideo() const; // 获取是否有视频流
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
    qreal videoAspectRatio() const; // 返回视频的宽高比
    PlaybackMode playbackMode() const;         // 返回视频播放模式
    bool isLocal();
    int pauseTimeRemaining() const; // 返回暂停倒计时
    QString coverArtBase64() const; // 获取封面图片的base64数据
    bool isAudioFile(const QUrl &url);
    void extractCoverArt(const QUrl &mediaUrl);

    Q_INVOKABLE bool playbackFinished() const; // 返回视频是否结束
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
    Q_INVOKABLE void setPlaybackMode(PlaybackMode mode); // 设置视频播放模式
    Q_INVOKABLE void setPlaybackFinished(bool finished); // 设置视频是否结束属性
    Q_INVOKABLE QString getFrameAtPosition(qint64 position); // 返回相应位置的视频帧
    Q_INVOKABLE void timedPauseStart(int minutes); // 定时暂停开始
    Q_INVOKABLE int pauseTime();                   // 返回设置的暂停时间
    Q_INVOKABLE QString pauseCountdown();          // 以00：00：00形式返回暂停

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
    void videoAspectRatioChanged();  // 视频宽高比变化
    void playbackModeChanged();      // 播放模式改变
    void playbackFinishedChanged();  // 视频是否结束改变
    void localChanged();
    void pauseTimeRemainingChanged(); // 暂停倒计时改变
    void timedPauseFinished();        // 定时暂停结束信号
    void coverImageChanged();         // 封面图片变化信号
    void hasVideoChanged();           // 视频流状态变化信号
    void videoPause();                // 视频暂停信号

private slots:
    void updatePauseTimeRemaining(); // 暂停倒计时减小

private:
    void parseLrcFile(const QString &filePath);
    void parseSrtFile(const QString &filePath);

    bool m_hasVideo; // 是否有视频流
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
    PlaybackMode m_playbackMode; // 视频播放模式
    bool m_playbackFinished;     // 视频是否结束
    bool m_islocal;
    QString m_coverArtBase64; // 存储封面图片的base64数据

    QMediaPlayer *m_thumbnailPlayer; // 缩略图专用播放器
    QVideoSink *m_thumbnailSink;     // 缩略图专用视频接收器
    QTimer *m_timedPause;            // 定时暂停计时器
    int m_pauseTime;                 // 暂停时间，单位为分
    QTimer *m_pauseCountdown;        // 暂停倒计时器
    int m_pauseTimeRemaining;        // 暂停倒计时,单位为秒
};
