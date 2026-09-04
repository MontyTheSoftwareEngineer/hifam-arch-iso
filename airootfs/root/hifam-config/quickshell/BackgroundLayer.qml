import QtQuick
import Quickshell
import Quickshell.Wayland

Item {
    id: root

    property string imagePath: ""

    function imageUrl(path) {
        if (!path) return ""
        return "file://" + String(path).split("/").map(encodeURIComponent).join("/")
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panel
            required property var modelData

            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"

            WlrLayershell.namespace: "custom-background"
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore

            Rectangle {
                anchors.fill: parent
                color: "#000000"
            }

            Image {
                id: wallpaper
                anchors.fill: parent
                source: root.imageUrl(root.imagePath)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                sourceSize.width: width
                sourceSize.height: height
            }
        }
    }
}
