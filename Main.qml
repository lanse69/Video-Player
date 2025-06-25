import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import VideoPlayer
import QtQuick.Dialogs
import "DanmuRender.js" as DanmuRender

ApplicationWindow {
    id: window
    width: 800
    height: 600
    visible: !content.player.smallWindowMode // 当小窗口显示时，大窗口不显示
    title: "Video Player"
    color: "black"

    // 媒体引擎
    MediaEngine {
        id: mediaEngine
        onHasSubtitleChanged: {
            actions.subtitle.enabled = mediaEngine.hasSubtitle
            actions.subtitle.checked = mediaEngine.subtitleVisible
        }
        onPlayingChanged: {
            if (mediaEngine.playing && playlistModel.currentIndex >= 0) {
                var mediaUrl = playlistModel.getUrl(playlistModel.currentIndex)
                if (mediaUrl) {
                    histroyListModel.setHistroy(mediaUrl)
                }
            }
        }
    }

    // 播放列表
    PlaylistModel {
        id: playlistModel
        onCurrentIndexChanged: {
            if (playlistModel.currentIndex >= 0) {
                var mediaUrl = getUrl(currentIndex)
                if (mediaUrl) {
                    mediaEngine.setMedia(mediaUrl)
                    mediaEngine.play()
                    var title = playlistModel.data(playlistModel.index(playlistModel.currentIndex,0),PlaylistModel.TitleRole)
                    if (title) {
                        window.title = "Video Player - " + title
                    }
                    content.danmuManager.initDanmus(title)
                    content.danmuManager.initTracks(content.height*(1/4))
                    DanmuRender.endDanmus()
                }
            }
        }
    }

    //历史记录的数据项
    PlaylistModel {
        id: histroyListModel
        Component.onCompleted: {
            histroy()
        }
    }

    CaptureManager {
        id: captureManager
        onScreenshotCaptured: content.dialogs.previewDialog.open()
        onErrorOccurred: function(error) {
            content.dialogs.errorDialog.text = error;
            content.dialogs.errorDialog.open();
        }
        onRecordStateChanged: {
            actions.pauseRecord.enabled = (captureManager.recordState !== CaptureManager.Stopped)
            actions.stopRecord.enabled = (captureManager.recordState !== CaptureManager.Stopped)
            actions.pauseRecord.checked = (captureManager.recordState === CaptureManager.Paused)
        }
        onRecordingTimeChanged: {
            var sec = captureManager.recordingTime
            var min = Math.floor(sec / 60)
            sec = sec % 60
            content.controlBar.recordTimeText.text = min.toString().padStart(2, '0') + ":" + sec.toString().padStart(2, '0')
        }
        onRecordAudioChanged: actions.microphone.checked = captureManager.recordAudio
        onCameraStateChanged: {
            actions.pauseCamera.enabled = (captureManager.cameraState !== CaptureManager.CameraStopped)
            actions.stopCamera.enabled = (captureManager.cameraState !== CaptureManager.CameraStopped)
            actions.pauseCamera.checked = (captureManager.cameraState === CaptureManager.CameraPaused)
            if(captureManager.cameraState === CaptureManager.CameraStopped){
                captureManager.playerLayout = CaptureManager.LayoutNull
                content.player.cameraOutput.visible = false
            }
        }
        onCameraRecordingTimeChanged: {
            var sec = captureManager.cameraRecordingTime
            var min = Math.floor(sec / 60)
            sec = sec % 60
            content.controlBar.cameraTimeText.text = min.toString().padStart(2, '0') + ":" + sec.toString().padStart(2, '0')
        }
        onHasCameraChanged: {
            if (!captureManager.hasCamera) {
                content.dialogs.errorDialog.text = "No camera found";
                content.dialogs.errorDialog.open();
            }
        }
        onCameraSessionChanged: {
            // 当摄像头会话更新时，确保连接到视频输出
            if (content.player && content.player.cameraOutput) {
                captureManager.setVideoSink(content.player.cameraOutput.videoSink)
            }
        }
        onCameraAudioChanged: actions.cameraMicrophone.checked = captureManager.cameraAudio
        onCameraChanged: actions.recordingLayout.enabled = captureManager.setCamera()
    }

    menuBar: MenuBar {
        id: menu
        Menu {
            title: qsTr("File")
            MenuItem { action: actions.open }
            MenuItem { action: actions.openUrl }
            MenuSeparator {}
            MenuItem { action: actions.download }
            MenuSeparator {}
            MenuItem { action: actions.close }
            MenuSeparator {}
            Menu{
                title: qsTr("Recently Opened")
                Repeater{
                    model:histroyListModel
                    delegate:MenuItem{
                        action:Action {
                            id:_histroy
                            property string url:model.url
                            text: qsTr("")
                            onTriggered: {
                                let urls=[url]
                                playlistModel.addMedias(urls)
                            }
                        }
                        text: model.title
                    }
                }
            }
            MenuSeparator {}
            MenuItem { action: actions.exit }
        }
        Menu {
            title: qsTr("Play")
            MenuItem { action: actions.play}
            MenuItem { action: actions.pause }
            MenuItem { action: actions.stop }

            Menu {
                title: qsTr("Rate")
                MenuItem { action: actions.zeroPointFiveRate }
                MenuItem { action: actions.oneRate }
                MenuItem { action: actions.onePointFiveRate }
                MenuItem { action: actions.twoRate }
            }

            MenuItem { action: actions.mute}
            MenuItem {
                action: actions.subtitle
                enabled: mediaEngine && mediaEngine.hasSubtitle
            }
            MenuSeparator {}
            MenuItem { action: actions.previous }
            MenuItem { action: actions.next }
            MenuSeparator {}
            MenuItem { action: actions.loopPlayback }
            MenuItem { action: actions.sequentialPlayback }
            MenuItem { action: actions.randomPlayback }
            MenuSeparator {}
            MenuItem { action: actions.timedPause }
        }

        Menu {
            title: qsTr("View")
            MenuItem { action: actions.fullScreen }
            MenuItem { action: actions.exitFullScreen }
            MenuSeparator {}
            MenuItem { action: actions.smallWindowMode }
            MenuSeparator {}
            Menu {
                title: qsTr("Video Scale")
                MenuItem { action: actions.originalAspectRatio }
                MenuItem { action: actions.aspectRatio16_9 }
                MenuItem { action: actions.aspectRatio4_3 }
            }
        }

        Menu {
            title: qsTr("Capture")
            Menu {
                title: qsTr("Screenshot")
                MenuItem { action: actions.screenshotWindow }
                MenuItem { action: actions.screenshotFull }
            }
            Menu {
                title: qsTr("Recording")
                MenuItem { action: actions.record }
                MenuSeparator {}
                MenuItem { action: actions.pauseRecord }
                MenuItem { action: actions.stopRecord }
                MenuSeparator {}
                MenuItem { action: actions.microphone }
            }
            Menu {
                title: qsTr("Camera")
                MenuItem { action: actions.camera }
                MenuItem { action: actions.cameraDevice }
                MenuItem { action: actions.recordingLayout }
                MenuSeparator {}
                MenuItem { action: actions.pauseCamera }
                MenuItem { action: actions.stopCamera }
                MenuSeparator {}
                MenuItem { action: actions.cameraMicrophone }
            }
        }
        Menu{
            title:"Danmu"
            Menu{
                title:"字体大小"
                MenuItem{action: actions.bigDanmu}
                MenuItem{action: actions.smallDanmu}
            }
            MenuItem{action: actions.danmuSwitch}
        }

        Menu {
            title: qsTr("Help")
            MenuItem { action: actions.about}
            MenuSeparator {}
            MenuItem { action: actions.saveLocation }
            MenuItem { action: actions.attention }
        }
    }

    Actions {
        id: actions
        open.onTriggered: content.dialogs.fileOpen.open()
        openUrl.onTriggered: content.dialogs.urlInputDialog.open()
        download.enabled: mediaEngine && !mediaEngine.isLocal && mediaEngine.currentMedia.toString() !== ""
        download.onTriggered: content.downloadManager.nowDownload();
        close.onTriggered: closeVideo()
        exit.onTriggered: Qt.quit()
        play.onTriggered: mediaEngine.play()
        pause.onTriggered: mediaEngine.pause()
        stop.onTriggered: mediaEngine.stop()
        mute.onTriggered: {
            if (content.mediaEngine) {
                content.mediaEngine.setMuted(mute.checked)
            }
        }
        subtitle.enabled: mediaEngine && mediaEngine.hasSubtitle
        subtitle.onTriggered: {
            if (content.mediaEngine) {
                content.mediaEngine.setSubtitleVisible(subtitle.checked)
            }
        }
        previous.onTriggered: {
            if (playlistModel.rowCount > 0) {
                var newIndex = playlistModel.currentIndex - 1
                if (newIndex < 0) newIndex = playlistModel.rowCount - 1
                playlistModel.currentIndex = newIndex
            }
        }
        next.onTriggered: {
            if (playlistModel.rowCount > 0) {
                var newIndex = playlistModel.currentIndex + 1
                if (newIndex >= playlistModel.rowCount) newIndex = 0
                playlistModel.currentIndex = newIndex
            }
        }
        about.onTriggered: content.dialogs.about.open()
        zeroPointFiveRate.onTriggered: mediaEngine.setPlaybackRate(0.5)
        oneRate.onTriggered: mediaEngine.setPlaybackRate(1)
        onePointFiveRate.onTriggered: mediaEngine.setPlaybackRate(1.5)
        twoRate.onTriggered: mediaEngine.setPlaybackRate(2)
        screenshotWindow.onTriggered: {
            mediaEngine.pause()
            window.takeScreenshot(CaptureManager.WindowCapture)
        }
        screenshotFull.onTriggered: {
            mediaEngine.pause()
            window.takeScreenshot(CaptureManager.FullScreenCapture)
        }
        record.onTriggered: captureManager.startRecording()
        pauseRecord.onTriggered: {
            if (pauseRecord.checked) {
                captureManager.pauseRecording()
            } else {
                captureManager.resumeRecording()
            }
        }
        stopRecord.onTriggered: captureManager.stopRecording()
        microphone.onTriggered: captureManager.recordAudio = microphone.checked
        saveLocation.onTriggered: content.dialogs.saveLocationDialog.open()
        attention.onTriggered: content.dialogs.attentionDialog.open()
        camera.enabled: captureManager.hasCamera
        camera.onTriggered: {
            if(captureManager.setCamera()){
                if(captureManager.playerLayout === CaptureManager.LayoutNull){
                    mediaEngine.pause()
                    content.dialogs.recordingLayoutDialog.open();
                }else{
                    mediaEngine.pause()
                    captureManager.startCameraRecording()
                }
            } else {
                if (captureManager.availableCameras.length > 1) {
                    content.dialogs.cameraSelectDialog.open()
                } else if (captureManager.availableCameras.length === 1) {
                    captureManager.selectCamera(captureManager.availableCameras[0].id)
                }
            }
        }
        pauseCamera.onTriggered: {
            if (pauseCamera.checked) {
                captureManager.pauseCameraRecording()
            } else {
                captureManager.resumeCameraRecording()
            }
        }
        stopCamera.onTriggered: captureManager.stopCameraRecording()
        cameraMicrophone.onTriggered: captureManager.cameraAudio = cameraMicrophone.checked
        cameraDevice.onTriggered: content.dialogs.cameraSelectDialog.open()
        recordingLayout.enabled: captureManager.setCamera()
        recordingLayout.onTriggered: content.dialogs.recordingLayoutDialog.open()
        fullScreen.onTriggered: { // 全屏
            if (!content.player.smallWindowMode) { // 小窗播放时不能全屏
                window.showFullScreen()
                menu.visible = false
            }
        }
        exitFullScreen.onTriggered: { // 退出全屏
            if (!content.player.smallWindowMode) { // 小窗播放时不能退出全屏
                window.showNormal()
                menu.visible = true
            }
        }
        loopPlayback.onTriggered: mediaEngine.setPlaybackMode(MediaEngine.Loop)
        sequentialPlayback.onTriggered: mediaEngine.setPlaybackMode(MediaEngine.Sequential)
        randomPlayback.onTriggered: mediaEngine.setPlaybackMode(MediaEngine.Random)
        originalAspectRatio.onTriggered: content.player.targetAspectRatio = 0
        aspectRatio16_9.onTriggered: content.player.targetAspectRatio = 16/9
        aspectRatio4_3. onTriggered: content.player.targetAspectRatio = 4/3
        smallWindowMode.onTriggered: content.player.smallWindowMode = true
        smallDanmu.onTriggered:{
            DanmuRender.smallDanmu()
            DanmuRender.endDanmus()
            content.danmuManager.initDanmus(window.title.replace(/^[^-]*-\x20/,""))
            content.danmuManager.fontSize=20
            content.danmuManager.initTracks(content.height*(1/4))
        }
        bigDanmu.onTriggered:{
            DanmuRender.bigDanmu()
            DanmuRender.endDanmus()
            content.danmuManager.initDanmus(window.title.replace(/^[^-]*-\x20/,""))
            content.danmuManager.fontSize=40
            content.danmuManager.initTracks(content.height*(1/4))
        }
        timedPause.onTriggered: content.dialogs.timedPauseDialog.open()
        danmuSwitch.onCheckedChanged:{
            if(actions.danmuSwitch.checked===true){
                DanmuRender.endDanmus()
            }
        }
    }

    Content {
        id: content
        anchors.fill: parent
        mediaEngine: mediaEngine
        playlistModel: playlistModel
        histroyListModel: histroyListModel
        captureManager: captureManager
        actions: actions

        // 双击全屏
        TapHandler {
            onDoubleTapped: {
                if (window.visibility === ApplicationWindow.FullScreen) {
                    window.showNormal()
                    menuBar.visible = true  // 退出全屏时显示菜单栏
                } else {
                    window.showFullScreen()
                    menuBar.visible = false // 进入全屏时隐藏菜单栏
                }
            }

            onTapped: { // 单击暂停播放或开始播放
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
    }

    Connections {
        target: mediaEngine

        function onPlaybackFinishedChanged() { // 连接视频结束的信号
            if (mediaEngine.playbackFinished) { // 检查视频结束
                switch(mediaEngine.playbackMode) { // 检查视频的播放模式
                    case MediaEngine.Sequential: // 顺序播放
                        var newIndex = playlistModel.currentIndex + 1;
                        if (newIndex > 0 && newIndex < playlistModel.rowCount) {
                            playlistModel.currentIndex = newIndex;
                        }
                        break;
                    case MediaEngine.Random: // 随机播放
                        var count = playlistModel.rowCount
                        if (count > 1) {
                            var index = playlistModel.getRandomIndex(0, count)
                            playlistModel.currentIndex = index
                        }
                        break;
                    case MediaEngine.Loop: // 循环播放
                        mediaEngine.setPosition(0) // 重置播放位置到开始
                        mediaEngine.play() // 重新开始播放
                        break;
                    default:
                        break;
                }
                mediaEngine.setPlaybackFinished(false) // 重置播放完成状态
            }
        }

        function onTimedPauseFinished() { // 连接定时暂停结束信号
            content.dialogs.timedPauseFinishedDialog.open();
        }
    }

    function closeVideo() {
        mediaEngine.stop()
        playlistModel.clear()
        title = "Video Player"
        content.folderListModel.folder = ""
    }

    // 让菜单栏收回截图按键，保证截图时截图按键不挡住窗口画面
    function takeScreenshot(type) {
        screenshotTimer.type = type
        screenshotTimer.start()
    }

    Timer {
        id: screenshotTimer
        property int type
        interval: 50 // 等待50毫秒确保UI更新
        onTriggered: {
            if (type === CaptureManager.WindowCapture) {
                captureManager.captureScreenshot(CaptureManager.WindowCapture)
            }
            if (type === CaptureManager.FullScreenCapture) {
                captureManager.captureScreenshot(CaptureManager.FullScreenCapture)
            }
        }
    }

    // 拖放处理器
    DragDropManager {
        id: dragHandler
        onFilesDropped: function (urls) {
            playlistModel.addMedias(urls)
            // 如果当前没有播放，则播放第一个
            if (playlistModel.rowCount > 0 && !mediaEngine.playing) {
                playlistModel.currentIndex = 0
            }
        }

        Component.onCompleted: setWindow(window)
    }

    // 拖放区域视觉反馈
    Rectangle {
        id: dragRect
        anchors.fill: parent
        color: "#4000aaff"
        border.color: "#0088ff"
        border.width: 4
        radius: 8
        visible: dragHandler.dragActive

        Label {
            anchors.centerIn: parent
            text: "拖放音视频文件到此处"
            font.pixelSize: 28
            color: "white"
        }
    }
}
