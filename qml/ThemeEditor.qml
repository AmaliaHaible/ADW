import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs
import Common 1.0

Window {
    id: themeWindow

    width: settingsBackend ? settingsBackend.getWidgetGeometry("theme").width : 320
    height: settingsBackend ? settingsBackend.getWidgetGeometry("theme").height : 450
    x: settingsBackend ? settingsBackend.getWidgetGeometry("theme").x : 100
    y: settingsBackend ? settingsBackend.getWidgetGeometry("theme").y : 370
    visible: hubBackend.themeVisible
    title: "Theme Editor"
    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.NoDropShadowWindowHint
    color: Theme.windowBackground

    onXChanged: if (visible) saveGeometryTimer.restart()
    onYChanged: if (visible) saveGeometryTimer.restart()
    onWidthChanged: if (visible) saveGeometryTimer.restart()
    onHeightChanged: if (visible) saveGeometryTimer.restart()

    Timer {
        id: saveGeometryTimer
        interval: 500
        onTriggered: {
            if (settingsBackend) {
                settingsBackend.setWidgetGeometry("theme", themeWindow.x, themeWindow.y, themeWindow.width, themeWindow.height)
            }
        }
    }

    // Right-click resize in edit mode
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        enabled: hubBackend.editMode
        onPressed: function(mouse) {
            themeWindow.startSystemResize(Qt.BottomEdge | Qt.RightEdge)
        }
    }

    Column {
        anchors.fill: parent
        spacing: 0

        TitleBar {
            id: titleBar
            width: parent.width
            title: "Theme Editor"
            dragEnabled: hubBackend.editMode
            leftButtons: [
                {icon: "rotate-ccw.svg", action: "reset"}
            ]

            onButtonClicked: function(action) {
                if (action === "reset") {
                    themeProvider.resetToDefaults()
                }
            }
        }

        // Content area with scroll
        Rectangle {
            width: parent.width
            height: parent.height - titleBar.height
            color: Theme.windowBackground

            ScrollView {
                anchors.fill: parent
                anchors.margins: Theme.padding
                clip: true

                ColumnLayout {
                    width: parent.parent.width - Theme.padding * 2
                    spacing: Theme.spacing

                    // Colors section
                    Text {
                        text: "Colors"
                        color: Theme.textPrimary
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Medium
                    }

                    // Color editors
                    Repeater {
                        model: [
                            {name: "windowBackground", label: "Window Background"},
                            {name: "surfaceColor", label: "Surface"},
                            {name: "titleBarBackground", label: "Title Bar"},
                            {name: "titleBarText", label: "Title Text"},
                            {name: "accentColor", label: "Accent"},
                            {name: "textPrimary", label: "Text Primary"},
                            {name: "textSecondary", label: "Text Secondary"},
                            {name: "textMuted", label: "Text Muted"}
                        ]

                        Rectangle {
                            Layout.fillWidth: true
                            height: 36
                            radius: Theme.borderRadius / 2
                            color: Theme.surfaceColor

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Theme.spacing
                                anchors.rightMargin: Theme.spacing
                                spacing: Theme.spacing

                                Text {
                                    text: modelData.label
                                    color: Theme.textSecondary
                                    font.pixelSize: Theme.fontSizeSmall
                                    Layout.fillWidth: true
                                }

                                Rectangle {
                                    width: 60
                                    height: 24
                                    radius: 4
                                    color: themeProvider ? themeProvider[modelData.name] : "#000"
                                    border.color: Theme.textMuted
                                    border.width: 1

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            colorDialog.colorName = modelData.name
                                            colorDialog.selectedColor = parent.color
                                            colorDialog.open()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Spacing
                    Item { height: Theme.spacing }

                    // Dimensions section
                    Text {
                        text: "Dimensions"
                        color: Theme.textPrimary
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Medium
                    }

                    // Dimension editors
                    Repeater {
                        model: [
                            {name: "fontSizeSmall", label: "Font Small", min: 8, max: 20},
                            {name: "fontSizeNormal", label: "Font Normal", min: 10, max: 24},
                            {name: "fontSizeLarge", label: "Font Large", min: 12, max: 32},
                            {name: "titleBarHeight", label: "Title Bar Height", min: 24, max: 48},
                            {name: "borderRadius", label: "Border Radius", min: 0, max: 20},
                            {name: "spacing", label: "Spacing", min: 4, max: 20},
                            {name: "padding", label: "Padding", min: 4, max: 24}
                        ]

                        Rectangle {
                            Layout.fillWidth: true
                            height: 36
                            radius: Theme.borderRadius / 2
                            color: Theme.surfaceColor

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Theme.spacing
                                anchors.rightMargin: Theme.spacing
                                spacing: Theme.spacing

                                Text {
                                    text: modelData.label
                                    color: Theme.textSecondary
                                    font.pixelSize: Theme.fontSizeSmall
                                    Layout.preferredWidth: 100
                                }

                                Slider {
                                    id: slider
                                    Layout.fillWidth: true
                                    from: modelData.min
                                    to: modelData.max
                                    stepSize: 1
                                    value: themeProvider ? themeProvider[modelData.name] : modelData.min

                                    onMoved: {
                                        if (themeProvider) {
                                            themeProvider.setInt(modelData.name, Math.round(value))
                                        }
                                    }

                                    background: Rectangle {
                                        x: slider.leftPadding
                                        y: slider.topPadding + slider.availableHeight / 2 - height / 2
                                        width: slider.availableWidth
                                        height: 4
                                        radius: 2
                                        color: Theme.titleBarBackground

                                        Rectangle {
                                            width: slider.visualPosition * parent.width
                                            height: parent.height
                                            radius: 2
                                            color: Theme.accentColor
                                        }
                                    }

                                    handle: Rectangle {
                                        x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
                                        y: slider.topPadding + slider.availableHeight / 2 - height / 2
                                        width: 14
                                        height: 14
                                        radius: 7
                                        color: Theme.textPrimary
                                    }
                                }

                                Text {
                                    text: Math.round(slider.value)
                                    color: Theme.textMuted
                                    font.pixelSize: Theme.fontSizeSmall
                                    Layout.preferredWidth: 24
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
                        }
                    }

                    // Spacer
                    Item { Layout.fillHeight: true }
                }
            }
        }
    }

    ColorDialog {
        id: colorDialog
        property string colorName: ""

        onAccepted: {
            if (themeProvider && colorName !== "") {
                themeProvider.setColor(colorName, selectedColor.toString())
            }
        }
    }
}
