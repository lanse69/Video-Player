import QtQuick
import QtQuick.Controls
import QtMultimedia
import VideoPlayer

Item {
    property MediaEngine mediaEngine

    VideoOutput {
        id: videoOutput
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectFit
        // videoSink: mediaEngine.videoSink
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
