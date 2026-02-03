import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs
import Common 1.0

WidgetWindow {
    id: launcherWindow

    geometryKey: "launcher"
    settingsStore: settingsBackend
    editMode: hubBackend.editMode
    hubVisible: hubBackend.hubVisible
    minResizeWidth: 150
    minResizeHeight: 150

    width: 250
    height: 300
    x: 1560
    y: 100
    visible: hubBackend.launcherVisible
    title: "Launcher"

    property string editingShortcutId: ""
    property string editingIcon: ""
    property bool useCustomIcon: false
    property string customImagePath: ""
    property string workingDir: ""
    property int currentView: 0

    property var availableIcons: [
        "file.svg", "folder.svg", "globe.svg", "terminal.svg", "link.svg",
        "app-window.svg", "chromium.svg", "code.svg", "database.svg", "file-text.svg",
        "film.svg", "gamepad-2.svg", "git-branch.svg", "hard-drive.svg", "image.svg",
        "mail.svg", "message-circle.svg", "music.svg", "package.svg", "pen-tool.svg",
        "settings.svg", "shopping-cart.svg", "slack.svg", "github.svg", "twitch.svg",
        "video.svg", "youtube.svg", "zap.svg", "coffee.svg", "camera.svg"
    ]

    FileDialog {
        id: imageFileDialog
        title: "Select Image"
        nameFilters: ["Image files (*.png *.jpg *.jpeg *.gif *.bmp *.svg *.ico)"]
        onAccepted: {
            launcherWindow.customImagePath = selectedFile.toString()
        }
    }

    Column {
        anchors.fill: parent
        spacing: 0

        TitleBar {
            id: titleBar
            width: parent.width
            title: launcherWindow.currentView === 0 ? "Launcher" : (launcherWindow.currentView === 2 ? "Settings" : (launcherWindow.editingShortcutId ? "Edit Shortcut" : "Add Shortcut"))
            dragEnabled: launcherWindow.editMode
            minimized: launcherWindow.minimized
            effectiveRadius: launcherWindow.effectiveWindowRadius
            leftButtons: launcherWindow.currentView !== 0 ? [
                {icon: "arrow-left.svg", action: "back", enabled: !hubBackend.editMode}
            ] : [
                {icon: "plus.svg", action: "add", enabled: !hubBackend.editMode},
                {icon: "settings.svg", action: "settings", enabled: !hubBackend.editMode}
            ]
            rightButtons: [
                {icon: launcherWindow.minimized ? "eye.svg" : "eye-off.svg", action: "minimize"}
            ]

            onButtonClicked: function(action) {
                if (action === "minimize") {
                    launcherWindow.toggleMinimize()
                } else if (action === "add") {
                    launcherWindow.editingShortcutId = ""
                    launcherWindow.editingIcon = "file.svg"
                    launcherWindow.useCustomIcon = false
                    launcherWindow.customImagePath = ""
                    launcherWindow.workingDir = ""
                    nameField.text = ""
                    pathField.text = ""
                    workingDirField.text = ""
                    launcherWindow.currentView = 1
                } else if (action === "settings") {
                    launcherWindow.currentView = 2
                } else if (action === "back") {
                    launcherWindow.currentView = 0
                }
            }
        }

        Rectangle {
            width: parent.width
            height: parent.height - titleBar.height
            color: "transparent"
            visible: !launcherWindow.minimized

            StackLayout {
                anchors.fill: parent
                currentIndex: launcherWindow.currentView

                Item {
                    id: mainView

                    Text {
                        anchors.centerIn: parent
                        width: parent.width - Theme.padding * 4
                        text: "No shortcuts yet.\n\nUse the + button in the\ntitle bar to add one,\nor drag files here.\n\nRight-click items to edit."
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSizeNormal
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        visible: launcherBackend.shortcuts.length === 0
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.padding
                        spacing: Theme.spacing
                        visible: launcherBackend.shortcuts.length > 0

                        TextField {
                            id: searchField
                            Layout.fillWidth: true
                            placeholderText: "Search..."
                            color: Theme.textPrimary
                            font.pixelSize: Theme.fontSizeNormal
                            visible: launcherBackend.showSearchBar

                            background: Rectangle {
                                color: Theme.surfaceColor
                                border.color: searchField.activeFocus ? Theme.accentColor : Theme.borderColor
                                border.width: 1
                                radius: Theme.borderRadius
                            }

                            onTextChanged: launcherBackend.setSearchQuery(text)
                        }

                        ScrollView {
                            id: shortcutsScrollView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            contentWidth: availableWidth

                            property int numColumns: launcherBackend.columns
                            property int cellSize: Math.floor((availableWidth - (numColumns - 1) * Theme.spacing) / numColumns)

                            Flow {
                                id: shortcutsFlow
                                width: parent.width
                                spacing: Theme.spacing

                                Repeater {
                                    model: launcherBackend.shortcuts

                                    delegate: Rectangle {
                                        width: shortcutsScrollView.cellSize
                                        height: shortcutsScrollView.cellSize
                                        radius: Theme.borderRadius
                                        color: shortcutArea.containsMouse ? Theme.surfaceColor : "transparent"

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 4
                                            spacing: 2

                                            Image {
                                                Layout.alignment: Qt.AlignHCenter
                                                Layout.preferredWidth: launcherBackend.iconSize
                                                Layout.preferredHeight: launcherBackend.iconSize
                                                fillMode: Image.PreserveAspectFit
                                                source: {
                                                    if (modelData.customImagePath) {
                                                        return modelData.customImagePath
                                                    }
                                                    if (modelData.useCustomIcon) {
                                                        return iconsPath + (modelData.icon || "file.svg")
                                                    }
                                                    if (modelData.extractedIcon) {
                                                        return modelData.extractedIcon
                                                    }
                                                    return iconsPath + (modelData.icon || "file.svg")
                                                }
                                                sourceSize: Qt.size(launcherBackend.iconSize, launcherBackend.iconSize)
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.name
                                                color: Theme.textPrimary
                                                font.pixelSize: Theme.fontSizeSmall
                                                horizontalAlignment: Text.AlignHCenter
                                                elide: Text.ElideRight
                                                maximumLineCount: 2
                                                wrapMode: Text.WordWrap
                                            }
                                        }

                                        MouseArea {
                                            id: shortcutArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            acceptedButtons: Qt.LeftButton | Qt.RightButton

                                            onClicked: function(mouse) {
                                                if (mouse.button === Qt.LeftButton) {
                                                    launcherBackend.launchShortcut(modelData.id)
                                                } else if (mouse.button === Qt.RightButton) {
                                                    launcherWindow.editingShortcutId = modelData.id
                                                    launcherWindow.editingIcon = modelData.icon || "file.svg"
                                                    launcherWindow.customImagePath = modelData.customImagePath || ""
                                                    launcherWindow.workingDir = modelData.workingDir || ""
                                                    nameField.text = modelData.name
                                                    pathField.text = modelData.path
                                                    workingDirField.text = modelData.workingDir || ""
                                                    launcherWindow.useCustomIcon = modelData.useCustomIcon || false
                                                    launcherWindow.currentView = 1
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    DropArea {
                        anchors.fill: parent
                        z: -1

                        onDropped: function(drop) {
                            if (drop.hasUrls) {
                                for (var i = 0; i < drop.urls.length; i++) {
                                    var url = drop.urls[i].toString()
                                    if (url.startsWith("file:///")) {
                                        var path = url.substring(8)
                                        var name = launcherBackend.getNameFromPath(path)
                                        var icon = launcherBackend.getIconForPath(path)
                                        launcherBackend.addShortcut(name, path, icon, false, "", "")
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    ScrollView {
                        anchors.fill: parent
                        contentWidth: availableWidth
                        clip: true

                        ColumnLayout {
                            width: parent.width
                            spacing: Theme.spacing

                            Item { Layout.preferredHeight: Theme.padding / 2 }

                            Text {
                                Layout.leftMargin: Theme.padding
                                Layout.rightMargin: Theme.padding
                                text: "Name"
                                color: Theme.textSecondary
                                font.pixelSize: Theme.fontSizeSmall
                            }

                            TextField {
                                id: nameField
                                Layout.fillWidth: true
                                Layout.leftMargin: Theme.padding
                                Layout.rightMargin: Theme.padding
                                placeholderText: "Shortcut name..."
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSizeNormal

                                background: Rectangle {
                                    color: Theme.surfaceColor
                                    border.color: nameField.activeFocus ? Theme.accentColor : Theme.borderColor
                                    border.width: 1
                                    radius: Theme.borderRadius
                                }
                            }

                            Text {
                                Layout.leftMargin: Theme.padding
                                Layout.rightMargin: Theme.padding
                                text: "Path"
                                color: Theme.textSecondary
                                font.pixelSize: Theme.fontSizeSmall
                            }

                            TextField {
                                id: pathField
                                Layout.fillWidth: true
                                Layout.leftMargin: Theme.padding
                                Layout.rightMargin: Theme.padding
                                placeholderText: "Full path to file or folder..."
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSizeNormal

                                background: Rectangle {
                                    color: Theme.surfaceColor
                                    border.color: pathField.activeFocus ? Theme.accentColor : Theme.borderColor
                                    border.width: 1
                                    radius: Theme.borderRadius
                                }
                            }

                            Text {
                                Layout.leftMargin: Theme.padding
                                Layout.rightMargin: Theme.padding
                                text: "Working Directory"
                                color: Theme.textSecondary
                                font.pixelSize: Theme.fontSizeSmall
                            }

                            TextField {
                                id: workingDirField
                                Layout.fillWidth: true
                                Layout.leftMargin: Theme.padding
                                Layout.rightMargin: Theme.padding
                                placeholderText: "Leave empty to use exe folder..."
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSizeNormal

                                background: Rectangle {
                                    color: Theme.surfaceColor
                                    border.color: workingDirField.activeFocus ? Theme.accentColor : Theme.borderColor
                                    border.width: 1
                                    radius: Theme.borderRadius
                                }
                            }

                            Text {
                                Layout.leftMargin: Theme.padding
                                Layout.rightMargin: Theme.padding
                                text: "Icon"
                                color: Theme.textSecondary
                                font.pixelSize: Theme.fontSizeSmall
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.leftMargin: Theme.padding
                                Layout.rightMargin: Theme.padding
                                spacing: 4

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 28
                                    radius: Theme.borderRadius
                                    color: (!launcherWindow.useCustomIcon && !launcherWindow.customImagePath) ? Theme.accentColor : (defaultIconArea.containsMouse ? Theme.borderColor : Theme.surfaceColor)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Default"
                                        color: Theme.textPrimary
                                        font.pixelSize: Theme.fontSizeSmall
                                    }

                                    MouseArea {
                                        id: defaultIconArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            launcherWindow.useCustomIcon = false
                                            launcherWindow.customImagePath = ""
                                            launcherWindow.editingIcon = launcherBackend.getIconForPath(pathField.text)
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 28
                                    radius: Theme.borderRadius
                                    color: (launcherWindow.useCustomIcon && !launcherWindow.customImagePath) ? Theme.accentColor : (presetIconArea.containsMouse ? Theme.borderColor : Theme.surfaceColor)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Preset"
                                        color: Theme.textPrimary
                                        font.pixelSize: Theme.fontSizeSmall
                                    }

                                    MouseArea {
                                        id: presetIconArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            launcherWindow.useCustomIcon = true
                                            launcherWindow.customImagePath = ""
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 28
                                    radius: Theme.borderRadius
                                    color: launcherWindow.customImagePath ? Theme.accentColor : (imageIconArea.containsMouse ? Theme.borderColor : Theme.surfaceColor)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Image"
                                        color: Theme.textPrimary
                                        font.pixelSize: Theme.fontSizeSmall
                                    }

                                    MouseArea {
                                        id: imageIconArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: imageFileDialog.open()
                                    }
                                }
                            }

                            ScrollView {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 72
                                Layout.leftMargin: Theme.padding
                                Layout.rightMargin: Theme.padding
                                clip: true
                                contentWidth: availableWidth
                                visible: launcherWindow.useCustomIcon && !launcherWindow.customImagePath

                                Flow {
                                    width: parent.width
                                    spacing: 4

                                    Repeater {
                                        model: launcherWindow.availableIcons

                                        delegate: Rectangle {
                                            width: 32
                                            height: 32
                                            radius: 4
                                            color: launcherWindow.editingIcon === modelData ? Theme.accentColor : (iconArea.containsMouse ? Theme.surfaceColor : "transparent")
                                            border.color: launcherWindow.editingIcon === modelData ? Theme.accentColor : "transparent"
                                            border.width: 2

                                            Image {
                                                anchors.centerIn: parent
                                                source: iconsPath + modelData
                                                sourceSize: Qt.size(20, 20)
                                            }

                                            MouseArea {
                                                id: iconArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                onClicked: launcherWindow.editingIcon = modelData
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 48
                                Layout.leftMargin: Theme.padding
                                Layout.rightMargin: Theme.padding
                                radius: Theme.borderRadius
                                color: Theme.surfaceColor
                                visible: !launcherWindow.useCustomIcon && !launcherWindow.customImagePath

                                property string extractedUrl: launcherBackend.getExtractedIconUrl(pathField.text)

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: Theme.spacing

                                    Image {
                                        source: parent.parent.extractedUrl || (iconsPath + (launcherWindow.editingIcon || "file.svg"))
                                        sourceSize: Qt.size(24, 24)
                                    }

                                    Text {
                                        text: parent.parent.extractedUrl ? "Using extracted icon" : "Using default icon"
                                        color: Theme.textSecondary
                                        font.pixelSize: Theme.fontSizeSmall
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 48
                                Layout.leftMargin: Theme.padding
                                Layout.rightMargin: Theme.padding
                                radius: Theme.borderRadius
                                color: Theme.surfaceColor
                                visible: launcherWindow.customImagePath

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: Theme.padding / 2
                                    spacing: Theme.spacing

                                    Image {
                                        source: launcherWindow.customImagePath
                                        sourceSize: Qt.size(32, 32)
                                        fillMode: Image.PreserveAspectFit
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: launcherWindow.customImagePath.split("/").pop().split("\\").pop()
                                        color: Theme.textSecondary
                                        font.pixelSize: Theme.fontSizeSmall
                                        elide: Text.ElideMiddle
                                    }

                                    Rectangle {
                                        width: 24
                                        height: 24
                                        radius: 4
                                        color: clearImgArea.containsMouse ? Theme.colorRed : Theme.surfaceColor

                                        Text {
                                            anchors.centerIn: parent
                                            text: "x"
                                            color: Theme.textPrimary
                                            font.pixelSize: 12
                                        }

                                        MouseArea {
                                            id: clearImgArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: launcherWindow.customImagePath = ""
                                        }
                                    }
                                }
                            }

                            Item { Layout.fillHeight: true }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.leftMargin: Theme.padding
                                Layout.rightMargin: Theme.padding
                                Layout.bottomMargin: Theme.padding
                                spacing: Theme.spacing

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 36
                                    radius: Theme.borderRadius
                                    color: deleteBtn.containsMouse ? Theme.colorRed : Theme.surfaceColor
                                    visible: launcherWindow.editingShortcutId !== ""

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Delete"
                                        color: Theme.textPrimary
                                        font.pixelSize: Theme.fontSizeNormal
                                    }

                                    MouseArea {
                                        id: deleteBtn
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            launcherBackend.removeShortcut(launcherWindow.editingShortcutId)
                                            launcherWindow.currentView = 0
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 36
                                    radius: Theme.borderRadius
                                    color: saveBtn.containsMouse ? Theme.accentHover : Theme.accentColor

                                    Text {
                                        anchors.centerIn: parent
                                        text: launcherWindow.editingShortcutId ? "Save" : "Add"
                                        color: Theme.textPrimary
                                        font.pixelSize: Theme.fontSizeNormal
                                    }

                                    MouseArea {
                                        id: saveBtn
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            if (nameField.text && pathField.text) {
                                                if (launcherWindow.editingShortcutId) {
                                                    launcherBackend.updateShortcut(launcherWindow.editingShortcutId, nameField.text, launcherWindow.editingIcon, launcherWindow.useCustomIcon, launcherWindow.customImagePath, workingDirField.text)
                                                } else {
                                                    launcherBackend.addShortcut(nameField.text, pathField.text, launcherWindow.editingIcon, launcherWindow.useCustomIcon, launcherWindow.customImagePath, workingDirField.text)
                                                }
                                                launcherWindow.currentView = 0
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    ScrollView {
                        anchors.fill: parent
                        contentWidth: availableWidth
                        clip: true

                        ColumnLayout {
                            width: parent.width
                            spacing: Theme.spacing

                            Item { Layout.preferredHeight: Theme.padding }

                            Text {
                                Layout.leftMargin: Theme.padding
                                Layout.rightMargin: Theme.padding
                                text: "Grid Columns"
                                color: Theme.textSecondary
                                font.pixelSize: Theme.fontSizeSmall
                            }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: Theme.padding
                            Layout.rightMargin: Theme.padding
                            spacing: 4

                            Rectangle {
                                width: 28
                                height: 28
                                radius: Theme.borderRadius
                                color: colDown.pressed ? Theme.accentColor : (colDown.containsMouse ? Theme.borderColor : Theme.surfaceColor)

                                Text {
                                    anchors.centerIn: parent
                                    text: "-"
                                    color: Theme.textPrimary
                                    font.pixelSize: 14
                                }

                                MouseArea {
                                    id: colDown
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: if (launcherBackend.columns > 1) launcherBackend.setColumns(launcherBackend.columns - 1)
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
                                    text: launcherBackend.columns
                                    color: Theme.textPrimary
                                    font.pixelSize: Theme.fontSizeNormal
                                }
                            }

                            Rectangle {
                                width: 28
                                height: 28
                                radius: Theme.borderRadius
                                color: colUp.pressed ? Theme.accentColor : (colUp.containsMouse ? Theme.borderColor : Theme.surfaceColor)

                                Text {
                                    anchors.centerIn: parent
                                    text: "+"
                                    color: Theme.textPrimary
                                    font.pixelSize: 14
                                }

                                MouseArea {
                                    id: colUp
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: if (launcherBackend.columns < 8) launcherBackend.setColumns(launcherBackend.columns + 1)
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: Theme.padding
                            Layout.rightMargin: Theme.padding
                            spacing: Theme.spacing

                            Text {
                                text: "Show Search Bar"
                                color: Theme.textSecondary
                                font.pixelSize: Theme.fontSizeSmall
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                width: 44
                                height: 24
                                radius: 12
                                color: launcherBackend.showSearchBar ? Theme.accentColor : Theme.surfaceColor
                                border.color: launcherBackend.showSearchBar ? Theme.accentColor : Theme.borderColor
                                border.width: 1

                                Rectangle {
                                    width: 18
                                    height: 18
                                    radius: 9
                                    x: launcherBackend.showSearchBar ? parent.width - width - 3 : 3
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: Theme.textPrimary

                                    Behavior on x { NumberAnimation { duration: 150 } }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: launcherBackend.setShowSearchBar(!launcherBackend.showSearchBar)
                                }
                            }
                        }

                        Text {
                            Layout.leftMargin: Theme.padding
                            Layout.rightMargin: Theme.padding
                            text: "Icon Size"
                            color: Theme.textSecondary
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: Theme.padding
                            Layout.rightMargin: Theme.padding
                            spacing: 4

                            Rectangle {
                                width: 28
                                height: 28
                                radius: Theme.borderRadius
                                color: iconDown.pressed ? Theme.accentColor : (iconDown.containsMouse ? Theme.borderColor : Theme.surfaceColor)

                                Text {
                                    anchors.centerIn: parent
                                    text: "-"
                                    color: Theme.textPrimary
                                    font.pixelSize: 14
                                }

                                MouseArea {
                                    id: iconDown
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: if (launcherBackend.iconSize > 16) launcherBackend.setIconSize(launcherBackend.iconSize - 4)
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
                                    text: launcherBackend.iconSize + "px"
                                    color: Theme.textPrimary
                                    font.pixelSize: Theme.fontSizeNormal
                                }
                            }

                            Rectangle {
                                width: 28
                                height: 28
                                radius: Theme.borderRadius
                                color: iconUp.pressed ? Theme.accentColor : (iconUp.containsMouse ? Theme.borderColor : Theme.surfaceColor)

                                Text {
                                    anchors.centerIn: parent
                                    text: "+"
                                    color: Theme.textPrimary
                                    font.pixelSize: 14
                                }

                                MouseArea {
                                    id: iconUp
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: if (launcherBackend.iconSize < 64) launcherBackend.setIconSize(launcherBackend.iconSize + 4)
                                }
                            }
                        }

                        Item { Layout.preferredHeight: Theme.padding }
                    }
                    }
                }
            }
        }
    }
}
