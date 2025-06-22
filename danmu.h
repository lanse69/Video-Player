#pragma once
#include <QString>
#include "font.h"

class Danmu
{
public:
    Danmu(qint64 sendTime, QString content);

private:
    qint64 m_sendTime;
    QString m_content;
};
