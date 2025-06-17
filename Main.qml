import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import VideoPlayer

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
            if (currentIndex >= 0) {
                mediaEngine.setMedia(get(currentIndex).url)
                mediaEngine.play()
            }
        }
    }

    menuBar: MenuBar {
        Menu {
            title: qsTr("File")
            MenuItem { action: actions.open }
            MenuItem { action: actions.close }
            MenuSeparator {}
            MenuItem { action: actions.exit }
        }
        Menu {
            title: qsTr("Play")
            MenuItem { action: actions.play }
            MenuItem { action: actions.pause }
            MenuItem { action: actions.stop }
            MenuSeparator {}
            MenuItem { action: actions.previous }
            MenuItem { action: actions.next }
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
        previous.onTriggered: {
            if (playlistModel.currentIndex > 0) {
                playlistModel.currentIndex--
            }
        }
        next.onTriggered: {
            if (playlistModel.currentIndex < playlistModel.rowCount - 1) {
                playlistModel.currentIndex++
            }
        }
        aboutQt.onTriggered: content.dialogs.aboutQt.open()
    }

    Content {
        id: content
        anchors.fill: parent
        mediaEngine: mediaEngine
        playlistModel: playlistModel
    }

    function closeVideo() {
        mediaEngine.stop()
        playlistModel.clear()
        title = "Video Player"
    }
}
