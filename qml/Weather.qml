import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Common 1.0

Window {
    id: weatherWindow

    width: settingsBackend ? settingsBackend.getWidgetGeometry("weather").width : 250
    height: settingsBackend ? settingsBackend.getWidgetGeometry("weather").height : 180
    x: settingsBackend ? settingsBackend.getWidgetGeometry("weather").x : 420
    y: settingsBackend ? settingsBackend.getWidgetGeometry("weather").y : 100
    visible: hubBackend.weatherVisible
    title: "Weather"
    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.NoDropShadowWindowHint
    color: "transparent"

    onXChanged: if (visible) saveGeometryTimer.restart()
    onYChanged: if (visible) saveGeometryTimer.restart()
    onWidthChanged: if (visible) saveGeometryTimer.restart()
    onHeightChanged: if (visible) saveGeometryTimer.restart()

    Timer {
        id: saveGeometryTimer
        interval: 500
        onTriggered: {
            if (settingsBackend) {
                settingsBackend.setWidgetGeometry("weather", weatherWindow.x, weatherWindow.y, weatherWindow.width, weatherWindow.height)
            }
        }
    }

    // Main container with border radius
    Rectangle {
        anchors.fill: parent
        color: Theme.windowBackground
        radius: Theme.windowRadius

        Column {
            anchors.fill: parent
            spacing: 0

            // Title bar with settings and refresh on left
            TitleBar {
                id: titleBar
                width: parent.width
                title: "Weather"
                dragEnabled: hubBackend.editMode
                leftButtons: [
                    {icon: "settings.svg", action: "settings"},
                    {icon: "refresh-cw.svg", action: "refresh"}
                ]

                onButtonClicked: function(action) {
                    if (action === "settings") {
                        console.log("Weather settings clicked")
                    } else if (action === "refresh") {
                        console.log("Weather refresh clicked")
                    }
                }
            }

            // Content area
            Rectangle {
                width: parent.width
                height: parent.height - titleBar.height
                color: "transparent"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.padding
                    spacing: Theme.spacing

                    // Weather icon placeholder
                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 64
                        Layout.preferredHeight: 64

                        Image {
                            anchors.centerIn: parent
                            source: iconsPath + "sun.svg"
                            sourceSize: Qt.size(48, 48)
                            width: 48
                            height: 48
                        }
                    }

                    // Temperature placeholder
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "22°C"
                        color: Theme.textPrimary
                        font.pixelSize: Theme.fontSizeLarge * 2
                        font.weight: Font.Light
                    }

                    // Location placeholder
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Weather Widget"
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSizeNormal
                    }

                    // Spacer
                    Item {
                        Layout.fillHeight: true
                    }
                }
            }
        }

        // Edit mode overlay - blocks all interactions and handles resize
        Rectangle {
            id: editOverlay
            anchors.fill: parent
            color: "transparent"
            visible: hubBackend.editMode
            radius: Theme.windowRadius

            property point resizeStartPos
            property size resizeStartSize
            property point dragStartPos
            property point windowStartPos

            // Visual indicator for edit mode
            Rectangle {
                anchors.fill: parent
                color: Theme.accentColor
                opacity: 0.1
                radius: Theme.windowRadius
            }

            // Border highlight in edit mode
            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: Theme.accentColor
                border.width: 2
                radius: Theme.windowRadius
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton | Qt.LeftButton
                hoverEnabled: true

                onPressed: function(mouse) {
                    if (mouse.button === Qt.RightButton) {
                        editOverlay.resizeStartPos = Qt.point(mouse.x, mouse.y)
                        editOverlay.resizeStartSize = Qt.size(weatherWindow.width, weatherWindow.height)
                    } else if (mouse.button === Qt.LeftButton) {
                        editOverlay.dragStartPos = Qt.point(mouse.x, mouse.y)
                        editOverlay.windowStartPos = Qt.point(weatherWindow.x, weatherWindow.y)
                    }
                }

                onPositionChanged: function(mouse) {
                    if (pressedButtons & Qt.RightButton) {
                        var deltaX = mouse.x - editOverlay.resizeStartPos.x
                        var deltaY = mouse.y - editOverlay.resizeStartPos.y
                        weatherWindow.width = Math.max(150, editOverlay.resizeStartSize.width + deltaX)
                        weatherWindow.height = Math.max(100, editOverlay.resizeStartSize.height + deltaY)
                    } else if (pressedButtons & Qt.LeftButton) {
                        var dx = mouse.x - editOverlay.dragStartPos.x
                        var dy = mouse.y - editOverlay.dragStartPos.y
                        weatherWindow.x = editOverlay.windowStartPos.x + dx
                        weatherWindow.y = editOverlay.windowStartPos.y + dy
                    }
                }
            }
        }
    }
}
