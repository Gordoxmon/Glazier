import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property real padding: 4

    Component { id: mediaComponent; MediaWidget {} }
    Component { id: weatherComponent; WeatherWidget {} }
    Component { id: newsComponent; NewsWidget {} }
    Component { id: resourcesComponent; ResourcesWidget {} }
    readonly property var widgetComponents: ({
        media: mediaComponent,
        weather: weatherComponent,
        news: newsComponent,
        resources: resourcesComponent
    })

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

            Repeater {
                model: Config.options.sidebar.widgets.order
                delegate: Loader {
                    required property string modelData
                    Layout.fillWidth: true
                    active: Config.options.sidebar.widgets[modelData]?.enable ?? false
                    visible: active
                    sourceComponent: root.widgetComponents[modelData]
                }
            }
        }
    }
}
