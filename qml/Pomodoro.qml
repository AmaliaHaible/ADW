import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Common 1.0

WidgetWindow {
    id: pomodoroWindow

    geometryKey: "pomodoro"
    settingsStore: settingsBackend
    editMode: hubBackend.editMode
    hubVisible: hubBackend.hubVisible
    minResizeWidth: 200
    minResizeHeight: 250

    width: 220
    height: 300
    x: 1320
    y: 100
    visible: hubBackend.pomodoroVisible
    title: "Pomodoro"

    property bool showSettings: false

    Column {
        anchors.fill: parent
        spacing: 0

        TitleBar {
            id: titleBar
            width: parent.width
            title: pomodoroWindow.showSettings ? "Settings" : "Pomodoro"
            dragEnabled: pomodoroWindow.editMode
            minimized: pomodoroWindow.minimized
            effectiveRadius: pomodoroWindow.effectiveWindowRadius
            leftButtons: pomodoroWindow.showSettings ? [
                {icon: "arrow-left.svg", action: "back", enabled: !hubBackend.editMode}
            ] : [
                {icon: "settings.svg", action: "settings", enabled: !hubBackend.editMode}
            ]
            rightButtons: [
                {icon: "eye-off.svg", action: "minimize"}
            ]

            onButtonClicked: function(action) {
                if (action === "minimize") {
                    pomodoroWindow.toggleMinimize()
                } else if (action === "settings") {
                    pomodoroWindow.showSettings = true
                } else if (action === "back") {
                    pomodoroWindow.showSettings = false
                }
            }
        }

        Rectangle {
            width: parent.width
            height: parent.height - titleBar.height
            color: "transparent"
            visible: !pomodoroWindow.minimized

            StackLayout {
                anchors.fill: parent
                currentIndex: pomodoroWindow.showSettings ? 1 : 0

                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.padding
                        spacing: Theme.spacing

                        Item { Layout.fillHeight: true }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 140
                            height: 140
                            radius: 70
                            color: "transparent"
                            border.color: {
                                if (pomodoroBackend.state === "work") return Theme.error
                                if (pomodoroBackend.state === "break" || pomodoroBackend.state === "long_break") return Theme.success
                                return Theme.borderColor
                            }
                            border.width: 4

                            Rectangle {
                                anchors.centerIn: parent
                                width: 130
                                height: 130
                                radius: 65
                                color: Theme.surfaceColor

                                Canvas {
                                    id: progressCanvas
                                    anchors.fill: parent
                                    rotation: -90

                                    onPaint: {
                                        var ctx = getContext("2d")
                                        ctx.clearRect(0, 0, width, height)

                                        if (pomodoroBackend.progress > 0) {
                                            ctx.beginPath()
                                            ctx.arc(width/2, height/2, 60, 0, Math.PI * 2 * pomodoroBackend.progress)
                                            ctx.strokeStyle = pomodoroBackend.state === "work" ? Theme.error : Theme.success
                                            ctx.lineWidth = 6
                                            ctx.lineCap = "round"
                                            ctx.stroke()
                                        }
                                    }

                                    Connections {
                                        target: pomodoroBackend
                                        function onProgressChanged() {
                                            progressCanvas.requestPaint()
                                        }
                                    }
                                }

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: pomodoroBackend.timeRemainingText
                                        color: Theme.textPrimary
                                        font.pixelSize: 28
                                        font.weight: Font.Light
                                    }

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: {
                                            switch (pomodoroBackend.state) {
                                                case "work": return "Focus"
                                                case "break": return "Break"
                                                case "long_break": return "Long Break"
                                                case "paused": return "Paused"
                                                default: return "Ready"
                                            }
                                        }
                                        color: Theme.textSecondary
                                        font.pixelSize: Theme.fontSizeSmall
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: Theme.spacing

                            Rectangle {
                                width: 40
                                height: 40
                                radius: 20
                                color: stopArea.containsMouse ? Theme.borderColor : Theme.surfaceColor
                                visible: pomodoroBackend.state !== "idle"

                                Image {
                                    anchors.centerIn: parent
                                    source: iconsPath + "square.svg"
                                    sourceSize: Qt.size(18, 18)
                                }

                                MouseArea {
                                    id: stopArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: pomodoroBackend.stop()
                                }
                            }

                            Rectangle {
                                width: 50
                                height: 50
                                radius: 25
                                color: playArea.containsMouse ? Theme.accentHover : Theme.accentColor

                                Image {
                                    anchors.centerIn: parent
                                    source: {
                                        if (pomodoroBackend.state === "idle") return iconsPath + "play.svg"
                                        if (pomodoroBackend.state === "paused") return iconsPath + "play.svg"
                                        return iconsPath + "pause.svg"
                                    }
                                    sourceSize: Qt.size(22, 22)
                                }

                                MouseArea {
                                    id: playArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        if (pomodoroBackend.state === "idle") {
                                            pomodoroBackend.startWork()
                                        } else if (pomodoroBackend.state === "paused") {
                                            pomodoroBackend.resume()
                                        } else {
                                            pomodoroBackend.pause()
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                width: 40
                                height: 40
                                radius: 20
                                color: skipArea.containsMouse ? Theme.borderColor : Theme.surfaceColor
                                visible: pomodoroBackend.state !== "idle"

                                Image {
                                    anchors.centerIn: parent
                                    source: iconsPath + "skip-forward.svg"
                                    sourceSize: Qt.size(18, 18)
                                }

                                MouseArea {
                                    id: skipArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: pomodoroBackend.skip()
                                }
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Sessions today: " + pomodoroBackend.sessionsToday
                            color: Theme.textSecondary
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                Item {
                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: Theme.padding
                        contentWidth: availableWidth
                        clip: true

                        ColumnLayout {
                            width: parent.width
                            spacing: Theme.spacing

                            Text {
                                text: "Work Duration (min)"
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSizeNormal
                            }

                            SpinBox {
                                id: workSpinBox
                                Layout.fillWidth: true
                                from: 1
                                to: 60
                                value: pomodoroBackend.workDuration
                                onValueModified: pomodoroBackend.setWorkDuration(value)

                                contentItem: TextInput {
                                    text: workSpinBox.value
                                    color: Theme.textPrimary
                                    font.pixelSize: Theme.fontSizeNormal
                                    horizontalAlignment: Qt.AlignHCenter
                                    verticalAlignment: Qt.AlignVCenter
                                    readOnly: true
                                }

                                up.indicator: Rectangle {
                                    x: workSpinBox.width - width
                                    height: workSpinBox.height / 2
                                    implicitWidth: 24
                                    implicitHeight: 20
                                    color: workSpinBox.up.pressed ? Theme.borderColor : Theme.surfaceColor
                                    border.color: Theme.borderColor

                                    Text {
                                        text: "+"
                                        font.pixelSize: Theme.fontSizeNormal
                                        color: Theme.textPrimary
                                        anchors.centerIn: parent
                                    }
                                }

                                down.indicator: Rectangle {
                                    x: workSpinBox.width - width
                                    y: workSpinBox.height / 2
                                    height: workSpinBox.height / 2
                                    implicitWidth: 24
                                    implicitHeight: 20
                                    color: workSpinBox.down.pressed ? Theme.borderColor : Theme.surfaceColor
                                    border.color: Theme.borderColor

                                    Text {
                                        text: "-"
                                        font.pixelSize: Theme.fontSizeNormal
                                        color: Theme.textPrimary
                                        anchors.centerIn: parent
                                    }
                                }

                                background: Rectangle {
                                    color: Theme.surfaceColor
                                    border.color: Theme.borderColor
                                    border.width: 1
                                    radius: Theme.borderRadius
                                }
                            }

                            Text {
                                text: "Break Duration (min)"
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSizeNormal
                            }

                            SpinBox {
                                id: breakSpinBox
                                Layout.fillWidth: true
                                from: 1
                                to: 30
                                value: pomodoroBackend.breakDuration
                                onValueModified: pomodoroBackend.setBreakDuration(value)

                                contentItem: TextInput {
                                    text: breakSpinBox.value
                                    color: Theme.textPrimary
                                    font.pixelSize: Theme.fontSizeNormal
                                    horizontalAlignment: Qt.AlignHCenter
                                    verticalAlignment: Qt.AlignVCenter
                                    readOnly: true
                                }

                                up.indicator: Rectangle {
                                    x: breakSpinBox.width - width
                                    height: breakSpinBox.height / 2
                                    implicitWidth: 24
                                    implicitHeight: 20
                                    color: breakSpinBox.up.pressed ? Theme.borderColor : Theme.surfaceColor
                                    border.color: Theme.borderColor

                                    Text {
                                        text: "+"
                                        font.pixelSize: Theme.fontSizeNormal
                                        color: Theme.textPrimary
                                        anchors.centerIn: parent
                                    }
                                }

                                down.indicator: Rectangle {
                                    x: breakSpinBox.width - width
                                    y: breakSpinBox.height / 2
                                    height: breakSpinBox.height / 2
                                    implicitWidth: 24
                                    implicitHeight: 20
                                    color: breakSpinBox.down.pressed ? Theme.borderColor : Theme.surfaceColor
                                    border.color: Theme.borderColor

                                    Text {
                                        text: "-"
                                        font.pixelSize: Theme.fontSizeNormal
                                        color: Theme.textPrimary
                                        anchors.centerIn: parent
                                    }
                                }

                                background: Rectangle {
                                    color: Theme.surfaceColor
                                    border.color: Theme.borderColor
                                    border.width: 1
                                    radius: Theme.borderRadius
                                }
                            }

                            Text {
                                text: "Long Break (min)"
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSizeNormal
                            }

                            SpinBox {
                                id: longBreakSpinBox
                                Layout.fillWidth: true
                                from: 1
                                to: 60
                                value: pomodoroBackend.longBreakDuration
                                onValueModified: pomodoroBackend.setLongBreakDuration(value)

                                contentItem: TextInput {
                                    text: longBreakSpinBox.value
                                    color: Theme.textPrimary
                                    font.pixelSize: Theme.fontSizeNormal
                                    horizontalAlignment: Qt.AlignHCenter
                                    verticalAlignment: Qt.AlignVCenter
                                    readOnly: true
                                }

                                up.indicator: Rectangle {
                                    x: longBreakSpinBox.width - width
                                    height: longBreakSpinBox.height / 2
                                    implicitWidth: 24
                                    implicitHeight: 20
                                    color: longBreakSpinBox.up.pressed ? Theme.borderColor : Theme.surfaceColor
                                    border.color: Theme.borderColor

                                    Text {
                                        text: "+"
                                        font.pixelSize: Theme.fontSizeNormal
                                        color: Theme.textPrimary
                                        anchors.centerIn: parent
                                    }
                                }

                                down.indicator: Rectangle {
                                    x: longBreakSpinBox.width - width
                                    y: longBreakSpinBox.height / 2
                                    height: longBreakSpinBox.height / 2
                                    implicitWidth: 24
                                    implicitHeight: 20
                                    color: longBreakSpinBox.down.pressed ? Theme.borderColor : Theme.surfaceColor
                                    border.color: Theme.borderColor

                                    Text {
                                        text: "-"
                                        font.pixelSize: Theme.fontSizeNormal
                                        color: Theme.textPrimary
                                        anchors.centerIn: parent
                                    }
                                }

                                background: Rectangle {
                                    color: Theme.surfaceColor
                                    border.color: Theme.borderColor
                                    border.width: 1
                                    radius: Theme.borderRadius
                                }
                            }

                            Text {
                                text: "Sessions for Long Break"
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSizeNormal
                            }

                            SpinBox {
                                id: sessionsSpinBox
                                Layout.fillWidth: true
                                from: 1
                                to: 10
                                value: pomodoroBackend.sessionsBeforeLongBreak
                                onValueModified: pomodoroBackend.setSessionsBeforeLongBreak(value)

                                contentItem: TextInput {
                                    text: sessionsSpinBox.value
                                    color: Theme.textPrimary
                                    font.pixelSize: Theme.fontSizeNormal
                                    horizontalAlignment: Qt.AlignHCenter
                                    verticalAlignment: Qt.AlignVCenter
                                    readOnly: true
                                }

                                up.indicator: Rectangle {
                                    x: sessionsSpinBox.width - width
                                    height: sessionsSpinBox.height / 2
                                    implicitWidth: 24
                                    implicitHeight: 20
                                    color: sessionsSpinBox.up.pressed ? Theme.borderColor : Theme.surfaceColor
                                    border.color: Theme.borderColor

                                    Text {
                                        text: "+"
                                        font.pixelSize: Theme.fontSizeNormal
                                        color: Theme.textPrimary
                                        anchors.centerIn: parent
                                    }
                                }

                                down.indicator: Rectangle {
                                    x: sessionsSpinBox.width - width
                                    y: sessionsSpinBox.height / 2
                                    height: sessionsSpinBox.height / 2
                                    implicitWidth: 24
                                    implicitHeight: 20
                                    color: sessionsSpinBox.down.pressed ? Theme.borderColor : Theme.surfaceColor
                                    border.color: Theme.borderColor

                                    Text {
                                        text: "-"
                                        font.pixelSize: Theme.fontSizeNormal
                                        color: Theme.textPrimary
                                        anchors.centerIn: parent
                                    }
                                }

                                background: Rectangle {
                                    color: Theme.surfaceColor
                                    border.color: Theme.borderColor
                                    border.width: 1
                                    radius: Theme.borderRadius
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                Layout.topMargin: Theme.spacing
                                radius: Theme.borderRadius
                                color: resetArea.containsMouse ? Theme.borderColor : Theme.surfaceColor

                                Text {
                                    anchors.centerIn: parent
                                    text: "Reset Session Count"
                                    color: Theme.textPrimary
                                    font.pixelSize: Theme.fontSizeNormal
                                }

                                MouseArea {
                                    id: resetArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: pomodoroBackend.resetSessionCount()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
