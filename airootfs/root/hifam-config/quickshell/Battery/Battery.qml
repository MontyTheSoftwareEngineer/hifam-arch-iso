import QtQuick
import "../" as Root

// Bar pill showing battery charge with a level/charging-aware icon. Click
// opens a popup with battery health/power-draw info and a profile picker.
Root.Pill {
    id: root

    readonly property string iconName: {
        var p = model.percent
        if (model.charging) {
            if (p >= 95) return "battery_charging_full"
            if (p >= 90) return "battery_charging_90"
            if (p >= 80) return "battery_charging_80"
            if (p >= 60) return "battery_charging_60"
            if (p >= 50) return "battery_charging_50"
            if (p >= 30) return "battery_charging_30"
            return "battery_charging_20"
        }
        if (p >= 95) return "battery_full"
        if (p >= 85) return "battery_6_bar"
        if (p >= 70) return "battery_5_bar"
        if (p >= 55) return "battery_4_bar"
        if (p >= 40) return "battery_3_bar"
        if (p >= 25) return "battery_2_bar"
        if (p >= 10) return "battery_1_bar"
        return "battery_0_bar"
    }

    icon: iconName
    iconColor: Root.Theme.iconColor
    text: model.percent + "%"
    visible: model.present

    onClicked: popup.toggle()

    BatteryModel {
        id: model
    }

    BatteryPopup {
        id: popup
        target: root
        model: model
    }
}
