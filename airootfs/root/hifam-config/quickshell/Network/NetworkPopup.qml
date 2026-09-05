import QtQuick
import Quickshell
import "../" as Root

// Popup anchored to the Network pill. Shows the Wi-Fi toggle + network list
// by default; switches to a password entry page when the user picks a
// secured network.
PopupWindow {
    id: root

    property Item target: null
    property var model: null

    property string pendingSsid: ""
    property string passwordText: ""
    property string errorText: ""
    readonly property bool showPassword: pendingSsid !== ""

    anchor.item: target
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.adjustment: PopupAdjustment.Slide
    anchor.margins.top: Root.Theme.spacing

    color: "transparent"
    visible: false
    grabFocus: true

    // Height of one network row and how many are shown before the list
    // becomes scrollable, so a long AP list can't push the popup past the
    // bottom of the screen.
    readonly property int rowHeight: Root.Theme.moduleHeight + 6
    readonly property int maxVisibleRows: 6
    readonly property real maxListHeight: Math.min(rowHeight * maxVisibleRows, (root.screen ? root.screen.height : 800) * 0.45)

    implicitWidth: 260
    implicitHeight: showPassword ? 168 : listPage.implicitHeight

    function open() {
        pendingSsid = ""
        passwordText = ""
        errorText = ""
        model.refresh()
        visible = true
    }

    function toggle() {
        if (visible) close()
        else open()
    }

    function close() {
        visible = false
    }

    function selectNetwork(network) {
        if (network.active) return
        if (model.connectingSsid !== "") return
        // Always ask for the password for secured networks. This avoids
        // silently reusing a stale or incorrect saved NetworkManager profile.
        if (network.security !== "") {
            pendingSsid = network.ssid
            passwordText = ""
            errorText = ""
            visible = true
        } else {
            model.connectTo(network.ssid, "")
        }
    }

    function submitPassword() {
        if (passwordText.length === 0) return
        if (model.connectingSsid !== "") return
        errorText = ""
        model.connectTo(pendingSsid, passwordText)
    }

    onVisibleChanged: if (!visible) { pendingSsid = ""; passwordText = ""; errorText = "" }

    Connections {
        target: root.model
        function onConnectFailed(ssid, message) {
            root.pendingSsid = ssid
            root.errorText = message || "Failed to connect"
        }
        function onRefreshed() {
            if (root.showPassword && root.model.activeSsid === root.pendingSsid && root.errorText === "") {
                root.pendingSsid = ""
                root.passwordText = ""
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Root.Theme.radius
        color: Root.Theme.backgroundColor
        border.color: Root.Theme.primaryColor
        border.width: 1
        clip: true

        // --- Network list page ---------------------------------------
        Column {
            id: listPage
            anchors.left: parent.left
            anchors.right: parent.right
            visible: !root.showPassword

            Row {
                id: headerRow
                width: parent.width
                height: Root.Theme.moduleHeight + 10
                leftPadding: Root.Theme.spacing
                rightPadding: Root.Theme.spacing
                spacing: Root.Theme.spacing

                Text {
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    text: root.model && root.model.wifiEnabled ? "network_wifi" : "signal_wifi_off"
                    font.family: Root.Theme.iconFont
                    font.pixelSize: Root.Theme.iconSize + 2
                    font.variableAxes: Root.Theme.iconAxes
                    color: Root.Theme.iconColor
                }
                Text {
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    text: "Wi-Fi"
                    color: Root.Theme.textColor
                    font.family: Root.Theme.font
                    font.pixelSize: Root.Theme.fontSize
                    font.weight: 600
                }
                Item { width: parent.width - 160; height: 1 }
                Text {
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    text: root.model && root.model.wifiEnabled ? "ON" : "OFF"
                    color: root.model && root.model.wifiEnabled ? Root.Theme.secondaryColor : Root.Theme.textColor
                    font.family: Root.Theme.font
                    font.pixelSize: Root.Theme.fontSize
                    font.weight: 600
                }
                MouseArea {
                    width: parent.width
                    height: parent.height
                    onClicked: root.model.toggleWifi()
                }
            }

            Rectangle { id: divider1; width: parent.width; height: 1; color: Root.Theme.primaryColor }

            Item {
                id: networkListContainer
                width: parent.width
                visible: root.model && root.model.wifiEnabled && root.model.networks.length > 0
                height: visible ? Math.min(networkListView.contentHeight, root.maxListHeight) : 0
                clip: true

                ListView {
                    id: networkListView
                    anchors.fill: parent
                    clip: true
                    interactive: contentHeight > height
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.model ? root.model.networks : []
                    delegate: Item {
                        required property var modelData
                        width: networkListView.width
                        height: root.rowHeight

                        readonly property bool connecting: root.model && root.model.connectingSsid === modelData.ssid

                        Row {
                            anchors.fill: parent
                            leftPadding: Root.Theme.spacing
                            rightPadding: Root.Theme.spacing
                            spacing: Root.Theme.spacing

                            Text {
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                width: 12
                                text: modelData.active ? "●" : ""
                                color: Root.Theme.secondaryColor
                                font.pixelSize: Root.Theme.fontSize
                            }
                            Text {
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                width: networkListView.width - 90
                                text: modelData.ssid
                                elide: Text.ElideRight
                                color: Root.Theme.textColor
                                font.family: Root.Theme.font
                                font.pixelSize: Root.Theme.fontSize
                            }
                            Text {
                                height: parent.height
                                verticalAlignment: Text.AlignVCenter
                                text: connecting ? "Connecting…" : modelData.signal + "%"
                                color: connecting ? Root.Theme.secondaryColor : Root.Theme.textColor
                                font.family: Root.Theme.font
                                font.pixelSize: Root.Theme.fontSize
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            z: 1
                            enabled: !connecting
                            onClicked: root.selectNetwork(modelData)
                        }
                    }
                }
            }

            Text {
                visible: root.model && root.model.wifiEnabled && root.model.networks.length === 0
                leftPadding: Root.Theme.spacing
                height: Root.Theme.moduleHeight
                verticalAlignment: Text.AlignVCenter
                text: root.model && root.model.scanning ? "Scanning…" : "No networks found"
                color: Root.Theme.textColor
                font.family: Root.Theme.font
                font.pixelSize: Root.Theme.fontSize
            }

            Rectangle { id: divider2; width: parent.width; height: 1; color: Root.Theme.primaryColor }

            Column {
                id: footerColumn
                width: parent.width

                Row {
                    width: parent.width
                    height: Root.Theme.moduleHeight + 6
                    leftPadding: Root.Theme.spacing
                    spacing: Root.Theme.spacing
                    Text {
                        height: parent.height
                        verticalAlignment: Text.AlignVCenter
                        text: "↻"
                        color: Root.Theme.iconColor
                        font.pixelSize: Root.Theme.fontSize
                    }
                    Text {
                        height: parent.height
                        verticalAlignment: Text.AlignVCenter
                        text: "Scan"
                        color: Root.Theme.textColor
                        font.family: Root.Theme.font
                        font.pixelSize: Root.Theme.fontSize
                    }
                    MouseArea { width: parent.width; height: parent.height; onClicked: root.model.startScan() }
                }
                Row {
                    width: parent.width
                    height: Root.Theme.moduleHeight + 6
                    leftPadding: Root.Theme.spacing
                    spacing: Root.Theme.spacing
                    Text {
                        height: parent.height
                        verticalAlignment: Text.AlignVCenter
                        text: "⏻"
                        color: Root.Theme.iconColor
                        font.pixelSize: Root.Theme.fontSize
                    }
                    Text {
                        height: parent.height
                        verticalAlignment: Text.AlignVCenter
                        text: "Wi-Fi"
                        color: Root.Theme.textColor
                        font.family: Root.Theme.font
                        font.pixelSize: Root.Theme.fontSize
                    }
                    MouseArea { width: parent.width; height: parent.height; onClicked: root.model.toggleWifi() }
                }
            }
        }

        // --- Password entry page ---------------------------------------
        Column {
            id: passwordPage
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Root.Theme.spacing
            spacing: Root.Theme.spacing
            visible: root.showPassword

            Row {
                width: parent.width
                spacing: Root.Theme.spacing
                Text {
                    text: "←"
                    color: Root.Theme.iconColor
                    font.pixelSize: Root.Theme.iconSize + 2
                    MouseArea { anchors.fill: parent; onClicked: root.pendingSsid = "" }
                }
                Text {
                    text: root.pendingSsid
                    color: Root.Theme.textColor
                    font.family: Root.Theme.font
                    font.pixelSize: Root.Theme.fontSize
                    font.weight: 600
                    elide: Text.ElideRight
                    width: parent.width - 30
                }
            }

            Text {
                text: "Password"
                color: Root.Theme.textColor
                font.family: Root.Theme.font
                font.pixelSize: Root.Theme.fontSize
            }

            Rectangle {
                width: parent.width
                height: Root.Theme.moduleHeight
                radius: Root.Theme.radius
                color: Root.Theme.primaryColor

                TextInput {
                    id: passwordInput
                    anchors.fill: parent
                    anchors.leftMargin: Root.Theme.spacing
                    anchors.rightMargin: Root.Theme.spacing
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    color: Root.Theme.textColor
                    font.family: Root.Theme.font
                    font.pixelSize: Root.Theme.fontSize
                    focus: root.showPassword
                    text: root.passwordText
                    onTextEdited: root.passwordText = text
                    Keys.onReturnPressed: root.submitPassword()
                }
            }

            Text {
                visible: root.errorText !== ""
                text: root.errorText
                color: "#ff6b6b"
                font.family: Root.Theme.font
                font.pixelSize: Root.Theme.fontSize - 1
                wrapMode: Text.WordWrap
                width: parent.width
            }

            Item { width: 1; height: Root.Theme.spacing }

            Rectangle {
                anchors.right: parent.right
                width: 90
                height: Root.Theme.moduleHeight
                radius: Root.Theme.radius
                color: Root.Theme.secondaryColor
                opacity: connecting ? 0.6 : 1

                readonly property bool connecting: root.model && root.model.connectingSsid === root.pendingSsid

                Text {
                    anchors.centerIn: parent
                    text: parent.connecting ? "Connecting…" : "Connect"
                    color: Root.Theme.highlightedTextColor
                    font.family: Root.Theme.font
                    font.pixelSize: Root.Theme.fontSize
                    font.weight: 600
                }
                MouseArea { anchors.fill: parent; enabled: !parent.connecting; onClicked: root.submitPassword() }
            }
        }
    }
}
