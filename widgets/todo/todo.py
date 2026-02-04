import uuid
from PySide6.QtCore import QObject, Property, Signal, Slot


class TodoBackend(QObject):
    todosChanged = Signal()

    def __init__(self, settings_backend=None, parent=None):
        super().__init__(parent)
        self._settings = settings_backend
        self._todos = []
        self._load_todos()

    def _load_todos(self):
        """Load todos from settings."""
        if self._settings:
            data = self._settings.getWidgetSetting("todo", "todos")
            if data and isinstance(data, list):
                self._todos = data
            else:
                self._todos = []
        else:
            self._todos = []

    def _save_todos(self):
        """Save todos to settings."""
        if self._settings:
            self._settings.setWidgetSetting("todo", "todos", self._todos)
        self.todosChanged.emit()

    def _get_next_order(self, parent_id=None):
        """Get the next order value for siblings."""
        siblings = [t for t in self._todos if t.get("parentId") == parent_id]
        if not siblings:
            return 0
        return max(t.get("order", 0) for t in siblings) + 1

    def _build_hierarchical_list(self, completed_filter):
        """Build hierarchical list of todos with children attached."""
        # Get parent todos matching the completion filter
        parents = [
            t
            for t in self._todos
            if t.get("parentId") is None
            and t.get("completed", False) == completed_filter
        ]
        parents.sort(key=lambda t: t.get("order", 0))

        result = []
        for parent in parents:
            # Get children for this parent
            children = [t for t in self._todos if t.get("parentId") == parent.get("id")]
            children.sort(key=lambda t: t.get("order", 0))

            # Create a copy with children attached
            parent_with_children = dict(parent)
            parent_with_children["children"] = children
            result.append(parent_with_children)

        return result

    @Property("QVariantList", notify=todosChanged)
    def currentTodos(self):
        """Return incomplete parent todos with their children."""
        return self._build_hierarchical_list(completed_filter=False)

    @Property("QVariantList", notify=todosChanged)
    def finishedTodos(self):
        """Return completed parent todos with their children."""
        return self._build_hierarchical_list(completed_filter=True)

    @Slot(str)
    def addTodo(self, text):
        """Add a new root-level todo."""
        text = text.strip()
        if not text:
            return

        todo = {
            "id": str(uuid.uuid4()),
            "text": text,
            "completed": False,
            "parentId": None,
            "order": self._get_next_order(None),
        }
        self._todos.append(todo)
        self._save_todos()

    @Slot(str, str)
    def addChildTodo(self, parent_id, text):
        """Add a child todo under a parent."""
        text = text.strip()
        if not text:
            return

        # Verify parent exists
        parent = next((t for t in self._todos if t.get("id") == parent_id), None)
        if not parent:
            return

        todo = {
            "id": str(uuid.uuid4()),
            "text": text,
            "completed": False,
            "parentId": parent_id,
            "order": self._get_next_order(parent_id),
        }
        self._todos.append(todo)
        self._save_todos()

    @Slot(str)
    def toggleTodo(self, todo_id):
        """Toggle completion status of a todo."""
        todo = next((t for t in self._todos if t.get("id") == todo_id), None)
        if not todo:
            return

        new_completed = not todo.get("completed", False)
        todo["completed"] = new_completed

        # If this is a parent todo, also toggle all children
        if todo.get("parentId") is None:
            for child in self._todos:
                if child.get("parentId") == todo_id:
                    child["completed"] = new_completed

        self._save_todos()

    @Slot(str)
    def deleteTodo(self, todo_id):
        """Delete a todo and its children."""
        # Find the todo
        todo = next((t for t in self._todos if t.get("id") == todo_id), None)
        if not todo:
            return

        # If it's a parent, also delete children
        if todo.get("parentId") is None:
            self._todos = [
                t
                for t in self._todos
                if t.get("id") != todo_id and t.get("parentId") != todo_id
            ]
        else:
            self._todos = [t for t in self._todos if t.get("id") != todo_id]

        self._save_todos()

    @Slot(str, int)
    def reorderTodo(self, todo_id, new_index):
        """Reorder a todo within its siblings."""
        todo = next((t for t in self._todos if t.get("id") == todo_id), None)
        if not todo:
            return

        parent_id = todo.get("parentId")
        completed = todo.get("completed", False)

        # Get all siblings with same parent AND same completion status
        if parent_id is None:
            # Root-level todos: filter by completion status
            siblings = [
                t
                for t in self._todos
                if t.get("parentId") is None and t.get("completed", False) == completed
            ]
        else:
            # Child todos: just filter by parent (children share parent's completion)
            siblings = [t for t in self._todos if t.get("parentId") == parent_id]

        siblings.sort(key=lambda t: t.get("order", 0))

        # Find current index
        current_index = next(
            (i for i, t in enumerate(siblings) if t.get("id") == todo_id), None
        )
        if current_index is None:
            return

        # Clamp new_index
        new_index = max(0, min(new_index, len(siblings) - 1))

        if current_index == new_index:
            return

        # Remove from current position and insert at new position
        siblings.pop(current_index)
        siblings.insert(new_index, todo)

        # Update order values
        for i, sibling in enumerate(siblings):
            sibling["order"] = i

        self._save_todos()

    @Slot(str, str)
    def updateTodoText(self, todo_id, new_text):
        """Update the text of a todo."""
        new_text = new_text.strip()
        if not new_text:
            return

        todo = next((t for t in self._todos if t.get("id") == todo_id), None)
        if todo:
            todo["text"] = new_text
            self._save_todos()
