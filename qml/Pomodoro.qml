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
                                if (pomodoroBackend.state === "work") return Theme.colorRed
                                if (pomodoroBackend.state === "break" || pomodoroBackend.state === "long_break") return Theme.colorGreen
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
                                            ctx.strokeStyle = pomodoroBackend.state === "work" ? Theme.colorRed : Theme.colorGreen
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
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.padding
                        spacing: Theme.spacing

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: Theme.spacing
                            rowSpacing: Theme.spacing

                            Text {
                                text: "Work"
                                color: Theme.textSecondary
                                font.pixelSize: Theme.fontSizeSmall
                                Layout.alignment: Qt.AlignVCenter
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: Theme.borderRadius
                                    color: workDown.pressed ? Theme.accentColor : (workDown.containsMouse ? Theme.borderColor : Theme.surfaceColor)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "-"
                                        color: Theme.textPrimary
                                        font.pixelSize: 14
                                    }

                                    MouseArea {
                                        id: workDown
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: if (pomodoroBackend.workDuration > 1) pomodoroBackend.setWorkDuration(pomodoroBackend.workDuration - 1)
                                    }
                                }

                                TextField {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 28
                                    text: pomodoroBackend.workDuration
                                    color: Theme.textPrimary
                                    font.pixelSize: Theme.fontSizeNormal
                                    horizontalAlignment: Qt.AlignHCenter
                                    verticalAlignment: Qt.AlignVCenter
                                    topPadding: 0
                                    bottomPadding: 0
                                    inputMethodHints: Qt.ImhDigitsOnly
                                    validator: IntValidator { bottom: 1; top: 60 }

                                    background: Rectangle {
                                        color: Theme.surfaceColor
                                        border.color: parent.activeFocus ? Theme.accentColor : Theme.borderColor
                                        border.width: 1
                                        radius: Theme.borderRadius
                                    }

                                    onEditingFinished: {
                                        var val = parseInt(text)
                                        if (val >= 1 && val <= 60) pomodoroBackend.setWorkDuration(val)
                                        else text = pomodoroBackend.workDuration
                                    }
                                }

                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: Theme.borderRadius
                                    color: workUp.pressed ? Theme.accentColor : (workUp.containsMouse ? Theme.borderColor : Theme.surfaceColor)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "+"
                                        color: Theme.textPrimary
                                        font.pixelSize: 14
                                    }

                                    MouseArea {
                                        id: workUp
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: if (pomodoroBackend.workDuration < 60) pomodoroBackend.setWorkDuration(pomodoroBackend.workDuration + 1)
                                    }
                                }
                            }

                            Text {
                                text: "Break"
                                color: Theme.textSecondary
                                font.pixelSize: Theme.fontSizeSmall
                                Layout.alignment: Qt.AlignVCenter
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: Theme.borderRadius
                                    color: breakDown.pressed ? Theme.accentColor : (breakDown.containsMouse ? Theme.borderColor : Theme.surfaceColor)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "-"
                                        color: Theme.textPrimary
                                        font.pixelSize: 14
                                    }

                                    MouseArea {
                                        id: breakDown
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: if (pomodoroBackend.breakDuration > 1) pomodoroBackend.setBreakDuration(pomodoroBackend.breakDuration - 1)
                                    }
                                }

                                TextField {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 28
                                    text: pomodoroBackend.breakDuration
                                    color: Theme.textPrimary
                                    font.pixelSize: Theme.fontSizeNormal
                                    horizontalAlignment: Qt.AlignHCenter
                                    verticalAlignment: Qt.AlignVCenter
                                    topPadding: 0
                                    bottomPadding: 0
                                    inputMethodHints: Qt.ImhDigitsOnly
                                    validator: IntValidator { bottom: 1; top: 30 }

                                    background: Rectangle {
                                        color: Theme.surfaceColor
                                        border.color: parent.activeFocus ? Theme.accentColor : Theme.borderColor
                                        border.width: 1
                                        radius: Theme.borderRadius
                                    }

                                    onEditingFinished: {
                                        var val = parseInt(text)
                                        if (val >= 1 && val <= 30) pomodoroBackend.setBreakDuration(val)
                                        else text = pomodoroBackend.breakDuration
                                    }
                                }

                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: Theme.borderRadius
                                    color: breakUp.pressed ? Theme.accentColor : (breakUp.containsMouse ? Theme.borderColor : Theme.surfaceColor)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "+"
                                        color: Theme.textPrimary
                                        font.pixelSize: 14
                                    }

                                    MouseArea {
                                        id: breakUp
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: if (pomodoroBackend.breakDuration < 30) pomodoroBackend.setBreakDuration(pomodoroBackend.breakDuration + 1)
                                    }
                                }
                            }

                            Text {
                                text: "Long Break"
                                color: Theme.textSecondary
                                font.pixelSize: Theme.fontSizeSmall
                                Layout.alignment: Qt.AlignVCenter
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: Theme.borderRadius
                                    color: longDown.pressed ? Theme.accentColor : (longDown.containsMouse ? Theme.borderColor : Theme.surfaceColor)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "-"
                                        color: Theme.textPrimary
                                        font.pixelSize: 14
                                    }

                                    MouseArea {
                                        id: longDown
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: if (pomodoroBackend.longBreakDuration > 1) pomodoroBackend.setLongBreakDuration(pomodoroBackend.longBreakDuration - 1)
                                    }
                                }

                                TextField {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 28
                                    text: pomodoroBackend.longBreakDuration
                                    color: Theme.textPrimary
                                    font.pixelSize: Theme.fontSizeNormal
                                    horizontalAlignment: Qt.AlignHCenter
                                    verticalAlignment: Qt.AlignVCenter
                                    topPadding: 0
                                    bottomPadding: 0
                                    inputMethodHints: Qt.ImhDigitsOnly
                                    validator: IntValidator { bottom: 1; top: 60 }

                                    background: Rectangle {
                                        color: Theme.surfaceColor
                                        border.color: parent.activeFocus ? Theme.accentColor : Theme.borderColor
                                        border.width: 1
                                        radius: Theme.borderRadius
                                    }

                                    onEditingFinished: {
                                        var val = parseInt(text)
                                        if (val >= 1 && val <= 60) pomodoroBackend.setLongBreakDuration(val)
                                        else text = pomodoroBackend.longBreakDuration
                                    }
                                }

                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: Theme.borderRadius
                                    color: longUp.pressed ? Theme.accentColor : (longUp.containsMouse ? Theme.borderColor : Theme.surfaceColor)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "+"
                                        color: Theme.textPrimary
                                        font.pixelSize: 14
                                    }

                                    MouseArea {
                                        id: longUp
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: if (pomodoroBackend.longBreakDuration < 60) pomodoroBackend.setLongBreakDuration(pomodoroBackend.longBreakDuration + 1)
                                    }
                                }
                            }

                            Text {
                                text: "Sessions"
                                color: Theme.textSecondary
                                font.pixelSize: Theme.fontSizeSmall
                                Layout.alignment: Qt.AlignVCenter
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: Theme.borderRadius
                                    color: sessDown.pressed ? Theme.accentColor : (sessDown.containsMouse ? Theme.borderColor : Theme.surfaceColor)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "-"
                                        color: Theme.textPrimary
                                        font.pixelSize: 14
                                    }

                                    MouseArea {
                                        id: sessDown
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: if (pomodoroBackend.sessionsBeforeLongBreak > 1) pomodoroBackend.setSessionsBeforeLongBreak(pomodoroBackend.sessionsBeforeLongBreak - 1)
                                    }
                                }

                                TextField {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 28
                                    text: pomodoroBackend.sessionsBeforeLongBreak
                                    color: Theme.textPrimary
                                    font.pixelSize: Theme.fontSizeNormal
                                    horizontalAlignment: Qt.AlignHCenter
                                    verticalAlignment: Qt.AlignVCenter
                                    topPadding: 0
                                    bottomPadding: 0
                                    inputMethodHints: Qt.ImhDigitsOnly
                                    validator: IntValidator { bottom: 1; top: 10 }

                                    background: Rectangle {
                                        color: Theme.surfaceColor
                                        border.color: parent.activeFocus ? Theme.accentColor : Theme.borderColor
                                        border.width: 1
                                        radius: Theme.borderRadius
                                    }

                                    onEditingFinished: {
                                        var val = parseInt(text)
                                        if (val >= 1 && val <= 10) pomodoroBackend.setSessionsBeforeLongBreak(val)
                                        else text = pomodoroBackend.sessionsBeforeLongBreak
                                    }
                                }

                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: Theme.borderRadius
                                    color: sessUp.pressed ? Theme.accentColor : (sessUp.containsMouse ? Theme.borderColor : Theme.surfaceColor)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "+"
                                        color: Theme.textPrimary
                                        font.pixelSize: 14
                                    }

                                    MouseArea {
                                        id: sessUp
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: if (pomodoroBackend.sessionsBeforeLongBreak < 10) pomodoroBackend.setSessionsBeforeLongBreak(pomodoroBackend.sessionsBeforeLongBreak + 1)
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            radius: Theme.borderRadius
                            color: resetArea.containsMouse ? Theme.borderColor : Theme.surfaceColor

                            Text {
                                anchors.centerIn: parent
                                text: "Reset Session Count"
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSizeSmall
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
