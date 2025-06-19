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

    ListView {
        id: listView
        anchors.fill: parent
        model: playlist
        clip: true
        currentIndex:playlist.currentIndex
        delegate: ItemDelegate {
            id:delegateItem
            width: scoll.width
            height: 50
            text: model.title
            highlighted: index ===listView.currentIndex   //当前视图项高亮

            Rectangle{
                id:itemRec
                anchors.fill: delegateItem
                color: "black"
                opacity: 0.3
            }                //通过mousearea完成拖拽排序
            MouseArea{
                id:dragArea
                anchors.fill: parent
                property int preIndex:-1
                drag{
                    target: parent
                    axis: Drag.YAxis
                    threshold: 10
                }
                onPressed:{                 //按下鼠标计时器开始计时，并把当前点击项置顶
                    timer.start()
                    delegateItem.z=10
                }
                onReleased: {               //松开鼠标，计时器结束，判断是否为长按或点击
                    timer.stop()
                    if(timer.isPress){
                        timer.isPress=false
                        delegateItem.z=0
                        delegateItem.y=index*50     //松开后按照当前索引固定位置
                    }else{
                        playlist.currentIndex=index      //将被点击项设为当前播放项
                    }
                }
                // 拖拽过程
                onPositionChanged: {
                    console.log(listView.currentIndex)
                    if (dragArea.drag.active) {
                        // 计算当前拖拽位置对应的新索引
                        var newIndex = Math.floor((delegateItem.y+delegateItem.height*(1/2))/50)

                        // 有效范围且位置发生变化时才移动
                        if (newIndex !== -1 && newIndex !== preIndex) {
                            playlist.move(preIndex, newIndex, 1)
                            preIndex = newIndex
                        }
                    }
                }
                Timer{
                    id:timer
                    property bool isPress: false
                    interval: 300
                    repeat: true
                    running: false

                    onTriggered:{
                        isPress=true
                        dragArea.preIndex=index
                    }
                }

                // states: State {
                //     when:dragArea.drag.active       //拖拽时改变拖拽项的父对象，以此实现计数
                //     ParentChange {
                //         target: itemRec
                //         parent: listView
                //     }
                // }
            }
        }
    }
}
