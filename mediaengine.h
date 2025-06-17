#pragma once

#include <QObject>
#include <QMediaPlayer>
#include <QAudioOutput>
#include <QUrl>
#include <qqmlintegration.h>

class MediaEngine : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(bool playing READ isPlaying NOTIFY playingChanged)
    Q_PROPERTY(qint64 position READ position WRITE setPosition NOTIFY positionChanged)
    Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(qreal volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(QUrl currentMedia READ currentMedia NOTIFY currentMediaChanged)

public:
    explicit MediaEngine(QObject *parent = nullptr);

    bool isPlaying() const;
    qint64 position() const;
    qint64 duration() const;
    qreal volume() const;
    QUrl currentMedia() const;

    Q_INVOKABLE void play();
    Q_INVOKABLE void pause();
    Q_INVOKABLE void stop();
    Q_INVOKABLE void setPosition(qint64 position);
    Q_INVOKABLE void setVolume(qreal volume);
    Q_INVOKABLE void setMedia(const QUrl &url);

signals:
    void playingChanged();
    void positionChanged();
    void durationChanged();
    void volumeChanged();
    void currentMediaChanged();
    void mediaStatusChanged(int status);
    void errorOccurred(int error, const QString &errorString);

private:
    QMediaPlayer *m_player;
    QAudioOutput *m_audioOutput;
};
