import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id:content
    property alias dialogs: _dialogs
    property MediaEngine mediaEngine
    property PlaylistModel playlistModel

    Dialogs {
        id: _dialogs
    }

    // 视频播放区域
    Player {
        id: player
        anchors.fill: parent
        mediaEngine: content.mediaEngine

        // 鼠标区域控制控制栏和列表显示
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onPositionChanged: {
                // 当鼠标靠近右侧时显示播放列表
                playlist.visible = (mouseX > parent.width - 50)

                // 当鼠标靠近底部时显示控制栏
                controlBar.visible = (mouseY > parent.height - 50)
            }
        }
    }

    // 播放列表（右侧）
    Playlist {
        id: playlist
        anchors {
            top: parent.top
            right: parent.right
            bottom: parent.bottom
        }
        playlist: content.playlistModel
    }

    // 控制栏（底部）
    ControlBar {
        id: controlBar
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        mediaEngine: content.mediaEngine
        playlistModel: content.playlistModel
    }

    Connections {
        target: dialogs.fileOpen

        function onAccepted() {
            playlistModel.addMedias(dialogs.fileOpen.selectedFiles)
        }
    }
}
