pragma Singleton

// From https://github.com/caelestia-dots/shell (GPLv3)

import Quickshell
import qs.services

Singleton {
    id: root

    function getBatteryIcon(percentage: int): string {
        if (percentage >= 93) return "battery_android_full";
        if (percentage >= 78) return "battery_android_6";
        if (percentage >= 64) return "battery_android_5";
        if (percentage >= 50) return "battery_android_4";
        if (percentage >= 35) return "battery_android_3";
        if (percentage >= 21) return "battery_android_2";
        if (percentage >= 7) return "battery_android_1";
        return "battery_android_0";
    }

    function getBluetoothDeviceMaterialSymbol(systemIconName: string): string {
        if (systemIconName.includes("headset") || systemIconName.includes("headphones"))
            return "headphones";
        if (systemIconName.includes("audio"))
            return "speaker";
        if (systemIconName.includes("phone"))
            return "smartphone";
        if (systemIconName.includes("mouse"))
            return "mouse";
        if (systemIconName.includes("keyboard"))
            return "keyboard";
        return "bluetooth";
    }

    function getNetworkMaterialSymbol() {
        if (Network.ethernet) return "lan";
        if (Network.wifiEnabled && Network.wifiStatus === "connected") {
            const strength = Network.active?.strength ?? 0
            if (strength > 83) return "signal_wifi_4_bar";
            if (strength > 67) return "network_wifi";
            if (strength > 50) return "network_wifi_3_bar";
            if (strength > 33) return "network_wifi_2_bar";
            if (strength > 17) return "network_wifi_1_bar";
            return "signal_wifi_0_bar"
        } else {
            if (Network.wifiStatus === "connecting") return "signal_wifi_statusbar_not_connected";
            if (Network.wifiStatus === "disconnected") return "wifi_find";
            if (Network.wifiStatus === "disabled") return "signal_wifi_off";
            return "signal_wifi_bad";
        }
    }

    // WMO weather interpretation codes (used by the Open-Meteo API)
    readonly property var weatherIconMap: ({
        "0": "clear_day",
        "1": "partly_cloudy_day",
        "2": "partly_cloudy_day",
        "3": "cloud",
        "45": "foggy",
        "48": "foggy",
        "51": "rainy",
        "53": "rainy",
        "55": "rainy",
        "56": "rainy",
        "57": "rainy",
        "61": "rainy",
        "63": "rainy",
        "65": "rainy",
        "66": "weather_hail",
        "67": "weather_hail",
        "71": "snowing",
        "73": "snowing",
        "75": "snowing_heavy",
        "77": "cloudy_snowing",
        "80": "rainy",
        "81": "rainy",
        "82": "rainy",
        "85": "snowing",
        "86": "snowing_heavy",
        "95": "thunderstorm",
        "96": "thunderstorm",
        "99": "thunderstorm"
    })

    
    function getWeatherIcon(code) {
        const key = String(code)
        if (weatherIconMap.hasOwnProperty(key)) {
            return weatherIconMap[key]
        }
    }
}
