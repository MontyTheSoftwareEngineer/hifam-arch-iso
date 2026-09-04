import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Power menu overlay, opened via `qs ipc call power toggle`. Presents Lock,
// Log Out, Reboot, and Shut Down; each runs its system command and closes
// the menu. Escape or clicking outside the card also closes it.
Item {
    id: root

    property bool opened: false

    readonly property var actions: [
        { icon: "lock", label: "Lock", handler: function() { LockScreenState.lock() } },
        { icon: "logout", label: "Log Out", handler: function() { logoutProcess.running = true } },
        { icon: "restart_alt", label: "Reboot", handler: function() { rebootProcess.running = true } },
        { icon: "power_settings_new", label: "Shut Down", handler: function() { shutdownProcess.running = true } }
    ]

    function open() {
        root.opened = true
    }

    function close() {
        root.opened = false
    }

    function toggle() {
        if (root.opened) root.close()
        else root.open()
    }

    function runAction(index) {
        if (index < 0 || index >= root.actions.length) return
        root.actions[index].handler()
        root.close()
    }

    IpcHandler {
        target: "power"

        function open(): string {
            root.open()
            return "ok"
        }

        function close(): string {
            root.close()
            return "ok"
        }

        function toggle(): string {
            root.toggle()
            return root.opened ? "open" : "closed"
        }
    }

    Process { id: logoutProcess; command: ["hyprctl", "dispatch", "hl.dsp.exit()"] }
    Process { id: rebootProcess; command: ["systemctl", "reboot"] }
    Process { id: shutdownProcess; command: ["systemctl", "poweroff"] }

    PanelWindow {
        id: panel
        visible: root.opened
        anchors { top: true; bottom: true; left: true; right: true }
        color: Qt.rgba(0, 0, 0, 0.38)

        WlrLayershell.namespace: "custom-powermenu"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        exclusionMode: ExclusionMode.Ignore

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }

        Rectangle {
            id: card
            width: 300
            height: contentColumn.implicitHeight + 32
            anchors.centerIn: parent
            radius: Theme.radius
            color: Theme.backgroundColor
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.12)
            clip: true

            MouseArea { anchors.fill: parent }

            Keys.onEscapePressed: root.close()

            ColumnLayout {
                id: contentColumn
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8

                Repeater {
                    model: root.actions

                    delegate: Rectangle {
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        height: 48
                        radius: Theme.radius
                        color: itemMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 12

                            Text {
                                text: modelData.icon
                                font.family: Theme.iconFont
                                font.pixelSize: Theme.iconSize + 4
                                font.variableAxes: Theme.iconAxes
                                color: Theme.iconColor
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.label
                                color: Theme.textColor
                                font.family: Theme.font
                                font.pixelSize: 15
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.runAction(index)
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        if (root.opened) Qt.callLater(function() { card.forceActiveFocus() })
    }

    onOpenedChanged: if (opened) Qt.callLater(function() { card.forceActiveFocus() })
}
