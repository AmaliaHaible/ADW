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
    height: 450
    minResizeWidth: 300
    minResizeHeight: 400

    title: "Media Control"

    Column {
        anchors.fill: parent

        TitleBar {
            title: "Media Control"
            dragEnabled: mediaWindow.editMode
            leftButtons: [{
                icon: "refresh-cw.svg",
                action: "refresh",
                enabled: true
            }]
            onButtonClicked: function(action) {
                if (action === "refresh") mediaBackend.refreshSessions()
            }
        }

        // Content area
        Item {
            width: parent.width
            height: parent.height - 32

            // Main content or placeholder
            Loader {
                anchors.fill: parent
                sourceComponent: mediaBackend.hasSession ? mainContent : placeholderContent
            }
        }
    }

    // Placeholder Component (no media playing)
    Component {
        id: placeholderContent

        Item {
            Column {
                anchors.centerIn: parent
                spacing: Theme.spacing * 2

                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 64
                    height: 64
                    source: iconsPath + "music.svg"
                    sourceSize: Qt.size(64, 64)
                    opacity: 0.4
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: mediaBackend.isLoading ?
                          "Connecting to media..." : "No media playing"
                    font.pixelSize: Theme.fontSizeNormal
                    color: Theme.textMuted
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: mediaBackend.errorMessage
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.error
                    visible: mediaBackend.errorMessage !== ""
                }
            }
        }
    }

    // Main Content Component
    Component {
        id: mainContent

        Item {
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.padding
                spacing: Theme.spacing * 1.5

                // Session tabs (if multiple sessions)
                ListView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    orientation: ListView.Horizontal
                    spacing: 6
                    visible: mediaBackend.sessionList.length > 1
                    clip: true

                    model: mediaBackend.sessionList

                    delegate: Rectangle {
                        width: 120
                        height: 36
                        radius: 6
                        color: index === mediaBackend.currentSessionIndex ?
                               Theme.accentColor : Theme.surfaceColor

                        Text {
                            anchors.centerIn: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            width: parent.width - 16
                            text: modelData.name
                            color: index === mediaBackend.currentSessionIndex ?
                                   Theme.windowBackground : Theme.textPrimary
                            font.pixelSize: Theme.fontSizeSmall
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: mediaBackend.switchSession(index)
                            enabled: !mediaWindow.editMode
                        }
                    }
                }

                // Album art
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 140

                    Rectangle {
                        anchors.centerIn: parent
                        width: 120
                        height: 120
                        color: Theme.surfaceColor
                        radius: Theme.borderRadius

                        Image {
                            anchors.fill: parent
                            anchors.margins: 2
                            source: mediaBackend.albumArtPath ?
                                    "file:///" + mediaBackend.albumArtPath : ""
                            fillMode: Image.PreserveAspectFit
                            smooth: true

                            // Fallback icon if no album art
                            Image {
                                anchors.centerIn: parent
                                width: 48
                                height: 48
                                source: iconsPath + "music.svg"
                                sourceSize: Qt.size(48, 48)
                                opacity: 0.3
                                visible: parent.status !== Image.Ready
                            }
                        }
                    }
                }

                // Track info
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        Layout.fillWidth: true
                        text: mediaBackend.title || "No title"
                        font.pixelSize: Theme.fontSizeLarge
                        font.bold: true
                        color: Theme.textPrimary
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Text {
                        Layout.fillWidth: true
                        text: mediaBackend.artist || "Unknown artist"
                        font.pixelSize: Theme.fontSizeNormal
                        color: Theme.textSecondary
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                // Control buttons
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    spacing: 8

                    Item { Layout.fillWidth: true } // Spacer

                    // Shuffle button
                    IconButton {
                        icon: "shuffle.svg"
                        size: 32
                        enabled: mediaBackend.shuffleState !== "Unknown" && !mediaWindow.editMode
                        highlighted: mediaBackend.shuffleState === "On"
                        onClicked: mediaBackend.toggleShuffle()
                    }

                    // Previous button
                    IconButton {
                        icon: "skip-back.svg"
                        size: 36
                        enabled: mediaBackend.canGoPrevious && !mediaWindow.editMode
                        onClicked: mediaBackend.previous()
                    }

                    // Play/Pause button
                    IconButton {
                        icon: mediaBackend.isPlaying ? "pause.svg" : "play.svg"
                        size: 44
                        enabled: mediaBackend.canPlayPause && !mediaWindow.editMode
                        onClicked: mediaBackend.playPause()
                        highlighted: true
                    }

                    // Next button
                    IconButton {
                        icon: "skip-forward.svg"
                        size: 36
                        enabled: mediaBackend.canGoNext && !mediaWindow.editMode
                        onClicked: mediaBackend.next()
                    }

                    // Repeat button
                    IconButton {
                        icon: mediaBackend.repeatState === "Track" ? "repeat-1.svg" : "repeat.svg"
                        size: 32
                        enabled: mediaBackend.repeatState !== "Unknown" && !mediaWindow.editMode
                        highlighted: mediaBackend.repeatState !== "Off"
                        onClicked: mediaBackend.cycleRepeat()
                    }

                    Item { Layout.fillWidth: true } // Spacer
                }

                // Progress slider
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: mediaBackend.positionText
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.textSecondary
                        Layout.preferredWidth: 40
                    }

                    Slider {
                        id: progressSlider
                        Layout.fillWidth: true
                        from: 0
                        to: mediaBackend.duration > 0 ? mediaBackend.duration : 100
                        value: mediaBackend.position
                        enabled: mediaBackend.duration > 0 && !mediaWindow.editMode

                        onMoved: {
                            mediaBackend.setPosition(Math.floor(value))
                        }

                        background: Rectangle {
                            x: progressSlider.leftPadding
                            y: progressSlider.topPadding + progressSlider.availableHeight / 2 - height / 2
                            width: progressSlider.availableWidth
                            height: 4
                            radius: 2
                            color: Theme.surfaceColor

                            Rectangle {
                                width: progressSlider.visualPosition * parent.width
                                height: parent.height
                                radius: 2
                                color: Theme.accentColor
                            }
                        }

                        handle: Rectangle {
                            x: progressSlider.leftPadding +
                               progressSlider.visualPosition *
                               (progressSlider.availableWidth - width)
                            y: progressSlider.topPadding +
                               progressSlider.availableHeight / 2 - height / 2
                            width: 12
                            height: 12
                            radius: 6
                            color: progressSlider.pressed ? Theme.accentHover : Theme.accentColor
                        }
                    }

                    Text {
                        text: mediaBackend.durationText
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.textSecondary
                        Layout.preferredWidth: 40
                        horizontalAlignment: Text.AlignRight
                    }
                }

                Item { Layout.fillHeight: true } // Spacer

                // Error message (if any)
                Text {
                    Layout.fillWidth: true
                    text: mediaBackend.errorMessage
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.error
                    visible: mediaBackend.errorMessage !== ""
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    // Reusable IconButton Component
    component IconButton: Rectangle {
        id: iconButton
        property string icon: ""
        property int size: 36
        property bool highlighted: false

        signal clicked()

        width: size
        height: size
        radius: size / 2
        color: mouseArea.pressed ? Theme.titleBarButtonPressed :
               mouseArea.containsMouse ? Theme.titleBarButtonHover :
               "transparent"
        opacity: enabled ? 1.0 : 0.4

        Image {
            anchors.centerIn: parent
            width: parent.size * 0.5
            height: parent.size * 0.5
            source: iconsPath + icon
            sourceSize: Qt.size(width, height)
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Theme.accentColor
            opacity: highlighted ? 0.2 : 0
            z: -1
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: if (enabled) parent.clicked()
        }
    }
}
