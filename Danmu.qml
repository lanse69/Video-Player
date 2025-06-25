import QtQuick
import "DanmuRender.js" as DanmuRender

Text {
    id:text
    visible:false
    color: "white"
    property var animation: animation
    font.family: "DejaVu Sans Mono"
    font.pixelSize: 20
    //交给弹幕渲染器管理
    Component.onCompleted: {
        text.x=-text.width
        DanmuRender.push(text)
    }
    Component.onDestruction: {
        DanmuRender.destroy(text)
    }

    //弹幕用动画实现
    NumberAnimation on x{
        id:animation
        onFinished: {
            text.visible=false
        }
    }

    //弹幕开始渲染
    function start(x,y,endx,content,time){
        text.visible=true
        DanmuRender.popRemain()
        text.text=content
        text.y=y
        animation.from=x
        animation.to=endx
        animation.duration=time
        animation.start()
    }
    onVisibleChanged: {
        if(!visible){
            DanmuRender.popRun(text)
        }
    }
}
