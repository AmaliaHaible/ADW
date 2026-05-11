import QtQuick 2.15
import Qt5Compat.GraphicalEffects
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
        anchors.fill: parent
        source: iconName ? iconsPath + iconName : ""
        sourceSize: Qt.size(size, size)
        fillMode: Image.PreserveAspectFit
        layer.enabled: true
        layer.effect: ColorOverlay {
            color: root.customColor
        }
    }
}
