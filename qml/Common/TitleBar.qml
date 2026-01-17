import QtQuick 
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Common 1.0

Rectangle {
    id: titleBar

    property string title: "Window"
    property bool dragEnabled: true

    // Button configurations: [{icon: "name.svg", action: "actionName"}]
    property var leftButtons: []
    property var rightButtons: []

    // Signals for button actions
    signal buttonClicked(string action)

    height: Theme.titleBarHeight

    color: Theme.titleBarBackground
    topRightRadius: Theme.windowRadius 
    topLeftRadius: Theme.windowRadius 

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
                width: Theme.buttonSize
                height: Theme.buttonSize
                radius: 4
                color: leftMouseArea.containsMouse
                       ? (leftMouseArea.pressed ? Theme.titleBarButtonPressed : Theme.titleBarButtonHover)
                       : "transparent"

                Image {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    source: iconsPath + modelData.icon
                    sourceSize: Qt.size(14, 14)
                }

                MouseArea {
                    id: leftMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
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
                width: Theme.buttonSize
                height: Theme.buttonSize
                radius: 4
                color: rightMouseArea.containsMouse
                       ? (rightMouseArea.pressed ? Theme.titleBarButtonPressed : Theme.titleBarButtonHover)
                       : "transparent"

                Image {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    source: iconsPath + modelData.icon
                    sourceSize: Qt.size(14, 14)
                }

                MouseArea {
                    id: rightMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: titleBar.buttonClicked(modelData.action)
                }
            }
        }
    }
}
