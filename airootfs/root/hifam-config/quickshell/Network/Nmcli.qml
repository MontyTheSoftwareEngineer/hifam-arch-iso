import QtQuick
import Quickshell.Io

// Thin wrapper around the `nmcli` actions the Network widget needs to
// perform. Read-only status lives in NetworkModel; this component only ever
// mutates state (scan, connect, disconnect, radio on/off) and reports back
// via signals so the model knows when to refresh.
QtObject {
    id: root

    signal scanFinished()
    signal connectFinished(bool success, string ssid, string message)
    signal disconnectFinished(bool success)
    signal radioToggled(bool success)

    // Triggers a fresh AP scan. NetworkModel's poll picks up the results on
    // its next tick; nmcli needs a beat for the scan to populate results.
    function scan() {
        scanProcess.running = true
    }

    function toggleWifi(enable) {
        radioProcess.enable = enable
        radioProcess.command = ["nmcli", "radio", "wifi", enable ? "on" : "off"]
        radioProcess.running = true
    }

    // Connects to `ssid`. When a password is supplied we assume it's a new
    // (or forgotten) network and hand it straight to `device wifi connect`;
    // otherwise we bring up the existing saved profile by name so already
    // known networks don't re-prompt.
    function connect(ssid, password) {
        connectProcess.ssid = ssid
        connectProcess.command = password
            ? ["nmcli", "device", "wifi", "connect", ssid, "password", password]
            : ["nmcli", "connection", "up", "id", ssid]
        connectProcess.running = true
    }

    function disconnect(ssid) {
        disconnectProcess.command = ["nmcli", "connection", "down", "id", ssid]
        disconnectProcess.running = true
    }

    property Process scanProcess: Process {
        command: ["nmcli", "device", "wifi", "rescan"]
        onExited: root.scanFinished()
    }

    property Process radioProcess: Process {
        property bool enable: true
        onExited: (exitCode) => root.radioToggled(exitCode === 0)
    }

    property Process connectProcess: Process {
        property string ssid: ""
        stdout: StdioCollector { id: connectOut }
        stderr: StdioCollector { id: connectErr }
        onExited: (exitCode) => {
            root.connectFinished(exitCode === 0, ssid, exitCode === 0 ? "" : connectErr.text.trim())
        }
    }

    property Process disconnectProcess: Process {
        onExited: (exitCode) => root.disconnectFinished(exitCode === 0)
    }
}
