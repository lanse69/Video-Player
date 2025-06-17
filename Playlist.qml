import QtQuick
import QtQuick.Controls

Rectangle {
    property PlaylistModel playlist
    width: 200
    height: parent.height
    color: "#66000000"
    visible: false
    anchors.right: parent.right

    ListView {
        id: listView
        anchors.fill: parent
        model: playlist
        clip: true

        delegate: ItemDelegate {
            width: parent.width
            text: playlist.data(playlist.index(currentIndex, 0), playlist.TitleRole)
            highlighted: index === playlist.currentIndex

            onClicked: {
                playlist.currentIndex = index
            }
        }
    }
}
