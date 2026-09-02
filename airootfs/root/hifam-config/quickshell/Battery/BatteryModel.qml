import QtQuick
import Quickshell.Io

// Polls upower for battery state/health and power-profiles-daemon for the
// active + available power profiles. setProfile() is the only mutation this
// widget needs, so it's inlined here rather than split into an action file.
Item {
    id: root

    property int interval: 5000
    property bool present: false
    property int percent: 0
    // "charging" | "discharging" | "fully-charged" | "pending-charge" | "pending-discharge" | "unknown"
    property string state: "unknown"
    property string timeToEmpty: ""
    property string timeToFull: ""
    property string energyRate: ""
    property int health: -1        // capacity vs design capacity, percent
    property string profile: ""
    property var profiles: []      // ["performance", "balanced", "power-saver"]

    readonly property bool charging: state === "charging" || state === "pending-charge"

    signal refreshed()

    function refresh() {
        statusProcess.running = true
    }

    function setProfile(name) {
        root.profile = name
        profileProcess.command = ["powerprofilesctl", "set", name]
        profileProcess.running = true
    }

    property Process profileProcess: Process {
        onExited: root.refresh()
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
            if (current) sections[current].push(line)
        }
        return sections
    }

    function fieldsOf(lines) {
        var fields = {}
        for (var i = 0; i < lines.length; i++) {
            var idx = lines[i].indexOf(":")
            if (idx === -1) continue
            var key = lines[i].slice(0, idx).trim()
            var value = lines[i].slice(idx + 1).trim()
            if (key) fields[key] = value
        }
        return fields
    }

    function applyStatus(raw) {
        var sections = parseSections(raw)

        root.profile = ((sections.PROFILE || [])[0] || "").trim()

        var profiles = []
        var profileLines = sections.PROFILES || []
        for (var p = 0; p < profileLines.length; p++) {
            var m = profileLines[p].trim().match(/^\*?\s*([A-Za-z0-9_-]+):$/)
            if (m) profiles.push(m[1])
        }
        root.profiles = profiles

        var batteryLines = sections.BATTERY || []
        root.present = batteryLines.length > 0
        var fields = fieldsOf(batteryLines)
        root.state = fields["state"] || "unknown"
        var pct = parseInt(fields["percentage"] || "", 10)
        root.percent = isNaN(pct) ? root.percent : pct
        root.timeToEmpty = fields["time to empty"] || ""
        root.timeToFull = fields["time to full"] || ""
        root.energyRate = fields["energy-rate"] || ""
        var capacity = parseFloat(fields["capacity"] || "")
        root.health = isNaN(capacity) ? -1 : Math.round(capacity)

        root.refreshed()
    }

    property Process statusProcess: Process {
        command: ["bash", "-c",
            "echo @@PROFILE@@; powerprofilesctl get 2>/dev/null; " +
            "echo @@PROFILES@@; powerprofilesctl list 2>/dev/null; " +
            "echo @@BATTERY@@; dev=$(upower -e | grep -m1 BAT); " +
            "if [ -n \"$dev\" ]; then upower -i \"$dev\"; fi"]
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
