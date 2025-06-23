.pragma library
//初始化弹幕渲染器
var count=100
var remainList=[]
var runningList=[]

//管理text的状态（是否被分配）
function push(text)
{
    remainList.push(text)
}

function popRun(text)
{
    let i=runningList.indexOf(text)
    remainList.push(text)
    runningList.splice(i,1)
    count++
}

function popRemain()
{
    count--
    let i=remainList.pop()
    runningList.push(i)
}

//弹幕渲染
function danmusRender(danmus)
{
    for(let i of danmus){
        count--
        let text=remainList.pop()
        text.start(i[0],i[1],i[2],i[3],i[4])
        runningList.push(text)
    }
}

//弹幕提前结束
function endDanmus()
{
    for(let i of runningList){
        i.animation.stop()
    }
}

//清除指定弹幕
function destroy(text){
    let i=remainList.indexOf(text)
    if(i>-1){
        remainList.splice(i,1)
    }else{
        i=runningList.indexOf(text)
        runningList.splice(i,1)
    }
}
