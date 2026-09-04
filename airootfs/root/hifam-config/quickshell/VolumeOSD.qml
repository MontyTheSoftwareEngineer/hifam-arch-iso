import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// On-screen volume popup. Shows instantly whenever the shared VolumeModel
// reports an explicit user-driven change (media keys via IPC, or the bar
// slider/mute button), then auto-hides after a short delay. Exposes an IPC
// target ("volume") for Hyprland media-key bindings: `qs ipc call volume up`.
Item {
    id: root

    required property var model

    readonly property string iconName: {
        if (root.model.muted) return "volume_off"
        if (root.model.volume === 0) return "volume_mute"
        if (root.model.volume < 50) return "volume_down"
        return "volume_up"
    }

    function show() {
        panel.visible = true
        hideTimer.restart()
    }

    Connections {
        target: root.model
        function onChanged() { root.show() }
    }

    IpcHandler {
        target: "volume"

        function up(): string {
            root.model.adjustVolume(5)
            return "ok"
        }

        function down(): string {
            root.model.adjustVolume(-5)
            return "ok"
        }

        function mute(): string {
            root.model.toggleMute()
            return "ok"
        }
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: panel.visible = false
    }

    PanelWindow {
        id: panel
        visible: false
        anchors.bottom: true
        margins.bottom: 140
        color: "transparent"

        implicitWidth: 260
        implicitHeight: card.implicitHeight

        WlrLayershell.namespace: "custom-volume-osd"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore

        Rectangle {
            id: card
            anchors.fill: parent
            implicitHeight: content.implicitHeight + Theme.spacing * 2
            radius: Theme.radius
            color: Theme.backgroundColor
            border.width: 1
            border.color: Theme.primaryColor

            Column {
                id: content
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: Theme.spacing
                spacing: Theme.spacing

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.spacing

                    Text {
                        text: root.iconName
                        color: Theme.iconColor
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.iconSize + 10
                        font.variableAxes: Theme.iconAxes
                    }

                    Text {
                        text: root.model.muted ? "Muted" : root.model.volume + "%"
                        color: Theme.textColor
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize + 2
                        font.weight: 600
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Rectangle {
                    width: parent.width - Theme.spacing * 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 8
                    radius: 4
                    color: Theme.primaryColor

                    Rectangle {
                        width: parent.width * (root.model.muted ? 0 : root.model.volume / 100)
                        height: parent.height
                        radius: parent.radius
                        color: Theme.secondaryColor

                        Behavior on width {
                            NumberAnimation { duration: 100; easing.type: Easing.OutQuad }
                        }
                    }
                }
            }
        }
    }
}
