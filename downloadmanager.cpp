#include "downloadmanager.h"

#include <QStandardPaths>

DownloadManager::DownloadManager(QObject *parent)
    : QObject(parent)
    , m_reply{nullptr}
    , m_downloading{false}
    , m_progress{0.0}
    , m_bytesReceived{0}
    , m_lastBytes{0}
    , m_speed{0}
    , m_speedTimer(this)
{
    connect(&m_speedTimer, &QTimer::timeout, this, &DownloadManager::updateSpeed);
    m_speedTimer.setInterval(1000); // 计时器初始化计时1秒
}

bool DownloadManager::downloading() const
{
    return m_downloading;
}

qreal DownloadManager::progress() const
{
    return m_progress;
}

qint64 DownloadManager::speed() const
{
    return m_speed;
}

void DownloadManager::download(const QUrl &url, const QString &fileName)
{
    if (m_downloading) { cancelDownload(); }

    m_fileName = fileName;
    if (m_fileName.isEmpty()) {
        m_fileName = "video_" + QDateTime::currentDateTime().toString("yyyyMMdd_HHmmss") + ".mp4";
    }

    QString filePath = generateFilePath().filePath(m_fileName);
    m_file.setFileName(filePath);

    if (!m_file.open(QIODevice::WriteOnly)) {
        emit errorOccurred(tr("Cannot open file for writing: %1").arg(filePath));
        return;
    }

    // 开始下载
    QNetworkRequest request(url);
    m_reply = m_manager.get(request);

    connect(m_reply, &QNetworkReply::downloadProgress, this, &DownloadManager::onDownloadProgress);
    connect(m_reply, &QNetworkReply::finished, this, &DownloadManager::onFinished);
    connect(m_reply, &QNetworkReply::readyRead, this, [this]() {
        if (m_reply && m_file.isOpen()) { m_file.write(m_reply->readAll()); }
    });

    m_downloading = true;
    m_progress = 0;
    m_lastBytes = 0;
    m_speed = 0;
    m_speedTimer.start();
    emit downloadingChanged();
    emit progressChanged();
    emit speedChanged();
}

void DownloadManager::cancelDownload()
{
    if (m_reply) {
        // 先断开所有信号连接，避免在删除过程中触发槽函数
        disconnect(m_reply, nullptr, this, nullptr);

        // 中止请求并删除对象
        m_reply->abort();
        m_reply->deleteLater();
        m_reply = nullptr;
    }

    if (m_file.isOpen()) {
        m_file.close();
        // 只有在文件不是空文件时才删除
        if (m_file.size() > 0) { m_file.remove(); }
    }

    m_downloading = false;
    m_progress = 0;
    m_bytesReceived = 0;
    m_lastBytes = 0;
    m_speed = 0;
    m_speedTimer.stop();
    emit downloadingChanged();
    emit progressChanged();
    emit speedChanged();
}

QDir DownloadManager::generateFilePath() const
{
    // 创建下载目录
    QString downloadDir = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
    if (downloadDir.isEmpty()) { downloadDir = QDir::currentPath(); }

    downloadDir += "/Video-Player_Downloads";
    QDir dir(downloadDir);
    if (!dir.exists()) { dir.mkpath("."); }
    return dir;
}

QString DownloadManager::downloadDirPath() const
{
    return generateFilePath().absolutePath();
}

void DownloadManager::onDownloadProgress(qint64 bytesReceived, qint64 bytesTotal)
{
    if (!m_reply || !m_downloading) return;
    // 更新已下载字节数
    m_bytesReceived = bytesReceived;

    if (bytesTotal > 0) {
        m_progress = static_cast<qreal>(bytesReceived) / bytesTotal;
        emit progressChanged();
    }
}

void DownloadManager::onFinished()
{
    if (!m_reply) return;
    m_speedTimer.stop();

    if (m_reply->error() != QNetworkReply::NoError) {
        if (m_reply->error() != QNetworkReply::OperationCanceledError) {
            // 只有非取消错误才报告
            m_file.close();
            if (m_file.exists()) { m_file.remove(); }
            emit errorOccurred(m_reply->errorString());
        }
    } else {
        // 确保写入所有数据
        if (m_reply->bytesAvailable() > 0 && m_file.isOpen()) { m_file.write(m_reply->readAll()); }
        if (m_file.isOpen()) { m_file.close(); }
        emit downloadFinished(m_file.fileName());
    }

    QNetworkReply *reply = m_reply;
    m_reply = nullptr;
    reply->deleteLater();

    m_downloading = false;
    m_progress = 0;
    m_bytesReceived = 0;
    m_lastBytes = 0;
    m_speed = 0;
    emit downloadingChanged();
    emit progressChanged();
    emit speedChanged();
}

void DownloadManager::updateSpeed()
{
    if (!m_reply || !m_downloading) return;
    m_speed = m_bytesReceived - m_lastBytes;
    m_lastBytes = m_bytesReceived;
    emit speedChanged();
}
