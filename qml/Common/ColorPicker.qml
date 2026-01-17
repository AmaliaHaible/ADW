import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Common 1.0

Rectangle {
    id: colorPicker

    property color selectedColor: "#ff0000"
    property bool showAlpha: true

    signal colorAccepted(color value)
    signal canceled()

    width: 280
    height: showAlpha ? 320 : 290
    color: Theme.surfaceColor
    radius: Theme.borderRadius

    // Internal state
    property real hue: 0
    property real saturation: 1
    property real brightness: 1
    property real alpha: 1

    Component.onCompleted: {
        // Parse initial color
        var c = selectedColor
        alpha = c.a
        // Convert RGB to HSV
        var r = c.r, g = c.g, b = c.b
        var max = Math.max(r, g, b), min = Math.min(r, g, b)
        var h, s, v = max

        var d = max - min
        s = max === 0 ? 0 : d / max

        if (max === min) {
            h = 0
        } else {
            switch (max) {
                case r: h = (g - b) / d + (g < b ? 6 : 0); break
                case g: h = (b - r) / d + 2; break
                case b: h = (r - g) / d + 4; break
            }
            h /= 6
        }
        hue = h
        saturation = s
        brightness = v
    }

    function updateColor() {
        // HSV to RGB
        var h = hue, s = saturation, v = brightness
        var r, g, b
        var i = Math.floor(h * 6)
        var f = h * 6 - i
        var p = v * (1 - s)
        var q = v * (1 - f * s)
        var t = v * (1 - (1 - f) * s)

        switch (i % 6) {
            case 0: r = v; g = t; b = p; break
            case 1: r = q; g = v; b = p; break
            case 2: r = p; g = v; b = t; break
            case 3: r = p; g = q; b = v; break
            case 4: r = t; g = p; b = v; break
            case 5: r = v; g = p; b = q; break
        }

        selectedColor = Qt.rgba(r, g, b, alpha)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.padding
        spacing: Theme.spacing

        // Color gradient picker (saturation/brightness)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 150
            radius: Theme.borderRadius / 2

            // Background gradient layers
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "white" }
                    GradientStop { position: 1.0; color: Qt.hsva(colorPicker.hue, 1, 1, 1) }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: "black" }
                }
            }

            // Selection indicator
            Rectangle {
                x: colorPicker.saturation * (parent.width - width)
                y: (1 - colorPicker.brightness) * (parent.height - height)
                width: 16
                height: 16
                radius: 8
                color: "transparent"
                border.color: "white"
                border.width: 2

                Rectangle {
                    anchors.centerIn: parent
                    width: 12
                    height: 12
                    radius: 6
                    color: "transparent"
                    border.color: "black"
                    border.width: 1
                }
            }

            MouseArea {
                anchors.fill: parent
                onPressed: updateSB(mouse)
                onPositionChanged: updateSB(mouse)

                function updateSB(mouse) {
                    colorPicker.saturation = Math.max(0, Math.min(1, mouse.x / width))
                    colorPicker.brightness = Math.max(0, Math.min(1, 1 - mouse.y / height))
                    colorPicker.updateColor()
                }
            }
        }

        // Hue slider
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 20
            radius: 4

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.hsva(0, 1, 1, 1) }
                GradientStop { position: 0.167; color: Qt.hsva(0.167, 1, 1, 1) }
                GradientStop { position: 0.333; color: Qt.hsva(0.333, 1, 1, 1) }
                GradientStop { position: 0.5; color: Qt.hsva(0.5, 1, 1, 1) }
                GradientStop { position: 0.667; color: Qt.hsva(0.667, 1, 1, 1) }
                GradientStop { position: 0.833; color: Qt.hsva(0.833, 1, 1, 1) }
                GradientStop { position: 1.0; color: Qt.hsva(1, 1, 1, 1) }
            }

            Rectangle {
                x: colorPicker.hue * (parent.width - width)
                y: (parent.height - height) / 2
                width: 8
                height: parent.height + 4
                radius: 2
                color: "white"
                border.color: Theme.borderColor
                border.width: 1
                anchors.verticalCenter: parent.verticalCenter
            }

            MouseArea {
                anchors.fill: parent
                onPressed: updateHue(mouse)
                onPositionChanged: updateHue(mouse)

                function updateHue(mouse) {
                    colorPicker.hue = Math.max(0, Math.min(1, mouse.x / width))
                    colorPicker.updateColor()
                }
            }
        }

        // Alpha slider (optional)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 20
            radius: 4
            visible: colorPicker.showAlpha

            // Checkerboard background for transparency
            Canvas {
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d")
                    var size = 6
                    for (var x = 0; x < width; x += size) {
                        for (var y = 0; y < height; y += size) {
                            ctx.fillStyle = ((x / size + y / size) % 2 === 0) ? "#ccc" : "#fff"
                            ctx.fillRect(x, y, size, size)
                        }
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.rgba(colorPicker.selectedColor.r, colorPicker.selectedColor.g, colorPicker.selectedColor.b, 0) }
                    GradientStop { position: 1.0; color: Qt.rgba(colorPicker.selectedColor.r, colorPicker.selectedColor.g, colorPicker.selectedColor.b, 1) }
                }
            }

            Rectangle {
                x: colorPicker.alpha * (parent.width - width)
                y: (parent.height - height) / 2
                width: 8
                height: parent.height + 4
                radius: 2
                color: "white"
                    border.color: Theme.borderColor
                border.width: 1
                anchors.verticalCenter: parent.verticalCenter
            }

            MouseArea {
                anchors.fill: parent
                onPressed: updateAlpha(mouse)
                onPositionChanged: updateAlpha(mouse)

                function updateAlpha(mouse) {
                    colorPicker.alpha = Math.max(0, Math.min(1, mouse.x / width))
                    colorPicker.updateColor()
                }
            }
        }

        // Preview and hex input
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing

            // Color preview
            Rectangle {
                Layout.preferredWidth: 48
                Layout.preferredHeight: 32
                radius: 4

                // Checkerboard background
                Canvas {
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d")
                        var size = 6
                        for (var x = 0; x < width; x += size) {
                            for (var y = 0; y < height; y += size) {
                                ctx.fillStyle = ((x / size + y / size) % 2 === 0) ? "#ccc" : "#fff"
                                ctx.fillRect(x, y, size, size)
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: colorPicker.selectedColor
                }
            }

            // Hex input
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                radius: 4
                color: Theme.windowBackground
                border.color: Theme.borderColor
                border.width: 1

                TextInput {
                    id: hexInput
                    anchors.fill: parent
                    anchors.margins: 6
                    color: Theme.textPrimary
                    font.pixelSize: Theme.fontSizeNormal
                    font.family: "monospace"
                    verticalAlignment: TextInput.AlignVCenter
                    text: colorPicker.selectedColor.toString().toUpperCase()
                    selectByMouse: true

                    onEditingFinished: {
                        var c = hexInput.text
                        if (c.match(/^#[0-9A-Fa-f]{6,8}$/)) {
                            colorPicker.selectedColor = c
                            // Re-parse to update HSV
                            var col = colorPicker.selectedColor
                            colorPicker.alpha = col.a
                            var r = col.r, g = col.g, b = col.b
                            var max = Math.max(r, g, b), min = Math.min(r, g, b)
                            var h, s, v = max
                            var d = max - min
                            s = max === 0 ? 0 : d / max
                            if (max === min) {
                                h = 0
                            } else {
                                switch (max) {
                                    case r: h = (g - b) / d + (g < b ? 6 : 0); break
                                    case g: h = (b - r) / d + 2; break
                                    case b: h = (r - g) / d + 4; break
                                }
                                h /= 6
                            }
                            colorPicker.hue = h
                            colorPicker.saturation = s
                            colorPicker.brightness = v
                        }
                    }
                }
            }
        }

        // Buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacing

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                radius: 4
                color: cancelMouse.containsMouse ? Theme.titleBarButtonHover : Theme.windowBackground

                Text {
                    anchors.centerIn: parent
                    text: "Cancel"
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontSizeNormal
                }

                MouseArea {
                    id: cancelMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: colorPicker.canceled()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                radius: 4
                color: okMouse.containsMouse ? Theme.accentHover : Theme.accentColor

                Text {
                    anchors.centerIn: parent
                    text: "OK"
                    color: Theme.windowBackground
                    font.pixelSize: Theme.fontSizeNormal
                    font.weight: Font.Medium
                }

                MouseArea {
                    id: okMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: colorPicker.colorAccepted(colorPicker.selectedColor)
                }
            }
        }
    }
}
