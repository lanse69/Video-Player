#pragma once

#include <QObject>
#include <QQmlEngine>
#include "danmu.h"
#include "danmutrack.h"
#include "font.h"

class Danmu; //前向申明Danmu类

class DanmuManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(
        int speed READ speed WRITE setSpeed NOTIFY speedChanged)
    Q_PROPERTY(
        QString fontName READ fontName WRITE setFontName NOTIFY fontNameChanged FINAL)
    Q_PROPERTY(
        int fontSize READ fontSize WRITE setFontSize NOTIFY fontSizeChanged FINAL)
public:
    explicit DanmuManager(QObject *parent = nullptr);

    Q_INVOKABLE void initDanmus(QString title);                   //从文件读入弹幕初始化弹幕列表
    Q_INVOKABLE void initTracks(int high);                        //初始化轨道
    Q_INVOKABLE void addDanmu(qint64 startTime, QString content); //添加弹幕
    Q_INVOKABLE void saveDanmu();                                 //写入文件，保存弹幕
    Q_INVOKABLE QList<QList<QVariant>> danmus(
        int width, int num, qint64 currentTime); //根据提供的屏幕宽度和需要弹幕数量提供弹幕

    //暴露属性的getter和setter
    int speed();
    void setSpeed(int speed);
    QString fontName();
    void setFontName(QString name);
    int fontSize();
    void setFontSize(int size);

private:
    float m_speed;
    QString m_title;
    QList<Danmu> m_danmus;
    QList<DanmuTrack> m_danmuTracks;
    Font *_font;
signals:
    void speedChanged();
    void fontNameChanged();
    void fontSizeChanged();
};
