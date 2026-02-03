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

    Column {
        anchors.fill: parent
        spacing: 0

        TitleBar {
            id: titleBar
            width: parent.width
            title: "Launcher"
            dragEnabled: launcherWindow.editMode
            minimized: launcherWindow.minimized
            effectiveRadius: launcherWindow.effectiveWindowRadius
            rightButtons: [
                {icon: "eye-off.svg", action: "minimize"}
            ]

            onButtonClicked: function(action) {
                if (action === "minimize") {
                    launcherWindow.toggleMinimize()
                }
            }
        }

        Rectangle {
            width: parent.width
            height: parent.height - titleBar.height
            color: "transparent"
            visible: !launcherWindow.minimized

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
                                            contextMenu.shortcutId = modelData.id
                                            contextMenu.popup()
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
                            border.style: Qt.DashLine

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
                                onClicked: addDialog.open()
                            }
                        }
                    }
                }
            }

            DropArea {
                anchors.fill: parent

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
    }

    Menu {
        id: contextMenu
        property string shortcutId: ""

        MenuItem {
            text: "Remove"
            onTriggered: launcherBackend.removeShortcut(contextMenu.shortcutId)
        }
    }

    Dialog {
        id: addDialog
        title: "Add Shortcut"
        anchors.centerIn: parent
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel

        background: Rectangle {
            color: Theme.windowBackground
            border.color: Theme.borderColor
            border.width: 1
            radius: Theme.borderRadius
        }

        ColumnLayout {
            spacing: Theme.spacing

            Text {
                text: "Name"
                color: Theme.textPrimary
                font.pixelSize: Theme.fontSizeNormal
            }

            TextField {
                id: nameField
                Layout.preferredWidth: 250
                placeholderText: "Shortcut name..."
                color: Theme.textPrimary

                background: Rectangle {
                    color: Theme.surfaceColor
                    border.color: Theme.borderColor
                    radius: Theme.borderRadius
                }
            }

            Text {
                text: "Path"
                color: Theme.textPrimary
                font.pixelSize: Theme.fontSizeNormal
            }

            TextField {
                id: pathField
                Layout.preferredWidth: 250
                placeholderText: "Full path to file or folder..."
                color: Theme.textPrimary

                background: Rectangle {
                    color: Theme.surfaceColor
                    border.color: Theme.borderColor
                    radius: Theme.borderRadius
                }
            }
        }

        onAccepted: {
            if (nameField.text && pathField.text) {
                launcherBackend.addShortcut(nameField.text, pathField.text, "")
                nameField.text = ""
                pathField.text = ""
            }
        }

        onRejected: {
            nameField.text = ""
            pathField.text = ""
        }
    }
}
