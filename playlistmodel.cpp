#include "playlistmodel.h"
#include <QDebug>
#include <QFileInfo>
#include <QFile>
#include <QRandomGenerator>
#include <QStandardPaths>
#include <QDir>

PlaylistModel::PlaylistModel(QObject *parent) : QAbstractListModel(parent), m_currentIndex{-1}
{
    avformat_network_init();
}

int PlaylistModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0; //列表为平面结构
    return m_mediaList.size();
}

QVariant PlaylistModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_mediaList.size())
        return QVariant(); //确保index合法

    const MediaInfo &info = m_mediaList.at(index.row());

    switch (role) {
    case UrlRole:
        return info.url;
    case TitleRole:
        return info.title;
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> PlaylistModel::roleNames() const
{
    QHash<int, QByteArray> roles; //用Qbytearray存储数据，比Qstring更轻量
    roles[UrlRole] = "url";
    roles[TitleRole] = "title";
    return roles;
}

void PlaylistModel::addMedia(const QUrl &url)
{
    if (url.isEmpty())
        return;
    MediaInfo cur;
    cur.url = url; //设置url

    QString title = getTitleByFF(url); //设置title
    cur.title = title == "" ? url.path().section('/', -1) : title;
    beginInsertRows(QModelIndex(), m_mediaList.size(),
                    m_mediaList.size()); //通知视图数据插入开始了
    m_mediaList.append(cur);
    endInsertRows(); //通知视图数据插入结束了
}

void PlaylistModel::addMedias(
    const QList<QUrl> &urls)
{
    if (urls.isEmpty()) return;

    for (auto &url : urls) {
        if (indexByUrl(url) == -1) { //如果url在列表里不存在
            addMedia(url);
            setCurrentIndex(m_mediaList.size() - 1);
        } else {
            setCurrentIndex(indexByUrl(url));
        }
    }
    emit rowCountChanged();
}

void PlaylistModel::removeMedia(int index)
{
    if (index < 0 || index >= m_mediaList.size()) return;

    beginRemoveRows(QModelIndex(), index, index); //通知视图数据删除开始了
    m_mediaList.removeAt(index);
    emit rowCountChanged();

    if (m_mediaList.isEmpty()) {
        setCurrentIndex(-1);
    } else if (index <= m_currentIndex) {
        setCurrentIndex(qMax(0, m_currentIndex - 1));
    }
}

void PlaylistModel::clear()
{
    beginResetModel(); //通知视图数据开始清除
    m_mediaList.clear();
    endResetModel(); //通知视图数据结束清除
    emit rowCountChanged();
    setCurrentIndex(-1);
}

QUrl PlaylistModel::getUrl(int index) const
{
    if (index >= 0 && index < m_mediaList.size()) {
        return m_mediaList.at(index).url;
    }
    return QUrl();
}

void PlaylistModel::move(int preIndex, int newIndex, int num)
{
    if (preIndex < 0 || newIndex < 0 || preIndex + num > m_mediaList.size()
        || newIndex > m_mediaList.size() || preIndex == newIndex) { //边界检查
        return;
    }

    beginMoveRows(QModelIndex(),
                  preIndex,
                  preIndex + num - 1,
                  QModelIndex(),
                  newIndex > preIndex ? newIndex + 1 : newIndex);  //通知视图要开始移动元素了
    QList<MediaInfo> movingItems = m_mediaList.mid(preIndex, num); // 创建临时列表保存要移动的元素

    m_mediaList.remove(preIndex, num); //将已存入的元素删除
    // 插入元素到新位置
    for (int i = 0; i < num; i++) {
        m_mediaList.insert(newIndex, movingItems[i]);
    }
    endMoveRows(); //通知视图元素移动结束了

    //根据preIndex和newIndex修改m_current
    if (preIndex <= m_currentIndex && m_currentIndex < preIndex + num) { //当m_currentIndex是移动项时
        m_currentIndex = newIndex + (m_currentIndex - preIndex);
    } else if (m_currentIndex >= preIndex + num
               && m_currentIndex <= newIndex) { //在移动项后并在移动目标前面
        m_currentIndex -= num;
    } else if (m_currentIndex >= newIndex
               && m_currentIndex < preIndex) { //在移动项前并在移动目标后面
        m_currentIndex += num;
    }
}

QList<QUrl> PlaylistModel::search(
    QString text)
{
    QList<QUrl> ans;
    for (int i = 0; i < m_mediaList.size(); i++) {
        if (isMatch(m_mediaList[i].title, text)) {
            ans.append(m_mediaList[i].url);
        }
    }
    return ans;
}

void PlaylistModel::histroy()
{
    QFile file(generateFilePath());
    QList<QUrl> readFile;
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&file);
        while (!in.atEnd()) {
            QString line = in.readLine().trimmed();
            QUrl url(line);

            // 检查 URL 类型
            if (url.isLocalFile()) {
                // 本地文件：检查文件是否存在
                if (QFile::exists(url.toLocalFile())) { readFile.append(url); }
            } else {
                // 网络 URL：直接添加
                readFile.append(url);
            }
        }
        file.close();
    }
    if (!readFile.empty()) addMedias(readFile);
}

