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
        captureManager: content.captureManager

        // 鼠标区域控制控制栏和列表显示
        HoverHandler {
            id:mouseHover
            acceptedDevices: PointerDevice.Mouse
            target: parent

            onPointChanged: {
                    // 当鼠标靠近右侧时显示播放列表
                    playlist.visible = (point.position.x > parent.width *(3/4))&&!searchList.visible&&searchBox.length===0
                    searchBox.visible=(point.position.x > parent.width *(3/4))
                    searchList.visible=(point.position.x > parent.width *(3/4))&&!playlist.visible&&searchBox.length!==0
                    playlistcurtain.visible=(point.position.x > parent.width *(3/4))
                    // 当鼠标靠近底部时显示控制栏
                    controlBar.visible = (point.position.y > parent.height - 100)

            }
        }
    }

    //播放列表的搜索框
    TextArea{
        id:searchBox
        anchors.top: parent.top
        width: playlist.width
        anchors.right: parent.right
        visible: false
        height: 30
        placeholderText: "请输入搜索内容(限10字)"
        placeholderTextColor: "gray"
        focus: true

        Keys.onPressed: (event)=>{
                            //确保输入合法
                            if(!/[a-zA-Z0-9]/.test(event.text) && event.key !== Qt.Key_Delete&&event.key !== Qt.Key_Backspace){
                                event.accepted=true
                            }
                            //确保输入内容的大小
                            if(length>=10&&event.key !== Qt.Key_Delete&&event.key !== Qt.Key_Backspace){
                                event.accepted=true
                            }
                        }

        onTextChanged: {
            //根据搜索框的状态改变列表视图
            if(length===0&&searchlistModel.currentIndex!==-1){
                playlist.visible=true
                content.playlistModel.currentIndex= content.playlistModel.indexByUrl(searchlistModel.getUrl(searchlistModel.currentIndex))
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
        onVisibleChanged: {
            if(!visible){
                searchBox.clear()
            }
        }
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
