import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

QuickToggleModel {
    name: Translation.tr("Hotspot")
    statusText: Hotspot.active ? Hotspot.ssid : Translation.tr("Off")
    tooltipText: Translation.tr("Wi-Fi hotspot | Right-click to configure")
    icon: Hotspot.active ? "wifi_tethering" : "wifi_tethering_off"

    toggled: Hotspot.active
    mainAction: () => Hotspot.toggle()
    hasMenu: true
}
