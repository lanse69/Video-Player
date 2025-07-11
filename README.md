# 视频播放器项目

基于 Qt QML/C++ 的视频播放器，支持本地和网络视频播放，提供弹幕、录屏等高级功能。

## 功能特性
- **基础功能**  
  播放控制、音量调节、进度条、播放列表、列表拖拽排序、倍速播放、切换视频、历史记录、全屏/小窗播放、定时暂停、连播/循环播放、画面尺寸调整、列表搜索、拖拽添加视频
- **高级功能**  
  截图、拍摄、录屏、弹幕系统、视频下载、手势识别、URL识别、字幕支持、视频缩略图、展示音乐封面
- **文件**  
  - 分工: Requirement.txt文件
  - 开发日志: log_report目录
  - 展示视频: 展示视频目录
  - 开发: 开发文档目录
  - assets: 链接文件
  - scripts: 运行脚本文件

## 部署要求
### 第三方依赖库
1. **Qt 6.9+** 框架组件：
   - Core
   - Quick
   - Multimedia
   - MultimediaWidgets
   - QuickDialogs2
   - QuickDialogs2QuickImpl
   
#### 安装Qt 6.9
- 如果系统仓库中的 Qt 版本低于 6.9，请从官网下载安装：
```bash
# 下载 Qt 在线安装器
wget https://download.qt.io/official_releases/online_installers/qt-unified-linux-x64-online.run
chmod +x qt-unified-linux-x64-online.run

# 运行安装器（选择安装 Qt 6.9.1）
./qt-unified-linux-x64-online.run
```
   
2. **FFmpeg 多媒体库**：
   - libavcodec
   - libavformat
   - libavutil
   - libswscale
   - libavfilter

### 系统环境要求
- **Linux 系统**（推荐 Manjaro/Arch）

支持X11桌面，wayland桌面屏幕捕获未支持
---

## 安装部署指南（Manjaro/Arch Linux）

### 步骤 1：安装依赖库
```bash
sudo pacman -S qt6-base qt6-multimedia qt6-declarative ffmpeg
sudo pacman -S qt6-tools qt6-shadertools
```

### 步骤 2：编译项目
```bash
git clone https://github.com/lanse69/Video-Player.git
cd video-player

mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr ..

# 如果提示版本过低，请自行参考前面下载Qt 6.9+的版本
# 如果使用自定义安装的 Qt 6.9.1 (根据实际路径修改)
# 运行命令后再次cmake
export PATH="/opt/Qt/6.9.1/gcc_64/bin:$PATH"
export LD_LIBRARY_PATH="/opt/Qt/6.9.1/gcc_64/lib:$LD_LIBRARY_PATH"
# ```

make -j$(nproc)
```

### 步骤 3：安装到系统

!!!请务必先前往项目根目录的scripts/video-player.sh文件中决定是否修改或者注释或者解除注释，再安装!!!

```bash
# 如果是使用自己安装的Qt, 请先看后面的Attention!!!
sudo make install
```

### 步骤 4：更新桌面数据库
```bash
sudo update-desktop-database
sudo gtk-update-icon-cache /usr/share/icons/hicolor
```
## Attention
wayland桌面无法截全屏，录制屏幕，录制摄像头画面

!!!关于：项目根目录的scripts/video-player.sh文件

如果需要使用自己安装的Qt,请修改第二条命令且取消注释

修改后进入build目录再次安装到系统!!!

NVIDIA 专有驱动与 FFmpeg 后端存在兼容性问题，遂可尝试使用GStreamer后端（可能会找不到一些库导致无法播放）, 所以更推荐切换到混显或者集显亦或者更换驱动
```bash
# GStreamer
sudo pacman -S gstreamer gst-libav gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly
sudo pacman -S qt6-multimedia-gstreamer
```
如果编译后运行进程直接崩溃，则根据前面安装GStreamer，在取消项目根目录的scripts/video-player.sh文件中第三条命名注释

修改后进入build目录再次安装到系统!!!
