import QtQuick 2.15
import Common 1.0

Item {
    id: root

    // Public properties
    property alias text: textItem.text
    property alias color: textItem.color
    property alias font: textItem.font
    property alias elide: textItem.elide
    property alias horizontalAlignment: textItem.horizontalAlignment

    clip: true

    // Calculate scroll duration based on distance and speed
    property int scrollDuration: {
        var distance = textItem.contentWidth - root.width
        var speed = Theme.textScrollSpeed
        if (distance <= 0 || speed <= 0) {
            return 2000
        }
        return Math.floor((distance / speed) * 1000)
    }

    // Internal text item
    Text {
        id: textItem
        y: 0
        color: Theme.textPrimary
        elide: Text.ElideRight

        // Scrolling animation
        SequentialAnimation {
            id: scrollAnimation
            running: false
            loops: Animation.Infinite

            // Initial pause (0.5 seconds)
            PauseAnimation {
                duration: 500
            }

            // Scroll to end
            NumberAnimation {
                target: textItem
                property: "x"
                from: 0
                to: root.width - textItem.contentWidth
                duration: root.scrollDuration
                easing.type: Easing.Linear
            }

            // Pause at end (0.5 seconds)
            PauseAnimation {
                duration: 500
            }

            // Reset to start (instant)
            PropertyAction {
                target: textItem
                property: "x"
                value: 0
            }
        }

        Component.onCompleted: {
            checkScrollNeeded()
        }

        onContentWidthChanged: {
            checkScrollNeeded()
        }
    }

    onWidthChanged: {
        checkScrollNeeded()
    }

    // Restart animation when duration changes
    onScrollDurationChanged: {
        if (scrollAnimation.running) {
            scrollAnimation.restart()
        }
    }

    function checkScrollNeeded() {
        if (textItem.contentWidth > root.width) {
            scrollAnimation.restart()
        } else {
            scrollAnimation.stop()
            textItem.x = 0
        }
    }
}
