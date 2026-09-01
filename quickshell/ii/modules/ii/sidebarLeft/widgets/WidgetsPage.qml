import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property real padding: 4

    StyledFlickable {
        anchors {
            fill: parent
            margins: root.padding
        }
        contentHeight: layout.implicitHeight

        ColumnLayout {
            id: layout
            anchors.fill: parent
            spacing: 10

            Loader {
                Layout.fillWidth: true
                active: Config.options.sidebar.widgets.media.enable
                visible: active
                sourceComponent: MediaWidget {}
            }
            Loader {
                Layout.fillWidth: true
                active: Config.options.sidebar.widgets.weather.enable
                visible: active
                sourceComponent: WeatherWidget {}
            }
            Loader {
                Layout.fillWidth: true
                active: Config.options.sidebar.widgets.news.enable
                visible: active
                sourceComponent: NewsWidget {}
            }
            Loader {
                Layout.fillWidth: true
                active: Config.options.sidebar.widgets.resources.enable
                visible: active
                sourceComponent: ResourcesWidget {}
            }
        }
    }
}
