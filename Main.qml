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

    // 截图管理器
    CaptureManager {
        id: captureManager
        onScreenshotCaptured: {
            content.dialogs.previewDialog.captureManager = captureManager
            content.dialogs.previewDialog.open()
        }
        onErrorOccurred: function(error) {
            content.dialogs.errorDialog.text = error;
            content.dialogs.errorDialog.open();
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
        Menu {
            title: qsTr("File")
            MenuItem { action: actions.open }
            MenuItem { action: actions.close }
            MenuSeparator {}
            MenuItem { action: actions.exit }
            Menu{
                title: qsTr("最近打开")
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
        }

        Menu {
            title: qsTr("Capture")
            Menu {
                title: qsTr("Screenshot")
                MenuItem { action: actions.screenshotWindow }
                MenuItem { action: actions.screenshotFull }
            }
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
    }

    Content {
        id: content
        anchors.fill: parent
        mediaEngine: mediaEngine
        playlistModel: playlistModel
    }

    Connections {
        target: mediaEngine

        function onHasSubtitleChanged() {
            actions.subtitle.enabled = mediaEngine.hasSubtitle
            actions.subtitle.checked = mediaEngine.subtitleVisible
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
}
