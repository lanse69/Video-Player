#pragma once
#include <QString>

class DanmuTrack
{
public:
    DanmuTrack(int y);

private:
    int m_y;
    qint64 m_lastTime = 0;
};
