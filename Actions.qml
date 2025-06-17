import QtQuick
import QtQuick.Controls

Item {
    property alias open: _open
    property alias close: _close
    property alias exit: _exit
    property alias play: _play
    property alias pause: _pause
    property alias stop: _stop
    property alias previous: _previous
    property alias next: _next
    property alias aboutQt: _aboutQt

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
        icon.name: "qt-logo"
    }
}
