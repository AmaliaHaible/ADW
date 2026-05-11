import QtQuick 2.15
import Common 1.0

Rectangle {
    id: root

    property string icon: ""
    property int iconSize: 24
    property string style: "hover-only"
    property color customColor: Theme.symbolColor
    property int buttonSize: 32
    property bool enabled: true

    signal clicked()

    width: buttonSize
    height: buttonSize
    radius: 4
    color: {
        if (!root.enabled) return "transparent"
        return mouseArea.pressed ? Theme.titleBarButtonPressed :
               (mouseArea.containsMouse ? Theme.titleBarButtonHover : "transparent")
    }

    ThemedIcon {
        anchors.centerIn: parent
        iconName: root.icon
        size: root.iconSize
        customColor: root.customColor
        opacity: root.enabled ? 1.0 : 0.5
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        onClicked: root.clicked()
    }
}
