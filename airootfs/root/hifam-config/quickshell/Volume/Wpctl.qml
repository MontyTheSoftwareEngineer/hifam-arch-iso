import QtQuick
import Quickshell.Io

// Action wrapper around wpctl/pactl mutations. VolumeModel owns polling and
// parsing; this component only ever changes state.
QtObject {
    id: root

    signal volumeChanged()
    signal muteToggled()
    signal defaultSinkChanged()

    function setVolume(percent) {
        var clamped = Math.max(0, Math.min(100, Math.round(percent)))
        volumeProcess.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", clamped + "%"]
        volumeProcess.running = true
    }

    function toggleMute() {
        muteProcess.running = true
    }

    function setDefaultSink(name) {
        sinkProcess.command = ["pactl", "set-default-sink", name]
        sinkProcess.running = true
    }

    property Process volumeProcess: Process {
        onExited: root.volumeChanged()
    }

    property Process muteProcess: Process {
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]
        onExited: root.muteToggled()
    }

    property Process sinkProcess: Process {
        onExited: root.defaultSinkChanged()
    }
}
