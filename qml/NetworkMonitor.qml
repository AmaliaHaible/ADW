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

    Column {
        anchors.fill: parent
        spacing: 0

        TitleBar {
            id: titleBar
            width: parent.width
            title: "Network"
            dragEnabled: netMonWindow.editMode
            minimized: netMonWindow.minimized
            effectiveRadius: netMonWindow.effectiveWindowRadius
            rightButtons: [
                {icon: "eye-off.svg", action: "minimize"}
            ]

            onButtonClicked: function(action) {
                if (action === "minimize") {
                    netMonWindow.toggleMinimize()
                }
            }
        }

        Rectangle {
            width: parent.width
            height: parent.height - titleBar.height
            color: "transparent"
            visible: !netMonWindow.minimized

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
                                color: Theme.warning
                                font.pixelSize: Theme.fontSizeNormal
                                font.weight: Font.Medium
                            }
                        }

                        Canvas {
                            id: uploadCanvas
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)

                                var history = networkMonitorBackend.uploadHistory
                                var maxVal = networkMonitorBackend.maxUploadHistory
                                if (history.length < 2 || maxVal <= 0) return

                                ctx.beginPath()
                                ctx.strokeStyle = Theme.warning
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
                                color: Theme.accentColor
                                font.pixelSize: Theme.fontSizeNormal
                                font.weight: Font.Medium
                            }
                        }

                        Canvas {
                            id: downloadCanvas
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)

                                var history = networkMonitorBackend.downloadHistory
                                var maxVal = networkMonitorBackend.maxDownloadHistory
                                if (history.length < 2 || maxVal <= 0) return

                                ctx.beginPath()
                                ctx.strokeStyle = Theme.accentColor
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
    }
}
