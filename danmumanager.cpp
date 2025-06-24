#include "danmumanager.h"

#include <QFile>
#include <QFont>
#include <QFontMetrics>
#include <algorithm>
#include <QStandardPaths>

DanmuManager::DanmuManager(QObject *parent) : QObject{parent}, m_speed{0.1}
{
    _font = new Font{};
}

void DanmuManager::initDanmus(
    QString title)
{
    //清空弹幕列表和改变title
    m_danmus.clear();
    m_title = title;

    QString filePath = generateFilePath().filePath(m_title + "danmu.txt");

    //从文件读入弹幕
    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) { return; }
    QTextStream in(&file);
    while (!in.atEnd()) {
        qint64 startTime = 0;
        QString content;
        QString line = in.readLine();

        qDebug() << line;
        //读入每行的开始时间和内容
        bool ok;
        startTime = line.section(" ", 0, 0).toLongLong(&ok);
        if (!ok) { continue; }
        content = line.section(" ", 1, 1);
        m_danmus.append(Danmu{startTime, content});
    }
    file.close();
}

void DanmuManager::initTracks(
    int high)
{
    m_danmuTracks.clear();
    //获取qml中显示的text的高度
    QFont font{_font->m_font, _font->m_size};
    QFontMetrics fontMetrics(font);
    int height = fontMetrics.height();

    //初始化轨道
    int n = high / height;
    for (int i = 0; i < n; i++) {
        m_danmuTracks.append(DanmuTrack{height * i});
    }
}

void DanmuManager::addDanmu(
    qint64 startTime, QString content)
{
    Danmu danmu{startTime, content};

    //寻找插入的位置
    auto it = std::lower_bound(m_danmus.begin(), m_danmus.end(), startTime, [](Danmu &a, qint64 b) {
        return a.m_sendTime < b;
    });
    //插入
    m_danmus.insert(it, danmu);

    //保存弹幕
    saveDanmu();
}

void DanmuManager::saveDanmu()
{
    QString filePath = generateFilePath().filePath(m_title + "danmu.txt");

    QFile file(filePath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate)) {
        qDebug() << m_title + "danmu save failed";
    }
    QTextStream out(&file);
    for (Danmu &i : m_danmus) {
        out << QString::number(i.m_sendTime) << " " << i.m_content << "\n";
    }
    file.close();
}

QList<QList<QVariant>> DanmuManager::danmus(
    int width, int num, qint64 currentTime)
{
    //初始化返回数组
    QList<QList<QVariant>> ans;

    //如果为空直接返回
    if (m_danmus.size() == 0)
        return ans;

    //初始化字体学（QFontMetrics）
    QFont font{_font->m_font, _font->m_size};
    QFontMetrics fontMetrics(font);

    //初始化备选列表
    QList<Danmu *> option;
    auto it = std::lower_bound(m_danmus.begin(), //用二分查找寻找第一个大于等于当前时间的弹幕
                               m_danmus.end(),
                               currentTime + 1000,
                               [](Danmu &a, qint64 b) { return a.m_sendTime < b; });
    int right = std::distance(m_danmus.begin(), it); //获取备选的右边界

    it = std::lower_bound(m_danmus.begin(),
                          m_danmus.end(),
                          currentTime - width / m_speed,
                          [](Danmu &a, qint64 b) {
                              return a.m_sendTime
                                     < b; //currentTime-width/m_speed：屏幕出现的弹幕的最小开始时间
                          });
    int left = std::distance(m_danmus.begin(), it); //获取备选的左边界
    for (int i = left; i < right; i++) {
        option.append(&m_danmus[i]);
    }
    //分配弹幕
    for (Danmu *i : option) {
        if (i->m_isAllocate)
            continue;
        for (DanmuTrack &j : m_danmuTracks) { //从列表里获取可置入的轨道
            if (i->m_sendTime > j.m_lastTime) {
                int fontWidth = fontMetrics.horizontalAdvance(i->m_content);
                int x = width - (currentTime - i->m_sendTime) * m_speed;
                j.m_lastTime = i->m_sendTime + fontWidth / m_speed
                               + 100; //更新轨道最后弹幕的结束时间,加100,增加弹幕之间的间隔
                ans.append(QList<QVariant>{
                    QVariant{x},                        //弹幕的起始x坐标
                    QVariant{j.m_y},                    //弹幕的x坐标
                    QVariant{-fontWidth},               //结束位置
                    QVariant{i->m_content},             //内容
                    QVariant{(x + fontWidth) / m_speed} //持续时间
                });
                num--;
                i->m_isAllocate = true;
                if (num == 0)
                    return ans; //分配了足够的弹幕，直接返回
                break;
            }
        }
    }

    return ans;
}

QDir DanmuManager::generateFilePath() const
{
    // 生成弹幕文件路径
    QString dirPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    if (dirPath.isEmpty()) { dirPath = QDir::currentPath(); }
    dirPath = QDir::cleanPath(dirPath);
    if (!dirPath.endsWith(QDir::separator())) { dirPath += QDir::separator(); }
    dirPath += "Video-Player_Danmu";
    QDir dir(dirPath);
    if (!dir.exists()) { dir.mkpath("."); }
    return dir;
}

QString DanmuManager::danmuDirPath() const
{
    return generateFilePath().absolutePath();
}

int DanmuManager::speed()
{
    return m_speed;
}

void DanmuManager::setSpeed(
    int speed)
{
    m_speed = speed;
}

QString DanmuManager::fontName()
{
    return _font->m_font;
}

void DanmuManager::setFontName(
    QString name)
{
    _font->m_font = name;
}

int DanmuManager::fontSize()
{
    return _font->m_size;
}

void DanmuManager::setFontSize(
    int size)
{
    _font->m_size = size;
}
