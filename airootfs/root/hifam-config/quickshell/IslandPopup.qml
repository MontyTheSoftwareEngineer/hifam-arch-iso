import QtQuick
import Quickshell
import "Network"
import "Volume"
import "Battery"

Item {
    id: root

    property var volumeModel: null
    property string selectedCard: ""
    property string pendingSsid: ""
    property string wifiPassword: ""
    property string wifiError: ""

    signal closeRequested()

    implicitWidth: 520
    implicitHeight: content.height
    width: implicitWidth
    height: implicitHeight

    BatteryModel { id: batteryModel }
    NetworkModel { id: networkModel }

    Connections {
        target: networkModel
        function onConnectFailed(ssid, message) {
            root.pendingSsid = ssid
            root.wifiError = message || "Failed to connect"
        }
        function onRefreshed() {
            if (root.pendingSsid !== "" && networkModel.activeSsid === root.pendingSsid) {
                root.pendingSsid = ""
                root.wifiPassword = ""
            }
        }
    }

    Rectangle {
        id: content
        width: root.width
        height: inner.childrenRect.height + Theme.spacing * 2
        color: Theme.backgroundColor
        radius: Theme.radius
        border.color: Theme.primaryColor
        border.width: 1

        Column {
            id: inner
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.spacing
            spacing: Theme.spacing

            Row {
                width: parent.width
                height: 30

                Text {
                    text: "tune"
                    color: Theme.secondaryColor
                    font.family: Theme.iconFont
                    font.pixelSize: 20
                    font.variableAxes: Theme.iconAxes
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "HIFAM"
                    color: Theme.textColor
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    font.weight: 700
                    font.letterSpacing: 0.5
                    anchors.verticalCenter: parent.verticalCenter
                    leftPadding: Theme.spacing
                }
                Item { width: parent.width - 180; height: 1 }
                Text {
                    text: "×"
                    color: Theme.textColor
                    font.pixelSize: 22
                    anchors.verticalCenter: parent.verticalCenter
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.closeRequested()
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.primaryColor
            }

            Column {
                width: parent.width
                spacing: Theme.spacing

                Row {
                    width: parent.width
                    height: 64
                    spacing: Theme.spacing

                    Rectangle {
                        id: volumeCard
                        width: (parent.width - Theme.spacing) / 2
                        height: parent.height
                        radius: Theme.radius
                        color: Theme.primaryColor
                        Pill {
                            anchors.centerIn: parent
                            icon: root.volumeModel.muted ? "volume_off" : "volume_up"
                            iconColor: Theme.iconColor
                            text: root.volumeModel.muted ? "Muted" : root.volumeModel.volume + "%"
                        }
                        MouseArea {
                            anchors.fill: parent
                            z: 5
                            onClicked: root.selectedCard = "volume"
                        }
                    }

                    Rectangle {
                        id: batteryCard
                        width: (parent.width - Theme.spacing) / 2
                        height: parent.height
                        radius: Theme.radius
                        color: Theme.primaryColor
                        Battery {
                            anchors.centerIn: parent
                        }
                        MouseArea {
                            anchors.fill: parent
                            z: 5
                            onClicked: root.selectedCard = "battery"
                        }
                    }
                }

                Row {
                    width: parent.width
                    height: 64
                    spacing: Theme.spacing

                    Rectangle {
                        id: networkCard
                        width: (parent.width - Theme.spacing) / 2
                        height: parent.height
                        radius: Theme.radius
                        color: Theme.primaryColor
                        Pill {
                            anchors.centerIn: parent
                            icon: networkModel.activeType === "wifi" ? "network_wifi" : "signal_wifi_off"
                            iconColor: Theme.iconColor
                            text: networkModel.activeSsid === "" ? "Wi-Fi" : networkModel.activeSsid
                        }
                        MouseArea {
                            anchors.fill: parent
                            z: 5
                            onClicked: {
                                root.selectedCard = "wifi"
                                networkModel.refresh()
                            }
                        }
                    }

                    Rectangle {
                        width: (parent.width - Theme.spacing) / 2
                        height: parent.height
                        radius: Theme.radius
                        color: Theme.primaryColor
                        Pill {
                            anchors.centerIn: parent
                            icon: bluetooth.text === "connected" ? "bluetooth_connected"
                                : (bluetooth.text === "on" ? "bluetooth" : "bluetooth_disabled")
                            iconColor: Theme.iconColor
                            text: bluetooth.text === "connected" ? "Connected" : bluetooth.text === "on" ? "On" : "Off"
                        }
                        MouseArea {
                            anchors.fill: parent
                            z: 5
                            onClicked: root.selectedCard = "bluetooth"
                        }
                    }
                }
            }

            Rectangle {
                visible: root.selectedCard !== ""
                width: parent.width
                height: visible ? detailColumn.childrenRect.height + Theme.spacing * 2 : 0
                radius: Theme.radius
                color: Theme.primaryColor

                Column {
                    id: detailColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Theme.spacing
                    spacing: Theme.spacing

                    Row {
                        width: parent.width
                        height: 28
                        Text {
                            text: root.selectedCard === "volume" ? "Output volume"
                                : root.selectedCard === "battery" ? "Battery and power"
                                : root.selectedCard === "bluetooth" ? "Bluetooth" : "Wi-Fi networks"
                            color: Theme.textColor
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                            font.weight: 700
                        }
                        Item { width: parent.width - 180; height: 1 }
                        Text {
                            text: "×"
                            color: Theme.textColor
                            font.pixelSize: 20
                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.selectedCard = ""
                            }
                        }
                    }

                    Row {
                        visible: root.selectedCard === "volume"
                        width: parent.width
                        spacing: Theme.spacing
                        Text {
                            text: root.volumeModel.muted ? "volume_off" : "volume_up"
                            color: Theme.iconColor
                            font.family: Theme.iconFont
                            font.pixelSize: 18
                            MouseArea { anchors.fill: parent; onClicked: root.volumeModel.toggleMute() }
                        }
                        Rectangle {
                            width: parent.width - 55
                            height: 22
                            color: "transparent"
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: 6
                                radius: 3
                                color: Theme.backgroundColor
                            }
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width * root.volumeModel.volume / 100
                                height: 6
                                radius: 3
                                color: Theme.secondaryColor
                            }
                            MouseArea {
                                anchors.fill: parent
                                function update(x) { root.volumeModel.setVolume(Math.max(0, Math.min(100, x / width * 100))) }
                                onPressed: update(mouse.x)
                                onPositionChanged: if (pressed) update(mouse.x)
                            }
                        }
                        Text {
                            text: root.volumeModel.volume + "%"
                            color: Theme.textColor
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                        }
                    }

                    Text {
                        visible: root.selectedCard === "volume"
                        text: "Output devices"
                        color: Theme.secondaryColor
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1
                    }
                    Column {
                        visible: root.selectedCard === "volume"
                        width: parent.width
                        Repeater {
                            model: root.volumeModel.sinks
                            delegate: Item {
                                required property var modelData
                                width: parent.width
                                height: 24
                                Text {
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    text: (modelData.active ? "●  " : "    ") + modelData.description
                                    color: Theme.textColor
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize - 1
                                    elide: Text.ElideRight
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.volumeModel.setDefaultSink(modelData.name)
                                }
                            }
                        }
                    }

                    Column {
                        visible: root.selectedCard === "battery"
                        width: parent.width
                        spacing: 4
                        Text {
                            text: batteryModel.percent + "%  " + (batteryModel.charging ? "Charging" : "On battery")
                            color: Theme.textColor
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize + 2
                            font.weight: 700
                        }
                        Text {
                            visible: batteryModel.timeToEmpty !== "" || batteryModel.timeToFull !== ""
                            text: batteryModel.charging ? "Time to full: " + batteryModel.timeToFull
                                : "Time remaining: " + batteryModel.timeToEmpty
                            color: Theme.textColor
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                        }
                        Text {
                            text: "Power draw: " + batteryModel.energyRate + "    Health: " + batteryModel.health + "%"
                            color: Theme.textColor
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                        }
                        Text {
                            text: "Power profile"
                            color: Theme.secondaryColor
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                        }
                        Row {
                            spacing: Theme.spacing
                            Repeater {
                                model: batteryModel.profiles
                                delegate: Rectangle {
                                    required property string modelData
                                    width: 90
                                    height: 26
                                    radius: Theme.radius
                                    color: batteryModel.profile === modelData ? Theme.secondaryColor : Theme.backgroundColor
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData
                                        color: batteryModel.profile === modelData ? Theme.highlightedTextColor : Theme.textColor
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize - 1
                                    }
                                    MouseArea { anchors.fill: parent; onClicked: batteryModel.setProfile(modelData) }
                                }
                            }
                        }
                    }

                    Column {
                        visible: root.selectedCard === "bluetooth"
                        width: parent.width
                        spacing: Theme.spacing
                        Text {
                            text: bluetooth.text === "connected" ? "Bluetooth is connected" : "Bluetooth " + bluetooth.text
                            color: Theme.textColor
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                        }
                        Rectangle {
                            width: 130
                            height: 30
                            radius: Theme.radius
                            color: Theme.secondaryColor
                            Text { anchors.centerIn: parent; text: "Open Bluetui"; color: Theme.highlightedTextColor; font.family: Theme.font; font.pixelSize: Theme.fontSize }
                            MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["kitty", "-e", "sh", "-c", "bluetui"]) }
                        }
                    }

                    Column {
                        visible: root.selectedCard === "wifi"
                        width: parent.width
                        spacing: Theme.spacing
                        Text {
                            text: networkModel.wifiEnabled ? "Available networks" : "Wi-Fi is off"
                            color: Theme.textColor
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                        }
                        ListView {
                            width: parent.width
                            height: Math.min(contentHeight, 150)
                            clip: true
                            model: networkModel.networks
                            delegate: Item {
                                required property var modelData
                                width: parent.width
                                height: 28
                                Text { anchors.fill: parent; verticalAlignment: Text.AlignVCenter; text: (modelData.active ? "●  " : "    ") + modelData.ssid + "  " + modelData.signal + "%"; color: Theme.textColor; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1 }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (modelData.security !== "") {
                                            root.pendingSsid = modelData.ssid
                                            root.wifiPassword = ""
                                            root.wifiError = ""
                                        } else {
                                            networkModel.connectTo(modelData.ssid, "")
                                        }
                                    }
                                }
                            }
                        }
                        Text {
                            visible: root.wifiError !== ""
                            text: root.wifiError
                            color: "#ff6b6b"
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                            wrapMode: Text.WordWrap
                            width: parent.width
                        }
                        Text {
                            text: "↻  Scan for networks"
                            color: Theme.secondaryColor
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                            MouseArea {
                                anchors.fill: parent
                                onClicked: networkModel.startScan()
                            }
                        }
                        Row {
                            visible: root.pendingSsid !== ""
                            width: parent.width
                            spacing: Theme.spacing
                            TextInput {
                                width: parent.width - 100
                                height: 28
                                color: Theme.textColor
                                echoMode: TextInput.Password
                                text: root.wifiPassword
                                onTextEdited: root.wifiPassword = text
                                Keys.onReturnPressed: if (root.wifiPassword !== "") networkModel.connectTo(root.pendingSsid, root.wifiPassword)
                            }
                            Rectangle {
                                width: 80
                                height: 28
                                color: Theme.secondaryColor
                                Text { anchors.centerIn: parent; text: "Connect"; color: Theme.highlightedTextColor; font.family: Theme.font; font.pixelSize: Theme.fontSize - 1 }
                                MouseArea { anchors.fill: parent; onClicked: if (root.wifiPassword !== "") networkModel.connectTo(root.pendingSsid, root.wifiPassword) }
                            }
                        }
                    }
                }
            }

            Rectangle {
                visible: recordingPoll.text !== ""
                width: parent.width
                height: 38
                radius: Theme.radius
                color: Theme.primaryColor
                Pill {
                    anchors.centerIn: parent
                    icon: "hangout_video"
                    iconColor: "#ff0000"
                    text: "Recording"
                }
            }
        }
    }

    Poll {
        id: bluetooth
        cmd: "bluetoothctl show | grep -q 'Powered: yes' && { [ -n \"$(bluetoothctl devices Connected)\" ] && echo connected || echo on; } || echo off"
    }

    Poll {
        id: recordingPoll
        cmd: "pgrep -f \"^gpu-screen-recorder\""
        interval: 3000
    }

}
