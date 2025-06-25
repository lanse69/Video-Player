import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import VideoPlayer

Item {
    property MediaEngine mediaEngine
    property CaptureManager captureManager
    property bool subtitleVisible: mediaEngine ? mediaEngine.subtitleVisible : true
    property string currentSubtitle: ""
    property real targetAspectRatio: 0  // 0为原始比例, 16/9为16:9, 4/3为4:3
    property bool cameraActive: captureManager ? captureManager.cameraState !== CaptureManager.CameraStopped : false
    property alias cameraOutput: _cameraOutput
    property bool smallWindowMode: false // 是否为小窗播放

    Item {
        id: _videoContainer
        anchors.centerIn: parent

        // 计算尺寸
        width: {
            if (targetAspectRatio === 0) {
                return parent.width
            } else {
                if (parent.width / parent.height > targetAspectRatio) { // 如果父容器更宽，按高度计算宽度
                    return parent.height * targetAspectRatio
                } else {
                    return parent.width
                }
            }
        }

        height: {
            if (targetAspectRatio === 0) {
                return parent.height
            } else {
                if (parent.width / parent.height > targetAspectRatio) { // 如果父容器更宽，直接使用父容器的全部高度
                    return parent.height
                } else {
                    return parent.width / targetAspectRatio
                }
            }
        }

        BusyIndicator {
            anchors.centerIn: parent
            running: mediaEngine && mediaEngine.mediaStatus === MediaEngine.Loading && !mediaEngine.isLocal && mediaEngine.playing
            visible: running
        }

        // 视频输出（根据模式选择填充方式）
        VideoOutput {
            id: videoOutput
            anchors.fill: parent
            fillMode: targetAspectRatio === 0 ? VideoOutput.PreserveAspectFit : VideoOutput.Stretch
        }
    }

    Image {
        id: coverArtImage
        anchors.fill: parent
        visible: mediaEngine.coverArtBase64 !== "" && captureManager.playerLayout === CaptureManager.LayoutNull
        source: mediaEngine.coverArtBase64 ? "data:image/png;base64," + mediaEngine.coverArtBase64 : ""
        fillMode: Image.PreserveAspectFit
        cache: false
        asynchronous: true // 异步加载
    }

    VideoOutput {
        id: _cameraOutput
        anchors.fill: parent
        visible: cameraActive
    }

    // 录制布局
    Item {
        anchors.fill: parent
        visible: cameraActive

        // 左右布局
        RowLayout {
            id: leftRight
            anchors.fill: parent
            spacing: 5

            VideoOutput {
                id: leftMedia
                Layout.fillWidth: true
                Layout.fillHeight: true
                fillMode: VideoOutput.PreserveAspectFit
            }

            VideoOutput {
                id: rightCamera
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }

        // 上下布局
        ColumnLayout {
            id: topBottom
            anchors.fill: parent
            spacing: 5

            VideoOutput {
                id: topMedia
                Layout.fillWidth: true
                Layout.fillHeight: true
                fillMode: VideoOutput.PreserveAspectFit
            }

            VideoOutput {
                id: bottomCamera
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }

    Connections {
        target: captureManager

        function onPlayerLayoutChanged() {
            closeVideos()
            if(captureManager.playerLayout === CaptureManager.NotVideo){
                captureManager.setVideoSink(_cameraOutput.videoSink)
                _cameraOutput.visible = true
            } else if(captureManager.playerLayout === CaptureManager.LayoutNull){
                mediaEngine.setVideoSink(videoOutput.videoSink)
                videoOutput.visible = true
            } else if(captureManager.playerLayout === CaptureManager.SideBySide) {
                mediaEngine.setVideoSink(leftMedia.videoSink)
                captureManager.setVideoSink(rightCamera.videoSink)
                leftRight.visible = true
            } else if(captureManager.playerLayout === CaptureManager.TopBottom) {
                mediaEngine.setVideoSink(topMedia.videoSink)
                captureManager.setVideoSink(bottomCamera.videoSink)
                topBottom.visible = true
            } else if(captureManager.playerLayout === CaptureManager.Pip){
                mediaEngine.setVideoSink(smallVideoOutput.videoSink)
                captureManager.setVideoSink(_cameraOutput.videoSink)
                _cameraOutput.visible = true
                smallWindow.show()
            }
        }

        function onCameraChanged() {
            if(captureManager.playerLayout === CaptureManager.NotVideo){
                captureManager.setVideoSink(_cameraOutput.videoSink)
                _cameraOutput.visible = true
            } else if(captureManager.playerLayout === CaptureManager.LayoutNull){
                mediaEngine.setVideoSink(videoOutput.videoSink)
                videoOutput.visible = true
            } else if(captureManager.playerLayout === CaptureManager.SideBySide) {
                mediaEngine.setVideoSink(leftMedia.videoSink)
                captureManager.setVideoSink(rightCamera.videoSink)
                leftRight.visible = true
            } else if(captureManager.playerLayout === CaptureManager.TopBottom) {
                mediaEngine.setVideoSink(topMedia.videoSink)
                captureManager.setVideoSink(bottomCamera.videoSink)
                topBottom.visible = true
            } else if(captureManager.playerLayout === CaptureManager.Pip){
                mediaEngine.setVideoSink(smallVideoOutput.videoSink)
                captureManager.setVideoSink(_cameraOutput.videoSink)
                _cameraOutput.visible = true
                smallWindow.show()
            }
        }
    }

    function closeVideos(){
        videoOutput.visible = false
        _cameraOutput.visible = false
        smallWindow.hide()
        leftRight.visible = false
        topBottom.visible = false
    }

    // 字幕显示区域
    Rectangle {
        id: subtitleContainer
        anchors {
            bottom: parent.bottom
            bottomMargin: 50
            left: parent.left
            right: parent.right
        }
        height: subtitleText.height + 20
        color: "transparent"
        visible: subtitleVisible && currentSubtitle !== "" && captureManager.playerLayout !== CaptureManager.NotVideo && captureManager.playerLayout !== CaptureManager.Pip

        Text {
            id: subtitleText
            anchors.centerIn: parent
            text: currentSubtitle
            color: "white"
            font.pixelSize: 24
            style: Text.Outline
            styleColor: "black"
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            width: parent.width * 0.8
        }
    }

    Connections {
        target: mediaEngine

        function onSubtitleTextChanged() {
            if (mediaEngine && mediaEngine.subtitleVisible) {
                currentSubtitle = mediaEngine.subtitleText
            }
        }

        function onCurrentMediaChanged() {
            currentSubtitle = ""
        }

        function onSubtitleVisibleChanged() {
            subtitleVisible = mediaEngine.subtitleVisible
            currentSubtitle = subtitleVisible ? mediaEngine.subtitleText : ""
        }

        function onHasSubtitleChanged() {
            if (mediaEngine.hasSubtitle && mediaEngine.subtitleVisible) {
                currentSubtitle = mediaEngine.subtitleText
            } else {
                currentSubtitle = ""
            }
        }

        function onCoverImageChanged() {
            if (mediaEngine.coverArtBase64) {
                coverArtImage.source = "data:image/png;base64," + mediaEngine.coverArtBase64
            }
        }
    }

    Component.onCompleted: {
        if (mediaEngine) {
            mediaEngine.setVideoSink(videoOutput.videoSink)
        }
    }

    onMediaEngineChanged: {
        if (mediaEngine) {
            mediaEngine.setVideoSink(videoOutput.videoSink)
        }
    }

    // 小窗
    Window {
        id: smallWindow
        width: 320
        height: 180
        flags: Qt.Window | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
        color: "transparent"
        visible: smallWindowMode

        DragHandler { // 拖动
            onActiveChanged: if (active) smallWindow.startSystemMove()
        }

        // 视频容器
        Rectangle {
            anchors.fill: parent
            color: "#66000000"
            radius: 5

            VideoOutput {
                id: smallVideoOutput
                anchors.fill: parent
                fillMode: VideoOutput.PreserveAspectFit
            }

            Image {
                id: smallArtImage
                anchors.fill: parent
                visible: mediaEngine.coverArtBase64 !== ""
                source: mediaEngine.coverArtBase64 ? "data:image/png;base64," + mediaEngine.coverArtBase64 : ""
                fillMode: Image.PreserveAspectFit
                cache: false
                asynchronous: true // 异步加载
            }

            // 字幕显示区域
            Rectangle {
                id: smallSubtitleContainer
                anchors {
                    bottom: smallControlBar.top
                    left: parent.left
                    right: parent.right
                    margins: 5
                }
                height: smallSubtitleText.height + 10
                color: "transparent"
                visible: subtitleVisible && currentSubtitle !== ""

                Text {
                    id: smallSubtitleText
                    anchors.centerIn: parent
                    text: currentSubtitle
                    color: "white"
                    font.pixelSize: 14
                    style: Text.Outline
                    styleColor: "black"
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    width: parent.width * 0.9
                }
            }

            HoverHandler { // 鼠标悬停显示控制栏
                acceptedDevices: PointerDevice.Mouse
                onHoveredChanged: {
                    smallControlBar.visible = hovered ? true : false
                }
            }

            // 控制栏
            Rectangle {
                id: smallControlBar
                anchors.bottom: parent.bottom
                height: 25
                width: parent.width
                color: "#80000000"
                visible: false

                RowLayout {
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

                    // 进度条
                    Slider {
                        Layout.fillWidth: true
                        from: 0
                        to: mediaEngine.duration
                        value: mediaEngine.position
                        onMoved: mediaEngine.setPosition(value)
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

                    // 关闭按钮
                    ToolButton {
                        id: closeBtn
                        icon.name: "edit-delete-remove"
                        onClicked: smallWindowMode = false
                    }
                }
            }
        }
    }

    onSmallWindowModeChanged: {
        if (smallWindowMode) {
            smallWindow.show()
            mediaEngine.setVideoSink(smallVideoOutput.videoSink)
        } else {
            smallWindow.hide()
            mediaEngine.setVideoSink(videoOutput.videoSink)
        }
    }
}
