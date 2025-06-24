#pragma once

#include <QAbstractListModel>
#include <QList>
#include <QUrl>
#include <qqmlintegration.h>

extern "C" {
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>
}

struct MediaInfo
{
    QUrl url;
    QString title;
};

class PlaylistModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(int currentIndex READ currentIndex WRITE setCurrentIndex NOTIFY currentIndexChanged)
    Q_PROPERTY(int rowCount READ rowCount NOTIFY rowCountChanged)

public:
    enum Roles { UrlRole = Qt::UserRole + 1, TitleRole }; //设置UrlRole枚举和TitleRole枚举
    Q_ENUM(Roles)

    explicit PlaylistModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override; //告知视图 数据项的数目
    QVariant data(const QModelIndex &index,
                  int role = Qt::DisplayRole) const override; //按照指定角色返回数据
    QHash<int, QByteArray> roleNames() const override;        //获取各个角色名

    Q_INVOKABLE void addMedia(const QUrl &url);          //添加单个数据项
    Q_INVOKABLE void addMedias(const QList<QUrl> &urls); //添加多个数据项
    Q_INVOKABLE void removeMedia(int index);             //根据索引移除数据项
    Q_INVOKABLE void clear();                            //清空数据项
    Q_INVOKABLE QUrl getUrl(int index) const;            //获取url
    Q_INVOKABLE void move(int preIndex, int newIndex,
                          int num);               //移动指定数量的元素到指定位置
    Q_INVOKABLE QList<QUrl> search(QString text); //按照给定的text筛选title并返回
    Q_INVOKABLE void histroy();                   //初始化历史列表(最多5项)
    Q_INVOKABLE void setHistroy(QUrl url);        //设置历史列表 (最多5项)
    Q_INVOKABLE int indexByUrl(QUrl url);         //通过url寻找对应的下标
    Q_INVOKABLE int getRandomIndex(int min, int max) const; // 生成随机下标

    //暴露属性的setter和getter
    int currentIndex() const;
    void setCurrentIndex(int index);

signals:
    //通知属性变化
    void currentIndexChanged(int index);
    void rowCountChanged();

private:
    bool isMatch(QString title, QString text); //返回title是否包含text字符串(KMP算法）

    QString getTitleByFF(QUrl url) const; //通过ffmpeg获取文件数据内的标题
    QList<MediaInfo> m_mediaList;
    int m_currentIndex;
};
