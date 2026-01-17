import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Common 1.0

Rectangle {
    id: titleBar

    property string title: "Window"
    property bool showMinimize: true
    property bool showClose: true
    property url minimizeIcon: iconsPath + "minimize.svg"
    property url closeIcon: iconsPath + "x.svg"
    property bool dragEnabled: true

    signal closeClicked()
    signal minimizeClicked()

    height: Theme.titleBarHeight
    color: Theme.titleBarBackground

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
        spacing: 0

        // Title text
        Text {
            text: titleBar.title
            color: Theme.titleBarText
            font.pixelSize: Theme.fontSizeTitle
            font.weight: Font.Medium
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        // Minimize button
        Rectangle {
            id: minimizeButton
            visible: titleBar.showMinimize
            width: Theme.buttonSize
            height: Theme.buttonSize
            radius: 4
            color: minimizeMouseArea.containsMouse
                   ? (minimizeMouseArea.pressed ? Theme.titleBarButtonPressed : Theme.titleBarButtonHover)
                   : "transparent"

            Image {
                anchors.centerIn: parent
                width: 14
                height: 14
                source: titleBar.minimizeIcon
                sourceSize: Qt.size(14, 14)
            }

            MouseArea {
                id: minimizeMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: titleBar.minimizeClicked()
            }
        }

        // Spacer between buttons
        Item {
            width: Theme.spacing / 2
            visible: titleBar.showMinimize && titleBar.showClose
        }

        // Close button
        Rectangle {
            id: closeButton
            visible: titleBar.showClose
            width: Theme.buttonSize
            height: Theme.buttonSize
            radius: 4
            color: closeMouseArea.containsMouse
                   ? (closeMouseArea.pressed ? Theme.titleBarButtonPressed : Theme.titleBarButtonHover)
                   : "transparent"

            Image {
                anchors.centerIn: parent
                width: 14
                height: 14
                source: titleBar.closeIcon
                sourceSize: Qt.size(14, 14)
            }

            MouseArea {
                id: closeMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: titleBar.closeClicked()
            }
        }
    }
}
