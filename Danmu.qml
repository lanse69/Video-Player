import QtQuick
import "DanmuRender.js" as DanmuRender

Text {
    id:text
    visible:false
    property var animation: animation
    font.family: "DejaVu Sans Mono"
    font.pixelSize: 40
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
            DanmuRender.popRun(text)
        }
    }

    //弹幕开始渲染
    function start(x,y,endx,content,time){
        text.visible=true
        DanmuRender.popRemain()
        text.text=content
        animation.from=x
        animation.to=endx
        animation.duration=time
        animation.start()
        console.log(x,y,endx,content,time)
    }
}
