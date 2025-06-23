#pragma once
#include <QString>

class DanmuTrack
{
    friend class DanmuManager;

public:
    DanmuTrack(int y);

private:
    int m_y;
    qint64 m_lastTime;
};
