import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Common 1.0

WidgetWindow {
    id: weatherWindow

    geometryKey: "weather"
    settingsStore: settingsBackend
    editMode: hubBackend.editMode
    minResizeWidth: 150
    minResizeHeight: 100

    width: 250
    height: 180
    x: 420
    y: 100
    visible: hubBackend.weatherVisible
    title: "Weather"

    Column {
        anchors.fill: parent
        spacing: 0

        // Title bar with settings and refresh on left
        TitleBar {
            id: titleBar
            width: parent.width
            title: "Weather"
            dragEnabled: weatherWindow.editMode
            leftButtons: [
                {icon: "settings.svg", action: "settings", enabled: !hubBackend.editMode},
                {icon: "refresh-cw.svg", action: "refresh", enabled: !hubBackend.editMode}
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
}
