import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Common 1.0

WidgetWindow {
    id: hubWindow

    geometryKey: "hub"
    settingsStore: settingsBackend
    editMode: hubBackend.editMode
    editOverlayEnabled: false
    minResizeWidth: 200
    minResizeHeight: 150

    width: 300
    height: 300
    x: 100
    y: 100
    visible: true
    title: "Widget Hub"

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
            rightButtons: [
                {icon: "eye-off.svg", action: "minimize"},
                {icon: "x.svg", action: "exit"}
            ]

            onButtonClicked: function(action) {
                if (action === "minimize") {
                    hubBackend.setEditMode(false)
                    hubWindow.hide()
                } else if (action === "exit") {
                    hubBackend.exitApp()
                }
            }
        }

        // Content area
        Rectangle {
            width: parent.width
            height: parent.height - titleBar.height
            color: "transparent"

            ScrollView {
                anchors.fill: parent
                anchors.margins: Theme.padding
                clip: true
                contentWidth: availableWidth

                ColumnLayout {
                    width: parent.width
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

                            Rectangle {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 20
                                radius: 10
                                color: hubBackend.editMode ? Theme.accentColor : Theme.accentInactive
                                border.color: hubBackend.editMode ? Theme.accentColor : Theme.borderColor
                                border.width: 1

                                Rectangle {
                                    x: hubBackend.editMode ? parent.width - width - 2 : 2
                                    y: 2
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: Theme.textPrimary
                                    Behavior on x { NumberAnimation { duration: 150 } }
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
                                text: "Weather"
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSizeNormal
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 20
                                radius: 10
                                color: hubBackend.weatherVisible ? Theme.accentColor : Theme.accentInactive
                                border.color: hubBackend.weatherVisible ? Theme.accentColor : Theme.borderColor
                                border.width: 1

                                Rectangle {
                                    x: hubBackend.weatherVisible ? parent.width - width - 2 : 2
                                    y: 2
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: Theme.textPrimary
                                    Behavior on x { NumberAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: hubBackend.setWeatherVisible(!hubBackend.weatherVisible)
                                }
                            }
                        }
                    }

                    // Theme widget toggle
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
                                source: iconsPath + "palette.svg"
                                sourceSize: Qt.size(20, 20)
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                            }

                            Text {
                                text: "Theme Editor"
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSizeNormal
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 20
                                radius: 10
                                color: hubBackend.themeVisible ? Theme.accentColor : Theme.accentInactive
                                border.color: hubBackend.themeVisible ? Theme.accentColor : Theme.borderColor
                                border.width: 1

                                Rectangle {
                                    x: hubBackend.themeVisible ? parent.width - width - 2 : 2
                                    y: 2
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: Theme.textPrimary
                                    Behavior on x { NumberAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: hubBackend.setThemeVisible(!hubBackend.themeVisible)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
