import QtQuick 2.15
import Common 1.0

Item {
    id: root

    property string iconName: ""
    property int size: 24
    property color customColor: Theme.symbolColor

    implicitWidth: size
    implicitHeight: size

    Image {
        id: sourceImage
        source: iconName ? iconsPath + iconName : ""
        sourceSize: Qt.size(size, size)
        visible: false
    }

    ColorOverlay {
        anchors.fill: parent
        source: sourceImage
        color: root.customColor
        visible: root.iconName !== ""
    }
}
