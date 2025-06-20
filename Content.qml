import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import VideoPlayer

Item {
    id:content
    property MediaEngine mediaEngine
    property PlaylistModel playlistModel
    property CaptureManager captureManager
    property alias dialogs: _dialogs
    property alias player: _player
    property alias controlBar: _controlBar

    Dialogs {
        id: _dialogs
        captureManager: content.captureManager
    }

    // 视频播放区域
    Player {
        id: _player
        anchors.fill: parent
        mediaEngine: content.mediaEngine

        // 鼠标区域控制控制栏和列表显示
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            KeyNavigation.backtab: parent

            onPositionChanged: {
                // 当鼠标靠近右侧时显示播放列表
                playlist.visible = (mouseX > parent.width *(3/4))&&!searchList.visible&&searchBox.length===0
                searchBox.visible=(mouseX > parent.width *(3/4))
                searchList.visible=(mouseX > parent.width *(3/4))&&!playlist.visible&&searchBox.length!==0
                playlistcurtain.visible=(mouseX > parent.width *(3/4))
                // 当鼠标靠近底部时显示控制栏
                controlBar.visible = (mouseY > parent.height - 100)
            }

            onDoubleClicked: { // 双击全屏
                if (window.visibility === ApplicationWindow.FullScreen) {
                    window.showNormal()
                    menuBar.visible = true  // 退出全屏时显示菜单栏
                } else {
                    window.showFullScreen()
                    menuBar.visible = false // 进入全屏时隐藏菜单栏
                }
            }
        }
    }

    //播放列表的搜索框
    TextArea{
        id:searchBox
        anchors.top: parent.top
        width: playlist.width
        anchors.right: parent.right
        height: 30
        placeholderText: "请输入搜索内容(限10字)"
        placeholderTextColor: "gray"


        onTextChanged: {
            //确保输入最多十个字
            if(length>10){
                remove(9,length-1)
            }
            //根据搜索框的状态改变列表视图
            if(length===0){
                playlist.visible=true
                searchList.visible=false
            }else{
                playlist.visible=false
                searchList.visible=true
                searchlistModel.clear()
                searchlistModel.currentIndex=-1
                searchlistModel.addMedias(playlistModel.search(text))
            }
        }

    }

    // 播放列表（右侧）
    Playlist {
        id: playlist
        anchors {
            top: searchBox.bottom
            right: parent.right
            bottom: parent.bottom
        }
        playlist: content.playlistModel
    }

    //搜索播放列表
    Playlist {
        id: searchList
        anchors {
            top: searchBox.bottom
            right: parent.right
            bottom: parent.bottom
        }
        visible: false
        playlist: searchlistModel
    }

    //搜索播放列表的数据项
    PlaylistModel{
        id: searchlistModel
        onCurrentIndexChanged: {
            if (searchlistModel.currentIndex >= 0) {
                var mediaUrl = getUrl(currentIndex)
                if (mediaUrl) {
                    mediaEngine.setMedia(mediaUrl)
                    mediaEngine.play()
                    var title = searchlistModel.data(searchlistModel.index(searchlistModel.currentIndex,0),PlaylistModel.TitleRole)
                    if (title) {
                        window.title = "Video Player - "+title
                    }
                }
            }
        }
    }

    //播放列表的底层
    Rectangle{
        id:playlistcurtain
        width: parent.width*(1/4)
        height: playlist.height
        visible: false
        anchors.top: searchBox.bottom
        anchors.right: parent.right
        color: "black"
        opacity: 0.2
    }

    // 控制栏（底部）
    ControlBar {
        id: _controlBar
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        mediaEngine: content.mediaEngine
        playlistModel: content.playlistModel
        captureManager: content.captureManager
    }

    Connections {
        target: dialogs.fileOpen

        function onAccepted() {
            playlistModel.addMedias(dialogs.fileOpen.selectedFiles)
            for(let i of dialogs.fileOpen.selectedFiles){
                histroyListModel.setHistroy(i)
            }
        }
    }
}
