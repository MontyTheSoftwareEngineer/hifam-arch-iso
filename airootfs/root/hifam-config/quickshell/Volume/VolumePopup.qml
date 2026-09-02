import QtQuick
import Quickshell
import "../" as Root

// Popup anchored to the volume pill. Drag the slider to set volume, click
// the icon to toggle mute, click a device row to switch the default sink.
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
    visible: true
    grabFocus: true

    implicitWidth: 260
    implicitHeight: content.implicitHeight + Root.Theme.spacing * 2

    function toggle() {
        if (visible) { visible = false; return }
        model.refresh()
        visible = true
    }

    readonly property string volumeIcon: {
        if (model.muted || model.volume === 0) return "volume_off"
        if (model.volume < 50) return "volume_down"
        return "volume_up"
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
            spacing: Root.Theme.spacing

            Row {
                width: parent.width
                height: Root.Theme.moduleHeight
                spacing: Root.Theme.spacing

                Text {
                    id: muteButton
                    width: 24
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: root.volumeIcon
                    color: Root.Theme.iconColor
                    font.family: Root.Theme.iconFont
                    font.pixelSize: Root.Theme.iconSize + 4
                    font.variableAxes: Root.Theme.iconAxes
                    MouseArea { anchors.fill: parent; onClicked: root.model.toggleMute() }
                }

                Item {
                    id: sliderTrack
                    width: parent.width - muteButton.width - percentLabel.width - 2 * Root.Theme.spacing
                    height: parent.height

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 6
                        radius: 3
                        color: Root.Theme.primaryColor
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width * (root.model ? root.model.volume / 100 : 0)
                        height: 6
                        radius: 3
                        color: root.model && root.model.muted ? Root.Theme.primaryColor : Root.Theme.secondaryColor
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        x: Math.max(0, Math.min(parent.width - width,
                            parent.width * (root.model ? root.model.volume / 100 : 0) - width / 2))
                        width: 14
                        height: 14
                        radius: 7
                        color: Root.Theme.textColor
                    }
                    MouseArea {
                        anchors.fill: parent
                        function updateFromMouse(mx) {
                            var ratio = Math.max(0, Math.min(1, mx / sliderTrack.width))
                            root.model.setVolume(ratio * 100)
                        }
                        onPressed: (mouse) => updateFromMouse(mouse.x)
                        onPositionChanged: (mouse) => { if (pressed) updateFromMouse(mouse.x) }
                    }
                }

                Text {
                    id: percentLabel
                    width: 36
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    text: (root.model ? root.model.volume : 0) + "%"
                    color: Root.Theme.textColor
                    font.family: Root.Theme.font
                    font.pixelSize: Root.Theme.fontSize
                }
            }

            Rectangle { width: parent.width; height: 1; color: Root.Theme.primaryColor }

            Text {
                text: "Output Device"
                color: Root.Theme.primaryColor
                font.family: Root.Theme.font
                font.pixelSize: Root.Theme.fontSize - 1
                font.weight: 600
            }

            Column {
                width: parent.width

                Repeater {
                    model: root.model ? root.model.sinks : []
                    delegate: Item {
                        required property var modelData
                        width: parent.width
                        height: Root.Theme.moduleHeight

                        Row {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Root.Theme.spacing

                            Text {
                                width: 14
                                text: modelData.active ? "●" : ""
                                color: Root.Theme.secondaryColor
                                font.pixelSize: Root.Theme.fontSize
                            }
                            Text {
                                width: parent.width - 14 - Root.Theme.spacing
                                elide: Text.ElideRight
                                text: modelData.description
                                color: Root.Theme.textColor
                                font.family: Root.Theme.font
                                font.pixelSize: Root.Theme.fontSize
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.model.setDefaultSink(modelData.name)
                        }
                    }
                }
            }
        }
    }
}
