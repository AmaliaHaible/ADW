import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Common 1.0

WidgetWindow {
    id: todoWindow

    geometryKey: "todo"
    settingsStore: settingsBackend
    editMode: hubBackend.editMode
    hubVisible: hubBackend.hubVisible
    minResizeWidth: 250
    minResizeHeight: 300

    width: 300
    height: 450
    x: 700
    y: 100
    visible: hubBackend.todoVisible
    title: "Todo"

    Column {
        anchors.fill: parent
        spacing: 0

        TitleBar {
            id: titleBar
            width: parent.width
            title: "Todo"
            dragEnabled: todoWindow.editMode
            minimized: todoWindow.minimized
            effectiveRadius: todoWindow.effectiveWindowRadius
            rightButtons: [
                {icon: "eye-off.svg", action: "minimize"}
            ]

            onButtonClicked: function(action) {
                if (action === "minimize") {
                    todoWindow.toggleMinimize()
                }
            }
        }

        // Content area (hidden when minimized)
        Item {
            width: parent.width
            height: parent.height - titleBar.height
            visible: !todoWindow.minimized

            Column {
                anchors.fill: parent
                spacing: 0

                // Tab bar
                TabBar {
                    id: tabBar
                    width: parent.width
                    height: 36

                    background: Rectangle {
                        color: Theme.surfaceColor
                    }

                    TabButton {
                        text: "Current"
                        width: implicitWidth
                        height: parent.height

                        background: Rectangle {
                            color: tabBar.currentIndex === 0 ? Theme.accentColor : "transparent"
                            radius: Theme.borderRadius
                            anchors.margins: 4
                            anchors.fill: parent
                        }

                        contentItem: Text {
                            text: parent.text
                            color: Theme.textPrimary
                            font.pixelSize: Theme.fontSizeNormal
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    TabButton {
                        text: "Finished"
                        width: implicitWidth
                        height: parent.height

                        background: Rectangle {
                            color: tabBar.currentIndex === 1 ? Theme.accentColor : "transparent"
                            radius: Theme.borderRadius
                            anchors.margins: 4
                            anchors.fill: parent
                        }

                        contentItem: Text {
                            text: parent.text
                            color: Theme.textPrimary
                            font.pixelSize: Theme.fontSizeNormal
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                // Content stack
                StackLayout {
                    id: stackLayout
                    width: parent.width
                    height: parent.height - tabBar.height
                    currentIndex: tabBar.currentIndex

                    // Current todos tab
                    Item {
                        id: currentTab

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 0

                            // Todo list
                            ScrollView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                contentWidth: availableWidth

                                ScrollBar.vertical.policy: ScrollBar.AlwaysOn
                                ScrollBar.vertical.visible: contentHeight > height

                                ColumnLayout {
                                    width: parent.width
                                    spacing: 4

                                    Item { height: Theme.padding / 2 }

                                    Repeater {
                                        model: todoBackend.currentTodos

                                        delegate: TodoItemDelegate {
                                            todoData: modelData
                                            isFinishedTab: false
                                            itemIndex: index
                                            totalItems: todoBackend.currentTodos.length
                                        }
                                    }

                                    Item { height: Theme.padding / 2 }
                                }
                            }

                            // Add todo input
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 48
                                color: Theme.surfaceColor

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: Theme.padding / 2
                                    spacing: Theme.spacing / 2

                                    TextField {
                                        id: newTodoField
                                        Layout.fillWidth: true
                                        placeholderText: "Add a todo..."
                                        color: Theme.textPrimary
                                        font.pixelSize: Theme.fontSizeNormal

                                        background: Rectangle {
                                            color: Theme.windowBackground
                                            border.color: newTodoField.activeFocus ? Theme.accentColor : Theme.borderColor
                                            border.width: 1
                                            radius: Theme.borderRadius
                                        }

                                        Keys.onReturnPressed: {
                                            if (newTodoField.text.trim() !== "") {
                                                todoBackend.addTodo(newTodoField.text)
                                                newTodoField.text = ""
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: 32
                                        Layout.preferredHeight: 32
                                        radius: Theme.borderRadius
                                        color: addButtonArea.containsMouse ? Theme.accentColor : Theme.borderColor

                                        Image {
                                            anchors.centerIn: parent
                                            source: iconsPath + "plus.svg"
                                            sourceSize: Qt.size(16, 16)
                                        }

                                        MouseArea {
                                            id: addButtonArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: {
                                                if (newTodoField.text.trim() !== "") {
                                                    todoBackend.addTodo(newTodoField.text)
                                                    newTodoField.text = ""
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Finished todos tab
                    Item {
                        id: finishedTab

                        ScrollView {
                            anchors.fill: parent
                            clip: true
                            contentWidth: availableWidth

                            ScrollBar.vertical.policy: ScrollBar.AlwaysOn
                            ScrollBar.vertical.visible: contentHeight > height

                            ColumnLayout {
                                width: parent.width
                                spacing: 4

                                Item { height: Theme.padding / 2 }

                                Repeater {
                                    model: todoBackend.finishedTodos

                                    delegate: TodoItemDelegate {
                                        todoData: modelData
                                        isFinishedTab: true
                                        itemIndex: index
                                        totalItems: todoBackend.finishedTodos.length
                                    }
                                }

                                // Empty state
                                Text {
                                    Layout.fillWidth: true
                                    Layout.topMargin: Theme.padding * 2
                                    text: "No completed todos"
                                    color: Theme.textSecondary
                                    font.pixelSize: Theme.fontSizeNormal
                                    horizontalAlignment: Text.AlignHCenter
                                    visible: todoBackend.finishedTodos.length === 0
                                }

                                Item { height: Theme.padding / 2 }
                            }
                        }
                    }
                }
            }
        }
    }

    // Todo item delegate component
    component TodoItemDelegate: ColumnLayout {
        id: todoItemRoot

        property var todoData
        property bool isFinishedTab: false
        property int itemIndex: 0
        property int totalItems: 0
        property bool showAddChild: false

        Layout.fillWidth: true
        Layout.leftMargin: Theme.padding
        Layout.rightMargin: Theme.padding
        spacing: 2

        // Main todo item
        Rectangle {
            id: todoItem
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(44, todoText.implicitHeight + Theme.padding)
            radius: Theme.borderRadius
            color: dragArea.drag.active ? Theme.accentColor : (itemMouseArea.containsMouse ? Theme.surfaceColor : "transparent")
            border.color: dropArea.containsDrag ? Theme.accentColor : "transparent"
            border.width: dropArea.containsDrag ? 2 : 0

            // Drop area for reordering
            DropArea {
                id: dropArea
                anchors.fill: parent

                onDropped: function(drop) {
                    var draggedId = drop.getDataAsString("todoId")
                    if (draggedId && draggedId !== todoData.id) {
                        todoBackend.reorderTodo(draggedId, itemIndex)
                    }
                }
            }

            MouseArea {
                id: itemMouseArea
                anchors.fill: parent
                hoverEnabled: true
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Theme.padding / 2
                anchors.rightMargin: Theme.padding / 2
                spacing: Theme.spacing / 2

                // Checkbox
                Rectangle {
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22
                    radius: 11
                    color: "transparent"
                    border.color: todoData.completed ? Theme.accentColor : Theme.borderColor
                    border.width: 2

                    Rectangle {
                        anchors.centerIn: parent
                        width: 14
                        height: 14
                        radius: 7
                        color: Theme.accentColor
                        visible: todoData.completed
                    }

                    Image {
                        anchors.centerIn: parent
                        source: iconsPath + "check.svg"
                        sourceSize: Qt.size(12, 12)
                        visible: todoData.completed
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: todoBackend.toggleTodo(todoData.id)
                    }
                }

                // Todo text
                Text {
                    id: todoText
                    Layout.fillWidth: true
                    text: todoData.text
                    color: todoData.completed ? Theme.textSecondary : Theme.textPrimary
                    font.pixelSize: Theme.fontSizeNormal
                    font.strikeout: todoData.completed
                    wrapMode: Text.WordWrap
                    verticalAlignment: Text.AlignVCenter
                }

                // Add child button (only for parents in current tab)
                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    radius: 4
                    color: addChildArea.containsMouse ? Theme.surfaceColor : "transparent"
                    visible: !isFinishedTab && !todoData.completed

                    Image {
                        anchors.centerIn: parent
                        source: iconsPath + "plus.svg"
                        sourceSize: Qt.size(14, 14)
                    }

                    MouseArea {
                        id: addChildArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: todoItemRoot.showAddChild = !todoItemRoot.showAddChild
                    }
                }

                // Delete button
                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    radius: 4
                    color: deleteArea.containsMouse ? Theme.surfaceColor : "transparent"
                    visible: itemMouseArea.containsMouse || deleteArea.containsMouse

                    Image {
                        anchors.centerIn: parent
                        source: iconsPath + "trash-2.svg"
                        sourceSize: Qt.size(14, 14)
                    }

                    MouseArea {
                        id: deleteArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: todoBackend.deleteTodo(todoData.id)
                    }
                }

                // Drag handle
                Rectangle {
                    id: dragHandle
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    radius: 4
                    color: dragArea.containsMouse ? Theme.surfaceColor : "transparent"
                    visible: !isFinishedTab

                    Image {
                        anchors.centerIn: parent
                        source: iconsPath + "grip-vertical.svg"
                        sourceSize: Qt.size(14, 14)
                    }

                    MouseArea {
                        id: dragArea
                        anchors.fill: parent
                        hoverEnabled: true
                        drag.target: todoItem
                        drag.axis: Drag.YAxis

                        onPressed: {
                            todoItem.Drag.active = true
                            todoItem.Drag.hotSpot = Qt.point(todoItem.width / 2, todoItem.height / 2)
                        }

                        onReleased: {
                            todoItem.Drag.active = false
                            todoItem.x = 0
                            todoItem.y = 0
                        }
                    }

                    Drag.active: dragArea.drag.active
                    Drag.source: todoItem
                    Drag.mimeData: {"todoId": todoData.id}
                }
            }
        }

        // Add child input (shown when + is clicked)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            Layout.leftMargin: 24
            color: Theme.surfaceColor
            radius: Theme.borderRadius
            visible: todoItemRoot.showAddChild

            RowLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 4

                TextField {
                    id: childTodoField
                    Layout.fillWidth: true
                    placeholderText: "Add subtask..."
                    color: Theme.textPrimary
                    font.pixelSize: Theme.fontSizeSmall

                    background: Rectangle {
                        color: Theme.windowBackground
                        border.color: childTodoField.activeFocus ? Theme.accentColor : Theme.borderColor
                        border.width: 1
                        radius: Theme.borderRadius
                    }

                    Keys.onReturnPressed: {
                        if (childTodoField.text.trim() !== "") {
                            todoBackend.addChildTodo(todoData.id, childTodoField.text)
                            childTodoField.text = ""
                            todoItemRoot.showAddChild = false
                        }
                    }

                    Keys.onEscapePressed: {
                        todoItemRoot.showAddChild = false
                        childTodoField.text = ""
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    radius: 4
                    color: childAddArea.containsMouse ? Theme.accentColor : Theme.borderColor

                    Image {
                        anchors.centerIn: parent
                        source: iconsPath + "plus.svg"
                        sourceSize: Qt.size(12, 12)
                    }

                    MouseArea {
                        id: childAddArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (childTodoField.text.trim() !== "") {
                                todoBackend.addChildTodo(todoData.id, childTodoField.text)
                                childTodoField.text = ""
                                todoItemRoot.showAddChild = false
                            }
                        }
                    }
                }
            }
        }

        // Children
        Repeater {
            model: todoData.children || []

            delegate: Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.max(36, childText.implicitHeight + Theme.padding)
                Layout.leftMargin: 24
                radius: Theme.borderRadius
                color: childMouseArea.containsMouse ? Theme.surfaceColor : "transparent"

                MouseArea {
                    id: childMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.padding / 2
                    anchors.rightMargin: Theme.padding / 2
                    spacing: Theme.spacing / 2

                    // Child checkbox
                    Rectangle {
                        Layout.preferredWidth: 18
                        Layout.preferredHeight: 18
                        radius: 9
                        color: "transparent"
                        border.color: modelData.completed ? Theme.accentColor : Theme.borderColor
                        border.width: 2

                        Rectangle {
                            anchors.centerIn: parent
                            width: 10
                            height: 10
                            radius: 5
                            color: Theme.accentColor
                            visible: modelData.completed
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: todoBackend.toggleTodo(modelData.id)
                        }
                    }

                    // Child text
                    Text {
                        id: childText
                        Layout.fillWidth: true
                        text: modelData.text
                        color: modelData.completed ? Theme.textSecondary : Theme.textPrimary
                        font.pixelSize: Theme.fontSizeSmall
                        font.strikeout: modelData.completed
                        wrapMode: Text.WordWrap
                        verticalAlignment: Text.AlignVCenter
                    }

                    // Child delete button
                    Rectangle {
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20
                        radius: 4
                        color: childDeleteArea.containsMouse ? Theme.surfaceColor : "transparent"
                        visible: childMouseArea.containsMouse || childDeleteArea.containsMouse

                        Image {
                            anchors.centerIn: parent
                            source: iconsPath + "trash-2.svg"
                            sourceSize: Qt.size(12, 12)
                        }

                        MouseArea {
                            id: childDeleteArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: todoBackend.deleteTodo(modelData.id)
                        }
                    }
                }
            }
        }
    }
}
