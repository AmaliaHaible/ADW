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
    minResizeWidth: 200
    minResizeHeight: 200

    width: 250
    height: 300
    x: 1560
    y: 100
    visible: hubBackend.launcherVisible
    title: "Launcher"

    property string editingShortcutId: ""
    property int currentView: 0

    Column {
        anchors.fill: parent
        spacing: 0

        TitleBar {
            id: titleBar
            width: parent.width
            title: launcherWindow.currentView === 0 ? "Launcher" : (launcherWindow.editingShortcutId ? "Edit Shortcut" : "Add Shortcut")
            dragEnabled: launcherWindow.editMode
            minimized: launcherWindow.minimized
            effectiveRadius: launcherWindow.effectiveWindowRadius
            leftButtons: launcherWindow.currentView === 1 ? [
                {icon: "arrow-left.svg", action: "back", enabled: !hubBackend.editMode}
            ] : [
                {icon: "plus.svg", action: "add", enabled: !hubBackend.editMode}
            ]
            rightButtons: [
                {icon: "eye-off.svg", action: "minimize"}
            ]

            onButtonClicked: function(action) {
                if (action === "minimize") {
                    launcherWindow.toggleMinimize()
                } else if (action === "add") {
                    launcherWindow.editingShortcutId = ""
                    nameField.text = ""
                    pathField.text = ""
                    launcherWindow.currentView = 1
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
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.padding
                        spacing: Theme.spacing

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
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            contentWidth: availableWidth

                            GridLayout {
                                width: parent.width
                                columns: 3
                                columnSpacing: Theme.spacing
                                rowSpacing: Theme.spacing

                                Repeater {
                                    model: launcherBackend.shortcuts

                                    delegate: Rectangle {
                                        Layout.preferredWidth: 64
                                        Layout.preferredHeight: 64
                                        radius: Theme.borderRadius
                                        color: shortcutArea.containsMouse ? Theme.surfaceColor : "transparent"

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 4
                                            spacing: 2

                                            Image {
                                                Layout.alignment: Qt.AlignHCenter
                                                source: iconsPath + (modelData.icon || "file.svg")
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
                                                    nameField.text = modelData.name
                                                    pathField.text = modelData.path
                                                    launcherWindow.currentView = 1
                                                }
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.preferredWidth: 64
                                    Layout.preferredHeight: 64
                                    radius: Theme.borderRadius
                                    color: addArea.containsMouse ? Theme.surfaceColor : "transparent"
                                    border.color: Theme.borderColor
                                    border.width: 1

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Image {
                                            Layout.alignment: Qt.AlignHCenter
                                            source: iconsPath + "plus.svg"
                                            sourceSize: Qt.size(24, 24)
                                        }

                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: "Add"
                                            color: Theme.textSecondary
                                            font.pixelSize: Theme.fontSizeSmall
                                        }
                                    }

                                    MouseArea {
                                        id: addArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            launcherWindow.editingShortcutId = ""
                                            nameField.text = ""
                                            pathField.text = ""
                                            launcherWindow.currentView = 1
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
                                        launcherBackend.addShortcut(name, path, "")
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

                        Item { Layout.fillHeight: true }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacing

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                radius: Theme.borderRadius
                                color: deleteBtn.containsMouse ? Theme.error : Theme.surfaceColor
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
                                                launcherBackend.updateShortcutName(launcherWindow.editingShortcutId, nameField.text)
                                            } else {
                                                launcherBackend.addShortcut(nameField.text, pathField.text, "")
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
        }
    }
}
