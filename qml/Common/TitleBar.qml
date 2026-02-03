import QtQuick 
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Common 1.0

Rectangle {
    id: titleBar

    property string title: "Window"
    property bool dragEnabled: true
    property bool minimized: false
    property real effectiveRadius: Theme.windowRadius

    // Button configurations: [{icon: "name.svg", action: "actionName", enabled: bool}]
    property var leftButtons: []
    property var rightButtons: []

    // Derived sizes from titleBarHeight
    readonly property int buttonSize: Theme.titleBarHeight - 8
    readonly property int iconSize: Math.round(buttonSize * 0.58)

    // Signals for button actions
    signal buttonClicked(string action)

    height: Theme.titleBarHeight

    color: Theme.titleBarBackground
    topRightRadius: effectiveRadius
    topLeftRadius: effectiveRadius
    bottomLeftRadius: minimized ? effectiveRadius : 0
    bottomRightRadius: minimized ? effectiveRadius : 0 

    // Drag handler for moving the window
    DragHandler {
        enabled: titleBar.dragEnabled
        target: null
        onActiveChanged: {
            if (active) {
                titleBar.Window.window.startSystemMove()
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.padding
        anchors.rightMargin: Theme.spacing
        spacing: Theme.spacing / 2

        // Left buttons
        Repeater {
            model: titleBar.leftButtons

            Rectangle {
                width: titleBar.buttonSize
                height: titleBar.buttonSize
                radius: 4
                color: leftMouseArea.containsMouse && leftMouseArea.enabled
                       ? (leftMouseArea.pressed ? Theme.titleBarButtonPressed : Theme.titleBarButtonHover)
                       : "transparent"

                Image {
                    anchors.centerIn: parent
                    width: titleBar.iconSize
                    height: titleBar.iconSize
                    source: iconsPath + modelData.icon
                    sourceSize: Qt.size(titleBar.iconSize, titleBar.iconSize)
                }

                MouseArea {
                    id: leftMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: modelData.enabled === undefined ? true : modelData.enabled
                    onClicked: titleBar.buttonClicked(modelData.action)
                }
            }
        }

        // Title text
        Text {
            text: titleBar.title
            color: Theme.titleBarText
            font.pixelSize: Theme.fontSizeTitle
            font.weight: Font.Medium
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        // Right buttons
        Repeater {
            model: titleBar.rightButtons

            Rectangle {
                width: titleBar.buttonSize
                height: titleBar.buttonSize
                radius: 4
                color: rightMouseArea.containsMouse && rightMouseArea.enabled
                       ? (rightMouseArea.pressed ? Theme.titleBarButtonPressed : Theme.titleBarButtonHover)
                       : "transparent"

                Image {
                    anchors.centerIn: parent
                    width: titleBar.iconSize
                    height: titleBar.iconSize
                    source: iconsPath + modelData.icon
                    sourceSize: Qt.size(titleBar.iconSize, titleBar.iconSize)
                }

                MouseArea {
                    id: rightMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: modelData.enabled === undefined ? true : modelData.enabled
                    onClicked: titleBar.buttonClicked(modelData.action)
                }
            }
        }
    }
}
