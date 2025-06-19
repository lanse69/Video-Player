import QtQuick
import QtQuick.Controls
import QtMultimedia
import VideoPlayer

Item {
    property MediaEngine mediaEngine
    property bool subtitleVisible: mediaEngine ? mediaEngine.subtitleVisible : true
    property string currentSubtitle: ""

    VideoOutput {
        id: videoOutput
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectFit
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
