import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts

WidgetCard {
    id: root
    title: Translation.tr("Resources")
    icon: "monitor_heart"

    component ResourceRow: ColumnLayout {
        required property string label
        required property string valueText
        required property list<real> history
        Layout.fillWidth: true
        spacing: 2

        RowLayout {
            Layout.fillWidth: true
            StyledText {
                text: label
                color: Appearance.colors.colOnLayer2
            }
            Item { Layout.fillWidth: true }
            StyledText {
                text: valueText
                color: Appearance.colors.colSubtext
            }
        }
        Graph {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            values: history
        }
    }

    ResourceRow {
        label: Translation.tr("CPU")
        valueText: Math.round(ResourceUsage.cpuUsage * 100) + "%" + (ResourceUsage.cpuTemp >= 0 ? ` · ${ResourceUsage.cpuTemp}°C` : "")
        history: ResourceUsage.cpuUsageHistory
    }
    ResourceRow {
        label: Translation.tr("RAM")
        valueText: Math.round(ResourceUsage.memoryUsedPercentage * 100) + "%"
        history: ResourceUsage.memoryUsageHistory
    }
    RowLayout {
        Layout.fillWidth: true
        visible: ResourceUsage.gpuAvailable
        StyledText {
            text: Translation.tr("GPU")
            color: Appearance.colors.colOnLayer2
        }
        Item { Layout.fillWidth: true }
        StyledText {
            text: Math.round(ResourceUsage.gpuUsage * 100) + "%" + (ResourceUsage.gpuTemp >= 0 ? ` · ${ResourceUsage.gpuTemp}°C` : "")
            color: Appearance.colors.colSubtext
        }
    }
}
