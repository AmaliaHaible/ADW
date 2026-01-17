pragma Singleton
import QtQuick 2.15

QtObject {
    // Base colors
    readonly property color baseColor: "#9cbfd7"
    readonly property color windowBackground: "#1e1e2e"
    readonly property color surfaceColor: "#313244"

    // Title bar
    readonly property color titleBarBackground: "#181825"
    readonly property color titleBarText: "#cdd6f4"
    readonly property color titleBarButtonHover: "#45475a"
    readonly property color titleBarButtonPressed: "#585b70"

    // Accent colors
    readonly property color accentColor: "#89b4fa"
    readonly property color accentHover: "#b4befe"

    // Text colors
    readonly property color textPrimary: "#cdd6f4"
    readonly property color textSecondary: "#a6adc8"
    readonly property color textMuted: "#6c7086"

    // Status colors
    readonly property color success: "#a6e3a1"
    readonly property color warning: "#f9e2af"
    readonly property color error: "#f38ba8"

    // Font sizes
    readonly property int fontSizeSmall: 11
    readonly property int fontSizeNormal: 13
    readonly property int fontSizeLarge: 16
    readonly property int fontSizeTitle: 14

    // Dimensions
    readonly property int titleBarHeight: 32
    readonly property int buttonSize: 24
    readonly property int borderRadius: 8
    readonly property int spacing: 8
    readonly property int padding: 12
}

