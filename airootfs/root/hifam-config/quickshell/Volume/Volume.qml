import QtQuick
import "../" as Root

// Bar pill showing current output volume/mute state. Click opens a popup
// with a slider and the output-device picker.
Root.Pill {
    id: root

    // Shared VolumeModel instance, owned by the caller (shell.qml) so the
    // OSD popup and this bar pill stay in sync.
    required property var model

    readonly property string iconName: {
        if (model.muted) return "volume_off"
        if (model.volume === 0) return "volume_mute"
        if (model.volume < 50) return "volume_down"
        return "volume_up"
    }

    icon: iconName
    iconColor: Root.Theme.iconColor
    text: model.muted ? "Muted" : model.volume + "%"

    onClicked: popup.toggle()

    VolumePopup {
        id: popup
        target: root
        model: root.model
    }
}
