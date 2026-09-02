import QtQuick
import Quickshell
import "../" as Root

// Popup anchored to the battery pill. Shows charge/health/power draw and a
// picker for power-profiles-daemon profiles (performance/balanced/power-saver).
PopupWindow {
    id: root

    property Item target: null
    property var model: null

    anchor.item: target
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.adjustment: PopupAdjustment.Slide
    anchor.margins.top: Root.Theme.spacing

    color: "transparent"
    visible: false
    grabFocus: true

    implicitWidth: 260
    implicitHeight: content.implicitHeight + Root.Theme.spacing * 2

    function toggle() {
        if (visible) { visible = false; return }
        model.refresh()
        visible = true
    }

    function profileLabel(name) {
        return name.split("-").map(function (w) {
            return w.charAt(0).toUpperCase() + w.slice(1)
        }).join(" ")
    }

    Rectangle {
        anchors.fill: parent
        radius: Root.Theme.radius
        color: Root.Theme.backgroundColor
        border.color: Root.Theme.primaryColor
        border.width: 1

        Column {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Root.Theme.spacing
            spacing: Root.Theme.spacing / 2

            Row {
                width: parent.width
                height: Root.Theme.moduleHeight
                Text {
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    text: (root.model ? root.model.percent : 0) + "%"
                    color: Root.Theme.textColor
                    font.family: Root.Theme.font
                    font.pixelSize: Root.Theme.fontSize + 4
                    font.weight: 700
                }
                Text {
                    height: parent.height
                    leftPadding: Root.Theme.spacing
                    verticalAlignment: Text.AlignVCenter
                    text: root.model && root.model.charging ? "Charging"
                        : (root.model && root.model.state === "fully-charged" ? "Fully Charged" : "On Battery")
                    color: Root.Theme.primaryColor
                    font.family: Root.Theme.font
                    font.pixelSize: Root.Theme.fontSize
                }
            }

            Text {
                visible: text !== ""
                text: root.model && root.model.charging && root.model.timeToFull !== ""
                    ? "Time to full: " + root.model.timeToFull
                    : (root.model && !root.model.charging && root.model.timeToEmpty !== ""
                        ? "Time remaining: " + root.model.timeToEmpty : "")
                color: Root.Theme.textColor
                font.family: Root.Theme.font
                font.pixelSize: Root.Theme.fontSize - 1
            }
            Text {
                visible: root.model && root.model.energyRate !== ""
                text: "Power draw: " + (root.model ? root.model.energyRate : "")
                color: Root.Theme.textColor
                font.family: Root.Theme.font
                font.pixelSize: Root.Theme.fontSize - 1
            }
            Text {
                visible: root.model && root.model.health >= 0
                text: "Battery health: " + (root.model ? root.model.health : 0) + "%"
                color: Root.Theme.textColor
                font.family: Root.Theme.font
                font.pixelSize: Root.Theme.fontSize - 1
            }

            Rectangle { width: parent.width; height: 1; color: Root.Theme.primaryColor }

            Text {
                text: "Power Profile"
                color: Root.Theme.primaryColor
                font.family: Root.Theme.font
                font.pixelSize: Root.Theme.fontSize - 1
                font.weight: 600
            }

            Column {
                width: parent.width

                Repeater {
                    model: root.model ? root.model.profiles : []
                    delegate: Item {
                        required property string modelData
                        width: parent.width
                        height: Root.Theme.moduleHeight

                        Row {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Root.Theme.spacing

                            Text {
                                width: 14
                                text: root.model && root.model.profile === modelData ? "●" : ""
                                color: Root.Theme.secondaryColor
                                font.pixelSize: Root.Theme.fontSize
                            }
                            Text {
                                text: root.profileLabel(modelData)
                                color: Root.Theme.textColor
                                font.family: Root.Theme.font
                                font.pixelSize: Root.Theme.fontSize
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.model.setProfile(modelData)
                        }
                    }
                }
            }
        }
    }
}
