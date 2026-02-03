import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
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
    property int currentView: 0  // 0=main, 1=edit shortcut, 2=settings

    property var availableIcons: [
        "file.svg", "folder.svg", "globe.svg", "terminal.svg", "link.svg",
        "app-window.svg", "chromium.svg", "code.svg", "database.svg", "file-text.svg",
        "film.svg", "gamepad-2.svg", "git-branch.svg", "hard-drive.svg", "image.svg",
        "mail.svg", "message-circle.svg", "music.svg", "package.svg", "pen-tool.svg",
        "settings.svg", "shopping-cart.svg", "slack.svg", "github.svg", "twitch.svg",
        "video.svg", "youtube.svg", "zap.svg", "coffee.svg", "camera.svg"
    ]

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
                {icon: "eye-off.svg", action: "minimize"}
            ]

            onButtonClicked: function(action) {
                if (action === "minimize") {
                    launcherWindow.toggleMinimize()
                } else if (action === "add") {
                    launcherWindow.editingShortcutId = ""
                    launcherWindow.editingIcon = "file.svg"
                    launcherWindow.useCustomIcon = false
                    nameField.text = ""
                    pathField.text = ""
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
                                                source: {
                                                    if (modelData.useCustomIcon) {
                                                        return iconsPath + (modelData.icon || "file.svg")
                                                    }
                                                    if (modelData.extractedIcon) {
                                                        return modelData.extractedIcon
                                                    }
                                                    return iconsPath + (modelData.icon || "file.svg")
                                                }
                                                sourceSize: Qt.size(28, 28)
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
                                                    nameField.text = modelData.name
                                                    pathField.text = modelData.path
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
                                        launcherBackend.addShortcut(name, path, icon, false)
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
                            text: "Name"
                            color: Theme.textSecondary
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        TextField {
                            id: nameField
                            Layout.fillWidth: true
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
                            text: "Path"
                            color: Theme.textSecondary
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        TextField {
                            id: pathField
                            Layout.fillWidth: true
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
                            text: "Icon"
                            color: Theme.textSecondary
                            font.pixelSize: Theme.fontSizeSmall
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacing

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 32
                                radius: Theme.borderRadius
                                color: !launcherWindow.useCustomIcon ? Theme.accentColor : (defaultIconArea.containsMouse ? Theme.borderColor : Theme.surfaceColor)

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
                                        launcherWindow.editingIcon = launcherBackend.getIconForPath(pathField.text)
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 32
                                radius: Theme.borderRadius
                                color: launcherWindow.useCustomIcon ? Theme.accentColor : (customIconArea.containsMouse ? Theme.borderColor : Theme.surfaceColor)

                                Text {
                                    anchors.centerIn: parent
                                    text: "Custom"
                                    color: Theme.textPrimary
                                    font.pixelSize: Theme.fontSizeSmall
                                }

                                MouseArea {
                                    id: customIconArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: launcherWindow.useCustomIcon = true
                                }
                            }
                        }

                        ScrollView {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 72
                            clip: true
                            contentWidth: availableWidth
                            visible: launcherWindow.useCustomIcon

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
                            radius: Theme.borderRadius
                            color: Theme.surfaceColor
                            visible: !launcherWindow.useCustomIcon

                            property string extractedUrl: launcherBackend.getExtractedIconUrl(pathField.text)

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: Theme.spacing

                                Image {
                                    source: parent.parent.extractedUrl || (iconsPath + (launcherWindow.editingIcon || "file.svg"))
                                    sourceSize: Qt.size(24, 24)
                                }

                                Text {
                                    text: parent.parent.extractedUrl ? "Using extracted icon" : "Using default icon for file type"
                                    color: Theme.textSecondary
                                    font.pixelSize: Theme.fontSizeSmall
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        RowLayout {
                            Layout.fillWidth: true
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
                                                launcherBackend.updateShortcut(launcherWindow.editingShortcutId, nameField.text, launcherWindow.editingIcon, launcherWindow.useCustomIcon)
                                            } else {
                                                launcherBackend.addShortcut(nameField.text, pathField.text, launcherWindow.editingIcon, launcherWindow.useCustomIcon)
                                            }
                                            launcherWindow.currentView = 0
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Settings view (index 2)
                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.padding
                        spacing: Theme.spacing

                        Text {
                            text: "Grid Columns"
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

                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }
    }
}
