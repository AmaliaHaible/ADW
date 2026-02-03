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
    property string draggedNoteId: ""
    property int draggedItemIndex: -1
    property int dragTargetIndex: -1

    function isLightColor(hexColor) {
        if (!hexColor || hexColor.length < 7) return false
        var r = parseInt(hexColor.substring(1, 3), 16)
        var g = parseInt(hexColor.substring(3, 5), 16)
        var b = parseInt(hexColor.substring(5, 7), 16)
        var luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255
        return luminance > 0.5
    }

    function getTextColor(bgColor) {
        return isLightColor(bgColor) ? Theme.textPrimaryDark : Theme.textPrimary
    }

    function getSecondaryTextColor(bgColor) {
        return isLightColor(bgColor) ? Theme.textSecondaryDark : Theme.textSecondary
    }

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
                {icon: notesWindow.minimized ? "eye.svg" : "eye-off.svg", action: "minimize"}
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
                                spacing: 0

                                Repeater {
                                    model: notesBackend.notes

                                    delegate: ColumnLayout {
                                        id: noteItemRoot
                                        property int itemIndex: index
                                        property int totalItems: notesBackend.notes.length
                                        property int colorIdx: modelData.colorIndex !== undefined ? modelData.colorIndex : 0
                                        property color noteColor: notesBackend.availableColors[colorIdx] || Theme.surfaceColor
                                        property color hoverColor: isLightColor(noteColor.toString()) ? Qt.darker(noteColor, 1.1) : Qt.lighter(noteColor, 1.2)

                                        Layout.fillWidth: true
                                        spacing: 0

                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 3
                                            color: Theme.accentColor
                                            radius: 1
                                            visible: notesWindow.draggedNoteId !== "" &&
                                                     notesWindow.draggedNoteId !== modelData.id &&
                                                     notesWindow.dragTargetIndex === itemIndex &&
                                                     notesWindow.draggedItemIndex !== itemIndex - 1
                                        }

                                        Rectangle {
                                            id: noteItem
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 56
                                            Layout.topMargin: Theme.spacing / 4
                                            Layout.bottomMargin: Theme.spacing / 4
                                            radius: Theme.borderRadius
                                            color: noteHoverHandler.hovered || noteDragHandler.active ? hoverColor : noteColor
                                            border.color: Theme.borderColor
                                            border.width: 1
                                            clip: true
                                            opacity: notesWindow.draggedNoteId === modelData.id ? 0.5 : 1.0

                                            HoverHandler {
                                                id: noteHoverHandler
                                            }

                                            DragHandler {
                                                id: noteDragHandler
                                                target: null

                                                onActiveChanged: {
                                                    if (active) {
                                                        notesWindow.draggedNoteId = modelData.id
                                                        notesWindow.draggedItemIndex = itemIndex
                                                        notesWindow.dragTargetIndex = itemIndex
                                                    } else {
                                                        var targetIdx = notesWindow.dragTargetIndex
                                                        var draggedId = modelData.id
                                                        var originalIdx = notesWindow.draggedItemIndex
                                                        var shouldReorder = false

                                                        if (notesWindow.draggedNoteId === draggedId && targetIdx >= 0) {
                                                            if (targetIdx > originalIdx) {
                                                                targetIdx = targetIdx - 1
                                                            }
                                                            if (targetIdx !== originalIdx) {
                                                                shouldReorder = true
                                                            }
                                                        }

                                                        notesWindow.draggedNoteId = ""
                                                        notesWindow.draggedItemIndex = -1
                                                        notesWindow.dragTargetIndex = -1

                                                        if (shouldReorder) {
                                                            notesBackend.reorderNote(draggedId, targetIdx)
                                                        }
                                                    }
                                                }

                                                onCentroidChanged: {
                                                    if (active) {
                                                        var dragOffset = centroid.position.y - centroid.pressPosition.y
                                                        var indexChange = Math.round(dragOffset / 60)
                                                        var newIndex = itemIndex + indexChange
                                                        newIndex = Math.max(0, Math.min(newIndex, totalItems))
                                                        notesWindow.dragTargetIndex = newIndex
                                                    }
                                                }
                                            }

                                            TapHandler {
                                                onTapped: notesBackend.selectNote(modelData.id)
                                            }

                                            Column {
                                                anchors.fill: parent
                                                anchors.margins: Theme.padding / 2
                                                spacing: 2

                                                Text {
                                                    width: parent.width
                                                    text: modelData.title || "Untitled"
                                                    color: getTextColor(noteItemRoot.noteColor.toString())
                                                    font.pixelSize: Theme.fontSizeNormal
                                                    font.weight: Font.Medium
                                                    elide: Text.ElideRight
                                                }

                                                Text {
                                                    width: parent.width
                                                    height: 28
                                                    text: modelData.content || ""
                                                    color: getSecondaryTextColor(noteItemRoot.noteColor.toString())
                                                    font.pixelSize: Theme.fontSizeSmall
                                                    elide: Text.ElideRight
                                                    maximumLineCount: 2
                                                    wrapMode: Text.WordWrap
                                                    clip: true
                                                }
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 3
                                    color: Theme.accentColor
                                    radius: 1
                                    visible: notesWindow.draggedNoteId !== "" &&
                                             notesWindow.dragTargetIndex === notesBackend.notes.length &&
                                             notesWindow.draggedItemIndex !== notesBackend.notes.length - 1
                                }

                                Text {
                                    Layout.fillWidth: true
                                    Layout.topMargin: Theme.padding * 2
                                    text: "No notes yet.\n\nUse the + button in the\ntitle bar to create one."
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
                    id: editorView
                    property int currentColorIndex: notesBackend.currentNote?.colorIndex !== undefined ? notesBackend.currentNote.colorIndex : 0
                    property color currentNoteColor: notesBackend.availableColors[currentColorIndex] || Theme.surfaceColor

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
                                placeholderTextColor: getSecondaryTextColor(editorView.currentNoteColor.toString())
                                color: getTextColor(editorView.currentNoteColor.toString())
                                font.pixelSize: Theme.fontSizeNormal
                                wrapMode: TextArea.Wrap

                                background: Rectangle {
                                    color: editorView.currentNoteColor
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

                            Repeater {
                                model: notesBackend.availableColors

                                delegate: Rectangle {
                                    width: 24
                                    height: 24
                                    radius: 12
                                    color: modelData
                                    border.color: editorView.currentColorIndex === index ? Theme.textPrimary : "transparent"
                                    border.width: 2

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: notesBackend.updateNoteColor(notesBackend.currentNoteId, index)
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Rectangle {
                                width: 32
                                height: 32
                                radius: Theme.borderRadius
                                color: deleteArea.containsMouse ? Theme.colorRed : Theme.surfaceColor

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
