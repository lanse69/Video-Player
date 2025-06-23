#pragma once
#include <QString>
#include "font.h"
#include "danmumanager.h"

class Danmu
{
    friend class DanmuManager;

public:
    Danmu(qint64 sendTime, QString content);

private:
    qint64 m_sendTime;
    QString m_content;
    bool isAllocate;
};
