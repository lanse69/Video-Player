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
    property alias fullScreen: _fullScreen
    property alias exitFullScreen: _exitFullScreen
    property alias loopPlayback: _loopPlayback
    property alias sequentialPlayback: _sequentialPlayback
    property alias randomPlayback: _randomPlayback
    property alias originalAspectRatio: _originalAspectRatio
    property alias aspectRatio16_9: _aspectRatio16_9
    property alias aspectRatio4_3: _aspectRatio4_3

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
        icon.name: "camera-photo"
    }

    Action {
        id: _screenshotFull
        text: qsTr("Full Screen")
        icon.name: "camera-photo"
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
    }

    Action {
        id: _sequentialPlayback
        text: qsTr("Sequential playback")
    }

    Action {
        id: _randomPlayback
        text: qsTr("Random playback")
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
}
