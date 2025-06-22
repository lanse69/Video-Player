import QtQuick
import QtQuick.Controls
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

        // 视频输出（根据模式选择填充方式）
        VideoOutput {
            id: videoOutput
            anchors.fill: parent
            fillMode: targetAspectRatio === 0 ? VideoOutput.PreserveAspectFit : VideoOutput.Stretch
        }
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
        visible: subtitleVisible && currentSubtitle !== ""

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

    VideoOutput {
        id: _cameraOutput
        anchors.fill: parent
        visible: cameraActive
    }

    Connections {
        target: captureManager
        function onCameraChanged() {
            if (captureManager && captureManager.cameraSession) {
                captureManager.setVideoSink(_cameraOutput.videoSink)
            }
        }
    }
}
