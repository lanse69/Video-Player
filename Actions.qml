import QtQuick
import QtQuick.Controls

Item {
    property alias open: _open
    property alias close: _close
    property alias exit: _exit
    property alias play: _play
    property alias pause: _pause
    property alias stop: _stop
    property alias mute: _mute
    property alias subtitle: _subtitle
    property alias previous: _previous
    property alias next: _next
    property alias aboutQt: _aboutQt
    property alias zeroPointFiveRate: _zeroPointFiveRate
    property alias oneRate: _oneRate
    property alias onePointFiveRate: _onePointFiveRate
    property alias twoRate: _twoRate
    property alias screenshotWindow: _screenshotWindow
    property alias screenshotFull: _screenshotFull
    property alias record: _record
    property alias pauseRecord: _pauseRecord
    property alias stopRecord: _stopRecord
    property alias microphone: _microphone
    property alias saveLocation: _saveLocation
    property alias camera: _camera
    property alias pauseCamera: _pauseCamera
    property alias stopCamera: _stopCamera
    property alias cameraMicrophone: _cameraMicrophone
    property alias cameraDevice: _cameraDevice
    property alias recordingLayout: _recordingLayout
    property alias fullScreen: _fullScreen
    property alias exitFullScreen: _exitFullScreen
    property alias loopPlayback: _loopPlayback
    property alias sequentialPlayback: _sequentialPlayback
    property alias randomPlayback: _randomPlayback
    property alias originalAspectRatio: _originalAspectRatio
    property alias aspectRatio16_9: _aspectRatio16_9
    property alias aspectRatio4_3: _aspectRatio4_3
    property alias smallWindowMode: _smallWindowMode

    Action {
        id: _open
        text: qsTr("&Open...")
        icon.name: "document-open"
        shortcut: StandardKey.Open
    }

    Action {
        id: _close
        text: qsTr("&Close")
        icon.name: "window-close"
    }

    Action {
        id: _exit
        text: qsTr("&Exit")
        icon.name: "application-exit"
        shortcut: StandardKey.Quit
    }

    Action {
        id: _play
        text: qsTr("&Play")
        icon.name: "media-playback-start"
    }

    Action {
        id: _pause
        text: qsTr("&Pause")
        icon.name: "media-playback-pause"
    }

    Action {
        id: _stop
        text: qsTr("&Stop")
        icon.name: "media-playback-stop"
    }

    Action {
        id: _mute
        text: qsTr("&Mute")
        icon.name: "audio-volume-muted"
        checkable: true
    }

    Action {
        id: _subtitle
        text: qsTr("&Subtitle")
        icon.name: "add-subtitle"
        checkable: true
        checked: true
    }

    Action {
        id: _previous
        text: qsTr("&Previous")
        icon.name: "media-skip-backward"
    }

    Action {
        id: _next
        text: qsTr("&Next")
        icon.name: "media-skip-forward"
    }

    Action {
        id: _aboutQt
        text: qsTr("About Qt")
        icon.name: "qtcreator"
    }

    Action {
        id: _zeroPointFiveRate
        text: qsTr("0.5x")
    }

    Action {
        id: _oneRate
        text: qsTr("1x")
    }

    Action {
        id: _onePointFiveRate
        text: qsTr("1.5x")
    }

    Action {
        id: _twoRate
        text: qsTr("2x")
    }

    Action {
        id: _screenshotWindow
        text: qsTr("Window")
        icon.name: "preferences-system-windows-effect-screenshot"
    }

    Action {
        id: _screenshotFull
        text: qsTr("Full Screen")
        icon.name: "preferences-system-windows-effect-screenshot"
    }

    Action {
        id: _record
        text: qsTr("Record Screen")
        icon.name: "applications-multimedia-symbolic"
    }

    Action {
        id: _pauseRecord
        text: qsTr("&Pause Recording")
        icon.name: "media-playback-pause"
        enabled: false
        checkable: true
    }

    Action {
        id: _stopRecord
        text: qsTr("&Stop Recording")
        icon.name: "media-playback-stop"
        enabled: false
    }

    Action {
        id: _microphone
        text: qsTr("Microphone")
        icon.name: "audio-input-microphone"
        checkable: true
        checked: true
    }

    Action {
        id: _saveLocation
        text: qsTr("Save Location")
        icon.name: "folder-black"
        shortcut: "Ctrl+L"
    }

    Action {
        id: _camera
        text: qsTr("&Camera")
        icon.name: "camera-video"
    }

    Action {
        id: _pauseCamera
        text: qsTr("Pause &Camera")
        icon.name: "media-playback-pause"
        enabled: false
        checkable: true
    }

    Action {
        id: _stopCamera
        text: qsTr("Stop &Camera")
        icon.name: "media-playback-stop"
        enabled: false
    }

    Action {
        id: _cameraDevice
        text: qsTr("Select &Camera")
        icon.name: "camera-ready"
    }

    Action {
        id: _recordingLayout
        text: qsTr("Select Camera Layout")
        icon.name: "labplot-editbreaklayout"
    }

    Action {
        id: _cameraMicrophone
        text: qsTr("Microphone")
        icon.name: "audio-input-microphone"
        checkable: true
        checked: true
    }

    Action {
        id: _fullScreen
        text: qsTr("Full Screen")
        icon.name: "view-fullscreen"
        shortcut: "F11"
    }

    Action {
        id: _exitFullScreen
        text: qsTr("Exit Full Screen")
        shortcut: "Esc"
    }

    Action {
        id: _loopPlayback
        text: qsTr("Loop Playback")
        icon.name: "media-playlist-repeat-symbolic"
    }

    Action {
        id: _sequentialPlayback
        text: qsTr("Sequential playback")
        icon.name: "media-playlist-normal"
    }

    Action {
        id: _randomPlayback
        text: qsTr("Random playback")
        icon.name: "media-playlist-shuffle"
    }

    Action {
        id: _originalAspectRatio
        text: qsTr("Original")
    }

    Action {
        id: _aspectRatio16_9
        text: qsTr("16:9")
    }

    Action {
        id: _aspectRatio4_3
        text: qsTr("4:3")
    }

    Action {
        id: _smallWindowMode
        text: qsTr("small Window")
    }
}
