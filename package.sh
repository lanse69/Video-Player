#!/bin/bash
set -e

# 确保在项目根目录
cd "$(dirname "$0")"

# 创建打包目录结构
rm -rf build AppDir 2>/dev/null
mkdir -p build AppDir/usr/bin AppDir/usr/lib AppDir/usr/share

# 安装依赖
sudo pacman -S --needed qt6-base qt6-multimedia qt6-declarative ffmpeg qt6-tools qt6-shadertools \
    gstreamer gst-libav gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly \
    qt6-multimedia-gstreamer wget fuse appimagetool --noconfirm || true

if ! command -v appimagetool &> /dev/null; then
    wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
    chmod +x appimagetool-x86_64.AppImage
    sudo mv appimagetool-x86_64.AppImage /usr/local/bin/appimagetool
fi

# 编译项目
mkdir -p build
cd build
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr ..
make -j$(nproc)
make install
make install DESTDIR=../AppDir
cd ..

# 修改启动脚本路径
sed -i 's|/usr/bin/appVideo-Player|appVideo-Player|' AppDir/usr/bin/video-player.sh

# 创建启动脚本
cat > AppDir/AppRun << 'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "${0}")")"
export PATH="${HERE}/usr/bin:${PATH}"
export QT_QPA_PLATFORMTHEME=xdgdesktopportal
export LD_LIBRARY_PATH="${HERE}/usr/lib:${LD_LIBRARY_PATH}"
export QT_PLUGIN_PATH="${HERE}/usr/lib/qt6/plugins"
export QML2_IMPORT_PATH="${HERE}/usr/lib/qt6/qml"
# 强制使用XCB平台插件
export QT_QPA_PLATFORM=xcb
# 启动播放器
exec video-player.sh "$@"
EOF
chmod +x AppDir/AppRun

# 创建桌面文件
cat > AppDir/video-player.desktop << 'EOF'
[Desktop Entry]
Name=Video Player
Exec=AppRun
Icon=video-player
Type=Application
Categories=AudioVideo;Player;
Comment=基于C++与Qt QML混合编程的视频播放器
TryExec=AppRun
EOF

# 复制图标到根目录
cp icons/video-player.svg AppDir/video-player.svg

# 复制桌面文件到标准位置
mkdir -p AppDir/usr/share/applications
cp assets/video-player.desktop AppDir/usr/share/applications/

# 复制图标
mkdir -p AppDir/usr/share/icons/hicolor/scalable/apps
cp icons/video-player.svg AppDir/usr/share/icons/hicolor/scalable/apps/

# 提取依赖库
copy_deps() {
    local binary="$1"
    ldd "$binary" | grep "=> /" | awk '{print $3}' | sort | uniq | while read -r lib; do
        if [[ -f "$lib" ]]; then
            cp --parents "$lib" AppDir/
        fi
    done
}

# 复制主程序依赖
copy_deps "AppDir/usr/bin/appVideo-Player"

# 复制Qt平台插件
QT_PLUGINS_DIR="/usr/lib/qt6/plugins"
mkdir -p AppDir/usr/plugins
cp -r $QT_PLUGINS_DIR/* AppDir/usr/plugins/

# 复制平台插件依赖
find $QT_PLUGINS_DIR -type f | while read -r plugin; do
    copy_deps "$plugin"
done

# 复制Qt6核心依赖
QT_DIR="/usr/lib/qt6"
mkdir -p AppDir/usr/lib/qt6
cp -r "$QT_DIR/qml" AppDir/usr/lib/qt6/

# 复制FFmpeg库
find /usr/lib -name 'libav*.so*' -exec cp -v --parents {} AppDir/ \;
find /usr/lib -name 'libsw*.so*' -exec cp -v --parents {} AppDir/ \;

# 创建AppImage
appimagetool AppDir

# 清理临时文件
rm -rf build AppDir
echo "打包完成: Video-Player-x86_64.AppImage"
