import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Common 1.0

WidgetWindow {
    id: sysMonWindow

    geometryKey: "system_monitor"
    settingsStore: settingsBackend
    editMode: hubBackend.editMode
    hubVisible: hubBackend.hubVisible
    minResizeWidth: 200
    minResizeHeight: 200

    width: 220
    height: 280
    x: 100
    y: 450
    visible: hubBackend.systemMonitorVisible
    title: "System"

    property int currentView: 0

    property var colorPalette: [
        Theme.colorRed, Theme.colorOrange, Theme.colorYellow,
        Theme.colorGreen, Theme.colorBlue, Theme.colorPurple
    ]

    function getColor(index) {
        return colorPalette[index] || Theme.accentColor
    }

    Column {
        anchors.fill: parent
        spacing: 0

        TitleBar {
            id: titleBar
            width: parent.width
            title: sysMonWindow.currentView === 0 ? "System" : "Settings"
            dragEnabled: sysMonWindow.editMode
            minimized: sysMonWindow.minimized
            effectiveRadius: sysMonWindow.effectiveWindowRadius
            leftButtons: sysMonWindow.currentView === 0 ? [
                {icon: "settings.svg", action: "settings", enabled: !hubBackend.editMode}
            ] : [
                {icon: "arrow-left.svg", action: "back", enabled: !hubBackend.editMode}
            ]
            rightButtons: [
                {icon: "eye-off.svg", action: "minimize"}
            ]

            onButtonClicked: function(action) {
                if (action === "minimize") {
                    sysMonWindow.toggleMinimize()
                } else if (action === "settings") {
                    sysMonWindow.currentView = 1
                } else if (action === "back") {
                    sysMonWindow.currentView = 0
                }
            }
        }

        Rectangle {
            width: parent.width
            height: parent.height - titleBar.height
            color: "transparent"
            visible: !sysMonWindow.minimized

            StackLayout {
                anchors.fill: parent
                currentIndex: sysMonWindow.currentView

                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.padding
                        spacing: Theme.spacing

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 80
                            radius: Theme.borderRadius
                            color: Theme.surfaceColor

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: Theme.padding / 2
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true

                                    Image {
                                        source: iconsPath + "cpu.svg"
                                        sourceSize: Qt.size(16, 16)
                                    }

                                    Text {
                                        text: "CPU"
                                        color: Theme.textPrimary
                                        font.pixelSize: Theme.fontSizeNormal
                                        font.weight: Font.Medium
                                    }

                                    Item { Layout.fillWidth: true }

                                    Text {
                                        text: systemMonitorBackend.cpuPercent.toFixed(0) + "%"
                                        color: sysMonWindow.getColor(systemMonitorBackend.cpuColorIndex)
                                        font.pixelSize: Theme.fontSizeNormal
                                        font.weight: Font.Medium
                                    }
                                }

                                Canvas {
                                    id: cpuCanvas
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    property color lineColor: sysMonWindow.getColor(systemMonitorBackend.cpuColorIndex)

                                    onPaint: {
                                        var ctx = getContext("2d")
                                        ctx.clearRect(0, 0, width, height)

                                        var history = systemMonitorBackend.cpuHistory
                                        if (history.length < 2) return

                                        ctx.beginPath()
                                        ctx.strokeStyle = lineColor
                                        ctx.lineWidth = 1.5

                                        var stepX = width / (history.length - 1)
                                        for (var i = 0; i < history.length; i++) {
                                            var x = i * stepX
                                            var y = height - (history[i] / 100 * height)
                                            if (i === 0) ctx.moveTo(x, y)
                                            else ctx.lineTo(x, y)
                                        }
                                        ctx.stroke()
                                    }

                                    onLineColorChanged: requestPaint()

                                    Connections {
                                        target: systemMonitorBackend
                                        function onHistoryChanged() {
                                            cpuCanvas.requestPaint()
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 80
                            radius: Theme.borderRadius
                            color: Theme.surfaceColor

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: Theme.padding / 2
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true

                                    Image {
                                        source: iconsPath + "memory-stick.svg"
                                        sourceSize: Qt.size(16, 16)
                                    }

                                    Text {
                                        text: "RAM"
                                        color: Theme.textPrimary
                                        font.pixelSize: Theme.fontSizeNormal
                                        font.weight: Font.Medium
                                    }

                                    Item { Layout.fillWidth: true }

                                    Text {
                                        text: systemMonitorBackend.memoryText
                                        color: sysMonWindow.getColor(systemMonitorBackend.ramColorIndex)
                                        font.pixelSize: Theme.fontSizeSmall
                                    }
                                }

                                Canvas {
                                    id: memCanvas
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    property color lineColor: sysMonWindow.getColor(systemMonitorBackend.ramColorIndex)

                                    onPaint: {
                                        var ctx = getContext("2d")
                                        ctx.clearRect(0, 0, width, height)

                                        var history = systemMonitorBackend.memoryHistory
                                        if (history.length < 2) return

                                        ctx.beginPath()
                                        ctx.strokeStyle = lineColor
                                        ctx.lineWidth = 1.5

                                        var stepX = width / (history.length - 1)
                                        for (var i = 0; i < history.length; i++) {
                                            var x = i * stepX
                                            var y = height - (history[i] / 100 * height)
                                            if (i === 0) ctx.moveTo(x, y)
                                            else ctx.lineTo(x, y)
                                        }
                                        ctx.stroke()
                                    }

                                    onLineColorChanged: requestPaint()

                                    Connections {
                                        target: systemMonitorBackend
                                        function onHistoryChanged() {
                                            memCanvas.requestPaint()
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: Theme.borderRadius
                            color: Theme.surfaceColor

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: Theme.padding / 2
                                spacing: 4

                                Text {
                                    text: "CPU Cores"
                                    color: Theme.textPrimary
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Medium
                                }

                                GridLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    columns: 4
                                    columnSpacing: 4
                                    rowSpacing: 4

                                    Repeater {
                                        model: systemMonitorBackend.cpuPerCore

                                        delegate: Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 16
                                            radius: 2
                                            color: Theme.windowBackground

                                            Rectangle {
                                                width: parent.width * (modelData / 100)
                                                height: parent.height
                                                radius: 2
                                                color: sysMonWindow.getColor(systemMonitorBackend.coresColorIndex)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.padding
                        spacing: Theme.spacing

                        Text {
                            text: "CPU Graph Color"
                            color: Theme.textSecondary
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        Row {
                            Layout.fillWidth: true
                            spacing: 8

                            Repeater {
                                model: sysMonWindow.colorPalette

                                delegate: Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 14
                                    color: modelData
                                    border.color: systemMonitorBackend.cpuColorIndex === index ? Theme.textPrimary : "transparent"
                                    border.width: 2

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: systemMonitorBackend.setCpuColorIndex(index)
                                    }
                                }
                            }
                        }

                        Text {
                            text: "RAM Graph Color"
                            color: Theme.textSecondary
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        Row {
                            Layout.fillWidth: true
                            spacing: 8

                            Repeater {
                                model: sysMonWindow.colorPalette

                                delegate: Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 14
                                    color: modelData
                                    border.color: systemMonitorBackend.ramColorIndex === index ? Theme.textPrimary : "transparent"
                                    border.width: 2

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: systemMonitorBackend.setRamColorIndex(index)
                                    }
                                }
                            }
                        }

                        Text {
                            text: "CPU Cores Color"
                            color: Theme.textSecondary
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        Row {
                            Layout.fillWidth: true
                            spacing: 8

                            Repeater {
                                model: sysMonWindow.colorPalette

                                delegate: Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 14
                                    color: modelData
                                    border.color: systemMonitorBackend.coresColorIndex === index ? Theme.textPrimary : "transparent"
                                    border.width: 2

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: systemMonitorBackend.setCoresColorIndex(index)
                                    }
                                }
                            }
                        }

                        Text {
                            text: "History Duration"
                            color: Theme.textSecondary
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Rectangle {
                                width: 28
                                height: 28
                                radius: Theme.borderRadius
                                color: histDown.pressed ? Theme.accentColor : (histDown.containsMouse ? Theme.borderColor : Theme.surfaceColor)

                                Text {
                                    anchors.centerIn: parent
                                    text: "-"
                                    color: Theme.textPrimary
                                    font.pixelSize: 14
                                }

                                MouseArea {
                                    id: histDown
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        var newVal = systemMonitorBackend.historyDuration - 10
                                        if (newVal >= 10) systemMonitorBackend.setHistoryDuration(newVal)
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 28
                                color: Theme.surfaceColor
                                border.color: Theme.borderColor
                                border.width: 1
                                radius: Theme.borderRadius

                                Text {
                                    anchors.centerIn: parent
                                    text: systemMonitorBackend.historyDuration + "s"
                                    color: Theme.textPrimary
                                    font.pixelSize: Theme.fontSizeNormal
                                }
                            }

                            Rectangle {
                                width: 28
                                height: 28
                                radius: Theme.borderRadius
                                color: histUp.pressed ? Theme.accentColor : (histUp.containsMouse ? Theme.borderColor : Theme.surfaceColor)

                                Text {
                                    anchors.centerIn: parent
                                    text: "+"
                                    color: Theme.textPrimary
                                    font.pixelSize: 14
                                }

                                MouseArea {
                                    id: histUp
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        var newVal = systemMonitorBackend.historyDuration + 10
                                        if (newVal <= 300) systemMonitorBackend.setHistoryDuration(newVal)
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }
    }
}
