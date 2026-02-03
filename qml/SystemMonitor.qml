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

    Column {
        anchors.fill: parent
        spacing: 0

        TitleBar {
            id: titleBar
            width: parent.width
            title: "System"
            dragEnabled: sysMonWindow.editMode
            minimized: sysMonWindow.minimized
            effectiveRadius: sysMonWindow.effectiveWindowRadius
            rightButtons: [
                {icon: "eye-off.svg", action: "minimize"}
            ]

            onButtonClicked: function(action) {
                if (action === "minimize") {
                    sysMonWindow.toggleMinimize()
                }
            }
        }

        Rectangle {
            width: parent.width
            height: parent.height - titleBar.height
            color: "transparent"
            visible: !sysMonWindow.minimized

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
                                color: Theme.accentColor
                                font.pixelSize: Theme.fontSizeNormal
                                font.weight: Font.Medium
                            }
                        }

                        Canvas {
                            id: cpuCanvas
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)

                                var history = systemMonitorBackend.cpuHistory
                                if (history.length < 2) return

                                ctx.beginPath()
                                ctx.strokeStyle = Theme.accentColor
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
                                color: Theme.success
                                font.pixelSize: Theme.fontSizeSmall
                            }
                        }

                        Canvas {
                            id: memCanvas
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)

                                var history = systemMonitorBackend.memoryHistory
                                if (history.length < 2) return

                                ctx.beginPath()
                                ctx.strokeStyle = Theme.success
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
                                        color: modelData > 80 ? Theme.error : (modelData > 50 ? Theme.warning : Theme.accentColor)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
