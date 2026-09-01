import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.bar.weather
import QtQuick
import QtQuick.Layouts

WidgetCard {
    id: root
    title: Weather.data.city || Translation.tr("Weather")
    icon: "cloud"

    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        MaterialSymbol {
            fill: 1
            iconSize: 48
            color: Appearance.colors.colOnLayer2
            text: Icons.getWeatherIcon(Weather.data.wCode) ?? "cloud"
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                text: Weather.data.temp || "--°"
                font.pixelSize: Appearance.font.pixelSize.hugeass
                font.weight: Font.Medium
                color: Appearance.colors.colOnLayer2
            }
            StyledText {
                text: Translation.tr("Feels like %1").arg(Weather.data.tempFeelsLike || "--°")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
        }
    }

    GridLayout {
        Layout.fillWidth: true
        visible: Config.options.sidebar.widgets.weather.forecast
        columns: 2
        rowSpacing: 5
        columnSpacing: 5
        uniformCellWidths: true

        WeatherCard {
            title: Translation.tr("UV Index")
            symbol: "wb_sunny"
            value: Weather.data.uv
        }
        WeatherCard {
            title: Translation.tr("Wind")
            symbol: "air"
            value: `(${Weather.data.windDir}) ${Weather.data.wind}`
        }
        WeatherCard {
            title: Translation.tr("Precipitation")
            symbol: "rainy_light"
            value: Weather.data.precip
        }
        WeatherCard {
            title: Translation.tr("Humidity")
            symbol: "humidity_low"
            value: Weather.data.humidity
        }
        WeatherCard {
            title: Translation.tr("Sunrise")
            symbol: "wb_twilight"
            value: Weather.data.sunrise
        }
        WeatherCard {
            title: Translation.tr("Sunset")
            symbol: "bedtime"
            value: Weather.data.sunset
        }
    }

    RowLayout {
        Layout.fillWidth: true
        visible: Config.options.sidebar.widgets.weather.forecast
        spacing: 6

        Repeater {
            model: Weather.forecast
            delegate: ColumnLayout {
                required property var modelData
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: modelData.day ? modelData.day.split("-").slice(1).join("/") : ""
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                }
                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colOnLayer2
                    text: Icons.getWeatherIcon(modelData.wCode) ?? "cloud"
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: modelData.high
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnLayer2
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: modelData.low
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                }
            }
        }
    }
}
