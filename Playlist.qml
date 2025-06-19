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

    Flickable {
        boundsBehavior: Flickable.StopAtBounds // 禁止拖动越界
    }

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
            }


            MouseArea{                                  //通过mousearea完成拖拽排序
                id:dragArea
                anchors.fill: parent
                property int preIndex:-1
                drag{
                    target:timer.isPress?  parent:null
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
                    }else{
                        playlist.currentIndex=index
                    }
                    delegateItem.y=index*50     //松开后按照当前索引固定位置
                }
                Timer{
                    id:timer
                    property bool isPress: false
                    interval: 100
                    repeat: true
                    running: false

                    onTriggered:{     //拖拽的初始化
                        isPress=true
                    }
                }
                // 拖拽过程
                onPositionChanged: {
                    if (dragArea.drag.active) {
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
}
