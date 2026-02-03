import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Common 1.0

WidgetWindow {
    id: notesWindow

    geometryKey: "notes"
    settingsStore: settingsBackend
    editMode: hubBackend.editMode
    hubVisible: hubBackend.hubVisible
    minResizeWidth: 250
    minResizeHeight: 300

    width: 300
    height: 400
    x: 1000
    y: 100
    visible: hubBackend.notesVisible
    title: "Notes"

    property bool showingEditor: notesBackend.currentNoteId !== ""

    Column {
        anchors.fill: parent
        spacing: 0

        TitleBar {
            id: titleBar
            width: parent.width
            title: notesWindow.showingEditor ? "Edit Note" : "Notes"
            dragEnabled: notesWindow.editMode
            minimized: notesWindow.minimized
            effectiveRadius: notesWindow.effectiveWindowRadius
            leftButtons: notesWindow.showingEditor ? [
                {icon: "arrow-left.svg", action: "back", enabled: !hubBackend.editMode}
            ] : [
                {icon: "plus.svg", action: "new", enabled: !hubBackend.editMode}
            ]
            rightButtons: [
                {icon: "eye-off.svg", action: "minimize"}
            ]

            onButtonClicked: function(action) {
                if (action === "minimize") {
                    notesWindow.toggleMinimize()
                } else if (action === "new") {
                    notesBackend.createNote()
                } else if (action === "back") {
                    notesBackend.selectNote("")
                }
            }
        }

        Rectangle {
            width: parent.width
            height: parent.height - titleBar.height
            color: "transparent"
            visible: !notesWindow.minimized

            StackLayout {
                anchors.fill: parent
                currentIndex: notesWindow.showingEditor ? 1 : 0

                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.padding
                        spacing: Theme.spacing

                        TextField {
                            id: searchField
                            Layout.fillWidth: true
                            placeholderText: "Search notes..."
                            color: Theme.textPrimary
                            font.pixelSize: Theme.fontSizeNormal

                            background: Rectangle {
                                color: Theme.surfaceColor
                                border.color: searchField.activeFocus ? Theme.accentColor : Theme.borderColor
                                border.width: 1
                                radius: Theme.borderRadius
                            }

                            onTextChanged: notesBackend.setSearchQuery(text)
                        }

                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            contentWidth: availableWidth

                            ColumnLayout {
                                width: parent.width
                                spacing: Theme.spacing / 2

                                Repeater {
                                    model: notesBackend.notes

                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 56
                                        radius: Theme.borderRadius
                                        color: noteMouseArea.containsMouse ? Theme.surfaceColor : modelData.color || Theme.surfaceColor
                                        border.color: Theme.borderColor
                                        border.width: 1
                                        clip: true

                                        Column {
                                            anchors.fill: parent
                                            anchors.margins: Theme.padding / 2
                                            spacing: 2

                                            Text {
                                                width: parent.width
                                                text: modelData.title || "Untitled"
                                                color: modelData.textColor || Theme.textPrimary
                                                font.pixelSize: Theme.fontSizeNormal
                                                font.weight: Font.Medium
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                width: parent.width
                                                height: 28
                                                text: modelData.content || ""
                                                color: modelData.textColor ? Qt.lighter(modelData.textColor, 1.3) : Theme.textSecondary
                                                font.pixelSize: Theme.fontSizeSmall
                                                elide: Text.ElideRight
                                                maximumLineCount: 2
                                                wrapMode: Text.WordWrap
                                                clip: true
                                            }
                                        }

                                        MouseArea {
                                            id: noteMouseArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: notesBackend.selectNote(modelData.id)
                                        }
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    Layout.topMargin: Theme.padding * 2
                                    text: "No notes yet.\nClick + to create one."
                                    color: Theme.textSecondary
                                    font.pixelSize: Theme.fontSizeNormal
                                    horizontalAlignment: Text.AlignHCenter
                                    visible: notesBackend.notes.length === 0
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

                        TextField {
                            id: titleField
                            Layout.fillWidth: true
                            text: notesBackend.currentNote ? notesBackend.currentNote.title : ""
                            placeholderText: "Note title..."
                            color: Theme.textPrimary
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.Medium

                            background: Rectangle {
                                color: "transparent"
                                border.color: titleField.activeFocus ? Theme.accentColor : "transparent"
                                border.width: 1
                                radius: Theme.borderRadius
                            }

                            onTextChanged: {
                                if (notesBackend.currentNoteId && text !== notesBackend.currentNote?.title) {
                                    titleSaveTimer.restart()
                                }
                            }

                            Timer {
                                id: titleSaveTimer
                                interval: 500
                                onTriggered: notesBackend.updateNoteTitle(notesBackend.currentNoteId, titleField.text)
                            }
                        }

                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true

                            TextArea {
                                id: contentArea
                                text: notesBackend.currentNote ? notesBackend.currentNote.content : ""
                                placeholderText: "Write your note..."
                                color: notesBackend.currentNote?.textColor || Theme.textPrimary
                                font.pixelSize: Theme.fontSizeNormal
                                wrapMode: TextArea.Wrap

                                background: Rectangle {
                                    color: notesBackend.currentNote?.color || Theme.surfaceColor
                                    border.color: contentArea.activeFocus ? Theme.accentColor : Theme.borderColor
                                    border.width: 1
                                    radius: Theme.borderRadius
                                }

                                onTextChanged: {
                                    if (notesBackend.currentNoteId && text !== notesBackend.currentNote?.content) {
                                        contentSaveTimer.restart()
                                    }
                                }

                                Timer {
                                    id: contentSaveTimer
                                    interval: 500
                                    onTriggered: notesBackend.updateNoteContent(notesBackend.currentNoteId, contentArea.text)
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacing

                            Text {
                                text: "Bg:"
                                color: Theme.textSecondary
                                font.pixelSize: Theme.fontSizeSmall
                            }

                            Repeater {
                                model: ["#313244", "#f38ba8", "#fab387", "#a6e3a1", "#89b4fa", "#cba6f7"]

                                delegate: Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: modelData
                                    border.color: notesBackend.currentNote?.color === modelData ? Theme.textPrimary : "transparent"
                                    border.width: 2

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: notesBackend.updateNoteColor(notesBackend.currentNoteId, modelData)
                                    }
                                }
                            }

                            Rectangle {
                                width: 1
                                height: 20
                                color: Theme.borderColor
                            }

                            Text {
                                text: "Txt:"
                                color: Theme.textSecondary
                                font.pixelSize: Theme.fontSizeSmall
                            }

                            Repeater {
                                model: ["#cdd6f4", "#313244", "#1e1e2e", "#45475a"]

                                delegate: Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: modelData
                                    border.color: notesBackend.currentNote?.textColor === modelData ? Theme.accentColor : Theme.borderColor
                                    border.width: 2

                                    Text {
                                        anchors.centerIn: parent
                                        text: "A"
                                        color: index < 1 ? "#313244" : "#cdd6f4"
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: notesBackend.updateNoteTextColor(notesBackend.currentNoteId, modelData)
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                width: 32
                                height: 32
                                radius: Theme.borderRadius
                                color: deleteArea.containsMouse ? Theme.error : Theme.surfaceColor

                                Image {
                                    anchors.centerIn: parent
                                    source: iconsPath + "trash-2.svg"
                                    sourceSize: Qt.size(16, 16)
                                }

                                MouseArea {
                                    id: deleteArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        notesBackend.deleteNote(notesBackend.currentNoteId)
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
