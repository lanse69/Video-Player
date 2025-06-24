#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QFile>
#include <QTimer>
#include <QDir>

class DownloadManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(bool downloading READ downloading NOTIFY downloadingChanged) // 是否在下载
    Q_PROPERTY(qreal progress READ progress NOTIFY progressChanged)         // 下载进度
    Q_PROPERTY(qint64 speed READ speed NOTIFY speedChanged)                 // 下载速度

public:
    explicit DownloadManager(QObject *parent = nullptr);

    bool downloading() const;
    qreal progress() const;
    qint64 speed() const;

    Q_INVOKABLE void download(const QUrl &url, const QString &fileName); // 下载
    Q_INVOKABLE void cancelDownload();                                   // 取消下载
    Q_INVOKABLE QDir generateFilePath() const;
    Q_INVOKABLE QString downloadDirPath() const;

signals:
    void downloadingChanged();
    void progressChanged();
    void speedChanged();
    void downloadFinished(const QString &filePath);
    void errorOccurred(const QString &error);

private slots:
    void onDownloadProgress(qint64 bytesReceived, qint64 bytesTotal); // 处理下载进度更新
    void onFinished();
    void updateSpeed(); // 更新下载速度

private:
    QNetworkAccessManager m_manager; // 网络访问管理器
    QNetworkReply *m_reply;          // 下载网络对象
    QFile m_file;                    // 文件
    QString m_fileName;              // 文件名
    bool m_downloading;
    qreal m_progress;       // 下载进度
    qint64 m_bytesReceived; // 已下载
    qint64 m_lastBytes;     // 上一秒下载量
    qint64 m_speed;         // 下载速度
    QTimer m_speedTimer;
};
