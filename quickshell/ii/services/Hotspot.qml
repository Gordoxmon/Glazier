pragma Singleton
pragma ComponentBehavior: Bound

// Wi-Fi hotspot control via nmcli, backed by a persistent connection
// profile named "Hotspot". Local addition on top of the vendored
// end-4/dots-hyprland tree (see UPSTREAM) — mirrors the Process/SplitParser
// idiom used by Network.qml.

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string connectionName: "Hotspot"

    // Created connections are scoped to this user (connection.permissions)
    // so activation/modification/secret reads stay in the "implicit active:
    // yes" polkit paths (network-control, settings.modify.own) instead of
    // settings.modify.system, which prompts for an admin password.
    property string username: ""

    property bool active: false
    property bool enabling: false
    property bool exists: false
    property string device: ""
    property string ssid: ""
    property string password: ""
    property bool secured: true
    property string band: "bg" // "bg" (2.4 GHz) or "a" (5 GHz)
    property string lastError: ""

    // Fires once applyConfig()'s nmcli call returns, so callers (the config
    // dialog) can wait for the real result instead of assuming success.
    signal configApplied(bool success)

    function toggle(): void {
        if (root.active) root.stop();
        else root.start();
    }

    function start(): void {
        if (!root.exists) return;
        root.lastError = "";
        root.enabling = true;
        enableRadioProc.exec(["nmcli", "radio", "wifi", "on"]);
    }

    function stop(): void {
        downProc.exec(["nmcli", "connection", "down", root.connectionName]);
    }

    function refresh(): void {
        findDeviceProc.running = true;
        readActiveProc.running = true;
        readConfigProc.running = true;
    }

    function applyConfig(newSsid: string, newPassword: string, newSecured: bool, newBand: string): void {
        root.lastError = "";
        const secArgs = newSecured
            ? ["wifi-sec.key-mgmt", "wpa-psk"]
            : ["remove", "802-11-wireless-security"];

        if (!root.exists) {
            createProc.exec({
                "environment": { "PASSWORD": newSecured ? newPassword : "" },
                "command": [
                    "nmcli", "connection", "add", "type", "wifi",
                    "ifname", root.device || "*",
                    "con-name", root.connectionName,
                    "autoconnect", "no",
                    "ssid", newSsid,
                    "802-11-wireless.mode", "ap",
                    "802-11-wireless.band", newBand,
                    "ipv4.method", "shared",
                    "ipv6.method", "ignore",
                    "connection.permissions", "user:" + root.username
                ].concat(newSecured ? ["wifi-sec.key-mgmt", "wpa-psk", "wifi-sec.psk", newPassword] : [])
            });
        } else {
            modifyProc.exec({
                "environment": { "PASSWORD": newSecured ? newPassword : "" },
                "command": [
                    "nmcli", "connection", "modify", root.connectionName,
                    "802-11-wireless.ssid", newSsid,
                    "802-11-wireless.band", newBand
                ].concat(secArgs).concat(newSecured ? ["wifi-sec.psk", newPassword] : [])
            });
        }
    }

    Process {
        id: enableRadioProc
        onExited: (exitCode, exitStatus) => {
            upProc.exec(["nmcli", "connection", "up", root.connectionName]);
        }
    }

    Process {
        id: upProc
        stderr: SplitParser {
            onRead: line => { root.lastError = line; }
        }
        onExited: (exitCode, exitStatus) => {
            root.enabling = false;
            root.refresh();
        }
    }

    Process {
        id: downProc
        onExited: (exitCode, exitStatus) => { root.refresh(); }
    }

    Process {
        id: createProc
        stderr: SplitParser {
            onRead: line => { root.lastError = line; }
        }
        onExited: (exitCode, exitStatus) => {
            root.refresh();
            root.configApplied(exitCode === 0);
        }
    }

    Process {
        id: modifyProc
        stderr: SplitParser {
            onRead: line => { root.lastError = line; }
        }
        onExited: (exitCode, exitStatus) => {
            root.refresh();
            root.configApplied(exitCode === 0);
        }
    }

    Process {
        id: readUsernameProc
        command: ["id", "-un"]
        stdout: StdioCollector {
            onStreamFinished: { root.username = this.text.trim(); }
        }
    }

    Process {
        id: findDeviceProc
        command: ["nmcli", "-t", "-g", "DEVICE,TYPE", "device", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n");
                for (const line of lines) {
                    const parts = line.split(":");
                    if (parts[1] === "wifi") {
                        root.device = parts[0];
                        break;
                    }
                }
            }
        }
    }

    Process {
        id: readActiveProc
        command: ["nmcli", "-t", "-g", "NAME", "connection", "show", "--active"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.active = this.text.trim().split("\n").includes(root.connectionName);
            }
        }
    }

    Process {
        id: readConfigProc
        command: ["nmcli", "-t", "-s", "-g",
            "802-11-wireless.ssid,802-11-wireless.band,802-11-wireless-security.key-mgmt,802-11-wireless-security.psk",
            "connection", "show", root.connectionName]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = this.text.trim();
                if (out.length === 0) {
                    root.exists = false;
                    return;
                }
                root.exists = true;
                const fields = out.split("\n");
                root.ssid = fields[0] ?? "";
                root.band = (fields[1] === "a") ? "a" : "bg";
                root.secured = (fields[2] ?? "").length > 0;
                root.password = fields[3] ?? "";
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) root.exists = false;
        }
    }

    Component.onCompleted: {
        readUsernameProc.running = true;
        root.refresh();
    }
}
