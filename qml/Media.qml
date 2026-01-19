import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Common 1.0

WidgetWindow {
    id: mediaWindow
    geometryKey: "media"
    settingsStore: settingsBackend
    editMode: hubBackend.editMode
    visible: hubBackend.mediaVisible
    hubVisible: hubBackend.hubVisible

    width: 350
    minResizeWidth: 300
    minResizeHeight: 132

    // Dynamic height based on number of sessions shown
    readonly property int sessionHeight: 100
    readonly property int visibleSessionCount: Math.min(mediaBackend.sessionList.length, mediaBackend.maxSessions)
    readonly property int maxSessionCount: 3
    readonly property int calculatedHeight: Theme.titleBarHeight + (visibleSessionCount * sessionHeight)
    readonly property int maxHeight: Theme.titleBarHeight + (maxSessionCount * sessionHeight)

    height: calculatedHeight

    title: "Media Control"

    // Session slot tracking - maintains stable slot assignments
    QtObject {
        id: sessionSlots

        // Map of session name -> slot index
        property var slotAssignments: ({})
        property int nextSlot: 0

        function assignSlot(sessionName) {
            if (!slotAssignments[sessionName] && slotAssignments[sessionName] !== 0) {
                slotAssignments[sessionName] = nextSlot
                nextSlot = (nextSlot + 1) % mediaBackend.maxSessions
            }
            return slotAssignments[sessionName]
        }

        function getSessionAtSlot(slotIndex) {
            // Find which session is assigned to this slot
            for (var i = 0; i < mediaBackend.sessionList.length; i++) {
                var session = mediaBackend.sessionList[i]
                if (assignSlot(session.name) === slotIndex) {
                    return session
                }
            }
            return null
        }

        function cleanup() {
            // Remove assignments for sessions that no longer exist
            var currentSessions = {}
            for (var i = 0; i < mediaBackend.sessionList.length; i++) {
                currentSessions[mediaBackend.sessionList[i].name] = true
            }

            var newAssignments = {}
            for (var name in slotAssignments) {
                if (currentSessions[name]) {
                    newAssignments[name] = slotAssignments[name]
                }
            }
            slotAssignments = newAssignments
        }
    }

    Connections {
        target: mediaBackend
        function onSessionListChanged() {
            sessionSlots.cleanup()
        }
    }

    // Handle dynamic resizing with anchor support
    onCalculatedHeightChanged: {
        if (mediaBackend.anchorTop) {
            // Anchor top - height grows downward
            height = calculatedHeight
        } else {
            // Anchor bottom - adjust y to keep bottom fixed
            var oldHeight = height
            var newHeight = calculatedHeight
            y = y + (oldHeight - newHeight)
            height = newHeight
        }
    }

    Column {
        anchors.fill: parent
        spacing: 0

        TitleBar {
            width: parent.width
            title: "Media Control"
            dragEnabled: mediaWindow.editMode
            leftButtons: stackView.depth > 1 ? [
                {icon: "arrow-left.svg", action: "back", enabled: !hubBackend.editMode}
            ] : [
                {icon: "settings.svg", action: "settings", enabled: !hubBackend.editMode}
            ]

            onButtonClicked: function(action) {
                if (action === "settings") {
                    stackView.push(settingsViewComponent)
                } else if (action === "back") {
                    stackView.pop()
                }
            }
        }

        // StackView for main/settings views
        StackView {
            id: stackView
            width: parent.width
            height: parent.height - Theme.titleBarHeight
            initialItem: mainViewComponent
        }
    }

    // Settings View Component
    Component {
        id: settingsViewComponent

        Item {
            ScrollView {
                anchors.fill: parent
                contentWidth: availableWidth
                clip: true

                ColumnLayout {
                    width: parent.width
                    spacing: Theme.spacing

                    // Max Sessions Setting
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.margins: Theme.padding
                        Layout.preferredHeight: 80
                        color: Theme.surfaceColor
                        radius: Theme.borderRadius

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.padding
                            spacing: Theme.spacing / 2

                            Text {
                                text: "Maximum Sessions"
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSizeNormal
                            }

                            Text {
                                text: "Show up to " + maxSessionsSlider.value + " media session(s)"
                                color: Theme.textSecondary
                                font.pixelSize: Theme.fontSizeSmall
                            }

                            Slider {
                                id: maxSessionsSlider
                                Layout.fillWidth: true
                                from: 1
                                to: 5
                                stepSize: 1
                                value: mediaBackend.maxSessions

                                onMoved: {
                                    mediaBackend.setMaxSessions(Math.floor(value))
                                }

                                background: Rectangle {
                                    x: maxSessionsSlider.leftPadding
                                    y: maxSessionsSlider.topPadding + maxSessionsSlider.availableHeight / 2 - height / 2
                                    width: maxSessionsSlider.availableWidth
                                    height: 4
                                    radius: 2
                                    color: Theme.borderColor

                                    Rectangle {
                                        width: maxSessionsSlider.visualPosition * parent.width
                                        height: parent.height
                                        radius: 2
                                        color: Theme.accentColor
                                    }
                                }

                                handle: Rectangle {
                                    x: maxSessionsSlider.leftPadding + maxSessionsSlider.visualPosition * (maxSessionsSlider.availableWidth - width)
                                    y: maxSessionsSlider.topPadding + maxSessionsSlider.availableHeight / 2 - height / 2
                                    width: 16
                                    height: 16
                                    radius: 8
                                    color: Theme.accentColor
                                }
                            }
                        }
                    }

                    // Anchor Position Setting
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.margins: Theme.padding
                        Layout.preferredHeight: 80
                        color: Theme.surfaceColor
                        radius: Theme.borderRadius

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.padding
                            spacing: Theme.spacing

                            Text {
                                text: "Resize Anchor"
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSizeNormal
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.spacing

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    radius: 4
                                    color: mediaBackend.anchorTop ? Theme.accentColor : Theme.surfaceColor
                                    border.color: Theme.borderColor
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Anchor Top"
                                        color: mediaBackend.anchorTop ? Theme.windowBackground : Theme.textSecondary
                                        font.pixelSize: Theme.fontSizeSmall
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: mediaBackend.setAnchorTop(true)
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    radius: 4
                                    color: !mediaBackend.anchorTop ? Theme.accentColor : Theme.surfaceColor
                                    border.color: Theme.borderColor
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Anchor Bottom"
                                        color: !mediaBackend.anchorTop ? Theme.windowBackground : Theme.textSecondary
                                        font.pixelSize: Theme.fontSizeSmall
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: mediaBackend.setAnchorTop(false)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Main View Component
    Component {
        id: mainViewComponent

        Item {
            // No media placeholder
            Column {
                anchors.centerIn: parent
                spacing: Theme.spacing * 2
                visible: mediaBackend.sessionList.length === 0

                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 48
                    height: 48
                    source: iconsPath + "music.svg"
                    sourceSize: Qt.size(48, 48)
                    opacity: 0.4
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: mediaBackend.isLoading ? "Connecting..." : "No media playing"
                    font.pixelSize: Theme.fontSizeNormal
                    color: Theme.textMuted
                }
            }

            // Session list
            Column {
                anchors.fill: parent
                visible: mediaBackend.sessionList.length > 0 || mediaWindow.editMode

                Repeater {
                    model: mediaWindow.editMode ? mediaBackend.maxSessions : Math.min(mediaBackend.sessionList.length, mediaBackend.maxSessions)

                    // Single session item
                    Rectangle {
                        width: parent.width
                        height: sessionHeight
                        color: "transparent"

                        property var session: mediaWindow.editMode ? null : sessionSlots.getSessionAtSlot(index)
                        property bool isFirstSession: session && mediaBackend.sessionList.length > 0 && session.name === mediaBackend.sessionList[0].name
                        property bool isDummy: mediaWindow.editMode && !session

                        opacity: isDummy ? 0.5 : 1.0

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.padding / 2
                            spacing: Theme.padding

                            // Album Art
                            Item {
                                Layout.preferredWidth: sessionHeight - Theme.padding
                                Layout.fillHeight: true

                                Rectangle {
                                    anchors.fill: parent
                                    color: Theme.surfaceColor
                                    radius: 4
                                    visible: isDummy

                                    Image {
                                        anchors.centerIn: parent
                                        width: 32
                                        height: 32
                                        source: iconsPath + "music.svg"
                                        sourceSize: Qt.size(32, 32)
                                        opacity: 0.2
                                    }
                                }

                                Image {
                                    anchors.fill: parent
                                    visible: !isDummy
                                    source: {
                                        if (isFirstSession && mediaBackend.albumArtPath) {
                                            return "file:///" + mediaBackend.albumArtPath
                                        }
                                        return ""
                                    }
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true

                                    // Fallback icon
                                    Image {
                                        anchors.centerIn: parent
                                        width: 32
                                        height: 32
                                        source: iconsPath + "music.svg"
                                        sourceSize: Qt.size(32, 32)
                                        opacity: 0.3
                                        visible: parent.status !== Image.Ready
                                    }
                                }
                            }

                            // Track info and controls
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: Theme.spacing / 2

                                // Title
                                Text {
                                    Layout.fillWidth: true
                                    text: isDummy ? "Empty Slot " + (index + 1) :
                                          (isFirstSession && mediaBackend.title ? mediaBackend.title :
                                           (session ? session.name : "Unknown"))
                                    font.pixelSize: Theme.fontSizeNormal
                                    font.bold: !isDummy
                                    color: isDummy ? Theme.textMuted : Theme.textPrimary
                                    elide: Text.ElideRight
                                }

                                // Artist
                                Text {
                                    Layout.fillWidth: true
                                    text: isFirstSession && mediaBackend.artist ? mediaBackend.artist : ""
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.textSecondary
                                    elide: Text.ElideRight
                                    visible: text !== "" && !isDummy
                                }

                                Item { Layout.fillHeight: true }

                                // Controls
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Theme.spacing
                                    visible: !isDummy

                                    Item { Layout.fillWidth: true }

                                    // Previous button
                                    Rectangle {
                                        width: 32
                                        height: 32
                                        radius: 16
                                        color: prevMouse.pressed ? Theme.titleBarButtonPressed :
                                               prevMouse.containsMouse ? Theme.titleBarButtonHover :
                                               Theme.surfaceColor
                                        opacity: isFirstSession && mediaBackend.canGoPrevious && !mediaWindow.editMode ? 1.0 : 0.4

                                        Image {
                                            anchors.centerIn: parent
                                            width: 16
                                            height: 16
                                            source: iconsPath + "skip-back.svg"
                                            sourceSize: Qt.size(16, 16)
                                        }

                                        MouseArea {
                                            id: prevMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            enabled: isFirstSession && mediaBackend.canGoPrevious && !mediaWindow.editMode
                                            onClicked: if (isFirstSession) mediaBackend.previous()
                                        }
                                    }

                                    // Play/Pause button
                                    Rectangle {
                                        width: 40
                                        height: 40
                                        radius: 20
                                        color: playMouse.pressed ? Theme.titleBarButtonPressed :
                                               playMouse.containsMouse ? Theme.titleBarButtonHover :
                                               Theme.surfaceColor
                                        opacity: isFirstSession && mediaBackend.canPlayPause && !mediaWindow.editMode ? 1.0 : 0.4

                                        Image {
                                            anchors.centerIn: parent
                                            width: 20
                                            height: 20
                                            source: iconsPath + (isFirstSession && mediaBackend.isPlaying ? "pause.svg" : "play.svg")
                                            sourceSize: Qt.size(20, 20)
                                        }

                                        MouseArea {
                                            id: playMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            enabled: isFirstSession && mediaBackend.canPlayPause && !mediaWindow.editMode
                                            onClicked: if (isFirstSession) mediaBackend.playPause()
                                        }
                                    }

                                    // Next button
                                    Rectangle {
                                        width: 32
                                        height: 32
                                        radius: 16
                                        color: nextMouse.pressed ? Theme.titleBarButtonPressed :
                                               nextMouse.containsMouse ? Theme.titleBarButtonHover :
                                               Theme.surfaceColor
                                        opacity: isFirstSession && mediaBackend.canGoNext && !mediaWindow.editMode ? 1.0 : 0.4

                                        Image {
                                            anchors.centerIn: parent
                                            width: 16
                                            height: 16
                                            source: iconsPath + "skip-forward.svg"
                                            sourceSize: Qt.size(16, 16)
                                        }

                                        MouseArea {
                                            id: nextMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            enabled: isFirstSession && mediaBackend.canGoNext && !mediaWindow.editMode
                                            onClicked: if (isFirstSession) mediaBackend.next()
                                        }
                                    }

                                    Item { Layout.fillWidth: true }
                                }
                            }
                        }

                        // Separator line
                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 1
                            color: Theme.borderColor
                            opacity: 0.3
                            visible: index < (mediaWindow.editMode ? mediaBackend.maxSessions : Math.min(mediaBackend.sessionList.length, mediaBackend.maxSessions)) - 1
                        }
                    }
                }
            }
        }
    }
}
