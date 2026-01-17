import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Common 1.0

Window {
    id: hubWindow

    width: settingsBackend ? settingsBackend.getWidgetGeometry("hub").width : 300
    height: settingsBackend ? settingsBackend.getWidgetGeometry("hub").height : 300
    x: settingsBackend ? settingsBackend.getWidgetGeometry("hub").x : 100
    y: settingsBackend ? settingsBackend.getWidgetGeometry("hub").y : 100
    visible: true
    title: "Widget Hub"
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
                settingsBackend.setWidgetGeometry("hub", hubWindow.x, hubWindow.y, hubWindow.width, hubWindow.height)
            }
        }
    }

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

    // Resize tracking for Hub
    property point resizeStartPos
    property size resizeStartSize

    // Main container with border radius
    Rectangle {
        anchors.fill: parent
        color: Theme.windowBackground
        radius: Theme.windowRadius

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
                    {icon: "minimize.svg", action: "minimize"},
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

                            Rectangle {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 20
                                radius: 10
                                color: hubBackend.editMode ? Theme.accentColor : Theme.accentInactive
                                border.color: hubBackend.editMode ? Theme.accentColor : Theme.textMuted
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
                                border.color: hubBackend.weatherVisible ? Theme.accentColor : Theme.textMuted
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
                                border.color: hubBackend.themeVisible ? Theme.accentColor : Theme.textMuted
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

                    // Spacer
                    Item {
                        Layout.fillHeight: true
                    }
                }
            }
        }

        // Right-click resize handler for Hub (only in edit mode)
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            enabled: hubBackend.editMode
            z: 100

            onPressed: function(mouse) {
                hubWindow.resizeStartPos = Qt.point(mouse.x, mouse.y)
                hubWindow.resizeStartSize = Qt.size(hubWindow.width, hubWindow.height)
            }

            onPositionChanged: function(mouse) {
                if (pressedButtons & Qt.RightButton) {
                    var deltaX = mouse.x - hubWindow.resizeStartPos.x
                    var deltaY = mouse.y - hubWindow.resizeStartPos.y
                    hubWindow.width = Math.max(200, hubWindow.resizeStartSize.width + deltaX)
                    hubWindow.height = Math.max(150, hubWindow.resizeStartSize.height + deltaY)
                }
            }
        }
    }
}
