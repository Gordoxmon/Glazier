import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: 10

    WidgetCard {
        Layout.fillWidth: true
        visible: News.groups.length === 0
        title: Translation.tr("News")
        icon: "newspaper"

        headerAction: RippleButton {
            implicitWidth: 28
            implicitHeight: 28
            buttonRadius: Appearance.rounding.full
            contentItem: MaterialSymbol {
                text: "refresh"
                iconSize: Appearance.font.pixelSize.normal
                horizontalAlignment: Text.AlignHCenter
                color: Appearance.colors.colOnLayer2
            }
            onClicked: News.refresh()
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 80

            PagePlaceholder {
                title: News.loading ? Translation.tr("Loading...") : Translation.tr("No headlines")
                icon: "newspaper"
            }
        }
    }

    Repeater {
        model: News.groups
        delegate: WidgetCard {
            id: card
            required property var modelData
            required property int index
            Layout.fillWidth: true
            title: modelData.name
            icon: modelData.icon

            headerAction: RippleButton {
                visible: card.index === 0
                implicitWidth: card.index === 0 ? 28 : 0
                implicitHeight: 28
                buttonRadius: Appearance.rounding.full
                contentItem: MaterialSymbol {
                    text: "refresh"
                    iconSize: Appearance.font.pixelSize.normal
                    horizontalAlignment: Text.AlignHCenter
                    color: Appearance.colors.colOnLayer2
                }
                onClicked: News.refresh()
            }

            Repeater {
                model: card.modelData.items
                delegate: RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 8

                    StyledImage {
                        visible: modelData.thumbnail !== ""
                        Layout.preferredWidth: visible ? 48 : 0
                        Layout.preferredHeight: 48
                        Layout.alignment: Qt.AlignVCenter
                        fillMode: Image.PreserveAspectCrop
                        source: modelData.thumbnail
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: modelData.title
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        color: Appearance.colors.colOnLayer2

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.openUrlExternally(modelData.link)
                        }
                    }
                    StyledText {
                        text: NotificationUtils.getFriendlyNotifTimeString(modelData.date)
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        color: Appearance.colors.colSubtext
                    }
                }
            }
        }
    }
}
