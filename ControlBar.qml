import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "DanmuRender.js" as DanmuRender

Rectangle {
    property MediaEngine mediaEngine
    property PlaylistModel playlistModel
    property CaptureManager captureManager
    property alias recordTimeText: _recordTimeText
    property alias cameraTimeText: _cameraTimeText

    height: 70
    width: parent.width
    color: "gray"
    visible: false
    anchors.bottom: parent.bottom

    ColumnLayout{
        anchors.fill: parent
        anchors.margins: 10

        RowLayout {
            Layout.fillWidth: true
            anchors.margins: 10
            // 进度条
            Slider {
                id: positionSlider
                focusPolicy: Qt.NoFocus // 禁用键盘焦点
                Layout.fillWidth: true
                from: 0
                to: mediaEngine ? mediaEngine.duration : 0

                property bool isDragging: false // 是否在拖拽
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
                        thumbnailImage.source = mediaEngine.getFrameAtPosition(positionSlider.dragValue); // 生成缩略图
                        thumbnailPopup.open() // 打开缩略图
                    } else { // 结束拖拽
                        isDragging = false
                        if (mediaEngine) {
                            mediaEngine.setPosition(dragValue)
                        }
                        thumbnailPopup.close() // 关闭缩略图
                        thumbnailImage.source = "" // 丢弃之前的缩略图

                        DanmuRender.endDanmus()//松开刷新弹幕
                        content.danmuManager.initDanmus(window.title.replace(/^[^-]*-\x20/,""))//通过正则表达式处理窗口标题得到正在播放的视频的标题
                        content.danmuManager.initTracks(content.height*(1/4))
                    }
                }

                onMoved: {
                    if (isDragging) {
                        dragValue = positionSlider.value
                        thumbnailImage.source = mediaEngine.getFrameAtPosition(positionSlider.dragValue); // 生成缩略图
                    }
                }

                // 缩略图弹出窗口
                Popup {
                    id: thumbnailPopup
                    parent: positionSlider.handle
                    visible: positionSlider.pressed
                    y: -height - 5
                    x: -width / 2
                    width: 160
                    height: 90
                    closePolicy: Popup.CloseOnReleaseOutside
                    background: Rectangle {
                        color: "transparent"
                    }

                    Image {
                        id: thumbnailImage
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        cache: false
                        source: ""
                    }

                    // 显示时间
                    Label {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "white"
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
                color: "white"
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
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            anchors.margins: 10

            // 播放控制按钮
            // 上一个
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

            // 播放和停止
            ToolButton {
                id: startandpause
                icon.name: mediaEngine.playing ? "media-playback-pause" : "media-playback-start"
                onClicked: {
                    if(mediaEngine){
                        mediaEngine.playing ? mediaEngine.pause() : mediaEngine.play()
                    }
                }
            }

            // 停止播放，并将播放位置重置为起始位置
            ToolButton {
                icon.name: "media-playback-stop-symbolic"
                onClicked:
                    if(mediaEngine){
                        mediaEngine.stop()
                    }
            }

            // 下一个
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

            // 播放模式
            ToolButton {
                id: playbackModeButton
                icon.name: {
                    switch (mediaEngine.playbackMode) {
                    case MediaEngine.Sequential: // 顺序播放
                        return "media-playlist-normal"
                    case MediaEngine.Random: // 随机播放
                        return "media-playlist-shuffle"
                    case MediaEngine.Loop: // 循环播放
                        return "media-playlist-repeat-symbolic"
                    default:
                        return ""
                    }
                }

                onClicked: { // 循环切换播放模式
                    var mode = (mediaEngine.playbackMode + 1) % 3
                    mediaEngine.setPlaybackMode(mode)
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
                    background: Rectangle {
                        color: "#66000000"
                    }
                    ColumnLayout {
                        id: rateSelectionColumn

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

            ToolButton {
                icon.name: "folder-download"
                visible: mediaEngine && !mediaEngine.isLocal && mediaEngine.currentMedia.toString() !== ""
                onClicked: {
                    content.downloadManager.nowDownload();
                }
            }

            //弹幕输入框
            Frame{
                id: danmInpustFrame
                enabled: mediaEngine.currentMedia.toString() !== "" && captureManager.playerLayout !== CaptureManager.NotVideo && !actions.danmuSwitch.checked
                Layout.preferredHeight: parent.height
                Layout.preferredWidth: danmuInputBox.width
                TextArea{
                    id:danmuInputBox
                    anchors.centerIn: parent
                    readOnly: !enabled
                    placeholderText: {
                        if (mediaEngine.currentMedia.toString() === "") {
                            "未打开音视频文件"
                        } else if (captureManager.playerLayout === CaptureManager.NotVideo) {
                            "该布局模式下无法发送弹幕"
                        } else if (actions.danmuSwitch.checked) {
                            "弹幕已关闭"
                        } else {
                            "请输入弹幕内容(限100字)"
                        }
                    }
                    color: "white"
                    placeholderTextColor: "white"
                    Keys.onPressed: function(event) {
                        if (!enabled) {
                            event.accepted = true;
                            return;
                        }

                        //输入回车键提交弹幕
                        if(event.key===Qt.Key_Enter||event.key===Qt.Key_Return){
                            content.danmuManager.addDanmu(content.mediaEngine.position,danmuInputBox.text)
                            danmuInputBox.text=""
                        }

                        //确保输入合法
                        if(!/[a-zA-Z0-9]/.test(event.text) && event.key !== Qt.Key_Delete&&event.key !== Qt.Key_Backspace){
                            event.accepted=true
                        }
                        //确保输入内容的大小
                        if(length>=100&&event.key !== Qt.Key_Delete&&event.key !== Qt.Key_Backspace){
                            event.accepted=true
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
                focusPolicy: Qt.NoFocus // 禁用键盘焦点
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

            RowLayout {
                spacing: 5
                visible: captureManager.recordState !== CaptureManager.Stopped

                // 录屏状态指示
                Rectangle {
                    width: 10
                    height: 10
                    radius: 5
                    color: captureManager.recordState === CaptureManager.Recording ? "red" : captureManager.recordState === CaptureManager.Paused ? "yellow" : "transparent"
                }

                // 录屏时间显示
                Label {
                    id: _recordTimeText
                    color: "white"
                    text: {
                        var sec = captureManager.recordingTime
                        var min = Math.floor(sec / 60)
                        sec = sec % 60
                        return min.toString().padStart(2, '0') + ":" + sec.toString().padStart(2, '0')
                    }
                }

                // 暂停/继续录屏按钮
                ToolButton {
                    icon.name: captureManager.recordState === CaptureManager.Paused ?
                               "media-playback-start" : "media-playback-pause"
                    enabled: captureManager.recordState !== CaptureManager.Stopped
                    onClicked: {
                        if (captureManager.recordState === CaptureManager.Paused) {
                            captureManager.resumeRecording()
                        } else {
                            captureManager.pauseRecording()
                        }
                    }
                }

                // 停止录屏按钮
                ToolButton {
                    icon.name: "media-playback-stop"
                    enabled: captureManager.recordState !== CaptureManager.Stopped
                    onClicked: captureManager.stopRecording()
                }
            }

            // 摄像头控制区域
            RowLayout {
                spacing: 5
                visible: captureManager.cameraState !== CaptureManager.CameraStopped

                // 摄像头状态指示
                Rectangle {
                    width: 10
                    height: 10
                    radius: 5
                    color: captureManager.cameraState === CaptureManager.CameraRecording ?
                           "green" : captureManager.cameraState === CaptureManager.CameraPaused ?
                           "yellow" : "transparent"
                }

                // 录制时间显示
                Label {
                    id: _cameraTimeText
                    color: "white"
                    text: {
                        var sec = captureManager.cameraRecordingTime
                        var min = Math.floor(sec / 60)
                        sec = sec % 60
                        return min.toString().padStart(2, '0') + ":" + sec.toString().padStart(2, '0')
                    }
                }

                // 暂停/继续按钮
                ToolButton {
                    icon.name: captureManager.cameraState === CaptureManager.CameraPaused ?
                               "media-playback-start" : "media-playback-pause"
                    onClicked: {
                        if (captureManager.cameraState === CaptureManager.CameraPaused) {
                            captureManager.resumeCameraRecording()
                        } else {
                            captureManager.pauseCameraRecording()
                        }
                    }
                }

                // 停止按钮
                ToolButton {
                    icon.name: "media-playback-stop"
                    onClicked: captureManager.stopCameraRecording()
                }
            }
        }
    }
}
