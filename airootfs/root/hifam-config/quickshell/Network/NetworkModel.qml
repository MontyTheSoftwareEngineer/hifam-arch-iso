import QtQuick
import Quickshell.Io

// Polls `nmcli` for Wi-Fi radio state, visible access points, and the active
// connection, then exposes it all as plain properties for NetworkPopup /
// Network.qml to bind against. Actions (connect/disconnect/scan/toggle) are
// delegated to Nmcli.qml; this component only reads state.
Item {
    id: root

    property int interval: 4000
    property bool wifiEnabled: false
    property bool wifiDeviceAvailable: false
    // "connected" | "connecting" | "disconnected" | "unavailable"
    property string wifiState: "unavailable"
    property string activeSsid: ""
    property string activeType: ""     // "wifi" | "ethernet" | ""
    property int activeSignal: -1
    property string activeIp: ""
    property var networks: []          // [{ssid, signal, security, active, known}]
    property bool scanning: false

    readonly property bool connected: activeType !== ""

    signal refreshed()
    signal connectFailed(string ssid, string message)

    function refresh() {
        statusProcess.running = true
    }

    function startScan() {
        root.scanning = true
        nmcli.scan()
    }

    function toggleWifi() {
        nmcli.toggleWifi(!root.wifiEnabled)
    }

    function connectTo(ssid, password) {
        nmcli.connect(ssid, password)
    }

    function disconnectFrom(ssid) {
        nmcli.disconnect(ssid)
    }

    readonly property Nmcli nmcli: Nmcli {
        onScanFinished: {
            root.scanning = false
            root.refresh()
        }
        onRadioToggled: root.refresh()
        onConnectFinished: (success, ssid, message) => {
            if (!success) root.connectFailed(ssid, message)
            root.refresh()
        }
        onDisconnectFinished: root.refresh()
    }

    // Splits one nmcli terse line ("a:b:c") on unescaped colons; nmcli
    // escapes literal ':' and '\' inside field values as "\:" / "\\".
    function splitTerse(line) {
        var fields = []
        var current = ""
        for (var i = 0; i < line.length; i++) {
            var c = line[i]
            if (c === "\\" && i + 1 < line.length) {
                current += line[i + 1]
                i++
            } else if (c === ":") {
                fields.push(current)
                current = ""
            } else {
                current += c
            }
        }
        fields.push(current)
        return fields
    }

    function parseSections(text) {
        var sections = {}
        var current = null
        var lines = text.split("\n")
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i]
            var marker = line.match(/^@@([A-Z]+)@@$/)
            if (marker) {
                current = marker[1]
                sections[current] = []
                continue
            }
            if (current && line.length > 0) sections[current].push(line)
        }
        return sections
    }

    function applyStatus(raw) {
        var sections = parseSections(raw)

        var radioLines = sections.RADIO || []
        root.wifiEnabled = radioLines[0] === "enabled"

        var deviceLines = sections.DEVICE || []
        var wifiDevice = null
        for (var d = 0; d < deviceLines.length; d++) {
            var df = splitTerse(deviceLines[d])
            if (df[1] === "wifi") { wifiDevice = df; break }
        }
        root.wifiDeviceAvailable = wifiDevice !== null
        root.wifiState = wifiDevice ? wifiDevice[2] : "unavailable"

        var knownLines = sections.KNOWN || []
        var known = {}
        for (var k = 0; k < knownLines.length; k++) {
            known[splitTerse(knownLines[k])[0]] = true
        }

        var wifiLines = sections.WIFI || []
        var byName = {}
        var order = []
        for (var w = 0; w < wifiLines.length; w++) {
            var wf = splitTerse(wifiLines[w])
            var ssid = wf[1]
            if (!ssid) continue // hidden network, nothing useful to show
            var signal = parseInt(wf[2], 10)
            if (isNaN(signal)) signal = 0
            var entry = {
                ssid: ssid,
                signal: signal,
                security: wf[3] && wf[3] !== "--" ? wf[3] : "",
                active: wf[0] === "*",
                known: !!known[ssid]
            }
            var prev = byName[ssid]
            if (!prev) {
                order.push(ssid)
                byName[ssid] = entry
            } else if (entry.active || (!prev.active && entry.signal > prev.signal)) {
                // Active AP always wins; otherwise keep the strongest BSSID
                // for this SSID. Never let a weaker/duplicate entry clobber
                // the one we're actually connected to.
                byName[ssid] = entry
            }
        }
        var networks = order.map(function (ssid) { return byName[ssid] })
        networks.sort(function (a, b) {
            if (a.active !== b.active) return a.active ? -1 : 1
            return b.signal - a.signal
        })
        root.networks = networks

        var activeLines = sections.ACTIVE || []
        var newActiveType = ""
        var newActiveSsid = ""
        var newActiveSignal = -1
        for (var a = 0; a < activeLines.length; a++) {
            var af = splitTerse(activeLines[a])
            var type = af[1]
            if (type === "802-11-wireless") {
                newActiveType = "wifi"
                newActiveSsid = af[0]
                var match = byName[af[0]]
                newActiveSignal = match ? match.signal : -1
                break
            } else if (type === "802-3-ethernet" && newActiveType === "") {
                newActiveType = "ethernet"
                newActiveSsid = af[0]
            }
        }
        // Assign once with the final values so bindings/handlers watching
        // activeSsid don't see a spurious "" flicker on every poll tick.
        root.activeType = newActiveType
        root.activeSsid = newActiveSsid
        root.activeSignal = newActiveSignal

        var ipLines = sections.IP || []
        var ip = ""
        if (ipLines.length > 0) {
            var ipFields = splitTerse(ipLines[0])
            ip = (ipFields[1] || "").split("/")[0]
        }
        root.activeIp = ip

        root.refreshed()
    }

    property Process statusProcess: Process {
        command: ["bash", "-c",
            "echo @@RADIO@@; nmcli radio wifi; " +
            "echo @@DEVICE@@; nmcli -t -f DEVICE,TYPE,STATE device status; " +
            "echo @@WIFI@@; nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY device wifi list; " +
            "echo @@ACTIVE@@; nmcli -t -f NAME,TYPE,DEVICE connection show --active; " +
            "echo @@KNOWN@@; nmcli -t -f NAME connection show; " +
            "echo @@IP@@; " +
            "dev=$(nmcli -t -f TYPE,DEVICE connection show --active | awk -F: '$1!=\"loopback\"{print $2; exit}'); " +
            "if [ -n \"$dev\" ]; then nmcli -t -f IP4.ADDRESS device show \"$dev\" | head -1; fi"]
        stdout: StdioCollector {
            id: statusOutput
            onStreamFinished: root.applyStatus(statusOutput.text)
        }
    }

    Timer {
        interval: root.interval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
