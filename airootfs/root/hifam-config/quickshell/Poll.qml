import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property string cmd: ""
    property int interval: 5000
    property string text: ""

    Process {
        id: process

        command: ["sh", "-c", root.cmd]
        running: true

        stdout: StdioCollector {
            id: output
            onStreamFinished: {
                root.text = output.text.trim()
                // console.log("Poll: " + root.cmd + " -> " + root.text)
            }
        }

    }

    Timer {
        interval: root.interval
        running: true
        repeat: true
        onTriggered: process.running = true
    }
}
