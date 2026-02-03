import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Common 1.0

WidgetWindow {
    id: netMonWindow

    geometryKey: "network_monitor"
    settingsStore: settingsBackend
    editMode: hubBackend.editMode
    hubVisible: hubBackend.hubVisible
    minResizeWidth: 200
    minResizeHeight: 180

    width: 220
    height: 200
    x: 340
    y: 450
    visible: hubBackend.networkMonitorVisible
    title: "Network"

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
            title: netMonWindow.currentView === 0 ? "Network" : "Settings"
            dragEnabled: netMonWindow.editMode
            minimized: netMonWindow.minimized
            effectiveRadius: netMonWindow.effectiveWindowRadius
            leftButtons: netMonWindow.currentView === 0 ? [
                {icon: "settings.svg", action: "settings", enabled: !hubBackend.editMode}
            ] : [
                {icon: "arrow-left.svg", action: "back", enabled: !hubBackend.editMode}
            ]
            rightButtons: [
                {icon: netMonWindow.minimized ? "eye.svg" : "eye-off.svg", action: "minimize"}
            ]

            onButtonClicked: function(action) {
                if (action === "minimize") {
                    netMonWindow.toggleMinimize()
                } else if (action === "settings") {
                    netMonWindow.currentView = 1
                } else if (action === "back") {
                    netMonWindow.currentView = 0
                }
            }
        }

        Rectangle {
            width: parent.width
            height: parent.height - titleBar.height
            color: "transparent"
            visible: !netMonWindow.minimized

            StackLayout {
                anchors.fill: parent
                currentIndex: netMonWindow.currentView

                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.padding
                        spacing: Theme.spacing

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 60
                            radius: Theme.borderRadius
                            color: Theme.surfaceColor

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: Theme.padding / 2
                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true

                                    Image {
                                        source: iconsPath + "upload.svg"
                                        sourceSize: Qt.size(14, 14)
                                    }

                                    Text {
                                        text: "Upload"
                                        color: Theme.textSecondary
                                        font.pixelSize: Theme.fontSizeSmall
                                    }

                                    Item { Layout.fillWidth: true }

                                    Text {
                                        text: networkMonitorBackend.uploadSpeedText
                                        color: netMonWindow.getColor(networkMonitorBackend.uploadColorIndex)
                                        font.pixelSize: Theme.fontSizeNormal
                                        font.weight: Font.Medium
                                    }
                                }

                                Canvas {
                                    id: uploadCanvas
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    property color lineColor: netMonWindow.getColor(networkMonitorBackend.uploadColorIndex)

                                    onPaint: {
                                        var ctx = getContext("2d")
                                        ctx.clearRect(0, 0, width, height)

                                        var history = networkMonitorBackend.uploadHistory
                                        var maxVal = networkMonitorBackend.maxUploadHistory
                                        if (history.length < 2 || maxVal <= 0) return

                                        ctx.beginPath()
                                        ctx.strokeStyle = lineColor
                                        ctx.lineWidth = 1.5

                                        var stepX = width / (history.length - 1)
                                        for (var i = 0; i < history.length; i++) {
                                            var x = i * stepX
                                            var y = height - (history[i] / maxVal * height * 0.9)
                                            if (i === 0) ctx.moveTo(x, y)
                                            else ctx.lineTo(x, y)
                                        }
                                        ctx.stroke()
                                    }

                                    onLineColorChanged: requestPaint()

                                    Connections {
                                        target: networkMonitorBackend
                                        function onHistoryChanged() {
                                            uploadCanvas.requestPaint()
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 60
                            radius: Theme.borderRadius
                            color: Theme.surfaceColor

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: Theme.padding / 2
                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true

                                    Image {
                                        source: iconsPath + "download.svg"
                                        sourceSize: Qt.size(14, 14)
                                    }

                                    Text {
                                        text: "Download"
                                        color: Theme.textSecondary
                                        font.pixelSize: Theme.fontSizeSmall
                                    }

                                    Item { Layout.fillWidth: true }

                                    Text {
                                        text: networkMonitorBackend.downloadSpeedText
                                        color: netMonWindow.getColor(networkMonitorBackend.downloadColorIndex)
                                        font.pixelSize: Theme.fontSizeNormal
                                        font.weight: Font.Medium
                                    }
                                }

                                Canvas {
                                    id: downloadCanvas
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    property color lineColor: netMonWindow.getColor(networkMonitorBackend.downloadColorIndex)

                                    onPaint: {
                                        var ctx = getContext("2d")
                                        ctx.clearRect(0, 0, width, height)

                                        var history = networkMonitorBackend.downloadHistory
                                        var maxVal = networkMonitorBackend.maxDownloadHistory
                                        if (history.length < 2 || maxVal <= 0) return

                                        ctx.beginPath()
                                        ctx.strokeStyle = lineColor
                                        ctx.lineWidth = 1.5

                                        var stepX = width / (history.length - 1)
                                        for (var i = 0; i < history.length; i++) {
                                            var x = i * stepX
                                            var y = height - (history[i] / maxVal * height * 0.9)
                                            if (i === 0) ctx.moveTo(x, y)
                                            else ctx.lineTo(x, y)
                                        }
                                        ctx.stroke()
                                    }

                                    onLineColorChanged: requestPaint()

                                    Connections {
                                        target: networkMonitorBackend
                                        function onHistoryChanged() {
                                            downloadCanvas.requestPaint()
                                        }
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacing

                            Text {
                                text: "Total: " + networkMonitorBackend.totalSentText + " / " + networkMonitorBackend.totalReceivedText
                                color: Theme.textSecondary
                                font.pixelSize: Theme.fontSizeSmall
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
                            text: "Upload Color"
                            color: Theme.textSecondary
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        Row {
                            Layout.fillWidth: true
                            spacing: 8

                            Repeater {
                                model: netMonWindow.colorPalette

                                delegate: Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 14
                                    color: modelData
                                    border.color: networkMonitorBackend.uploadColorIndex === index ? Theme.textPrimary : "transparent"
                                    border.width: 2

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: networkMonitorBackend.setUploadColorIndex(index)
                                    }
                                }
                            }
                        }

                        Text {
                            text: "Download Color"
                            color: Theme.textSecondary
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        Row {
                            Layout.fillWidth: true
                            spacing: 8

                            Repeater {
                                model: netMonWindow.colorPalette

                                delegate: Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 14
                                    color: modelData
                                    border.color: networkMonitorBackend.downloadColorIndex === index ? Theme.textPrimary : "transparent"
                                    border.width: 2

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: networkMonitorBackend.setDownloadColorIndex(index)
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
                                color: netHistDown.pressed ? Theme.accentColor : (netHistDown.containsMouse ? Theme.borderColor : Theme.surfaceColor)

                                Text {
                                    anchors.centerIn: parent
                                    text: "-"
                                    color: Theme.textPrimary
                                    font.pixelSize: 14
                                }

                                MouseArea {
                                    id: netHistDown
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        var newVal = networkMonitorBackend.historyDuration - 10
                                        if (newVal >= 10) networkMonitorBackend.setHistoryDuration(newVal)
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
                                    text: networkMonitorBackend.historyDuration + "s"
                                    color: Theme.textPrimary
                                    font.pixelSize: Theme.fontSizeNormal
                                }
                            }

                            Rectangle {
                                width: 28
                                height: 28
                                radius: Theme.borderRadius
                                color: netHistUp.pressed ? Theme.accentColor : (netHistUp.containsMouse ? Theme.borderColor : Theme.surfaceColor)

                                Text {
                                    anchors.centerIn: parent
                                    text: "+"
                                    color: Theme.textPrimary
                                    font.pixelSize: 14
                                }

                                MouseArea {
                                    id: netHistUp
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        var newVal = networkMonitorBackend.historyDuration + 10
                                        if (newVal <= 300) networkMonitorBackend.setHistoryDuration(newVal)
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
