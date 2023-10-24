// =============================================
// =============== 忽略区域编辑器 ===============
// =============================================

import QtQuick 2.15
import QtQuick.Controls 2.15
import ".."

Rectangle {
    id: iRoot
    visible: false
    color: theme.coverColor4
    property string previewPath: "" // 图片预览路径
    property string previewType: "" // 图片预览路径
    property bool running: false
    property var configsComp: undefined // 设置组件
    property string configKey: "" // 设置组件中忽略区域的key

    // 显示面板
    function show() {
        running = false
        iRoot.visible = true
        let initArea = configsComp.getValue(configKey)
        if(initArea && initArea.length>0) {
            // 读取设置，反格式化
            let ig1 = []
            for(let i=0,l=initArea.length; i<l; i++) {
                const b = initArea[i]
                ig1.push({
                    "x": b[0][0],
                    "y": b[0][1],
                    "width": b[2][0] - b[0][0],
                    "height": b[2][1] - b[0][1],
                })
            }
            imageWithIgnore.ig1Boxes = ig1
        }
    }
    function showPath(path) {
        show()
        imageWithIgnore.showPath(path)
        if(pathPreview) {
            pathPreview(path)
            running = true
        }
    }
    function showImgID(imgID) {
        show()
        imageWithIgnore.showImgID(imgID)
        if(imgIdPreview) {
            imgIdPreview(imgID)
            running = true
        }
    }
    // 关闭面板
    function close() {
        if(imageWithIgnore.ig1Boxes.length > 0) {
            // 格式化，存入设置
            let ig1 = []
            for(let i=0,l=imageWithIgnore.ig1Boxes.length; i<l; i++) {
                const b = imageWithIgnore.ig1Boxes[i]
                ig1.push([[b.x, b.y], [b.x+b.width, b.y],
                    [b.x+b.width, b.y+b.height], [b.x, b.y+b.height]])
            }
            configsComp.setValue(configKey, ig1)
        }
        running = false
        iRoot.visible = false
    }
    // 调用预览函数
    property var pathPreview // (path)
    property var imgIdPreview // (imgID)
    // 获取预览
    function getPreview(res, path="", imgID="") {
        running = false
        if(path) imageWithIgnore.showPath(path)
        else if(imgID) imageWithIgnore.showImgID(imgID)
        imageWithIgnore.showTextBoxes(res)
    }

    MouseArea {
        anchors.fill: parent
        onWheel: {} // 拦截滚轮事件
        hoverEnabled: true // 拦截悬停事件
        onClicked: close() // 单击关闭面板
        cursorShape: Qt.PointingHandCursor
    }
    Loader {
        id: panelLoader
        asynchronous: false // 同步实例化
        sourceComponent: com
        active: iRoot.visible
    }

    property var imageWithIgnore: undefined // 存放图片组件
    Component {
        id: com
        Panel {
            parent: iRoot
            anchors.fill: parent
            anchors.margins: size_.line * 2
            color: theme.bgColor
            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }
            // 左控制栏
            Item {
                id: lCtrl
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: size_.spacing * 2
                width: size_.line * 10

                Column {
                    id: colTop
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: size_.spacing
                    Button_ {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        bgColor_: theme.coverColor1
                        text_: qsTr("保存并返回")
                        onClicked: close()
                    }
                }
                Text_ {
                    anchors.top: colTop.bottom
                    anchors.bottom: colBottom.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.topMargin: size_.spacing
                    anchors.bottomMargin: size_.spacing
                    clip: true
                    wrapMode: TextEdit.Wrap
                    color: theme.subTextColor
                    font.pixelSize: size_.smallText
                    elide: Text.ElideRight // 隐藏超出
                    text: qsTr("拖入本地图片：OCR预览\n滚轮：缩放\n左键：拖拽\n右键：绘制忽略区域\n\n可绘制一个或多个忽略区域矩形框。在执行批量OCR时，完全位于忽略区域内的文本块将被排除。\n比如批量处理影视截图时，可在右上角水印处添加忽略区域，避免输出水印文本。")
                }
                Column {
                    id: colBottom
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: size_.spacing
                    Text_ {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        font.pixelSize: size_.smallText
                        color: theme.subTextColor
                        text: qsTr("图像尺寸：")+imageWithIgnore.imageSW+"×"+imageWithIgnore.imageSH
                    }
                    Text_ {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        font.pixelSize: size_.smallText
                        color: theme.subTextColor
                        text: qsTr("区域数量：")+imageWithIgnore.ig1Boxes.length
                    }
                    Button_ {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        bgColor_: theme.coverColor1
                        text_: qsTr("撤销")
                        onClicked: imageWithIgnore.revokeIg()
                    }
                    Button_ {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        bgColor_: theme.coverColor1
                        textColor_: theme.noColor
                        text_: qsTr("清空")
                        onClicked: imageWithIgnore.clearIg()
                    }
                }
            }
            // 右图片组件
            ImageWithIgnore {
                id: imageWithIgnore
                anchors.left: lCtrl.right
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: size_.spacing
                anchors.leftMargin: size_.spacing * 2

                Component.onCompleted: {
                    iRoot.imageWithIgnore = this
                }

                // 加载图标
                Loading{
                    anchors.centerIn: parent
                    visible: running
                }
            }
            // 文件拖拽
            DropArea_ {
                anchors.fill: parent
                callback: (paths)=>{
                    paths = qmlapp.utilsConnector.findImages(paths, false)
                    if(paths && paths.length > 0) {
                        showPath(paths[0])
                    }
                }
            }
        }
    }
}