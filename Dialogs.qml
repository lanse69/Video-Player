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
    property alias recordingLayoutDialog: _recordingLayoutDialog
    property alias timedPauseDialog: _timedPauseDialog

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

            Label {
                text: "录制时功能键会出现在下方工具栏里\n录屏：录制时显示红色\n拍摄：录制时显示绿色"
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

    // 录制布局选择对话框
    Dialog {
        id: _recordingLayoutDialog
        title: "录制布局设置"
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel
        width: 400

        ColumnLayout {
            spacing: 15
            width: parent.width

            Label {
                text: "选择录制时播放画面的显示方式:"
                font.bold: true
            }

            ButtonGroup {
                id: layoutGroup
            }

            RadioButton {
                text: "关闭播放画面"
                ButtonGroup.group: layoutGroup
                checked: true
            }

            RadioButton {
                text: "左右分框 (播放器 | 摄像头)"
                ButtonGroup.group: layoutGroup
            }

            RadioButton {
                text: "上下分框 (播放器 / 摄像头)"
                ButtonGroup.group: layoutGroup
            }

            RadioButton {
                text: "小窗模式 (摄像头主画面，播放器小窗)"
                ButtonGroup.group: layoutGroup
            }

            CheckBox {
                id: rememberChoice
                text: "记住我的选择"
                checked: true
            }
        }

        onAccepted: {
            var layout = CaptureManager.LayoutNull;
            if (layoutGroup.buttons[1].checked) layout = CaptureManager.SideBySide;
            else if (layoutGroup.buttons[2].checked) layout = CaptureManager.TopBottom;
            else if (layoutGroup.buttons[0].checked) layout = CaptureManager.Pip;
            else if (layoutGroup.buttons[3].checked) layout = CaptureManager.NotVideo;

            captureManager.playerLayout = layout;

            if(captureManager.setCamera()){
                mediaEngine.pause()
                captureManager.startCameraRecording()
            }
        }
    }

    // 定时暂停
    Dialog {
        id: _timedPauseDialog
        title: qsTr("Set Pause time")
        modal: true

        ColumnLayout {
            width: parent.width
            Button {
                Layout.fillWidth: parent
                text: qsTr("Cancel Timed Pause")
                onClicked: timedPause(0)
            }

            Button {
                Layout.fillWidth: parent
                text: qsTr("5:00")
                onClicked: timedPause(5)
            }

            Button {
                Layout.fillWidth: parent
                text: qsTr("15:00")
                onClicked: timedPause(15)
            }

            Button {
                Layout.fillWidth: parent
                text: qsTr("30:00")
                onClicked: timedPause(30)
            }

            Button {
                Layout.fillWidth: parent
                text: qsTr("60:00")
                onClicked: timedPause(60)
            }

            Button {
                Layout.fillWidth: parent
                text: qsTr("Custom")
                onClicked: {
                    _timedPauseDialog.close()
                    customTimedPauseDialog.open()
                }
            }
        }
    }

    Dialog { // 自定义定时暂停
        id: customTimedPauseDialog
        title: "Custom Timed Pause"
        standardButtons: Dialog.Ok | Dialog.Cancel
        ColumnLayout {
            RowLayout {
                Label {
                    text: "Hours:"
                    Layout.preferredWidth: 60
                }

                SpinBox {
                    id: hoursInput
                    from: 0
                    to: 24
                    value: 0
                }
            }

            RowLayout {
                Label {
                    text: "Minutes:"
                    Layout.preferredWidth: 60
                }

                SpinBox {
                    id: minutesInput
                    from: 0
                    to: 59
                    value: 0
                }
            }
        }

        onOpened: {
            var minutes = mediaEngine.pauseTime();
            if (minutes > 0) { // 如果有已设置的定时暂停时间，初始化对话框值
                hoursInput.value = Math.floor(minutes / 60)
                minutesInput.value = minutes % 60
            } else {
                hoursInput.value = 0;
                minutesInput.value = 0;
            }
        }

        onAccepted: {
            var totalMinutes = hoursInput.value * 60 + minutesInput.value
            if (totalMinutes > 0) {
                mediaEngine.timedPauseStart(totalMinutes)
                showTimedPauseNotification(totalMinutes)
            } else {
                mediaEngine.timedPauseStart(0)
                showTimedPauseNotification(0)
            }
        }
    }

    function timedPause(minutes) {
        mediaEngine.timedPauseStart(minutes);
        _timedPauseDialog.close();
        showTimedPauseNotification(minutes);
    }

    // 定时暂停设置通知
    Dialog {
        id: timedPauseNotification
        width: 200
        height: 30

        property alias text : notificationText.text
        Text {
            id: notificationText
        }
    }

    function showTimedPauseNotification(minutes) {
        if (minutes > 0) {
            timedPauseNotification.text = "Timed puase acivited";
        } else {
            timedPauseNotification.text = "Cancel timed pause";
        }
        timedPauseNotification.open();
    }

    Timer {
        interval: 2000
        running: timedPauseNotification.opened
        onTriggered: timedPauseNotification.close()
    }
}
