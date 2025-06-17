import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    property MediaEngine mediaEngine
    property PlaylistModel playlistModel
    height: 50
    width: parent.width
    color: "#66000000"
    visible: false
    anchors.bottom: parent.bottom

    RowLayout {
        anchors.fill: parent
        anchors.margins: 10

        // 播放控制按钮
        ToolButton {
            icon.name: "media-seek-backward-symbolic"
            onClicked: {
                if (playlistModel && playlistModel.rowCount > 0) {
                    var newIndex = playlistModel.currentIndex - 1
                    if (newIndex < 0) newIndex = playlistModel.rowCount - 1
                    playlistModel.currentIndex = newIndex
                }
            }
        }

        ToolButton {
            id: startandpause
            icon.name: mediaEngine.playing ? "media-playback-pause" : "media-playback-start"
            onClicked: {
                if(mediaEngine){
                    mediaEngine.playing ? mediaEngine.pause() : mediaEngine.play()
                }
            }
        }

        ToolButton {
            icon.name: "media-playback-stop-symbolic"
            onClicked:
                if(mediaEngine){
                    mediaEngine.stop()
                }
        }

        ToolButton {
            icon.name: "media-seek-forward-symbolic"
            onClicked: {
                if (playlistModel && playlistModel.rowCount > 0) {
                    var newIndex = playlistModel.currentIndex + 1
                    if (newIndex >= playlistModel.rowCount) newIndex = 0
                    playlistModel.currentIndex = newIndex
                }
            }
        }

        // 进度条
        Slider {
            Layout.fillWidth: true
            from: 0
            to: mediaEngine ? mediaEngine.duration : 0
            value: mediaEngine ? mediaEngine.position : 0

            onMoved: {
                if (mediaEngine) {
                    mediaEngine.setPosition(value)
                }
            }
        }

        // 时间显示
        Label {
            text: {
                if (!mediaEngine) return "00:00 / 00:00"

                var currentSec = Math.floor(mediaEngine.position / 1000)
                var totalSec = Math.floor(mediaEngine.duration / 1000)

                return formatTime(currentSec) + " / " + formatTime(totalSec)
            }

            function formatTime(seconds) {
                var minutes = Math.floor(seconds / 60)
                var secs = seconds % 60
                return minutes.toString().padStart(2, '0') + ":" + secs.toString().padStart(2, '0')
            }
        }

        // 音量控制
        ToolButton {
            icon.name: mediaEngine && mediaEngine.muted ? "audio-volume-muted" :
                            (mediaEngine && mediaEngine.volume < 0.01) ? "audio-volume-low" :
                                (mediaEngine && mediaEngine.volume < 0.33) ? "audio-volume-medium" :
                                    (mediaEngine && mediaEngine.volume < 0.66) ? "player-volume" :
                                        "audio-volume-high-danger"
            onClicked: {
                if (mediaEngine) {
                    mediaEngine.setMuted(!mediaEngine.muted)
                }
            }
        }

        Slider {
            from: 0
            to: 1
            value: mediaEngine ? (mediaEngine.muted ? 0 : mediaEngine.volume) : 0.5
            orientation: Qt.Horizontal
            width: 100

            onMoved: {
                if (mediaEngine) {
                    if (mediaEngine.muted) {
                        mediaEngine.setMuted(false)
                    }
                    mediaEngine.setVolume(value)
                }
            }
        }
    }
}
