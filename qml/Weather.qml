import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Common 1.0

Window {
    id: weatherWindow

    width: 250
    height: 180
    visible: hubBackend.weatherVisible
    title: "Weather"
    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.NoDropShadowWindowHint
    color: Theme.windowBackground

    Column {
        anchors.fill: parent
        spacing: 0

        // Title bar
        TitleBar {
            id: titleBar
            width: parent.width
            title: "Weather"
            showMinimize: false
            dragEnabled: hubBackend.editMode

            onCloseClicked: {
                hubBackend.setWeatherVisible(false)
            }
        }

        // Content area
        Rectangle {
            width: parent.width
            height: parent.height - titleBar.height
            color: Theme.windowBackground
            radius: Theme.borderRadius

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
