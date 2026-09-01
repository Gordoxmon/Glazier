import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string title: ""
    property string icon: ""
    default property alias content: contentColumn.data
    property alias headerAction: headerActionLoader.sourceComponent

    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer2
    implicitHeight: layout.implicitHeight + 24
    Layout.fillWidth: true

    ColumnLayout {
        id: layout
        anchors {
            fill: parent
            margins: 12
        }
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            MaterialSymbol {
                visible: root.icon !== ""
                text: root.icon
                iconSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colOnLayer2
            }
            StyledText {
                text: root.title
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer2
            }
            Item { Layout.fillWidth: true }
            Loader {
                id: headerActionLoader
            }
        }

        ColumnLayout {
            id: contentColumn
            Layout.fillWidth: true
            spacing: 8
        }
    }
}
