#pragma once
#include <QString>
#include <QObject>

class Font : public QObject
{
    Q_OBJECT
    friend class DanmuManager;

public:
    Font();

private:
    QString m_font;
    int m_size;
};
