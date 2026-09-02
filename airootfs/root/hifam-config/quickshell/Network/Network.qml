import QtQuick
import "../" as Root

// Bar pill showing current network connection status. Click toggles a
// popup with the Wi-Fi list; icon/text react live to NetworkModel's state.
Root.Pill {
    id: root

    readonly property string iconName: {
        if (!model.wifiEnabled && model.activeType !== "ethernet") return "signal_wifi_off"
        if (model.activeType === "ethernet") return "lan"
        if (model.activeType === "wifi") {
            var s = model.activeSignal
            if (s >= 80) return "network_wifi"
            if (s >= 55) return "network_wifi_3_bar"
            if (s >= 30) return "network_wifi_2_bar"
            return "network_wifi_1_bar"
        }
        return "signal_wifi_0_bar"
    }

    // Right-click toggles between showing the SSID and the current IP
    // address; left-click opens the network popup.
    property bool showIp: false

    readonly property string statusText: {
        if (model.activeSsid === "") return model.wifiEnabled ? "Not Connected" : "Wi-Fi Off"
        if (showIp && model.activeIp !== "") return model.activeIp
        return model.activeSsid
    }

    icon: iconName
    iconColor: Root.Theme.iconColor
    text: statusText

    onClicked: popup.toggle()
    onRightClicked: root.showIp = !root.showIp

    Connections {
        target: model
        function onActiveSsidChanged() { root.showIp = false }
    }

    NetworkModel {
        id: model
    }

    NetworkPopup {
        id: popup
        target: root
        model: model
    }
}

