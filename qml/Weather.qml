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
    color: Theme.windowBackground

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

    // Right-click resize in edit mode
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        enabled: hubBackend.editMode
        onPressed: function(mouse) {
            weatherWindow.startSystemResize(Qt.BottomEdge | Qt.RightEdge)
        }
    }

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
            color: Theme.windowBackground

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
}
