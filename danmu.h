#pragma once
#include <QString>
#include "font.h"

class Danmu
{
public:
    Danmu(qint64 sendTime, QString content, Font *font);

private:
    Font *font;
};
