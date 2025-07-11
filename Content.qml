import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import VideoPlayer
import Qt.labs.folderlistmodel
import "DanmuRender.js" as DanmuRender

Item {
    id:content
    property MediaEngine mediaEngine
    property PlaylistModel playlistModel
    property PlaylistModel histroyListModel
    property CaptureManager captureManager
    property Actions actions
    property alias dialogs: _dialogs
    property alias player: _player
    property alias controlBar: _controlBar
    property alias danmuManager: _danmuManager
    property alias danmuTimer: _danmuTimer
    property alias danmuGenerater: _danmuGenerater
    property alias downloadManager: _downloadManager
    property alias folderListModel: folderListModel

    // 双击全屏
    TapHandler {
        exclusiveSignals: TapHandler.DoubleTap | TapHandler.SingleTap
        onDoubleTapped: {
            if (window.visibility === ApplicationWindow.FullScreen) {
                window.showNormal()
                menuBar.visible = true  // 退出全屏时显示菜单栏
            } else {
                window.showFullScreen()
                menuBar.visible = false // 进入全屏时隐藏菜单栏
            }
        }

        onSingleTapped: { // 单击暂停播放或开始播放
            mediaEngine.playing ? mediaEngine.pause() : mediaEngine.play()
        }
    }

    // 滑动切换视频
    DragHandler {
        id: slideHandler
        target: null
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchScreen

        onActiveChanged: {
            var startY = 0
            var endY = 0
            var isSlide = false
            if (!active) {
                var distance = centroid.position.y - centroid.pressPosition.y
                if (Math.abs(distance) > 20) { // 滑动距离大于20像素才算滑动
                    if (distance < 0) { // 向上滑动，下一个视频
                        if (playlistModel.rowCount > 0) {
                            var nextIndex = playlistModel.currentIndex + 1
                            if (nextIndex >= playlistModel.rowCount) nextIndex = 0
                            playlistModel.currentIndex = nextIndex
                        }
                    } else { // 向下滑动，上一个视频
                        if (playlistModel.rowCount > 0) {
                            var preIndex = playlistModel.currentIndex - 1
                            if (preIndex < 0) preIndex = playlistModel.rowCount - 1
                            playlistModel.currentIndex = preIndex
                        }
                    }
                }
            }
        }
    }

    focus: true
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Left) {  // 左方向键，快退5秒
            mediaEngine.setPosition(mediaEngine.position - 5000);
            event.accepted = true;
        } else if (event.key === Qt.Key_Right) { // 右方向键，快进5秒
            mediaEngine.setPosition(mediaEngine.position + 5000);
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) { // 上方向键，音量加5
            mediaEngine.setVolume(mediaEngine.volume + 0.05);
            event.accepted = true;
        } else if (event.key === Qt.Key_Down) { // 下方向键，音量减5
            mediaEngine.setVolume(mediaEngine.volume - 0.05);
            event.accepted = true;
        }
    }

    Dialogs {
        id: _dialogs
        captureManager: content.captureManager
        playlistModel: content.playlistModel
        danmuManager: content.danmuManager
        downloadManager: content.downloadManager
    }

    // 视频播放区域
    Player {
        id: _player
        anchors.fill: parent
        mediaEngine: content.mediaEngine
        captureManager: content.captureManager

        // 鼠标区域控制控制栏和列表显示
        HoverHandler {
            id:mouseHover
            // acceptedDevices: PointerDevice.Mouse
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchScreen | PointerDevice.TouchPad
            target: parent

            onPointChanged: {
                const pos = Qt.point(point.scenePosition.x, point.scenePosition.y)
                if(captureManager.playerLayout !== CaptureManager.NotVideo){ // NotVideo布局中不允许展示列表
                    // 当鼠标靠近右侧时显示播放列表
                    if((pos.x > parent.width - 30) && (pos.y <= parent.height - 70)){
                        playlist.visible = !searchList.visible && searchBox.length === 0
                        searchBox.visible = true
                        searchList.visible = !playlist.visible && searchBox.length !== 0
                        playlistcurtain.visible = true
                    } else if((pos.x < parent.width * (2/3)) || (pos.y > parent.height - 70)){
                        playlist.visible = false
                        searchBox.visible = false
                        searchList.visible = false
                        playlistcurtain.visible = false
                    }
                }
                // 当鼠标靠近底部时显示控制栏
                if(pos.y > parent.height - 30){
                    controlBar.visible = true
                } else if(pos.y < parent.height - 70){
                    controlBar.visible = false
                }
            }
        }
    }

    //弹幕渲染,由弹幕管理器，弹幕计时器（定时读取弹幕），弹幕生成器,弹幕渲染器配合完成
    DanmuManager{
        id: _danmuManager
    }

    Timer{
        id:_danmuTimer
        running:mediaEngine.playing && !actions.danmuSwitch.checked && captureManager.playerLayout !== CaptureManager.NotVideo
        repeat: true
        interval: 1000
        onTriggered: {
            if(DanmuRender.count > 0){
                DanmuRender.danmusRender(danmuManager.danmus(parent.width, DanmuRender.count, mediaEngine.position))
            }
        }
    }

    Repeater{
        id:_danmuGenerater
        property var previousState: undefined
        visible: mediaEngine.playing
        anchors.fill: parent
        model:100
        delegate: Danmu{}
    }

    Connections {
        target: captureManager

        function onPlayerLayoutChanged() {
            if (captureManager.playerLayout === CaptureManager.NotVideo) {
                // 保存当前弹幕开关状态
                _danmuGenerater.previousState = actions.danmuSwitch.checked
                // 强制关闭弹幕
                actions.danmuSwitch.checked = true
            } else if (_danmuGenerater.previousState !== undefined) {
                // 恢复之前的弹幕开关状态
                actions.danmuSwitch.checked = _danmuGenerater.previousState
                _danmuGenerater.previousState = undefined
            }
        }
    }

    //播放列表的搜索框
    TextArea{
        id:searchBox
        anchors.top: parent.top
        width: playlist.width
        anchors.right: parent.right
        visible: false
        height: 30
        placeholderText: "请输入搜索内容(限10字)"
        placeholderTextColor: "green"
        color: "green"
        focus: true

        Keys.onPressed: function (event){
            //确保输入合法
            if(!/[a-zA-Z0-9]/.test(event.text) && event.key !== Qt.Key_Delete&&event.key !== Qt.Key_Backspace){
                event.accepted=true
            }
            //确保输入内容的大小
            if(length >= 10 && event.key !== Qt.Key_Delete&&event.key !== Qt.Key_Backspace){
                event.accepted = true
            }
        }

        onTextChanged: {
            //根据搜索框的状态改变列表视图
            if(length === 0 && searchlistModel.currentIndex !== -1){
                playlist.visible = true
                content.playlistModel.currentIndex = content.playlistModel.indexByUrl(searchlistModel.getUrl(searchlistModel.currentIndex))
                searchList.visible = false
            }else{
                playlist.visible = false
                searchList.visible = true
                searchlistModel.clear()
                searchlistModel.currentIndex = -1
                searchlistModel.addMedias(playlistModel.search(text))
            }
        }

    }

    // 播放列表（右侧）
    Playlist {
        id: playlist
        anchors {
            top: searchBox.bottom
            right: parent.right
            bottom: _controlBar.top
        }
        playlist: content.playlistModel
    }

    //搜索播放列表
    Playlist {
        id: searchList
        anchors {
            top: searchBox.bottom
            right: parent.right
            bottom: _controlBar.top
        }
        visible: false
        playlist: searchlistModel
        onVisibleChanged: {
            if(!visible){
                searchBox.clear()
            }
        }
    }

    //搜索播放列表的数据项
    PlaylistModel{
        id: searchlistModel
        onCurrentIndexChanged: {
            if (searchlistModel.currentIndex >= 0) {
                var mediaUrl = getUrl(currentIndex)
                if (mediaUrl) {
                    mediaEngine.setMedia(mediaUrl)
                    mediaEngine.play()
                    var title = searchlistModel.data(searchlistModel.index(searchlistModel.currentIndex, 0), PlaylistModel.TitleRole)
                    if (title) {
                        window.title = "Video Player - " + title
                    }
                    //初始化弹幕
                    danmuManager.initDanmus(title)
                    danmuManager.initTracks(content.height * (1/4))
                    DanmuRender.endDanmus()
                }
            }
        }
    }

    //播放列表的底层
    Rectangle{
        id:playlistcurtain
        width: parent.width * (1/3)
        height: playlist.height
        visible: false
        anchors.top: searchBox.bottom
        anchors.right: parent.right
        color: "black"
        opacity: 0.2
    }

    // 控制栏（底部）
    ControlBar {
        id: _controlBar
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        mediaEngine: content.mediaEngine
        playlistModel: content.playlistModel
        captureManager: content.captureManager
    }

    //读入文件
    Connections {
        id:readFiles
        property var openUrl
        target: dialogs.fileOpen

        function onAccepted() {
            let folderUrl=(dialogs.fileOpen.selectedFiles)[0]   //获取选择的路径的文件夹的路径
            openUrl=folderUrl
            folderListModel.folder=folderUrl.toString().replace(/\/[^\/]*$/,"/")
        }
    }

    FolderListModel{
        id:folderListModel
        showFiles: true
        showDirs: false
        nameFilters: ["*.mp4","*.avi","*.mkv","*.mov","*.wmv","*.ogg","*.mp3","*.wav","*.flac","*.ogg","*.wav"]
        onFolderChanged: {
            if (folder.toString() !== "") {
                //初始化当前文件夹的所有文件的url
                let files=[]
                for(let i=0; i < folderListModel.count; i++){
                    files.push(folderListModel.get(i,"fileUrl"))
                }

                //添加文件和设置历史记录
                playlistModel.addMedias(files)
                playlistModel.currentIndex=playlistModel.indexByUrl(readFiles.openUrl)
            }
        }
    }

    DownloadManager {
        id: _downloadManager

        onProgressChanged: {
            dialogs.downloadDialog.progress = progress * 100;
        }

        onSpeedChanged: {
            var speedKB = speed / 1024;
            var speedText;
            if (speedKB > 1024) {
                speedText = (speedKB / 1024).toFixed(1) + " MB/s";
            } else {
                speedText = speedKB.toFixed(1) + " KB/s";
            }
            dialogs.downloadDialog.speed = "Speed: " + speedText;
        }

        onDownloadingChanged: {
            if (downloading) {
                dialogs.downloadDialog.progress = 0;
                dialogs.downloadDialog.speed = "Speed: 0 KB/s";
                dialogs.downloadDialog.open();
            } else {
                dialogs.downloadDialog.close();
            }
        }

        onDownloadFinished: function (filePath) {
            // 显示下载完成消息
            content.dialogs.successDialog.text = "Download finished:\n" + filePath;
            content.dialogs.successDialog.open();
        }

        onErrorOccurred: function (error) {
            content.dialogs.errorDialog.text = "Download error: \n" + error;
            content.dialogs.errorDialog.open();
        }

        function nowDownload () {
            // 获取当前播放项在播放列表中的标题
            var currentIndex = playlistModel.currentIndex;
            var title = playlistModel.data(playlistModel.index(currentIndex, 0), PlaylistModel.TitleRole);
            // 提取文件名
            var baseName = title;
            // 如果标题为空，则使用URL的文件名部分
            if (baseName === "") {
                var urlString = mediaEngine.currentMedia.toString();
                var lastSlash = urlString.lastIndexOf('/');
                if (lastSlash !== -1) {
                    baseName = urlString.substring(lastSlash + 1);
                    // 去掉可能存在的查询参数
                    var questionMark = baseName.indexOf('?');
                    if (questionMark !== -1) {
                        baseName = baseName.substring(0, questionMark);
                    }
                } else {
                    baseName = "video";
                }
            }
            // 移除非法字符
            baseName = baseName.replace(/[\\/:*?"<>|]/g, '_');
            // 检查是否已有扩展名
            var hasExtension = false;
            // 常见视频扩展名列表
            var videoExtensions = [".mp4", ".avi", ".mkv", ".mov", ".wmv", ".flv", ".webm", ".mp3", ".wav", ".ogg"];

            for (var i = 0; i < videoExtensions.length; i++) {
                if (baseName.toLowerCase().endsWith(videoExtensions[i])) {
                    hasExtension = true;
                    break;
                }
            }

            // 如果没有扩展名，则添加.mp4扩展名
            var fileName = baseName;
            if (!hasExtension) {
                fileName += ".mp4";
            }

            if (content.downloadManager.downloading) {
                content.dialogs.errorDialog.text = "Another download is already in progress";
                content.dialogs.errorDialog.open();
                return;
            }

            // 触发下载操作
            content.downloadManager.download(mediaEngine.currentMedia, fileName);
        }
    }
}
