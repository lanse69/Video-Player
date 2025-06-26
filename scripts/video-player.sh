#!/bin/sh
export QT_QPA_PLATFORMTHEME=xdgdesktopportal

# 如果使用自定义 Qt 安装，添加以下路径（根据实际路径修改）
export LD_LIBRARY_PATH="/opt/Qt/6.9.1/gcc_64/lib:$LD_LIBRARY_PATH"

exec /usr/bin/appVideo-Player "$@"
