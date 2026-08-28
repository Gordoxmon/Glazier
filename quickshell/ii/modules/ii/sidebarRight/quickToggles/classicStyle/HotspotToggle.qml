import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.sidebarRight.quickToggles

QuickToggleButton {
    toggled: Hotspot.active
    buttonIcon: Hotspot.active ? "wifi_tethering" : "wifi_tethering_off"
    onClicked: Hotspot.toggle()
    StyledToolTip {
        text: Translation.tr("Wi-Fi hotspot | Right-click to configure")
    }
}
