pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import QtPositioning

import qs.modules.common

Singleton {
    id: root
    // 10 minute
    readonly property int fetchInterval: Config.options.bar.weather.fetchInterval * 60 * 1000
    readonly property string city: Config.options.bar.weather.city
    readonly property bool useUSCS: Config.options.bar.weather.useUSCS
    property bool gpsActive: Config.options.bar.weather.enableGPS

    onUseUSCSChanged: {
        root.getData();
    }
    onCityChanged: {
        root.getData();
    }

    property var location: ({
        valid: false,
        lat: 0,
        lon: 0
    })

    property var data: ({
        uv: 0,
        humidity: 0,
        sunrise: 0,
        sunset: 0,
        windDir: 0,
        wCode: 0,
        city: 0,
        wind: 0,
        precip: 0,
        visib: 0,
        press: 0,
        temp: 0,
        tempFeelsLike: 0,
        lastRefresh: 0,
    })

    property var forecast: []

    function degToCompass(deg) {
        const dirs = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"];
        return dirs[Math.round(deg / 22.5) % 16];
    }

    function formatTime(iso) {
        const parts = (iso || "").split("T");
        return parts.length > 1 ? parts[1] : "--:--";
    }

    function refineData(res, cityLabel) {
        const c = res?.current || {};
        const daily = res?.daily || {};
        let temp = {};
        temp.uv = c.uv_index ?? 0;
        temp.humidity = (c.relative_humidity_2m ?? 0) + "%";
        temp.sunrise = formatTime(daily.sunrise?.[0]);
        temp.sunset = formatTime(daily.sunset?.[0]);
        temp.windDir = degToCompass(c.wind_direction_10m ?? 0);
        temp.wCode = c.weather_code ?? 0;
        temp.city = cityLabel || root.city || "City";
        if (root.useUSCS) {
            temp.wind = Math.round((c.wind_speed_10m ?? 0) * 0.621371) + " mph";
            temp.precip = ((c.precipitation ?? 0) / 25.4).toFixed(2) + " in";
            temp.visib = ((c.visibility ?? 0) / 1609.34).toFixed(1) + " mi";
            temp.press = ((c.surface_pressure ?? 0) * 0.02953).toFixed(2) + " inHg";
            temp.temp = Math.round((c.temperature_2m ?? 0) * 9 / 5 + 32) + "°F";
            temp.tempFeelsLike = Math.round((c.apparent_temperature ?? 0) * 9 / 5 + 32) + "°F";
        } else {
            temp.wind = Math.round(c.wind_speed_10m ?? 0) + " km/h";
            temp.precip = (c.precipitation ?? 0) + " mm";
            temp.visib = ((c.visibility ?? 0) / 1000).toFixed(1) + " km";
            temp.press = Math.round(c.surface_pressure ?? 0) + " hPa";
            temp.temp = Math.round(c.temperature_2m ?? 0) + "°C";
            temp.tempFeelsLike = Math.round(c.apparent_temperature ?? 0) + "°C";
        }
        temp.lastRefresh = DateTime.time + " • " + DateTime.date;
        root.data = temp;

        const days = daily.time || [];
        root.forecast = days.slice(0, 5).map((day, i) => {
            const hi = daily.temperature_2m_max?.[i] ?? 0;
            const lo = daily.temperature_2m_min?.[i] ?? 0;
            return {
                day: day,
                wCode: daily.weather_code?.[i] ?? 0,
                high: root.useUSCS ? Math.round(hi * 9 / 5 + 32) + "°F" : Math.round(hi) + "°C",
                low: root.useUSCS ? Math.round(lo * 9 / 5 + 32) + "°F" : Math.round(lo) + "°C",
            };
        });
    }

    function fetchForecast(lat, lon, cityLabel) {
        const params = "current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,surface_pressure,wind_speed_10m,wind_direction_10m,uv_index,visibility&daily=sunrise,sunset,temperature_2m_max,temperature_2m_min,weather_code&timezone=auto";
        const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&${params}`;
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status !== 200) {
                console.error(`[WeatherService] Forecast request failed with status ${xhr.status}`);
                return;
            }
            try {
                root.refineData(JSON.parse(xhr.responseText), cityLabel);
            } catch (e) {
                console.error(`[WeatherService] ${e.message}`);
            }
        };
        xhr.open("GET", url);
        xhr.send();
    }

    function reverseGeocode(lat, lon) {
        const url = `https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lon}&format=jsonv2&zoom=14`;
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            let cityLabel = root.city || "Current location";
            if (xhr.status === 200) {
                try {
                    const address = JSON.parse(xhr.responseText)?.address || {};
                    cityLabel = address.village || address.town || address.city || address.suburb || cityLabel;
                } catch (e) {
                    console.error(`[WeatherService] ${e.message}`);
                }
            }
            root.fetchForecast(lat, lon, cityLabel);
        };
        xhr.open("GET", url);
        xhr.setRequestHeader("User-Agent", "quickshell-weather-widget");
        xhr.send();
    }

    function geocodeCity(cityName) {
        // Open-Meteo's geocoder matches a bare locality name, not a
        // comma-qualified "Parish, Municipality" string (e.g. the first
        // result for "Arcozelo" alone is the right Vila Nova de Gaia parish;
        // the full string returns no match at all).
        const query = (cityName || "").split(",")[0].trim();
        const url = `https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(query)}&count=1&language=pt&format=json`;
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status !== 200) {
                console.error(`[WeatherService] Geocoding request failed with status ${xhr.status}`);
                return;
            }
            try {
                const hit = JSON.parse(xhr.responseText)?.results?.[0];
                if (!hit) {
                    console.error(`[WeatherService] No geocoding match for "${cityName}"`);
                    return;
                }
                root.fetchForecast(hit.latitude, hit.longitude, hit.name);
            } catch (e) {
                console.error(`[WeatherService] ${e.message}`);
            }
        };
        xhr.open("GET", url);
        xhr.send();
    }

    function getData() {
        if (root.gpsActive && root.location.valid) {
            root.reverseGeocode(root.location.lat, root.location.long);
        } else {
            root.geocodeCity(root.city);
        }
    }

    Component.onCompleted: {
        if (!root.gpsActive) return;
        console.info("[WeatherService] Starting the GPS service.");
        positionSource.start();
    }

    PositionSource {
        id: positionSource
        updateInterval: root.fetchInterval

        onPositionChanged: {
            // update the location if the given location is valid
            // if it fails getting the location, use the last valid location
            if (position.latitudeValid && position.longitudeValid) {
                root.location.lat = position.coordinate.latitude;
                root.location.long = position.coordinate.longitude;
                root.location.valid = true;
                // console.info(`📍 Location: ${position.coordinate.latitude}, ${position.coordinate.longitude}`);
                root.getData();
                // if can't get initialized with valid location deactivate the GPS
            } else {
                root.gpsActive = root.location.valid ? true : false;
                console.error("[WeatherService] Failed to get the GPS location.");
            }
        }

        onValidityChanged: {
            if (!positionSource.valid) {
                positionSource.stop();
                root.location.valid = false;
                root.gpsActive = false;
                Quickshell.execDetached(["notify-send", Translation.tr("Weather Service"), Translation.tr("Cannot find a GPS service. Using the fallback method instead."), "-a", "Shell"]);
                console.error("[WeatherService] Could not aquire a valid backend plugin.");
            }
        }
    }

    Timer {
        running: !root.gpsActive
        repeat: true
        interval: root.fetchInterval
        triggeredOnStart: !root.gpsActive
        onTriggered: root.getData()
    }
}
