import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
    id: root

    property int screenOffMinutes: 5
    property int lockMinutes: 10
    property bool respectInhibitors: true

    property bool inIdleCycle: false
    property bool displaysOff: false
    property bool lockTriggeredThisCycle: false

    readonly property int screenOffSeconds: Math.max(0, Number(screenOffMinutes) * 60)
    readonly property int lockSeconds: Math.max(0, Number(lockMinutes) * 60)
    readonly property int firstIdleTimeoutSeconds: earliestTimeout(screenOffSeconds, lockSeconds)
    readonly property int screenOffDelaySeconds: screenOffSeconds > 0 && firstIdleTimeoutSeconds > 0
        ? Math.max(0, screenOffSeconds - firstIdleTimeoutSeconds)
        : -1
    readonly property int lockDelaySeconds: lockSeconds > 0 && firstIdleTimeoutSeconds > 0
        ? Math.max(0, lockSeconds - firstIdleTimeoutSeconds)
        : -1

    function earliestTimeout(a, b) {
        if (a > 0 && b > 0) return Math.min(a, b)
        if (a > 0) return a
        if (b > 0) return b
        return 0
    }

    function startProcess(process, command) {
        if (process.running) return false
        process.command = command
        process.running = true
        return true
    }

    function turnDisplaysOff() {
        if (root.displaysOff) return
        root.displaysOff = true
        startProcess(displayOffProcess, ["hyprctl", "dispatch", "dpms", "off"])
    }

    function turnDisplaysOn() {
        if (!root.displaysOff) return
        root.displaysOff = false
        startProcess(displayOnProcess, ["hyprctl", "dispatch", "dpms", "on"])
    }

    function triggerLock() {
        if (root.lockTriggeredThisCycle) return
        root.lockTriggeredThisCycle = true
        lockTimer.stop()
        startProcess(lockProcess, ["qs", "ipc", "call", "lockscreen", "lock"])
    }

    function startIdleCycle() {
        if (root.inIdleCycle || root.firstIdleTimeoutSeconds <= 0) return

        root.inIdleCycle = true
        root.lockTriggeredThisCycle = false

        if (root.screenOffDelaySeconds === 0) turnDisplaysOff()
        else if (root.screenOffDelaySeconds > 0) screenOffTimer.restart()

        if (root.lockDelaySeconds === 0) triggerLock()
        else if (root.lockDelaySeconds > 0) lockTimer.restart()
    }

    function cancelIdleCycle() {
        screenOffTimer.stop()
        lockTimer.stop()
        root.inIdleCycle = false
        root.lockTriggeredThisCycle = false
        turnDisplaysOn()
    }

    function handleIdleChanged() {
        if (root.firstIdleTimeoutSeconds <= 0) {
            cancelIdleCycle()
            return
        }

        if (idleMonitor.isIdle) startIdleCycle()
        else cancelIdleCycle()
    }

    IdleMonitor {
        id: idleMonitor
        enabled: root.firstIdleTimeoutSeconds > 0
        timeout: root.firstIdleTimeoutSeconds
        respectInhibitors: root.respectInhibitors
        onIsIdleChanged: root.handleIdleChanged()
    }

    Timer {
        id: screenOffTimer
        interval: root.screenOffDelaySeconds * 1000
        repeat: false
        onTriggered: if (root.inIdleCycle) root.turnDisplaysOff()
    }

    Timer {
        id: lockTimer
        interval: root.lockDelaySeconds * 1000
        repeat: false
        onTriggered: if (root.inIdleCycle) root.triggerLock()
    }

    Process {
        id: displayOffProcess
        onExited: function(exitCode, exitStatus) {
            console.log("idle display-off exited", exitCode, exitStatus)
        }
    }

    Process {
        id: displayOnProcess
        onExited: function(exitCode, exitStatus) {
            console.log("idle display-on exited", exitCode, exitStatus)
        }
    }

    Process {
        id: lockProcess
        onExited: function(exitCode, exitStatus) {
            console.log("idle lock exited", exitCode, exitStatus)
        }
    }

    Component.onCompleted: root.handleIdleChanged()
}
