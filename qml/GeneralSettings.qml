import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs
import Common 1.0

WidgetWindow {
    id: themeWindow

    geometryKey: "theme"
    settingsStore: settingsBackend
    editMode: hubBackend.editMode
    hubVisible: hubBackend.hubVisible
    minResizeWidth: 250
    minResizeHeight: 200

    width: 320
    height: 450
    x: 100
    y: 370
    visible: hubBackend.themeVisible
    title: "General Settings"

    Column {
        anchors.fill: parent
        spacing: 0

        TitleBar {
            id: titleBar
            width: parent.width
            title: "General Settings"
            dragEnabled: themeWindow.editMode
            minimized: themeWindow.minimized
            effectiveRadius: themeWindow.effectiveWindowRadius
            leftButtons: [
                {icon: "save.svg", action: "save", enabled: !hubBackend.editMode},
                {icon: "folder.svg", action: "load", enabled: !hubBackend.editMode}
            ]
            rightButtons: [
                {icon: "rotate-ccw.svg", action: "reset", enabled: !hubBackend.editMode},
                {icon: "eye-off.svg", action: "minimize"}
            ]

            onButtonClicked: function(action) {
                if (action === "save") {
                    saveThemeDialog.open()
                } else if (action === "load") {
                    loadThemeDialog.open()
                } else if (action === "reset") {
                    themeProvider.resetToDefaults()
                } else if (action === "minimize") {
                    themeWindow.toggleMinimize()
                }
            }
        }

        // Content area with scroll
        Rectangle {
            width: parent.width
            height: parent.height - titleBar.height
            color: "transparent"
            visible: !themeWindow.minimized

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
                                {name: "accentInactive", label: "Accent Inactive"},
                                {name: "textPrimary", label: "Text Primary"},
                                {name: "textSecondary", label: "Text Secondary"},
                                {name: "textMuted", label: "Text Muted"},
                                {name: "textPrimaryDark", label: "Text Primary (Dark)"},
                                {name: "textSecondaryDark", label: "Text Secondary (Dark)"},
                                {name: "borderColor", label: "Border"},
                                {name: "colorRed", label: "Red"},
                                {name: "colorOrange", label: "Orange"},
                                {name: "colorYellow", label: "Yellow"},
                                {name: "colorGreen", label: "Green"},
                                {name: "colorBlue", label: "Blue"},
                                {name: "colorPurple", label: "Purple"}
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
                                        border.color: Theme.borderColor
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

                                    Rectangle {
                                        width: 24
                                        height: 24
                                        radius: 4
                                        color: Theme.surfaceColor
                                        border.color: Theme.borderColor
                                        border.width: 1

                                        Image {
                                            anchors.centerIn: parent
                                            width: 12
                                            height: 12
                                            source: iconsPath + "rotate-ccw.svg"
                                            sourceSize: Qt.size(12, 12)
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                if (themeProvider) {
                                                    themeProvider.resetValue(modelData.name)
                                                }
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
                            {name: "windowRadius", label: "Window Radius", min: 0, max: 24},
                            {name: "spacing", label: "Spacing", min: 4, max: 20},
                            {name: "padding", label: "Padding", min: 4, max: 24},
                            {name: "textScrollSpeed", label: "Text Scroll Speed", min: 10, max: 150}
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
                                        color: Theme.accentInactive

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

                                    Rectangle {
                                        width: 24
                                        height: 24
                                        radius: 4
                                        color: Theme.surfaceColor
                                        border.color: Theme.borderColor
                                        border.width: 1

                                        Image {
                                            anchors.centerIn: parent
                                            width: 12
                                            height: 12
                                            source: iconsPath + "rotate-ccw.svg"
                                            sourceSize: Qt.size(12, 12)
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                if (themeProvider) {
                                                    themeProvider.resetValue(modelData.name)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                    // Spacing
                    Item { height: Theme.spacing }

                    // Hotkeys section
                    Text {
                        text: "Hotkeys"
                        color: Theme.textPrimary
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Medium
                    }

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
                                text: "Always on Top"
                                color: Theme.textSecondary
                                font.pixelSize: Theme.fontSizeSmall
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                id: hotkeyButton
                                width: Math.max(80, hotkeyText.implicitWidth + 16)
                                height: 24
                                radius: 4
                                color: hotkeyBackend && hotkeyBackend.recording && hotkeyBackend.recordingTarget === "always_on_top" ? Theme.accentColor : Theme.surfaceColor
                                border.color: Theme.borderColor
                                border.width: 1

                                Text {
                                    id: hotkeyText
                                    anchors.centerIn: parent
                                    text: hotkeyBackend ? (hotkeyBackend.recording && hotkeyBackend.recordingTarget === "always_on_top" ?
                                        (hotkeyBackend.recordedHotkey || "Press keys...") :
                                        hotkeyBackend.getDisplayHotkey()) : "N/A"
                                    color: Theme.textPrimary
                                    font.pixelSize: Theme.fontSizeSmall
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (hotkeyBackend && !hotkeyBackend.recording) {
                                            hotkeyBackend.startRecording("always_on_top")
                                            hotkeyButton.forceActiveFocus()
                                        }
                                    }
                                }

                                Keys.onPressed: function(event) {
                                    if (hotkeyBackend && hotkeyBackend.recording && hotkeyBackend.recordingTarget === "always_on_top") {
                                        if (event.key === Qt.Key_Escape) {
                                            hotkeyBackend.cancelRecording()
                                        } else {
                                            hotkeyBackend.recordKeyPress(event.key, event.modifiers)
                                        }
                                        event.accepted = true
                                    }
                                }

                                focus: hotkeyBackend ? (hotkeyBackend.recording && hotkeyBackend.recordingTarget === "always_on_top") : false
                            }

                            Rectangle {
                                width: 24
                                height: 24
                                radius: 4
                                color: Theme.surfaceColor
                                border.color: Theme.borderColor
                                border.width: 1
                                visible: hotkeyBackend ? (hotkeyBackend.recording && hotkeyBackend.recordingTarget === "always_on_top") : false

                                Image {
                                    anchors.centerIn: parent
                                    width: 12
                                    height: 12
                                    source: iconsPath + "x.svg"
                                    sourceSize: Qt.size(12, 12)
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (hotkeyBackend) {
                                            hotkeyBackend.cancelRecording()
                                        }
                                    }
                                }
                            }
                        }
                    }

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
                                text: "Show Hub"
                                color: Theme.textSecondary
                                font.pixelSize: Theme.fontSizeSmall
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                id: showHubHotkeyButton
                                width: Math.max(80, showHubHotkeyText.implicitWidth + 16)
                                height: 24
                                radius: 4
                                color: hotkeyBackend && hotkeyBackend.recording && hotkeyBackend.recordingTarget === "show_hub" ? Theme.accentColor : Theme.surfaceColor
                                border.color: Theme.borderColor
                                border.width: 1

                                Text {
                                    id: showHubHotkeyText
                                    anchors.centerIn: parent
                                    text: hotkeyBackend ? (hotkeyBackend.recording && hotkeyBackend.recordingTarget === "show_hub" ?
                                        (hotkeyBackend.recordedHotkey || "Press keys...") :
                                        hotkeyBackend.getDisplayShowHubHotkey()) : "N/A"
                                    color: Theme.textPrimary
                                    font.pixelSize: Theme.fontSizeSmall
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (hotkeyBackend && !hotkeyBackend.recording) {
                                            hotkeyBackend.startRecording("show_hub")
                                            showHubHotkeyButton.forceActiveFocus()
                                        }
                                    }
                                }

                                Keys.onPressed: function(event) {
                                    if (hotkeyBackend && hotkeyBackend.recording && hotkeyBackend.recordingTarget === "show_hub") {
                                        if (event.key === Qt.Key_Escape) {
                                            hotkeyBackend.cancelRecording()
                                        } else {
                                            hotkeyBackend.recordKeyPress(event.key, event.modifiers)
                                        }
                                        event.accepted = true
                                    }
                                }

                                focus: hotkeyBackend ? (hotkeyBackend.recording && hotkeyBackend.recordingTarget === "show_hub") : false
                            }

                            Rectangle {
                                width: 24
                                height: 24
                                radius: 4
                                color: Theme.surfaceColor
                                border.color: Theme.borderColor
                                border.width: 1
                                visible: hotkeyBackend ? (hotkeyBackend.recording && hotkeyBackend.recordingTarget === "show_hub") : false

                                Image {
                                    anchors.centerIn: parent
                                    width: 12
                                    height: 12
                                    source: iconsPath + "x.svg"
                                    sourceSize: Qt.size(12, 12)
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (hotkeyBackend) {
                                            hotkeyBackend.cancelRecording()
                                        }
                                    }
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

    // Custom Color Picker Dialog
    Rectangle {
        id: colorDialog
        property string colorName: ""
        property color selectedColor: "#000000"
        property bool dialogOpen: false

        visible: dialogOpen
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
        z: 1000

        function open() {
            dialogOpen = true
        }

        function close() {
            dialogOpen = false
        }

        MouseArea {
            anchors.fill: parent
            onClicked: parent.close()
        }

        Rectangle {
            anchors.centerIn: parent
            width: 320
            height: 420
            radius: Theme.windowRadius
            color: Theme.windowBackground
            border.color: Theme.borderColor
            border.width: 1

            MouseArea {
                anchors.fill: parent
                onClicked: {} // Prevent closing when clicking inside dialog
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.padding
                spacing: Theme.spacing

                // Title
                Text {
                    text: "Pick Color"
                    color: Theme.textPrimary
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Medium
                }

                // Color preview
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    radius: Theme.borderRadius
                    color: colorDialog.selectedColor
                    border.color: Theme.borderColor
                    border.width: 1
                }

                // Hex input
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacing

                    Text {
                        text: "Hex:"
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSizeNormal
                    }

                    TextField {
                        id: hexInput
                        Layout.fillWidth: true
                        text: colorDialog.selectedColor.toString()
                        color: Theme.textPrimary
                        font.pixelSize: Theme.fontSizeNormal

                        background: Rectangle {
                            color: Theme.surfaceColor
                            border.color: Theme.borderColor
                            border.width: 1
                            radius: 4
                        }

                        onTextChanged: {
                            if (text.match(/^#[0-9A-Fa-f]{6,8}$/)) {
                                colorDialog.selectedColor = text
                            }
                        }
                    }
                }

                // RGB sliders
                Text {
                    text: "RGB"
                    color: Theme.textPrimary
                    font.pixelSize: Theme.fontSizeNormal
                    font.weight: Font.Medium
                }

                // Red slider
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacing

                    Text {
                        text: "R:"
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSizeSmall
                        Layout.preferredWidth: 20
                    }

                    Slider {
                        id: redSlider
                        Layout.fillWidth: true
                        from: 0
                        to: 255
                        stepSize: 1
                        value: colorDialog.selectedColor.r * 255

                        onMoved: {
                            var g = greenSlider.value
                            var b = blueSlider.value
                            var a = alphaSlider.value
                            colorDialog.selectedColor = Qt.rgba(value/255, g/255, b/255, a/255)
                        }

                        background: Rectangle {
                            x: redSlider.leftPadding
                            y: redSlider.topPadding + redSlider.availableHeight / 2 - height / 2
                            width: redSlider.availableWidth
                            height: 4
                            radius: 2
                            color: Theme.accentInactive

                            Rectangle {
                                width: redSlider.visualPosition * parent.width
                                height: parent.height
                                radius: 2
                                color: "#ff0000"
                            }
                        }

                        handle: Rectangle {
                            x: redSlider.leftPadding + redSlider.visualPosition * (redSlider.availableWidth - width)
                            y: redSlider.topPadding + redSlider.availableHeight / 2 - height / 2
                            width: 14
                            height: 14
                            radius: 7
                            color: Theme.textPrimary
                        }
                    }

                    Text {
                        text: Math.round(redSlider.value)
                        color: Theme.textMuted
                        font.pixelSize: Theme.fontSizeSmall
                        Layout.preferredWidth: 30
                        horizontalAlignment: Text.AlignRight
                    }
                }

                // Green slider
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacing

                    Text {
                        text: "G:"
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSizeSmall
                        Layout.preferredWidth: 20
                    }

                    Slider {
                        id: greenSlider
                        Layout.fillWidth: true
                        from: 0
                        to: 255
                        stepSize: 1
                        value: colorDialog.selectedColor.g * 255

                        onMoved: {
                            var r = redSlider.value
                            var b = blueSlider.value
                            var a = alphaSlider.value
                            colorDialog.selectedColor = Qt.rgba(r/255, value/255, b/255, a/255)
                        }

                        background: Rectangle {
                            x: greenSlider.leftPadding
                            y: greenSlider.topPadding + greenSlider.availableHeight / 2 - height / 2
                            width: greenSlider.availableWidth
                            height: 4
                            radius: 2
                            color: Theme.accentInactive

                            Rectangle {
                                width: greenSlider.visualPosition * parent.width
                                height: parent.height
                                radius: 2
                                color: "#00ff00"
                            }
                        }

                        handle: Rectangle {
                            x: greenSlider.leftPadding + greenSlider.visualPosition * (greenSlider.availableWidth - width)
                            y: greenSlider.topPadding + greenSlider.availableHeight / 2 - height / 2
                            width: 14
                            height: 14
                            radius: 7
                            color: Theme.textPrimary
                        }
                    }

                    Text {
                        text: Math.round(greenSlider.value)
                        color: Theme.textMuted
                        font.pixelSize: Theme.fontSizeSmall
                        Layout.preferredWidth: 30
                        horizontalAlignment: Text.AlignRight
                    }
                }

                // Blue slider
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacing

                    Text {
                        text: "B:"
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSizeSmall
                        Layout.preferredWidth: 20
                    }

                    Slider {
                        id: blueSlider
                        Layout.fillWidth: true
                        from: 0
                        to: 255
                        stepSize: 1
                        value: colorDialog.selectedColor.b * 255

                        onMoved: {
                            var r = redSlider.value
                            var g = greenSlider.value
                            var a = alphaSlider.value
                            colorDialog.selectedColor = Qt.rgba(r/255, g/255, value/255, a/255)
                        }

                        background: Rectangle {
                            x: blueSlider.leftPadding
                            y: blueSlider.topPadding + blueSlider.availableHeight / 2 - height / 2
                            width: blueSlider.availableWidth
                            height: 4
                            radius: 2
                            color: Theme.accentInactive

                            Rectangle {
                                width: blueSlider.visualPosition * parent.width
                                height: parent.height
                                radius: 2
                                color: "#0000ff"
                            }
                        }

                        handle: Rectangle {
                            x: blueSlider.leftPadding + blueSlider.visualPosition * (blueSlider.availableWidth - width)
                            y: blueSlider.topPadding + blueSlider.availableHeight / 2 - height / 2
                            width: 14
                            height: 14
                            radius: 7
                            color: Theme.textPrimary
                        }
                    }

                    Text {
                        text: Math.round(blueSlider.value)
                        color: Theme.textMuted
                        font.pixelSize: Theme.fontSizeSmall
                        Layout.preferredWidth: 30
                        horizontalAlignment: Text.AlignRight
                    }
                }

                // Alpha slider
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacing

                    Text {
                        text: "A:"
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSizeSmall
                        Layout.preferredWidth: 20
                    }

                    Slider {
                        id: alphaSlider
                        Layout.fillWidth: true
                        from: 0
                        to: 255
                        stepSize: 1
                        value: colorDialog.selectedColor.a * 255

                        onMoved: {
                            var r = redSlider.value
                            var g = greenSlider.value
                            var b = blueSlider.value
                            colorDialog.selectedColor = Qt.rgba(r/255, g/255, b/255, value/255)
                        }

                        background: Rectangle {
                            x: alphaSlider.leftPadding
                            y: alphaSlider.topPadding + alphaSlider.availableHeight / 2 - height / 2
                            width: alphaSlider.availableWidth
                            height: 4
                            radius: 2
                            color: Theme.accentInactive

                            Rectangle {
                                width: alphaSlider.visualPosition * parent.width
                                height: parent.height
                                radius: 2
                                color: Theme.accentColor
                            }
                        }

                        handle: Rectangle {
                            x: alphaSlider.leftPadding + alphaSlider.visualPosition * (alphaSlider.availableWidth - width)
                            y: alphaSlider.topPadding + alphaSlider.availableHeight / 2 - height / 2
                            width: 14
                            height: 14
                            radius: 7
                            color: Theme.textPrimary
                        }
                    }

                    Text {
                        text: Math.round(alphaSlider.value)
                        color: Theme.textMuted
                        font.pixelSize: Theme.fontSizeSmall
                        Layout.preferredWidth: 30
                        horizontalAlignment: Text.AlignRight
                    }
                }

                Item { Layout.fillHeight: true }

                // Buttons
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacing

                    Button {
                        text: "Cancel"
                        Layout.fillWidth: true

                        background: Rectangle {
                            color: Theme.surfaceColor
                            border.color: Theme.borderColor
                            border.width: 1
                            radius: 4
                        }

                        contentItem: Text {
                            text: parent.text
                            color: Theme.textPrimary
                            font.pixelSize: Theme.fontSizeNormal
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: colorDialog.close()
                    }

                    Button {
                        text: "OK"
                        Layout.fillWidth: true

                        background: Rectangle {
                            color: Theme.accentColor
                            radius: 4
                        }

                        contentItem: Text {
                            text: parent.text
                            color: Theme.textPrimary
                            font.pixelSize: Theme.fontSizeNormal
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            if (themeProvider && colorDialog.colorName !== "") {
                                themeProvider.setColor(colorDialog.colorName, colorDialog.selectedColor.toString())
                            }
                            colorDialog.close()
                        }
                    }
                }
            }
        }
    }

    FileDialog {
        id: saveThemeDialog
        title: "Save Theme"
        nameFilters: ["Theme files (*.json)"]
        fileMode: FileDialog.SaveFile

        onAccepted: {
            if (themeProvider) {
                themeProvider.saveThemeToPath(selectedFile.toString())
            }
        }
    }

    FileDialog {
        id: loadThemeDialog
        title: "Load Theme"
        nameFilters: ["Theme files (*.json)"]
        fileMode: FileDialog.OpenFile

        onAccepted: {
            if (themeProvider) {
                themeProvider.loadThemeFromPath(selectedFile.toString())
            }
        }
    }
}
