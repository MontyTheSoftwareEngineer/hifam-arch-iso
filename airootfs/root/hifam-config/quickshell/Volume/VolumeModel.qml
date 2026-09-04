import QtQuick
import Quickshell.Io

// Polls wpctl/pactl for the default sink's volume/mute state and the full
// list of available output devices. Mutations are delegated to Wpctl.qml.
Item {
    id: root

    property int interval: 3000
    property int volume: 0          // 0-100
    property bool muted: false
    property string defaultSinkName: ""
    property var sinks: []          // [{name, description, active}]

    signal refreshed()
    // Emitted only for explicit user-driven changes (keybinds, slider,
    // mute toggle) -- distinct from refreshed() which also fires on every
    // background poll. Used to trigger the on-screen volume popup.
    signal changed()

    function refresh() {
        statusProcess.running = true
    }

    function setVolume(percent) {
        root.volume = Math.max(0, Math.min(100, Math.round(percent)))
        wpctl.setVolume(root.volume)
        root.changed()
    }

    function adjustVolume(step) {
        root.setVolume(root.volume + step)
    }

    function toggleMute() {
        root.muted = !root.muted
        wpctl.toggleMute()
        root.changed()
    }

    function setDefaultSink(name) {
        root.defaultSinkName = name
        wpctl.setDefaultSink(name)
    }

    readonly property Wpctl wpctl: Wpctl {
        onVolumeChanged: root.refresh()
        onMuteToggled: root.refresh()
        onDefaultSinkChanged: root.refresh()
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

        var volumeLine = (sections.VOLUME || [])[0] || ""
        var match = volumeLine.match(/Volume:\s*([0-9.]+)/)
        root.volume = match ? Math.round(parseFloat(match[1]) * 100) : root.volume
        root.muted = volumeLine.indexOf("[MUTED]") !== -1

        root.defaultSinkName = (sections.DEFAULT || [])[0] || ""

        var sinksJsonText = (sections.SINKS || []).join("")
        var sinks = []
        try {
            var parsed = sinksJsonText ? JSON.parse(sinksJsonText) : []
            for (var i = 0; i < parsed.length; i++) {
                var sink = parsed[i]
                sinks.push({
                    name: sink.name,
                    description: sink.description || sink.name,
                    active: sink.name === root.defaultSinkName
                })
            }
        } catch (e) {
            sinks = []
        }
        root.sinks = sinks

        root.refreshed()
    }

    property Process statusProcess: Process {
        command: ["bash", "-c",
            "echo @@VOLUME@@; wpctl get-volume @DEFAULT_AUDIO_SINK@; " +
            "echo @@DEFAULT@@; pactl get-default-sink; " +
            "echo @@SINKS@@; pactl -f json list sinks"]
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
