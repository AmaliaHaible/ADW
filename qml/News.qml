import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import Common 1.0

WidgetWindow {
    id: newsWindow

    geometryKey: "news"
    settingsStore: settingsBackend
    editMode: hubBackend.editMode
    hubVisible: hubBackend.hubVisible
    minResizeWidth: 280
    minResizeHeight: 350

    width: 320
    height: 450
    x: 800
    y: 450
    visible: hubBackend.newsVisible
    title: "News"

    property bool showCategories: false

    Column {
        anchors.fill: parent
        spacing: 0

        TitleBar {
            id: titleBar
            width: parent.width
            title: newsWindow.showCategories ? "Categories" : "Kagi News"
            dragEnabled: newsWindow.editMode
            minimized: newsWindow.minimized
            effectiveRadius: newsWindow.effectiveWindowRadius
            leftButtons: newsWindow.showCategories ? [
                {icon: "arrow-left.svg", action: "back", enabled: !hubBackend.editMode}
            ] : [
                {icon: "list.svg", action: "categories", enabled: !hubBackend.editMode},
                {icon: "refresh-cw.svg", action: "refresh", enabled: !hubBackend.editMode && !newsBackend.isLoading}
            ]
            rightButtons: [
                {icon: "eye-off.svg", action: "minimize"}
            ]

            onButtonClicked: function(action) {
                if (action === "minimize") {
                    newsWindow.toggleMinimize()
                } else if (action === "categories") {
                    newsWindow.showCategories = true
                } else if (action === "back") {
                    newsWindow.showCategories = false
                } else if (action === "refresh") {
                    newsBackend.refresh()
                }
            }
        }

        Rectangle {
            width: parent.width
            height: parent.height - titleBar.height
            color: "transparent"
            visible: !newsWindow.minimized

            StackLayout {
                anchors.fill: parent
                currentIndex: newsWindow.showCategories ? 1 : 0

                Item {
                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 30
                            color: Theme.surfaceColor
                            visible: newsBackend.error !== ""

                            Text {
                                anchors.centerIn: parent
                                text: newsBackend.error
                                color: Theme.error
                                font.pixelSize: Theme.fontSizeSmall
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 30
                            color: Theme.surfaceColor
                            visible: newsBackend.isLoading

                            Text {
                                anchors.centerIn: parent
                                text: "Loading..."
                                color: Theme.textSecondary
                                font.pixelSize: Theme.fontSizeSmall
                            }
                        }

                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            contentWidth: availableWidth

                            ColumnLayout {
                                width: parent.width
                                spacing: 0

                                Repeater {
                                    model: newsBackend.articles

                                    delegate: Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: articleContent.height + Theme.padding
                                        color: articleArea.containsMouse ? Theme.surfaceColor : "transparent"

                                        ColumnLayout {
                                            id: articleContent
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.top: parent.top
                                            anchors.margins: Theme.padding / 2
                                            spacing: 4

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: Theme.spacing / 2

                                                Text {
                                                    text: modelData.emoji || ""
                                                    font.pixelSize: Theme.fontSizeNormal
                                                    visible: modelData.emoji !== ""
                                                }

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: modelData.title
                                                    color: Theme.textPrimary
                                                    font.pixelSize: Theme.fontSizeNormal
                                                    font.weight: Font.Medium
                                                    wrapMode: Text.WordWrap
                                                }
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.summary
                                                color: Theme.textSecondary
                                                font.pixelSize: Theme.fontSizeSmall
                                                wrapMode: Text.WordWrap
                                                maximumLineCount: 3
                                                elide: Text.ElideRight
                                            }

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: Theme.spacing / 2

                                                Text {
                                                    text: modelData.category
                                                    color: Theme.accentColor
                                                    font.pixelSize: Theme.fontSizeSmall
                                                    visible: modelData.category !== ""
                                                }

                                                Text {
                                                    text: modelData.sources + " sources"
                                                    color: Theme.textMuted
                                                    font.pixelSize: Theme.fontSizeSmall
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: articleArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            acceptedButtons: Qt.LeftButton

                                            onClicked: {
                                                if (modelData.kagiLink) {
                                                    newsBackend.openArticle(modelData.kagiLink)
                                                } else {
                                                    var articles = modelData.articles
                                                    if (articles && articles.length > 0) {
                                                        newsBackend.openArticle(articles[0].link)
                                                    }
                                                }
                                            }
                                        }

                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.leftMargin: Theme.padding
                                            anchors.rightMargin: Theme.padding
                                            height: 1
                                            color: Theme.borderColor
                                            opacity: 0.3
                                        }
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    Layout.topMargin: Theme.padding * 2
                                    text: "No articles"
                                    color: Theme.textSecondary
                                    font.pixelSize: Theme.fontSizeNormal
                                    horizontalAlignment: Text.AlignHCenter
                                    visible: newsBackend.articles.length === 0 && !newsBackend.isLoading
                                }
                            }
                        }
                    }
                }

                Item {
                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: Theme.padding
                        clip: true
                        contentWidth: availableWidth

                        Flow {
                            width: parent.width
                            spacing: Theme.spacing / 2

                            Repeater {
                                model: newsBackend.categories

                                delegate: Rectangle {
                                    width: catText.width + Theme.padding
                                    height: 28
                                    radius: 14
                                    color: modelData.file.replace(".json", "") === newsBackend.selectedCategory ?
                                           Theme.accentColor : (catArea.containsMouse ? Theme.surfaceColor : Theme.windowBackground)
                                    border.color: Theme.borderColor
                                    border.width: 1

                                    Text {
                                        id: catText
                                        anchors.centerIn: parent
                                        text: modelData.name
                                        color: modelData.file.replace(".json", "") === newsBackend.selectedCategory ?
                                               Theme.windowBackground : Theme.textPrimary
                                        font.pixelSize: Theme.fontSizeSmall
                                    }

                                    MouseArea {
                                        id: catArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: {
                                            newsBackend.setCategory(modelData.file.replace(".json", ""))
                                            newsWindow.showCategories = false
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
