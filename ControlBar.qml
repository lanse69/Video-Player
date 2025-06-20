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
            id: positionSlider
            Layout.fillWidth: true
            from: 0
            to: mediaEngine ? mediaEngine.duration : 0

            property bool isDragging: false // 是否拖拽
            property real dragValue: 0

            value: {
                if (isDragging) {
                    return dragValue
                } else {
                    return mediaEngine ? mediaEngine.position : 0
                }
            }

            onPressedChanged: { // 处理拖拽
                if (pressed) { // 开始拖拽
                    isDragging = true
                    dragValue = value
                } else { // 结束拖拽
                    isDragging = false
                    if (mediaEngine) {
                        mediaEngine.setPosition(dragValue)
                    }
                    thumbnailPopup.close()
                }
            }

            onMoved: {
                if (isDragging) {
                    dragValue = position * to
                }
            }

            // 缩略图弹出窗口
            Popup {
                id: thumbnailPopup
                y: -height - 10
                x: Math.min(Math.max(positionSlider.handle.x - width/2 + positionSlider.handle.width/2, 0),
                          positionSlider.width - width)
                width: 160
                height: 90
                padding: 0
                closePolicy: Popup.NoAutoClose
                visible: positionSlider.pressed && thumbnailImage.source !== ""

                Image {
                    id: thumbnailImage
                    anchors.fill: parent
                    anchors.margins: 2
                    fillMode: Image.PreserveAspectFit
                    cache: false
                    asynchronous: true
                    source: ""
                }

                // 显示时间
                Label {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: 4
                    color: "white"
                    style: Text.Outline
                    styleColor: "black"
                    font.pixelSize: 12
                    text: formatTime(Math.floor(positionSlider.dragValue / 1000))

                    function formatTime(seconds) {
                        var minutes = Math.floor(seconds / 60)
                        seconds = seconds % 60
                        return minutes.toString().padStart(2, '0') + ":" + seconds.toString().padStart(2, '0')
                    }
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

        // 播放速率选择按钮
        ToolButton {
            id: rateButton
            text: mediaEngine ? mediaEngine.playbackRate + "x" : "1.0x"

            onClicked: {
                rateSelectionPopup.open()
            }

            // 速率选择窗口
            Popup {
                id: rateSelectionPopup
                y: -height - 10
                x: (rateButton.width - width) / 2
                width: 100
                height: rateSelectionColumn.height + 20
                padding: 10

                background: Rectangle {
                    color: "#66000000"
                    radius: 10
                }

                ColumnLayout {
                    id: rateSelectionColumn
                    width: parent.width

                    Button {
                        text: "0.5x"
                        onClicked: {
                            mediaEngine.setPlaybackRate(0.5)
                            rateSelectionPopup.close()
                        }
                    }

                    Button {
                        text: "1.0x"
                        onClicked: {
                            mediaEngine.setPlaybackRate(1.0)
                            rateSelectionPopup.close()
                        }
                    }

                    Button {
                        text: "1.5x"
                        onClicked: {
                            mediaEngine.setPlaybackRate(1.5)
                            rateSelectionPopup.close()
                        }
                    }

                    Button {
                        text: "2.0x"
                        onClicked: {
                            mediaEngine.setPlaybackRate(2.0)
                            rateSelectionPopup.close()
                        }
                    }
                }
            }
        }

        // 音量控制
        ToolButton {
            icon.name: mediaEngine && mediaEngine.muted ? "audio-volume-muted" :
                            (mediaEngine && mediaEngine.volume < 0.3) ? "audio-volume-low" :
                                (mediaEngine && mediaEngine.volume < 0.6) ? "audio-volume-medium" :
                                    (mediaEngine && mediaEngine.volume < 0.9) ? "player-volume" :
                                        "audio-volume-high-danger"
            onClicked: {
                if (mediaEngine) {
                    mediaEngine.setMuted(!mediaEngine.muted)
                    actions.mute.trigger()
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
                    if (value === 0) {
                        if (!mediaEngine.muted) {
                            mediaEngine.setMuted(true)
                            actions.mute.checked = true
                        }
                    } else {
                        if (mediaEngine.muted) {
                            mediaEngine.setMuted(false)
                            actions.mute.checked = false
                        }
                        mediaEngine.setVolume(value)
                    }
                }
            }
        }
    }
}
