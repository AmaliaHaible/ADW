import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Common 1.0

WidgetWindow {
    id: hubWindow

    geometryKey: "hub"
    settingsStore: settingsBackend
    editMode: hubBackend.editMode
    hubVisible: true  // Hub always counts as visible for window flags
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

    // Track hub visibility changes
    onVisibleChanged: {
        hubBackend.setHubVisible(visible)
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
                {icon: "eye-off.svg", action: "hide"},
                {icon: "x.svg", action: "exit"}
            ]

            onButtonClicked: function(action) {
                if (action === "hide") {
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

                    // Always on top toggle
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
                                source: iconsPath + "arrow-up.svg"
                                sourceSize: Qt.size(20, 20)
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                            }

                            Text {
                                text: "Always on Top"
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSizeNormal
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 20
                                radius: 10
                                color: hubBackend.alwaysOnTop ? Theme.accentColor : Theme.accentInactive
                                border.color: hubBackend.alwaysOnTop ? Theme.accentColor : Theme.borderColor
                                border.width: 1

                                Rectangle {
                                    x: hubBackend.alwaysOnTop ? parent.width - width - 2 : 2
                                    y: 2
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: Theme.textPrimary
                                    Behavior on x { NumberAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: hubBackend.setAlwaysOnTop(!hubBackend.alwaysOnTop)
                                }
                            }
                        }
                    }

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
                        id: weatherToggle
                        property bool widgetEnabled: enabledWidgets && enabledWidgets.weather === true

                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        radius: Theme.borderRadius
                        color: Theme.surfaceColor
                        opacity: widgetEnabled ? 1.0 : 0.5

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
                                font.strikeout: !weatherToggle.widgetEnabled
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
                                    enabled: weatherToggle.widgetEnabled
                                    onClicked: hubBackend.setWeatherVisible(!hubBackend.weatherVisible)
                                }
                            }
                        }
                    }

                    // Media control widget toggle
                    Rectangle {
                        id: mediaToggle
                        property bool widgetEnabled: enabledWidgets && enabledWidgets.media === true

                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        radius: Theme.borderRadius
                        color: Theme.surfaceColor
                        opacity: widgetEnabled ? 1.0 : 0.5

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.padding
                            anchors.rightMargin: Theme.padding
                            spacing: Theme.spacing

                            Image {
                                source: iconsPath + "music.svg"
                                sourceSize: Qt.size(20, 20)
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                            }

                            Text {
                                text: "Media Control"
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSizeNormal
                                font.strikeout: !mediaToggle.widgetEnabled
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 20
                                radius: 10
                                color: hubBackend.mediaVisible ? Theme.accentColor : Theme.accentInactive
                                border.color: hubBackend.mediaVisible ? Theme.accentColor : Theme.borderColor
                                border.width: 1

                                Rectangle {
                                    x: hubBackend.mediaVisible ? parent.width - width - 2 : 2
                                    y: 2
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: Theme.textPrimary
                                    Behavior on x { NumberAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: mediaToggle.widgetEnabled
                                    onClicked: hubBackend.setMediaVisible(!hubBackend.mediaVisible)
                                }
                            }
                        }
                    }

                    // Theme widget toggle
                    Rectangle {
                        id: settingsToggle
                        property bool widgetEnabled: enabledWidgets && enabledWidgets.general_settings === true

                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        radius: Theme.borderRadius
                        color: Theme.surfaceColor
                        opacity: widgetEnabled ? 1.0 : 0.5

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
                                text: "General Settings"
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSizeNormal
                                font.strikeout: !settingsToggle.widgetEnabled
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
                                    enabled: settingsToggle.widgetEnabled
                                    onClicked: hubBackend.setThemeVisible(!hubBackend.themeVisible)
                                }
                            }
                        }
                    }

                    // Todo widget toggle
                    Rectangle {
                        id: todoToggle
                        property bool widgetEnabled: enabledWidgets && enabledWidgets.todo === true

                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        radius: Theme.borderRadius
                        color: Theme.surfaceColor
                        opacity: widgetEnabled ? 1.0 : 0.5

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.padding
                            anchors.rightMargin: Theme.padding
                            spacing: Theme.spacing

                            Image {
                                source: iconsPath + "list-todo.svg"
                                sourceSize: Qt.size(20, 20)
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                            }

                            Text {
                                text: "Todo"
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSizeNormal
                                font.strikeout: !todoToggle.widgetEnabled
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 20
                                radius: 10
                                color: hubBackend.todoVisible ? Theme.accentColor : Theme.accentInactive
                                border.color: hubBackend.todoVisible ? Theme.accentColor : Theme.borderColor
                                border.width: 1

                                Rectangle {
                                    x: hubBackend.todoVisible ? parent.width - width - 2 : 2
                                    y: 2
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: Theme.textPrimary
                                    Behavior on x { NumberAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: todoToggle.widgetEnabled
                                    onClicked: hubBackend.setTodoVisible(!hubBackend.todoVisible)
                                }
                            }
                        }
                    }

                    // Notes widget toggle
                    Rectangle {
                        id: notesToggle
                        property bool widgetEnabled: enabledWidgets && enabledWidgets.notes === true

                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        radius: Theme.borderRadius
                        color: Theme.surfaceColor
                        opacity: widgetEnabled ? 1.0 : 0.5

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.padding
                            anchors.rightMargin: Theme.padding
                            spacing: Theme.spacing

                            Image {
                                source: iconsPath + "sticky-note.svg"
                                sourceSize: Qt.size(20, 20)
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                            }

                            Text {
                                text: "Notes"
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSizeNormal
                                font.strikeout: !notesToggle.widgetEnabled
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 20
                                radius: 10
                                color: hubBackend.notesVisible ? Theme.accentColor : Theme.accentInactive
                                border.color: hubBackend.notesVisible ? Theme.accentColor : Theme.borderColor
                                border.width: 1

                                Rectangle {
                                    x: hubBackend.notesVisible ? parent.width - width - 2 : 2
                                    y: 2
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: Theme.textPrimary
                                    Behavior on x { NumberAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: notesToggle.widgetEnabled
                                    onClicked: hubBackend.setNotesVisible(!hubBackend.notesVisible)
                                }
                            }
                        }
                    }

                    // Pomodoro widget toggle
                    Rectangle {
                        id: pomodoroToggle
                        property bool widgetEnabled: enabledWidgets && enabledWidgets.pomodoro === true

                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        radius: Theme.borderRadius
                        color: Theme.surfaceColor
                        opacity: widgetEnabled ? 1.0 : 0.5

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.padding
                            anchors.rightMargin: Theme.padding
                            spacing: Theme.spacing

                            Image {
                                source: iconsPath + "timer.svg"
                                sourceSize: Qt.size(20, 20)
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                            }

                            Text {
                                text: "Pomodoro"
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSizeNormal
                                font.strikeout: !pomodoroToggle.widgetEnabled
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 20
                                radius: 10
                                color: hubBackend.pomodoroVisible ? Theme.accentColor : Theme.accentInactive
                                border.color: hubBackend.pomodoroVisible ? Theme.accentColor : Theme.borderColor
                                border.width: 1

                                Rectangle {
                                    x: hubBackend.pomodoroVisible ? parent.width - width - 2 : 2
                                    y: 2
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: Theme.textPrimary
                                    Behavior on x { NumberAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: pomodoroToggle.widgetEnabled
                                    onClicked: hubBackend.setPomodoroVisible(!hubBackend.pomodoroVisible)
                                }
                            }
                        }
                    }

                    // Launcher widget toggle
                    Rectangle {
                        id: launcherToggle
                        property bool widgetEnabled: enabledWidgets && enabledWidgets.launcher === true

                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        radius: Theme.borderRadius
                        color: Theme.surfaceColor
                        opacity: widgetEnabled ? 1.0 : 0.5

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.padding
                            anchors.rightMargin: Theme.padding
                            spacing: Theme.spacing

                            Image {
                                source: iconsPath + "rocket.svg"
                                sourceSize: Qt.size(20, 20)
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                            }

                            Text {
                                text: "Launcher"
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSizeNormal
                                font.strikeout: !launcherToggle.widgetEnabled
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 20
                                radius: 10
                                color: hubBackend.launcherVisible ? Theme.accentColor : Theme.accentInactive
                                border.color: hubBackend.launcherVisible ? Theme.accentColor : Theme.borderColor
                                border.width: 1

                                Rectangle {
                                    x: hubBackend.launcherVisible ? parent.width - width - 2 : 2
                                    y: 2
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: Theme.textPrimary
                                    Behavior on x { NumberAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: launcherToggle.widgetEnabled
                                    onClicked: hubBackend.setLauncherVisible(!hubBackend.launcherVisible)
                                }
                            }
                        }
                    }

                    // System Monitor widget toggle
                    Rectangle {
                        id: sysMonToggle
                        property bool widgetEnabled: enabledWidgets && enabledWidgets.system_monitor === true

                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        radius: Theme.borderRadius
                        color: Theme.surfaceColor
                        opacity: widgetEnabled ? 1.0 : 0.5

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.padding
                            anchors.rightMargin: Theme.padding
                            spacing: Theme.spacing

                            Image {
                                source: iconsPath + "cpu.svg"
                                sourceSize: Qt.size(20, 20)
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                            }

                            Text {
                                text: "System"
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSizeNormal
                                font.strikeout: !sysMonToggle.widgetEnabled
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 20
                                radius: 10
                                color: hubBackend.systemMonitorVisible ? Theme.accentColor : Theme.accentInactive
                                border.color: hubBackend.systemMonitorVisible ? Theme.accentColor : Theme.borderColor
                                border.width: 1

                                Rectangle {
                                    x: hubBackend.systemMonitorVisible ? parent.width - width - 2 : 2
                                    y: 2
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: Theme.textPrimary
                                    Behavior on x { NumberAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: sysMonToggle.widgetEnabled
                                    onClicked: hubBackend.setSystemMonitorVisible(!hubBackend.systemMonitorVisible)
                                }
                            }
                        }
                    }

                    // Network Monitor widget toggle
                    Rectangle {
                        id: netMonToggle
                        property bool widgetEnabled: enabledWidgets && enabledWidgets.network_monitor === true

                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        radius: Theme.borderRadius
                        color: Theme.surfaceColor
                        opacity: widgetEnabled ? 1.0 : 0.5

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.padding
                            anchors.rightMargin: Theme.padding
                            spacing: Theme.spacing

                            Image {
                                source: iconsPath + "wifi.svg"
                                sourceSize: Qt.size(20, 20)
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                            }

                            Text {
                                text: "Network"
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSizeNormal
                                font.strikeout: !netMonToggle.widgetEnabled
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 20
                                radius: 10
                                color: hubBackend.networkMonitorVisible ? Theme.accentColor : Theme.accentInactive
                                border.color: hubBackend.networkMonitorVisible ? Theme.accentColor : Theme.borderColor
                                border.width: 1

                                Rectangle {
                                    x: hubBackend.networkMonitorVisible ? parent.width - width - 2 : 2
                                    y: 2
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: Theme.textPrimary
                                    Behavior on x { NumberAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: netMonToggle.widgetEnabled
                                    onClicked: hubBackend.setNetworkMonitorVisible(!hubBackend.networkMonitorVisible)
                                }
                            }
                        }
                    }

                    // Battery widget toggle
                    Rectangle {
                        id: batteryToggle
                        property bool widgetEnabled: enabledWidgets && enabledWidgets.battery === true

                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        radius: Theme.borderRadius
                        color: Theme.surfaceColor
                        opacity: widgetEnabled ? 1.0 : 0.5

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.padding
                            anchors.rightMargin: Theme.padding
                            spacing: Theme.spacing

                            Image {
                                source: iconsPath + "battery.svg"
                                sourceSize: Qt.size(20, 20)
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                            }

                            Text {
                                text: "Battery"
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSizeNormal
                                font.strikeout: !batteryToggle.widgetEnabled
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 20
                                radius: 10
                                color: hubBackend.batteryVisible ? Theme.accentColor : Theme.accentInactive
                                border.color: hubBackend.batteryVisible ? Theme.accentColor : Theme.borderColor
                                border.width: 1

                                Rectangle {
                                    x: hubBackend.batteryVisible ? parent.width - width - 2 : 2
                                    y: 2
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: Theme.textPrimary
                                    Behavior on x { NumberAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: batteryToggle.widgetEnabled
                                    onClicked: hubBackend.setBatteryVisible(!hubBackend.batteryVisible)
                                }
                            }
                        }
                    }

                    // News widget toggle
                    Rectangle {
                        id: newsToggle
                        property bool widgetEnabled: enabledWidgets && enabledWidgets.news === true

                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        radius: Theme.borderRadius
                        color: Theme.surfaceColor
                        opacity: widgetEnabled ? 1.0 : 0.5

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.padding
                            anchors.rightMargin: Theme.padding
                            spacing: Theme.spacing

                            Image {
                                source: iconsPath + "newspaper.svg"
                                sourceSize: Qt.size(20, 20)
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                            }

                            Text {
                                text: "News"
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSizeNormal
                                font.strikeout: !newsToggle.widgetEnabled
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                Layout.preferredWidth: 40
                                Layout.preferredHeight: 20
                                radius: 10
                                color: hubBackend.newsVisible ? Theme.accentColor : Theme.accentInactive
                                border.color: hubBackend.newsVisible ? Theme.accentColor : Theme.borderColor
                                border.width: 1

                                Rectangle {
                                    x: hubBackend.newsVisible ? parent.width - width - 2 : 2
                                    y: 2
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: Theme.textPrimary
                                    Behavior on x { NumberAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    enabled: newsToggle.widgetEnabled
                                    onClicked: hubBackend.setNewsVisible(!hubBackend.newsVisible)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
