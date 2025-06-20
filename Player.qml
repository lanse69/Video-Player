import QtQuick
import QtQuick.Controls
import QtMultimedia
import VideoPlayer

Item {
    property MediaEngine mediaEngine
    property bool subtitleVisible: mediaEngine ? mediaEngine.subtitleVisible : true
    property string currentSubtitle: ""
    property real targetAspectRatio: 0  // 0为原始比例, 16/9为16:9, 4/3为4:3

    Item {
        id: _videoContainer
        anchors.centerIn: parent

        // 动态计算尺寸
        width: {
            if (targetAspectRatio === 0) {
                // 自动模式：使用视频原始比例或默认16:9
                var videoRatio = mediaEngine.videoAspectRatio || (16/9)
                return Math.min(parent.width, parent.height * videoRatio)
            } else {
                // 强制比例模式
                if (parent.width/parent.height > targetAspectRatio) {
                    return parent.height * targetAspectRatio
                } else {
                    return parent.width
                }
            }
        }

        height: {
            if (targetAspectRatio === 0) {
                var videoRatio = mediaEngine.videoAspectRatio || (16/9)
                return Math.min(parent.height, parent.width / videoRatio)
            } else {
                if (parent.width/parent.height > targetAspectRatio) {
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
}
