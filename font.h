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
    QString m_font = "DejaVu Sans Mono";
    int m_size = 20;
};
