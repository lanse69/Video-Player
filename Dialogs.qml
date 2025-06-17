import QtQuick
import QtCore
import QtQuick.Dialogs

Item {
    property alias fileOpen: _fileOpen
    property alias aboutQt: _aboutQt

    FileDialog {
        id: _fileOpen
        title: "Open Video Files"
        currentFolder: StandardPaths.standardLocations(StandardPaths.MoviesLocation)[0]
        nameFilters: ["All files(*.mp4 *.avi *.mkv *.mov *.wmv *.ogg *.mp3)", "Video files (*.mp4 *.avi *.mkv *.mov *.wmv)", "Music files (*.ogg *.mp3)"]
        fileMode: FileDialog.OpenFiles
    }

    MessageDialog {
        id: _aboutQt
        title: "About Qt"
        modality: Qt.WindowModal
        buttons: MessageDialog.Ok
        text: "Qt " + Qt.platform.os + " version"
        informativeText: "This application uses Qt version " + Qt.runtimeVersion
    }
}
