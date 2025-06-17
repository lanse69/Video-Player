import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    property alias dialogs: _dialogs
    property MediaEngine mediaEngine
    property PlaylistModel playlistModel

    Dialogs{
        id: _dialogs
    }
}
