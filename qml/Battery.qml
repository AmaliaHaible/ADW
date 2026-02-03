import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Common 1.0

WidgetWindow {
    id: batteryWindow

    geometryKey: "battery"
    settingsStore: settingsBackend
    editMode: hubBackend.editMode
    hubVisible: hubBackend.hubVisible
    minResizeWidth: 180
    minResizeHeight: 120

    width: 200
    height: 140
    x: 580
    y: 450
    visible: hubBackend.batteryVisible
    title: "Battery"

    Column {
        anchors.fill: parent
        spacing: 0

        TitleBar {
            id: titleBar
            width: parent.width
            title: "Battery"
            dragEnabled: batteryWindow.editMode
            minimized: batteryWindow.minimized
            effectiveRadius: batteryWindow.effectiveWindowRadius
            rightButtons: [
                {icon: batteryWindow.minimized ? "eye.svg" : "eye-off.svg", action: "minimize"}
            ]

            onButtonClicked: function(action) {
                if (action === "minimize") {
                    batteryWindow.toggleMinimize()
                }
            }
        }

        Rectangle {
            width: parent.width
            height: parent.height - titleBar.height
            color: "transparent"
            visible: !batteryWindow.minimized

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.padding
                spacing: Theme.spacing * 1.5

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.spacing / 2
                    spacing: Theme.spacing * 1.5

                    Rectangle {
                        width: 60
                        height: 30
                        radius: 4
                        color: "transparent"
                        border.color: {
                            if (!batteryBackend.hasBattery) return Theme.borderColor
                            if (batteryBackend.percent <= 20) return Theme.colorRed
                            if (batteryBackend.percent <= 50) return Theme.colorYellow
                            return Theme.colorGreen
                        }
                        border.width: 2

                        Rectangle {
                            x: 4
                            y: 4
                            width: (parent.width - 12) * (batteryBackend.percent / 100)
                            height: parent.height - 8
                            radius: 2
                            color: {
                                if (!batteryBackend.hasBattery) return Theme.borderColor
                                if (batteryBackend.percent <= 20) return Theme.colorRed
                                if (batteryBackend.percent <= 50) return Theme.colorYellow
                                return Theme.colorGreen
                            }
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.rightMargin: -6
                            anchors.verticalCenter: parent.verticalCenter
                            width: 4
                            height: 12
                            radius: 2
                            color: Theme.borderColor
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            text: batteryBackend.hasBattery ? batteryBackend.percent + "%" : "No battery"
                            color: Theme.textPrimary
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.Medium
                        }

                        Text {
                            text: batteryBackend.statusText
                            color: Theme.textSecondary
                            font.pixelSize: Theme.fontSizeSmall
                        }
                    }

                    Image {
                        source: iconsPath + batteryBackend.icon
                        sourceSize: Qt.size(24, 24)
                        visible: batteryBackend.isCharging
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: Theme.spacing / 2
                    text: batteryBackend.timeRemainingText
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontSizeNormal
                    visible: batteryBackend.hasBattery
                }

                Item { Layout.fillHeight: true }
            }
        }
    }
}
