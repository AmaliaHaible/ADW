pragma Singleton
import QtQuick 2.15

QtObject {
    // Base colors - read from themeProvider if available, otherwise use defaults
    readonly property color windowBackground: themeProvider ? themeProvider.windowBackground : "#1e1e2e"
    readonly property color surfaceColor: themeProvider ? themeProvider.surfaceColor : "#313244"

    // Title bar
    readonly property color titleBarBackground: themeProvider ? themeProvider.titleBarBackground : "#383858"
    readonly property color titleBarText: themeProvider ? themeProvider.titleBarText : "#cdd6f4"
    readonly property color titleBarButtonHover: themeProvider ? themeProvider.titleBarButtonHover : "#45475a"
    readonly property color titleBarButtonPressed: themeProvider ? themeProvider.titleBarButtonPressed : "#585b70"

    // Accent colors
    readonly property color accentColor: themeProvider ? themeProvider.accentColor : "#89b4fa"
    readonly property color accentHover: themeProvider ? themeProvider.accentHover : "#b4befe"
    readonly property color accentInactive: themeProvider ? themeProvider.accentInactive : "#45475a"

    // Text colors
    readonly property color textPrimary: themeProvider ? themeProvider.textPrimary : "#cdd6f4"
    readonly property color textSecondary: themeProvider ? themeProvider.textSecondary : "#a6adc8"
    readonly property color textMuted: themeProvider ? themeProvider.textMuted : "#6c7086"
    readonly property color textPrimaryInverted: themeProvider ? themeProvider.textPrimaryInverted : "#1e1e2e"
    readonly property color textSecondaryInverted: themeProvider ? themeProvider.textSecondaryInverted : "#313244"
    readonly property color borderColor: themeProvider ? themeProvider.borderColor : "#6c7086"

    // Custom palette colors
    readonly property color colorRed: themeProvider ? themeProvider.colorRed : "#f38ba8"
    readonly property color colorOrange: themeProvider ? themeProvider.colorOrange : "#fab387"
    readonly property color colorYellow: themeProvider ? themeProvider.colorYellow : "#f9e2af"
    readonly property color colorGreen: themeProvider ? themeProvider.colorGreen : "#a6e3a1"
    readonly property color colorBlue: themeProvider ? themeProvider.colorBlue : "#89b4fa"
    readonly property color colorPurple: themeProvider ? themeProvider.colorPurple : "#cba6f7"

    // Font sizes
    readonly property int fontSizeSmall: themeProvider ? themeProvider.fontSizeSmall : 11
    readonly property int fontSizeNormal: themeProvider ? themeProvider.fontSizeNormal : 13
    readonly property int fontSizeLarge: themeProvider ? themeProvider.fontSizeLarge : 16
    readonly property int fontSizeTitle: themeProvider ? themeProvider.fontSizeTitle : 14

    // Dimensions
    readonly property int titleBarHeight: themeProvider ? themeProvider.titleBarHeight : 32
    readonly property int borderRadius: themeProvider ? themeProvider.borderRadius : 8
    readonly property int windowRadius: themeProvider ? themeProvider.windowRadius : 12
    readonly property int spacing: themeProvider ? themeProvider.spacing : 8
    readonly property int padding: themeProvider ? themeProvider.padding : 12
    readonly property int textScrollSpeed: themeProvider ? themeProvider.textScrollSpeed : 50
}

