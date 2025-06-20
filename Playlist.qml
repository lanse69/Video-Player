import QtQuick
import QtQuick.Controls

//播放列表
ScrollView {
    id:scoll
    property PlaylistModel playlist
    width: parent.width*(1/4)      //位于播放器右侧
    height: parent.height
    visible: false
    anchors.right: parent.right
    clip: true


    ListView {
        id: listView
        anchors.fill: parent
        model: playlist
        clip: true
        currentIndex:playlist.currentIndex

        // 添加位移过渡动画：使所有项都有平滑动画
        displaced: Transition {
            NumberAnimation {
                properties: "x,y"
                duration: 200
                easing.type: Easing.OutQuad
            }
        }

        delegate: Rectangle {
            id:delegateItem
            width: scoll.width
            height: 50
            color:index ===listView.currentIndex? "skyblue":"white"  //当前视图项变蓝
            opacity: 0.8
            property int preIndex:-1
            Label{
                color: "black"
                verticalAlignment: Text.AlignVCenter
                anchors.fill: parent
                text: model.title
            }

            //鼠标点击时的处理
            TapHandler{
                target: parent
                onTapped: {
                    if(!itemDrag.active){
                        playlist.currentIndex=index
                    }
                }
            }
            //拖拽实现
            DragHandler{
                id:itemDrag
                target: parent
                enabled: true
                xAxis.enabled:false
                onActiveChanged: {
                    if(!active){
                        delegateItem.y=index*50     //松开后按照当前索引固定位置
                        delegateItem.z=0
                    }else{
                        preIndex=index              //拖拽时将当前项置顶
                        delegateItem.z=listView.z+2
                    }
                }
            }

            //拖拽点移动时执行move函数
            HoverHandler{
                id:dragPoint
                target:parent
                enabled: itemDrag.active
                acceptedDevices: PointerDevice.Mouse
                onPointChanged: {
                        // 计算当前拖拽位置对应的新索引
                        var newIndex = Math.floor((delegateItem.y+delegateItem.height*(1/2))/50)
                        if(newIndex>listView.count-1) newIndex=listView.count-1
                        else if(newIndex<0) newIndex=0
                        // 有效范围且位置发生变化时才移动
                        if (newIndex !== -1 && newIndex !== preIndex) {
                            playlist.move(preIndex, newIndex, 1)
                            preIndex = newIndex
                        }
                }
            }

        }
    }
}
