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

    // Track which view is shown (false = current, true = finished)
    property bool showingFinished: false
    // Track the currently dragged item ID
    property string draggedTodoId: ""
    // Track drag position for drop indicator
    property int dragTargetIndex: -1

    Column {
        anchors.fill: parent
        spacing: 0

        TitleBar {
            id: titleBar
            width: parent.width
            title: todoWindow.showingFinished ? "Finished" : "Todo"
            dragEnabled: todoWindow.editMode
            minimized: todoWindow.minimized
            effectiveRadius: todoWindow.effectiveWindowRadius
            leftButtons: todoWindow.showingFinished ? [
                {icon: "arrow-left.svg", action: "back", enabled: !hubBackend.editMode}
            ] : [
                {icon: "circle-check-big.svg", action: "finished", enabled: !hubBackend.editMode}
            ]
            rightButtons: [
                {icon: "eye-off.svg", action: "minimize"}
            ]

            onButtonClicked: function(action) {
                if (action === "minimize") {
                    todoWindow.toggleMinimize()
                } else if (action === "finished") {
                    todoWindow.showingFinished = true
                } else if (action === "back") {
                    todoWindow.showingFinished = false
                }
            }
        }

        // Content area (hidden when minimized)
        Rectangle {
            width: parent.width
            height: parent.height - titleBar.height
            visible: !todoWindow.minimized
            color: "transparent"
            bottomLeftRadius: todoWindow.effectiveWindowRadius
            bottomRightRadius: todoWindow.effectiveWindowRadius

            StackLayout {
                id: stackLayout
                anchors.fill: parent
                currentIndex: todoWindow.showingFinished ? 1 : 0

                // Current todos view
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
                                id: currentTodosList
                                width: parent.width
                                spacing: 0

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
                            bottomLeftRadius: todoWindow.effectiveWindowRadius
                            bottomRightRadius: todoWindow.effectiveWindowRadius

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

                // Finished todos view
                Item {
                    id: finishedTab

                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        bottomLeftRadius: todoWindow.effectiveWindowRadius
                        bottomRightRadius: todoWindow.effectiveWindowRadius

                        ScrollView {
                            anchors.fill: parent
                            clip: true
                            contentWidth: availableWidth

                            ScrollBar.vertical.policy: ScrollBar.AlwaysOn
                            ScrollBar.vertical.visible: contentHeight > height

                            ColumnLayout {
                                width: parent.width
                                spacing: 0

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
        property bool childrenCollapsed: false
        property bool isEditing: false

        Layout.fillWidth: true
        Layout.leftMargin: Theme.padding
        Layout.rightMargin: Theme.padding
        spacing: 2

        // Drop indicator (shown when dragging over this item)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 3
            color: Theme.accentColor
            radius: 1
            visible: todoWindow.draggedTodoId !== "" && todoWindow.draggedTodoId !== todoData.id && todoWindow.dragTargetIndex === itemIndex
        }

        // Main todo item
        Rectangle {
            id: todoItem
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(44, (todoItemRoot.isEditing ? todoEditField.implicitHeight : todoText.implicitHeight) + Theme.padding)
            radius: Theme.borderRadius
            color: itemHoverHandler.hovered || dragHandler.active ? Theme.surfaceColor : "transparent"
            opacity: todoWindow.draggedTodoId === todoData.id ? 0.5 : 1.0

            // Hover handler for background color
            HoverHandler {
                id: itemHoverHandler
                enabled: !todoItemRoot.isEditing
            }

            // DragHandler for drag operations
            DragHandler {
                id: dragHandler
                target: null
                enabled: !todoItemRoot.isEditing && !isFinishedTab

                onActiveChanged: {
                    if (active) {
                        console.log("DRAG ACTIVE for:", todoData.text)
                        todoWindow.draggedTodoId = todoData.id
                        todoWindow.dragTargetIndex = itemIndex
                    } else {
                        console.log("DRAG RELEASED")
                        if (todoWindow.draggedTodoId === todoData.id && todoWindow.dragTargetIndex >= 0) {
                            if (todoWindow.dragTargetIndex !== itemIndex) {
                                todoBackend.reorderTodo(todoData.id, todoWindow.dragTargetIndex)
                            }
                        }
                        todoWindow.draggedTodoId = ""
                        todoWindow.dragTargetIndex = -1
                    }
                }

                onCentroidChanged: {
                    if (active) {
                        var dragOffset = centroid.position.y - centroid.pressPosition.y
                        var indexChange = Math.round(dragOffset / 50)
                        var newIndex = itemIndex + indexChange
                        newIndex = Math.max(0, Math.min(newIndex, totalItems - 1))
                        todoWindow.dragTargetIndex = newIndex
                        console.log("Dragging:", todoData.id, "offset:", dragOffset, "target:", newIndex)
                    }
                }
            }

            // TapHandler for double-click to edit
            TapHandler {
                enabled: !todoItemRoot.isEditing && !isFinishedTab
                onDoubleTapped: {
                    todoWindow.draggedTodoId = ""
                    todoWindow.dragTargetIndex = -1
                    todoItemRoot.isEditing = true
                    todoEditField.forceActiveFocus()
                    todoEditField.selectAll()
                }
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

                // Todo text (or edit field)
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Text {
                        id: todoText
                        anchors.fill: parent
                        text: todoData.text
                        color: todoData.completed ? Theme.textSecondary : Theme.textPrimary
                        font.pixelSize: Theme.fontSizeNormal
                        font.strikeout: todoData.completed
                        wrapMode: Text.WordWrap
                        verticalAlignment: Text.AlignVCenter
                        visible: !todoItemRoot.isEditing
                    }

                    TextField {
                        id: todoEditField
                        anchors.fill: parent
                        text: todoData.text
                        color: Theme.textPrimary
                        font.pixelSize: Theme.fontSizeNormal
                        visible: todoItemRoot.isEditing

                        background: Rectangle {
                            color: Theme.windowBackground
                            border.color: Theme.accentColor
                            border.width: 1
                            radius: Theme.borderRadius
                        }

                        onActiveFocusChanged: {
                            if (!activeFocus) {
                                if (todoEditField.text.trim() !== "") {
                                    todoBackend.updateTodoText(todoData.id, todoEditField.text)
                                }
                                todoItemRoot.isEditing = false
                            }
                        }

                        Keys.onReturnPressed: {
                            if (todoEditField.text.trim() !== "") {
                                todoBackend.updateTodoText(todoData.id, todoEditField.text)
                            }
                            todoItemRoot.isEditing = false
                        }

                        Keys.onEscapePressed: {
                            todoEditField.text = todoData.text
                            todoItemRoot.isEditing = false
                        }
                    }
                }

                // Collapse/expand button (only if has children) - on the right with background
                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    radius: Theme.borderRadius
                    color: collapseArea.containsMouse ? Theme.borderColor : Theme.surfaceColor
                    visible: (todoData.children && todoData.children.length > 0)

                    Image {
                        anchors.centerIn: parent
                        source: iconsPath + (todoItemRoot.childrenCollapsed ? "chevron-down.svg" : "chevron-up.svg")
                        sourceSize: Qt.size(14, 14)
                    }

                    MouseArea {
                        id: collapseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: todoItemRoot.childrenCollapsed = !todoItemRoot.childrenCollapsed
                    }
                }

                // Add child button (only for parents in current tab)
                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    radius: Theme.borderRadius
                    color: addChildArea.containsMouse ? Theme.borderColor : Theme.surfaceColor
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
                        onClicked: {
                            todoItemRoot.showAddChild = true
                            todoItemRoot.childrenCollapsed = false
                        }
                    }
                }

                // Delete button (always visible)
                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    radius: Theme.borderRadius
                    color: deleteArea.containsMouse ? Theme.borderColor : Theme.surfaceColor

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
            }
        }

        // Add child input (shown when + is clicked)
        Rectangle {
            id: addChildContainer
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            Layout.leftMargin: 24
            color: Theme.surfaceColor
            radius: Theme.borderRadius
            visible: todoItemRoot.showAddChild && !todoItemRoot.childrenCollapsed

            onVisibleChanged: {
                if (visible) {
                    childTodoField.forceActiveFocus()
                }
            }

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

                    onActiveFocusChanged: {
                        if (!activeFocus && childTodoField.text.trim() === "") {
                            todoItemRoot.showAddChild = false
                        }
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
                    radius: Theme.borderRadius
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

        // Children container (collapsible)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            visible: !todoItemRoot.childrenCollapsed

            Repeater {
                model: todoData.children || []

                delegate: ColumnLayout {
                    id: childItemRoot
                    Layout.fillWidth: true
                    spacing: 0

                    property int childIndex: index
                    property int totalChildren: todoData.children ? todoData.children.length : 0
                    property bool isChildEditing: false

                    Rectangle {
                        id: childItem
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(36, (childItemRoot.isChildEditing ? childEditField.implicitHeight : childText.implicitHeight) + Theme.padding)
                        Layout.leftMargin: 24
                        radius: Theme.borderRadius
                        color: childHoverHandler.hovered || childDragHandler.active ? Theme.surfaceColor : "transparent"
                        opacity: todoWindow.draggedTodoId === modelData.id ? 0.5 : 1.0

                        // Hover handler for background color
                        HoverHandler {
                            id: childHoverHandler
                            enabled: !childItemRoot.isChildEditing
                        }

                        // DragHandler for child reordering
                        DragHandler {
                            id: childDragHandler
                            target: null
                            enabled: !childItemRoot.isChildEditing && !isFinishedTab

                            onActiveChanged: {
                                if (active) {
                                    console.log("CHILD DRAG ACTIVE for:", modelData.text)
                                    todoWindow.draggedTodoId = modelData.id
                                } else {
                                    console.log("CHILD DRAG RELEASED")
                                    todoWindow.draggedTodoId = ""
                                }
                            }
                        }

                        // TapHandler for double-click to edit
                        TapHandler {
                            enabled: !childItemRoot.isChildEditing && !isFinishedTab
                            onDoubleTapped: {
                                childItemRoot.isChildEditing = true
                                childEditField.forceActiveFocus()
                                childEditField.selectAll()
                            }
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

                            // Child text (or edit field)
                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                Text {
                                    id: childText
                                    anchors.fill: parent
                                    text: modelData.text
                                    color: modelData.completed ? Theme.textSecondary : Theme.textPrimary
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.strikeout: modelData.completed
                                    wrapMode: Text.WordWrap
                                    verticalAlignment: Text.AlignVCenter
                                    visible: !childItemRoot.isChildEditing
                                }

                                TextField {
                                    id: childEditField
                                    anchors.fill: parent
                                    text: modelData.text
                                    color: Theme.textPrimary
                                    font.pixelSize: Theme.fontSizeSmall
                                    visible: childItemRoot.isChildEditing

                                    background: Rectangle {
                                        color: Theme.windowBackground
                                        border.color: Theme.accentColor
                                        border.width: 1
                                        radius: Theme.borderRadius
                                    }

                                    onActiveFocusChanged: {
                                        if (!activeFocus) {
                                            if (childEditField.text.trim() !== "") {
                                                todoBackend.updateTodoText(modelData.id, childEditField.text)
                                            }
                                            childItemRoot.isChildEditing = false
                                        }
                                    }

                                    Keys.onReturnPressed: {
                                        if (childEditField.text.trim() !== "") {
                                            todoBackend.updateTodoText(modelData.id, childEditField.text)
                                        }
                                        childItemRoot.isChildEditing = false
                                    }

                                    Keys.onEscapePressed: {
                                        childEditField.text = modelData.text
                                        childItemRoot.isChildEditing = false
                                    }
                                }
                            }

                            // Child delete button (always visible)
                            Rectangle {
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                radius: Theme.borderRadius
                                color: childDeleteArea.containsMouse ? Theme.borderColor : Theme.surfaceColor

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

    }
}
