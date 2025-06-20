import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import VideoPlayer
import QtQuick.Dialogs

ApplicationWindow {
    id: window
    width: 800
    height: 600
    visible: true
    title: "Video Player"

    // 媒体引擎
    MediaEngine {
        id: mediaEngine
        onHasSubtitleChanged: {
            actions.subtitle.enabled = mediaEngine.hasSubtitle
            actions.subtitle.checked = mediaEngine.subtitleVisible
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
                        window.title = "Video Player - "+title
                    }
                }
            }
        }
    }

    CaptureManager {
        id: captureManager
        onScreenshotCaptured: {
            content.dialogs.previewDialog.open()
        }
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
    }

    //历史记录的数据项
    PlaylistModel {
        id: histroyListModel
        Component.onCompleted: {
            histroy()
        }
    }

    menuBar: MenuBar {
        id: menu
        Menu {
            title: qsTr("File")
            MenuItem { action: actions.open }
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
        }

        Menu {
            title: qsTr("View")
            MenuItem { action: actions.fullScreen }
            MenuItem { action: actions.exitFullScreen }
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
                MenuItem { action: actions.recordWindow }
                MenuItem { action: actions.recordFull }
                MenuSeparator {}
                MenuItem { action: actions.pauseRecord }
                MenuItem { action: actions.stopRecord }
            }
            MenuSeparator {}
            MenuItem { action: actions.saveLocation }
        }

        Menu {
            title: qsTr("Help")
            MenuItem { action: actions.aboutQt }
        }
    }

    Actions {
        id: actions
        open.onTriggered: content.dialogs.fileOpen.open()
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

        aboutQt.onTriggered: content.dialogs.aboutQt.open()
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

        recordWindow.onTriggered: captureManager.startRecording(CaptureManager.WindowCapture)
        recordFull.onTriggered: captureManager.startRecording(CaptureManager.FullScreenCapture)
        pauseRecord.onTriggered: {
            if (pauseRecord.checked) {
                captureManager.pauseRecording()
            } else {
                captureManager.resumeRecording()
            }
        }
        stopRecord.onTriggered: captureManager.stopRecording()

        saveLocation.onTriggered: content.dialogs.saveLocationDialog.open()

        fullScreen.onTriggered: { // 全屏
            window.showFullScreen()
            menu.visible = false
        }

        exitFullScreen.onTriggered: { // 退出全屏
            window.showNormal()
            menu.visible = true
        }

        loopPlayback.onTriggered: mediaEngine.setPlaybackMode(MediaEngine.Loop)
        sequentialPlayback.onTriggered: mediaEngine.setPlaybackMode(MediaEngine.Sequential)
        randomPlayback.onTriggered: mediaEngine.setPlaybackMode(MediaEngine.Random)
        originalAspectRatio.onTriggered: content.player.targetAspectRatio = 0
        aspectRatio16_9.onTriggered: content.player.targetAspectRatio = 16/9
        aspectRatio4_3. onTriggered: content.player.targetAspectRatio = 4/3

    }

    Content {
        id: content
        anchors.fill: parent
        mediaEngine: mediaEngine
        playlistModel: playlistModel
        captureManager: captureManager

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
        }
    }

    Connections {
        target: mediaEngine

        function onPlaybackFinishedChanged() {
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
                        playlistModel.currentIndex = playlistModel.currentIndex
                        break;
                    default:
                        break;
                }
            }
        }
    }

    function closeVideo() {
        mediaEngine.stop()
        playlistModel.clear()
        title = "Video Player"
    }

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

    Component.onCompleted: {
        captureManager.setWindowToRecord(window)
    }
}
