import QtQuick
import Quickshell
import "Network"
import "Calendar"
import "Volume"
import "Battery"

ShellRoot {
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: bar
            required property var modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: 38
            color: Qt.rgba(0,0,0,0)

            LockScreen {}

            Workspaces {
                id: ws
                anchors.left: parent.left
                anchors.leftMargin: Theme.spacing
                anchors.top: parent.top
            }
            Pill {
                id: screenRecordingIndicator
                anchors.centerIn: parent
                icon: "hangout_video"
                iconColor: "#ff0000"
                text: "Recording"
                visible: screenRecordingIndicatorPoll.text !== ""
            }
            SystemClock {
                id: clock
                precision: SystemClock.Precision.Minutes
            }

            Poll {
                id: bluetooth
                cmd: "bluetoothctl show | grep -q 'Powered: yes' && { [ -n \"$(bluetoothctl devices Connected)\" ] && echo connected || echo on; } || echo off"
            }

            Poll {
                debug: true
                id: screenRecordingIndicatorPoll
                cmd: "pgrep -f \"^gpu-screen-recorder\""
                interval: 3000
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: Theme.spacing
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacing

                Volume { id: volumeWidget }

                Battery { id: batteryWidget }

                Pill {
                    icon: bluetooth.text === "connected" ? "bluetooth_connected"
                        : (bluetooth.text === "on" ? "bluetooth" : "bluetooth_disabled")
                    iconColor: Theme.iconColor
                    text: bluetooth.text === "connected" ? "On and Connected"
                        : (bluetooth.text === "on" ? "On" : "Off")
                    onClicked: {
                        Quickshell.execDetached(["kitty", "-e", "sh", "-c", "bluetui"])
                    }
                }

                Network {
                    id: network
                }
                Pill {
                    id: clockPill
                    icon: "nest_clock_farsight_analog"
                    iconColor: Theme.iconColor
                    text: Qt.formatDateTime(clock.date, "hh:mm A")
                    onClicked: calendarPopup.toggle()
                }

                CalendarPopup {
                    id: calendarPopup
                    target: clockPill
                }
            }
        }
    }
}
