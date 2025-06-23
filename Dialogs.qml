import QtQuick
import QtCore
import QtQuick.Dialogs
import QtQuick.Controls
import QtQuick.Layouts
import VideoPlayer

Item {
    property CaptureManager captureManager
    property alias fileOpen: _fileOpen
    property alias aboutQt: _aboutQt
    property alias previewDialog: _previewDialog
    property alias errorDialog: _errorDialog
    property alias saveLocationDialog: _saveLocationDialog
    property alias cameraSelectDialog: _cameraSelectDialog

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
        title: "Screenshot Preview"
        modal: true
        standardButtons: Dialog.Save | Dialog.Discard

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
                        "file://" + captureManager.generateFilePath(CaptureManager.Screenshot) : ""

            currentFolder: captureDir
            selectedFile: captureDir + "/screenshot_" +
                                Qt.formatDateTime(new Date(), "yyyyMMdd_hhmmss") + ".png"

            onAccepted: {
                if (captureManager.saveScreenshot(selectedFile)) {
                    _previewDialog.close();
                } else {
                    _errorDialog.text = "Failed to save file";
                    _errorDialog.open();
                }
            }
        }

        onOpened: {
            previewImage.source = captureManager ? captureManager.previewUrl() : ""
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

    Dialog {
        id: _saveLocationDialog
        title: "截图与录制保存位置"
        width: 500
        height: 300
        modal: true
        standardButtons: Dialog.Close

        ColumnLayout {
            width: parent.width
            spacing: 15

            // 截图路径
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5

                Label {
                    text: "截图保存位置:"
                    font.bold: true
                    color: "red"
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    color: "white"
                    radius: 5
                    border.color: "gray"

                    Label {
                        anchors.fill: parent
                        anchors.margins: 8
                        text: captureManager ? captureManager.generateFilePath(CaptureManager.Screenshot) : ""
                        elide: Text.ElideMiddle
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            // 录制路径
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5

                Label {
                    text: "录制保存位置:"
                    font.bold: true
                    color: "red"
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    color: "white"
                    radius: 5
                    border.color: "gray"

                    Label {
                        anchors.fill: parent
                        anchors.margins: 8
                        text: captureManager ? captureManager.generateFilePath(CaptureManager.Record) : ""
                        elide: Text.ElideMiddle
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            Label {
                text: "麦克风的选项是决定是否录制时是否录音\n只有在录制前的选择才可改变，录制中更改无法改变"
                font.bold: true
                color: "red"
            }
        }
    }

    Dialog {
        id: _cameraSelectDialog
        title: "Select Camera"
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel

        ColumnLayout {
            width: parent.width

            Label {
                text: "Available Cameras:"
                font.bold: true
            }

            ComboBox {
                id: cameraComboBox
                Layout.fillWidth: true
                textRole: "description"
            }

            Label {
                visible: cameraComboBox.count === 0
                text: "No cameras found"
                color: "red"
            }

            Button {
                text: "flush available"
                Layout.alignment: Qt.AlignRight

                onClicked: {
                    cameraComboBox.model = captureManager.availableCameras
                }
            }
        }

        onOpened: {
            cameraComboBox.model = captureManager ? captureManager.availableCameras : []
        }

        onAccepted: {
           if (cameraComboBox.currentIndex >= 0) {
               var device = cameraComboBox.model[cameraComboBox.currentIndex]
               captureManager.selectCamera(device.id)
           }
       }
   }
}
