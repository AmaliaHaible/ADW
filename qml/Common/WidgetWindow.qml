import QtQuick 2.15
import QtQuick.Window 2.15
import Common 1.0

Window {
    id: widgetWindow

    property string geometryKey: ""
    property var settingsStore
    property bool editMode: false
    property bool editOverlayEnabled: true
    property bool resizeHandleEnabled: true
    property int minResizeWidth: 150
    property int minResizeHeight: 100
    property color backgroundColor: Theme.windowBackground
    property real windowRadius: Theme.windowRadius
    property bool hubVisible: false
    property bool minimized: false
    property real _expandedHeight: 0
    property bool anchorTop: true
    property bool _wasMinimizedBeforeEdit: false
    readonly property real effectiveWindowRadius: Math.min(windowRadius, Theme.titleBarHeight / 2)

    default property alias content: mainContainer.data

    onEditModeChanged: {
        if (editMode) {
            if (minimized) {
                _wasMinimizedBeforeEdit = true
                expandWithoutSaving()
            }
        } else {
            if (_wasMinimizedBeforeEdit) {
                _wasMinimizedBeforeEdit = false
                collapseWithoutSaving()
            }
        }
    }

    function expandWithoutSaving() {
        if (!anchorTop) {
            y = y - (_expandedHeight - height)
        }
        height = _expandedHeight
        minimized = false
    }

    function collapseWithoutSaving() {
        _expandedHeight = height
        if (!anchorTop) {
            y = y + (height - Theme.titleBarHeight)
        }
        height = Theme.titleBarHeight
        minimized = true
    }

    function toggleMinimize() {
        if (minimized) {
            if (!anchorTop) {
                y = y - (_expandedHeight - height)
            }
            height = _expandedHeight
            minimized = false
        } else {
            _expandedHeight = height
            if (!anchorTop) {
                y = y + (height - Theme.titleBarHeight)
            }
            height = Theme.titleBarHeight
            minimized = true
        }
        saveMinimizedSetting()
    }

    function toggleAnchor() {
        anchorTop = !anchorTop
        saveAnchorSetting()
    }

    function saveAnchorSetting() {
        if (settingsStore && geometryKey !== "") {
            settingsStore.setWidgetSetting(geometryKey, "anchorTop", anchorTop)
        }
    }

    function saveMinimizedSetting() {
        if (settingsStore && geometryKey !== "") {
            settingsStore.setWidgetSetting(geometryKey, "minimized", minimized)
            if (!minimized) {
                settingsStore.setWidgetSetting(geometryKey, "expandedHeight", height)
            }
        }
    }

    function loadAnchorSetting() {
        if (settingsStore && geometryKey !== "") {
            var saved = settingsStore.getWidgetSetting(geometryKey, "anchorTop")
            if (saved !== null && saved !== undefined) {
                anchorTop = saved
            }
        }
    }

    function loadMinimizedSetting() {
        if (settingsStore && geometryKey !== "") {
            var savedHeight = settingsStore.getWidgetSetting(geometryKey, "expandedHeight")
            if (typeof savedHeight === "number" && savedHeight > 0) {
                _expandedHeight = savedHeight
            } else {
                _expandedHeight = height
            }
            
            var savedMinimized = settingsStore.getWidgetSetting(geometryKey, "minimized")
            if (savedMinimized === true) {
                if (!anchorTop) {
                    y = y + (_expandedHeight - Theme.titleBarHeight)
                }
                height = Theme.titleBarHeight
                minimized = true
            }
        }
    }

    minimumWidth: minResizeWidth
    minimumHeight: minResizeHeight

    // Set initial flags
    flags: Qt.Tool | Qt.FramelessWindowHint | Qt.NoDropShadowWindowHint |
           (hubBackend.alwaysOnTop || hubVisible ? Qt.WindowStaysOnTopHint : Qt.WindowStaysOnBottomHint)

    color: "transparent"

    onXChanged: if (visible && !minimized) saveGeometryTimer.restart()
    onYChanged: if (visible && !minimized) saveGeometryTimer.restart()
    onWidthChanged: if (visible && !minimized) saveGeometryTimer.restart()
    onHeightChanged: if (visible && !minimized) saveGeometryTimer.restart()

    Timer {
        id: saveGeometryTimer
        interval: 500
        onTriggered: {
            if (settingsStore && geometryKey !== "" && !minimized) {
                settingsStore.setWidgetGeometry(
                    geometryKey,
                    widgetWindow.x,
                    widgetWindow.y,
                    widgetWindow.width,
                    widgetWindow.height
                )
            }
        }
    }

    function applyGeometryFromSettings() {
        if (!settingsStore || geometryKey === "") {
            return
        }
        var geometry = settingsStore.getWidgetGeometry(geometryKey)
        if (!geometry) {
            return
        }
        if (typeof geometry.width === "number") {
            widgetWindow.width = geometry.width
        }
        if (typeof geometry.height === "number") {
            widgetWindow.height = geometry.height
        }
        if (typeof geometry.x === "number") {
            widgetWindow.x = geometry.x
        }
        if (typeof geometry.y === "number") {
            widgetWindow.y = geometry.y
        }
    }

    property bool isUpdatingFlags: false

    Component.onCompleted: {
        applyGeometryFromSettings()
        loadAnchorSetting()
        loadMinimizedSetting()
    }
    onSettingsStoreChanged: {
        applyGeometryFromSettings()
        loadAnchorSetting()
        loadMinimizedSetting()
    }
    onGeometryKeyChanged: {
        applyGeometryFromSettings()
        loadAnchorSetting()
        loadMinimizedSetting()
    }

    // Update window flags when conditions change
    onHubVisibleChanged: {
        if (!isUpdatingFlags) updateWindowFlags()
    }

    Connections {
        target: hubBackend
        function onAlwaysOnTopChanged() {
            if (!isUpdatingFlags) updateWindowFlags()
        }
    }

    function updateWindowFlags() {
        if (isUpdatingFlags) return
        isUpdatingFlags = true

        var baseFlags = Qt.Tool | Qt.FramelessWindowHint | Qt.NoDropShadowWindowHint
        var shouldBeOnTop = hubBackend.alwaysOnTop || hubVisible

        // Get current flags and explicitly remove both top/bottom hints
        var newFlags = baseFlags & ~Qt.WindowStaysOnTopHint & ~Qt.WindowStaysOnBottomHint

        // Add the appropriate flag
        if (shouldBeOnTop) {
            newFlags = newFlags | Qt.WindowStaysOnTopHint
        } else {
            newFlags = newFlags | Qt.WindowStaysOnBottomHint
        }

        // Setting flags alone doesn't work in Qt - need to hide/show to force OS update
        if (widgetWindow.visible) {
            var savedX = widgetWindow.x
            var savedY = widgetWindow.y

            // Force Qt to reapply flags by toggling them
            widgetWindow.flags = baseFlags  // Clear both hints first
            widgetWindow.hide()
            widgetWindow.flags = newFlags   // Then set the correct flags
            widgetWindow.show()
            widgetWindow.x = savedX
            widgetWindow.y = savedY

            // Explicitly raise window if it should be on top
            if (shouldBeOnTop) {
                widgetWindow.raise()
            } else {
                widgetWindow.lower()
            }
        } else {
            widgetWindow.flags = newFlags
        }

        isUpdatingFlags = false
    }

    Rectangle {
        id: mainContainer
        anchors.fill: parent
        color: backgroundColor
        radius: effectiveWindowRadius
    }

    Rectangle {
        id: editOverlay
        anchors.fill: parent
        color: "transparent"
        visible: editOverlayEnabled && editMode
        z: 10

        Rectangle {
            anchors.fill: parent
            color: Theme.accentColor
            opacity: 0.1
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: Theme.accentColor
            border.width: 2
        }

        Rectangle {
            id: anchorIndicator
            width: parent.width
            height: 20
            color: Theme.colorGreen
            opacity: 0.9
            anchors.horizontalCenter: parent.horizontalCenter
            y: anchorTop ? Theme.titleBarHeight : (parent.height - height)

            Text {
                anchors.centerIn: parent
                text: "Anchor"
                color: "#1e1e2e"
                font.pixelSize: 11
                font.weight: Font.Medium
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true

            onPressed: function(mouse) {
                if (mouse.button === Qt.LeftButton) {
                    widgetWindow.startSystemMove()
                }
            }

            onClicked: function(mouse) {
                if (mouse.button === Qt.RightButton) {
                    widgetWindow.toggleAnchor()
                }
            }
        }
    }

    Item {
        id: resizeHandle
        width: 16
        height: 16
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 4
        anchors.bottomMargin: 4
        visible: resizeHandleEnabled && editMode
        z: 20

        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.fillStyle = Theme.accentColor
                ctx.beginPath()
                ctx.moveTo(width, 0)
                ctx.lineTo(width, height)
                ctx.lineTo(0, height)
                ctx.lineTo(width, 0)
                ctx.closePath()
                ctx.fill()
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeFDiagCursor
            onPressed: function(mouse) {
                if (mouse.button === Qt.LeftButton) {
                    widgetWindow.startSystemResize(Qt.RightEdge | Qt.BottomEdge)
                }
            }
        }
    }
}
