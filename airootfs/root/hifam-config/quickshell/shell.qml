import QtQuick
import Quickshell

ShellRoot {
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: bar
            required property var modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: 38
            color: Qt.rgba(0,0,0,0)

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
                id: volume
                cmd: "wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2}'"
            }

            Poll {
                id: battery
                cmd: "awk '{print $1}' /sys/class/power_supply/BAT0/capacity"
            }

            Poll {
                id: bluetooth
                cmd: "bluetoothctl show | grep 'Powered: yes' && echo on || echo off"
            }

            Poll {
                id: wifi
                cmd: "nmcli -t -f active.ssid dev wifi | grep '^yes:' | cut -d: -f2"
            }

            Poll {
                id: screenRecordingIndicatorPoll
                cmd: "pgrep -f \"^gpu-screen-recorder\""
                interval: 3000
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: Theme.spacing
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.spacing

                Pill {
                    icon: "volume_up"
                    iconColor: Theme.iconColor
                    text: volume.text * 100 + "%"
                }

                Pill {
                    icon: "battery_full"
                    iconColor: Theme.iconColor
                    text: battery.text + "%"
                }

                Pill {
                    icon: "bluetooth"
                    iconColor: Theme.iconColor
                    text: bluetooth.text
                    onClicked: {
                        Quickshell.execDetached(["kitty", "-e", "sh", "-c", "bluetui"])
                    }
                }

                Pill {
                    icon: "wifi"
                    iconColor: Theme.iconColor
                    text: wifi.text
                    onClicked: {
                        Quickshell.execDetached(["kitty", "-e", "sh", "-c", "impala"])
                    }
                }
                Pill {
                    icon: "nest_clock_farsight_analog"
                    iconColor: Theme.iconColor
                    text: Qt.formatDateTime(clock.date, "hh:mm A")
                    onClicked: {
                        Quickshell.execDetached(["kitty", "-e", "sh", "-c", "tmux new"])
                        Quickshell.execDetached("kitty")
                    }
                }
            }
        }
    }
}
