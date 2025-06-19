import QtQuick
import QtCore
import QtQuick.Dialogs
import QtQuick.Controls
import QtQuick.Layouts

Item {
    property alias fileOpen: _fileOpen
    property alias aboutQt: _aboutQt
    property alias previewDialog: _previewDialog
    property alias errorDialog: _errorDialog

    FileDialog {
        id: _fileOpen
        title: "Open Video Files"
        currentFolder: StandardPaths.standardLocations(StandardPaths.MoviesLocation)[0]
        nameFilters: ["All AV files(*.mp4 *.avi *.mkv *.mov *.wmv *.ogg *.mp3 *.wav *.flac)",
                        "Video files (*.mp4 *.avi *.mkv *.mov *.wmv)",
                        "Music files (*.ogg *.mp3 *.wav *.flac)"]
        fileMode: FileDialog.OpenFiles
    }

    MessageDialog {
        id: _aboutQt
        title: qsTr("About Qt")
        modality: Qt.WindowModal
        buttons: MessageDialog.Ok
        text: qsTr("This is a video player.")
        informativeText: qsTr("This application uses Qt version 6.9.1")
    }

    Dialog {
        id: _previewDialog

        property CaptureManager captureManager

        title: "Screenshot Preview"
        modal: true
        standardButtons: Dialog.Save | Dialog.Discard
        // Layout.fillWidth: parent.width
        // Layout.fillHeight: parent.height

        background: Rectangle {
            color: "black"
        }

        contentItem: Image {
            id: previewImage
            Layout.fillWidth: parent.width
            Layout.fillHeight: parent.height
            fillMode: Image.PreserveAspectFit
        }


        FileDialog {
            id: saveFileDialog
            title: "Save Screenshot"
            fileMode: FileDialog.SaveFile
            nameFilters: ["PNG Image (*.png)"]
            defaultSuffix: "png"

            property string captureDir: captureManager ?
                        "file://" + captureManager.generateFilePath() : ""

            currentFolder: captureDir
            selectedFile: captureDir + "/screenshot_" +
                                Qt.formatDateTime(new Date(), "yyyyMMdd_hhmmss") + ".png"

            onAccepted: {
                if (_previewDialog.captureManager.saveScreenshot(selectedFile)) {
                    _previewDialog.close();
                } else {
                    _errorDialog.text = "Failed to save file";
                    _errorDialog.open();
                }
            }
        }

        onOpened: {
            previewImage.source = _previewDialog.captureManager ? _previewDialog.captureManager.previewUrl() : ""
        }

        onAccepted: {
            saveFileDialog.open()
        }

        onClosed: {
            if (captureManager) {
                captureManager.removePreviewFile();
            }
        }
    }

    MessageDialog {
        id: _errorDialog
        title: "Error"
        buttons: MessageDialog.Ok
    }
}
