import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Common 1.0

WidgetWindow {
    id: weatherWindow

    geometryKey: "weather"
    settingsStore: settingsBackend
    editMode: hubBackend.editMode
    hubVisible: hubBackend.hubVisible
    minResizeWidth: 250
    minResizeHeight: 300

    width: 250
    height: 400
    x: 420
    y: 100
    visible: hubBackend.weatherVisible
    title: "Weather"

    Column {
        anchors.fill: parent
        spacing: 0

        // Title bar with settings and refresh on left
        TitleBar {
            id: titleBar
            width: parent.width
            title: "Weather"
            dragEnabled: weatherWindow.editMode
            minimized: weatherWindow.minimized
            effectiveRadius: weatherWindow.effectiveWindowRadius
            leftButtons: stackView.depth > 1 ? [
                {icon: "arrow-left.svg", action: "back", enabled: !hubBackend.editMode}
            ] : [
                {icon: "settings.svg", action: "settings", enabled: !hubBackend.editMode},
                {icon: "refresh-cw.svg", action: "refresh", enabled: !hubBackend.editMode}
            ]
            rightButtons: [
                {icon: "eye-off.svg", action: "minimize"}
            ]

            onButtonClicked: function(action) {
                if (action === "settings") {
                    stackView.push(settingsViewComponent)
                } else if (action === "refresh") {
                    weatherBackend.refreshWeather()
                } else if (action === "back") {
                    stackView.pop()
                } else if (action === "minimize") {
                    weatherWindow.toggleMinimize()
                }
            }
        }

        // StackView for main/settings views
        StackView {
            id: stackView
            width: parent.width
            height: parent.height - titleBar.height
            initialItem: mainViewComponent
            visible: !weatherWindow.minimized
        }
    }

    // Main Weather View Component
    Component {
        id: mainViewComponent

        Item {
            ScrollView {
                anchors.fill: parent
                contentWidth: availableWidth
                clip: true

                ColumnLayout {
                    width: parent.width
                    spacing: Theme.spacing

                    // Error message
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.margins: Theme.padding
                        height: errorText.height + Theme.padding * 2
                        color: Theme.surfaceColor
                        radius: 4
                        visible: weatherBackend.errorMessage !== ""

                        Text {
                            id: errorText
                            anchors.centerIn: parent
                            width: parent.width - Theme.padding * 2
                            text: weatherBackend.errorMessage
                            color: Theme.error
                            font.pixelSize: Theme.fontSizeSmall
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    // Current Weather
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: currentWeatherLayout.height + Theme.padding * 2
                        visible: weatherBackend.locationName !== ""

                        ColumnLayout {
                            id: currentWeatherLayout
                            anchors.centerIn: parent
                            spacing: 2

                            Image {
                                Layout.alignment: Qt.AlignHCenter
                                source: weatherBackend.currentIcon ? "file:///" + weatherBackend.currentIcon : ""
                                sourceSize: Qt.size(64, 64)
                                width: 64
                                height: 64
                                visible: weatherBackend.currentIcon !== ""
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: Math.round(weatherBackend.currentTemp) + "°C"
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSizeLarge * 2
                                font.weight: Font.Light
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: weatherBackend.currentPrecip + "%"
                                color: Theme.accentColor
                                font.pixelSize: Theme.fontSizeSmall
                                visible: weatherBackend.currentPrecip > 0
                            }
                        }
                    }

                    // No location message
                    Text {
                        Layout.fillWidth: true
                        Layout.margins: Theme.padding
                        text: "No location set.\nClick settings to choose a location."
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSizeNormal
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        visible: weatherBackend.locationName === ""
                    }

                    // Hourly Forecast
                    ColumnLayout {
                        Layout.fillWidth: true
                        // Layout.margins: Theme.padding
                        Layout.leftMargin: Theme.padding
                        Layout.rightMargin: Theme.padding
                        spacing: Theme.spacing / 2
                        visible: weatherBackend.hourlyData.length > 0

                        Text {
                            text: "Hourly Forecast"
                            color: Theme.textPrimary
                            font.pixelSize: Theme.fontSizeNormal
                            font.weight: Font.Medium
                        }

                        ListView {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 80
                            orientation: ListView.Horizontal
                            spacing: Theme.spacing
                            clip: true

                            model: weatherBackend.hourlyData

                            delegate: Item {
                                width: 60
                                height: 80

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 2

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: {
                                            var date = new Date(modelData.time)
                                            return Qt.formatTime(date, "hh:mm")
                                        }
                                        color: Theme.textSecondary
                                        font.pixelSize: Theme.fontSizeSmall
                                    }

                                    Image {
                                        Layout.alignment: Qt.AlignHCenter
                                        source: modelData.icon ? "file:///" + modelData.icon : ""
                                        sourceSize: Qt.size(24, 24)
                                        width: 24
                                        height: 24
                                    }

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: Math.round(modelData.temp) + "°"
                                        color: Theme.textPrimary
                                        font.pixelSize: Theme.fontSizeSmall
                                    }

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.precip + "%"
                                        color: Theme.accentColor
                                        font.pixelSize: Theme.fontSizeSmall
                                    }
                                }
                            }
                        }
                    }

                    // Daily Forecast
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: Theme.padding
                        Layout.rightMargin: Theme.padding
                        Layout.topMargin: Theme.spacing 
                        // Layout.bottomMargin: Theme.padding
                        spacing: Theme.spacing / 2
                        visible: weatherBackend.dailyData.length > 0

                        Text {
                            text: "Daily Forecast"
                            color: Theme.textPrimary
                            font.pixelSize: Theme.fontSizeNormal
                            font.weight: Font.Medium
                        }

                        Flow {
                            Layout.fillWidth: true
                            spacing: Theme.spacing

                            Repeater {
                                model: weatherBackend.dailyData

                                delegate: Item {
                                    width: 60
                                    height: contentColumn.implicitHeight

                                    ColumnLayout {
                                        id: contentColumn
                                        anchors.centerIn: parent
                                        spacing: 2

                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: {
                                                var date = new Date(modelData.date)
                                                return Qt.formatDate(date, "ddd")
                                            }
                                            color: Theme.textPrimary
                                            font.pixelSize: Theme.fontSizeSmall
                                            font.weight: Font.Medium
                                        }

                                        Image {
                                            Layout.alignment: Qt.AlignHCenter
                                            source: modelData.icon ? "file:///" + modelData.icon : ""
                                            sourceSize: Qt.size(32, 32)
                                            width: 32
                                            height: 32
                                        }

                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: Math.round(modelData.maxTemp) + "°"
                                            color: Theme.textPrimary
                                            font.pixelSize: Theme.fontSizeSmall
                                            font.weight: Font.Medium
                                        }

                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: Math.round(modelData.minTemp) + "°"
                                            color: Theme.textSecondary
                                            font.pixelSize: Theme.fontSizeSmall
                                        }

                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: modelData.precip + "%"
                                            color: Theme.accentColor
                                            font.pixelSize: Theme.fontSizeSmall
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Loading indicator
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.margins: Theme.padding
                        text: "Loading..."
                        color: Theme.textSecondary
                        font.pixelSize: Theme.fontSizeNormal
                        visible: weatherBackend.isLoading
                    }

                    // Spacer
                    Item {
                        Layout.fillHeight: true
                    }
                }
            }
        }
    }

    // Settings View Component
    Component {
        id: settingsViewComponent

        Item {
            id: settingsViewRoot

            // Auto-navigate back when location is selected
            Connections {
                target: weatherBackend
                function onLocationNameChanged() {
                    if (weatherBackend.locationName) {
                        settingsViewRoot.StackView.view.pop()
                    }
                }
            }

            ScrollView {
                anchors.fill: parent
                contentWidth: availableWidth
                clip: true

                ColumnLayout {
                    width: parent.width
                    spacing: Theme.spacing * 2

                    // Current location
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.margins: Theme.padding
                        spacing: Theme.spacing / 2

                        Text {
                            text: "Current Location"
                            color: Theme.textPrimary
                            font.pixelSize: Theme.fontSizeNormal
                            font.weight: Font.Medium
                        }

                        Text {
                            Layout.fillWidth: true
                            text: weatherBackend.locationName || "No location set"
                            color: Theme.textSecondary
                            font.pixelSize: Theme.fontSizeSmall
                            wrapMode: Text.WordWrap
                        }
                    }

                    // Location search
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.margins: Theme.padding
                        spacing: Theme.spacing / 2

                        Text {
                            text: "Search Location"
                            color: Theme.textPrimary
                            font.pixelSize: Theme.fontSizeNormal
                            font.weight: Font.Medium
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacing

                            TextField {
                                id: searchField
                                Layout.fillWidth: true
                                placeholderText: "Enter city name..."
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSizeNormal

                                background: Rectangle {
                                    color: Theme.surfaceColor
                                    border.color: Theme.borderColor
                                    border.width: 1
                                    radius: Theme.borderRadius
                                }

                                Keys.onReturnPressed: {
                                    if (searchField.text.trim() !== "") {
                                        weatherBackend.searchLocation(searchField.text)
                                    }
                                }
                            }

                            Button {
                                text: "Search"
                                enabled: searchField.text.trim() !== "" && !weatherBackend.isSearching
                                onClicked: weatherBackend.searchLocation(searchField.text)

                                background: Rectangle {
                                    color: parent.enabled ? Theme.accentColor : Theme.borderColor
                                    radius: Theme.borderRadius
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

                        // Search results
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Theme.spacing / 2
                            visible: weatherBackend.searchResults.length > 0

                            Repeater {
                                model: weatherBackend.searchResults

                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: resultText.implicitHeight + Theme.padding * 2
                                    color: resultMouseArea.containsMouse ? Theme.borderColor : "transparent"
                                    border.color: Theme.borderColor
                                    border.width: 1
                                    radius: Theme.borderRadius

                                    Text {
                                        id: resultText
                                        width: parent.width - Theme.padding * 2
                                        anchors.centerIn: parent
                                        text: modelData.display_name
                                        color: Theme.textPrimary
                                        font.pixelSize: Theme.fontSizeSmall
                                        wrapMode: Text.WordWrap
                                    }

                                    MouseArea {
                                        id: resultMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            weatherBackend.selectLocation(index)
                                        }
                                    }
                                }
                            }
                        }

                        // Search loading
                        Text {
                            text: "Searching..."
                            color: Theme.textSecondary
                            font.pixelSize: Theme.fontSizeSmall
                            visible: weatherBackend.isSearching
                        }

                        // Error message
                        Text {
                            Layout.fillWidth: true
                            text: weatherBackend.errorMessage
                            color: Theme.error
                            font.pixelSize: Theme.fontSizeSmall
                            wrapMode: Text.WordWrap
                            visible: weatherBackend.errorMessage !== ""
                        }
                    }

                    // Forecast count
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.margins: Theme.padding
                        spacing: Theme.spacing / 2

                        Text {
                            text: "Forecast Hours/Days"
                            color: Theme.textPrimary
                            font.pixelSize: Theme.fontSizeNormal
                            font.weight: Font.Medium
                        }

                        SpinBox {
                            id: forecastSpinBox
                            from: 3
                            to: 7
                            value: weatherBackend.forecastHours
                            editable: true

                            onValueModified: {
                                weatherBackend.setForecastHours(value)
                            }

                            contentItem: TextInput {
                                text: forecastSpinBox.textFromValue(forecastSpinBox.value, forecastSpinBox.locale)
                                color: Theme.textPrimary
                                font.pixelSize: Theme.fontSizeNormal
                                horizontalAlignment: Qt.AlignHCenter
                                verticalAlignment: Qt.AlignVCenter
                                readOnly: !forecastSpinBox.editable
                                validator: forecastSpinBox.validator
                                inputMethodHints: Qt.ImhDigitsOnly
                            }

                            up.indicator: Rectangle {
                                x: forecastSpinBox.width - width
                                height: forecastSpinBox.height / 2
                                implicitWidth: 24
                                implicitHeight: 20
                                color: forecastSpinBox.up.pressed ? Theme.borderColor : Theme.surfaceColor
                                border.color: Theme.borderColor

                                Text {
                                    text: "+"
                                    font.pixelSize: Theme.fontSizeNormal
                                    color: Theme.textPrimary
                                    anchors.centerIn: parent
                                }
                            }

                            down.indicator: Rectangle {
                                x: forecastSpinBox.width - width
                                y: forecastSpinBox.height / 2
                                height: forecastSpinBox.height / 2
                                implicitWidth: 24
                                implicitHeight: 20
                                color: forecastSpinBox.down.pressed ? Theme.borderColor : Theme.surfaceColor
                                border.color: Theme.borderColor

                                Text {
                                    text: "-"
                                    font.pixelSize: Theme.fontSizeNormal
                                    color: Theme.textPrimary
                                    anchors.centerIn: parent
                                }
                            }

                            background: Rectangle {
                                color: Theme.surfaceColor
                                border.color: Theme.borderColor
                                border.width: 1
                                radius: 4
                            }
                        }
                    }

                    // Spacer
                    Item {
                        Layout.fillHeight: true
                    }
                }
            }
        }
    }
}
