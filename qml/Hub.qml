import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Common 1.0

Window {
    id: hubWindow

    width: 300
    height: 250
    visible: true
    title: "Widget Hub"
    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.NoDropShadowWindowHint
    color: Theme.windowBackground

    // Handle show request from tray
    Connections {
        target: hubBackend
        function onShowHubRequested() {
            hubWindow.show()
            hubWindow.raise()
            hubWindow.requestActivate()
        }
        function onExitRequested() {
            Qt.quit()
        }
    }

    Column {
        anchors.fill: parent
        spacing: 0

        // Title bar
        TitleBar {
            id: titleBar
            width: parent.width
            title: "Widget Hub"
            dragEnabled: hubBackend.editMode

            onMinimizeClicked: {
                hubWindow.hide()
            }
            onCloseClicked: {
                hubBackend.exitApp()
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

                // Edit mode toggle
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    radius: Theme.borderRadius
                    color: Theme.surfaceColor

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.padding
                        anchors.rightMargin: Theme.padding
                        spacing: Theme.spacing

                        Image {
                            source: iconsPath + "move.svg"
                            sourceSize: Qt.size(20, 20)
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                        }

                        Text {
                            text: "Edit Mode"
                            color: Theme.textPrimary
                            font.pixelSize: Theme.fontSizeNormal
                            Layout.fillWidth: true
                        }

                        // Custom toggle
                        Rectangle {
                            id: editToggle
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 20
                            radius: 10
                            color: hubBackend.editMode ? Theme.accentColor : Theme.titleBarBackground
                            border.color: hubBackend.editMode ? Theme.accentColor : Theme.textMuted
                            border.width: 1

                            Rectangle {
                                x: hubBackend.editMode ? parent.width - width - 2 : 2
                                y: 2
                                width: 16
                                height: 16
                                radius: 8
                                color: Theme.textPrimary

                                Behavior on x {
                                    NumberAnimation { duration: 150 }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: hubBackend.setEditMode(!hubBackend.editMode)
                            }
                        }
                    }
                }

                // Weather widget toggle
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    radius: Theme.borderRadius
                    color: Theme.surfaceColor

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.padding
                        anchors.rightMargin: Theme.padding
                        spacing: Theme.spacing

                        Image {
                            source: iconsPath + "sun.svg"
                            sourceSize: Qt.size(20, 20)
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                        }

                        Text {
                            text: "Weather Widget"
                            color: Theme.textPrimary
                            font.pixelSize: Theme.fontSizeNormal
                            Layout.fillWidth: true
                        }

                        // Custom toggle
                        Rectangle {
                            id: weatherToggle
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 20
                            radius: 10
                            color: hubBackend.weatherVisible ? Theme.accentColor : Theme.titleBarBackground
                            border.color: hubBackend.weatherVisible ? Theme.accentColor : Theme.textMuted
                            border.width: 1

                            Rectangle {
                                x: hubBackend.weatherVisible ? parent.width - width - 2 : 2
                                y: 2
                                width: 16
                                height: 16
                                radius: 8
                                color: Theme.textPrimary

                                Behavior on x {
                                    NumberAnimation { duration: 150 }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: hubBackend.setWeatherVisible(!hubBackend.weatherVisible)
                            }
                        }
                    }
                }

                // Spacer
                Item {
                    Layout.fillHeight: true
                }
            }
        }
    }
}