void PlaylistModel::setHistroy(QUrl url)
{
    //读入数据
    QFile file(generateFilePath());
    QList<QUrl> readFile;
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&file);
        while (!in.atEnd()) {
            QString line = in.readLine();
            readFile.append(line);
        }
        file.close();
    } else {
        qDebug() << "setHistroy read failed";
    }
    //移除已存在的相同的url
    if (readFile.contains(url)) {
        readFile.removeOne(url);
    }
    readFile.prepend(url);

    //清除超出范围的数据
    while (readFile.length() > 5) {
        readFile.removeLast();
    }
    //写入文件
    if (file.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate)) {
        QTextStream out(&file);
        for (auto &i : readFile) {
            out << i.toString() << '\n';
        }
        file.close();
    } else {
        qDebug() << "setHistory write failed";
    }

    clear();             //清空列表
    addMedias(readFile); //重新读取列表
}

int PlaylistModel::indexByUrl(
    QUrl url)
{
    for (int i = 0; i < m_mediaList.size(); i++) {
        if (m_mediaList[i].url == url) {
            return i;
        }
    }
    qDebug() << "indexByUrl failed";
    return -1;
}

bool PlaylistModel::isMatch(
    QString title, QString text)
{
    int m = title.size(), n = text.size();
    QVector<int> match(n, 0);
    int j = 0;
    for (int i = 1; i < n; i++) {
        if (text[j] == text[i]) {
            match[i] = j + 1;
            j++;
        } else {
            while (j > 0 && text[j] != text[i]) {
                j = match[j - 1];
            }
            if (text[j] == text[i]) {
                j++;
            }
            match[i] = j;
        }
    }
    j = 0;
    for (int i = 0; i < m; i++) {
        if (text[j] == title[i]) {
            j++;
            if (j == n) {
                return true;
            }
        } else {
            if (j != 0)
                j = match[j - 1];
        }
    }
    return false;
}

QString PlaylistModel::generateFilePath() const
{
    // 生成历史记录文件路径
    QString dirPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    if (dirPath.isEmpty()) { dirPath = QDir::currentPath(); }
    dirPath = QDir::cleanPath(dirPath);
    if (!dirPath.endsWith(QDir::separator())) { dirPath += QDir::separator(); }
    dirPath += "Video-Player_History";
    QDir dir(dirPath);
    if (!dir.exists()) { dir.mkpath("."); }
    QString filePath = dir.filePath("history.txt");
    return filePath;
}

int PlaylistModel::currentIndex() const
{
    return m_currentIndex;
}

void PlaylistModel::setCurrentIndex(int index)
{
    int preIndex = m_currentIndex;
    if (index < -1 || index >= m_mediaList.size()) {
        qDebug() << "currentIndex change failed\n";
        return;
    }
    m_currentIndex = index;

    //如果属性的值没有变化则不发送变化信号
    if (m_currentIndex != preIndex)
        emit currentIndexChanged(m_currentIndex);
}

QString PlaylistModel::getTitleByFF(QUrl url) const
{
    if (url.isLocalFile()) {
        QString localPath = url.toLocalFile(); // 获取本地文件路径
        if (localPath.isEmpty()) return "";

        QByteArray utf8 = localPath.toUtf8();
        const char *fileName = utf8.constData();
        AVFormatContext *fmt_ctx = NULL;
        QString ans{};

        // 打开媒体文件
        if (avformat_open_input(&fmt_ctx, fileName, NULL, NULL) < 0) {
            av_log(NULL, AV_LOG_ERROR, "avformat_open_input failed\n");
            return ans;
        }

        // 获取流信息
        if (avformat_find_stream_info(fmt_ctx, NULL) < 0) {
            av_log(NULL, AV_LOG_ERROR, "avformat_find_stream_info failed\n");
            avformat_close_input(&fmt_ctx);
            return ans;
        }

        // 获取标题元数据
        AVDictionaryEntry *tag = av_dict_get(fmt_ctx->metadata, "title", NULL, 0);
        if (tag && tag->value) {
            ans = QString::fromUtf8(tag->value); // 正确处理UTF-8编码
        } else {
            // 使用文件名作为标题
            QFileInfo fileInfo(localPath);
            ans = fileInfo.fileName();
        }

        avformat_close_input(&fmt_ctx);
        return ans;
    } else {
        // 网络URL - 使用URL的文件名部分
        QString path = url.path();
        int lastSlash = path.lastIndexOf('/');
        if (lastSlash != -1) { return path.mid(lastSlash + 1); }
        return url.toString();
    }
}

int PlaylistModel::getRandomIndex(int min, int max) const
{
    if (max < 2) return 0;
    int newIndex;
    do {
        newIndex = QRandomGenerator::global()->bounded(min, max);
    } while (newIndex == m_currentIndex);

    return newIndex;
}
