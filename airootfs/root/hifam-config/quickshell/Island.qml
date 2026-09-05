import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "Battery"

Rectangle {
    id: root
    property var volumeModel: null
    property bool islandShown: true
    property bool expanded: false
    property bool overlayVisible: false
    property bool showExpandedDetails: false
    property real slideOffset: islandShown ? 0 : -height - Theme.spacing

    color: root.overlayVisible ? "transparent" : Theme.primaryColor
    // border.color: Theme.secondaryColor
    // border.width: 2
    height: Theme.barHeight * 1.25

    width: parent.width / 4
    anchors.top: parent.top
    anchors.topMargin: root.slideOffset
    anchors.horizontalCenter: parent.horizontalCenter
    radius: 10

    BatteryModel { id: batteryModel }

    Behavior on color { ColorAnimation { duration: 90 } }

    Behavior on slideOffset {
        NumberAnimation {
            duration: 420
            easing.type: root.islandShown ? Easing.OutBack : Easing.InBack
            easing.overshoot: 1.6
        }
    }

    function toggleOpen() {
        if (!root.islandShown || root.overlayVisible) {
            closeDetails()
            return "island closed"
        }
        else {
            openDetails()
            return "island opened"
        }
        return ""
    }


    function openDetails() {
        if (!root.islandShown || root.overlayVisible) return
        root.showExpandedDetails = false
        root.expanded = false
        root.overlayVisible = true
        expandStartTimer.restart()
    }

    function closeDetails() {
        if (!root.overlayVisible) return
        root.showExpandedDetails = false
        root.expanded = false
        overlayCloseTimer.restart()
    }

    function toggleDetails() {
        if (root.overlayVisible) root.closeDetails()
        else root.openDetails()
    }

    function showIsland() {
        root.islandShown = true
        return "shown"
    }

    function hideIsland() {
        root.closeDetails()
        root.islandShown = false
        return "hidden"
    }

    function toggleIsland() {
        root.islandShown = !root.islandShown
        if (!root.islandShown) root.closeDetails()
        return root.islandShown ? "shown" : "hidden"
    }

    Timer {
        id: expandStartTimer
        interval: 16
        repeat: false
        onTriggered: {
            root.expanded = true
            detailRevealTimer.restart()
        }
    }

    Timer {
        id: detailRevealTimer
        interval: 220
        repeat: false
        onTriggered: root.showExpandedDetails = true
    }

    Timer {
        id: overlayCloseTimer
        interval: 360
        repeat: false
        onTriggered: root.overlayVisible = false
    }

    onShowExpandedDetailsChanged: if (root.showExpandedDetails) Qt.callLater(function() { expandingCard.forceActiveFocus() })

    IpcHandler {
        target: "island"

        function show(): string {
            return root.showIsland()
        }

        function hide(): string {
            return root.hideIsland()
        }

        function toggle(): string {
            return root.toggleIsland()
        }

        function toggleOpen(): string {
            return root.toggleOpen()
        }

        function open(): string {
            root.openDetails()
            return root.overlayVisible ? "open" : "hidden"
        }

        function close(): string {
            root.closeDetails()
            return "closed"
        }
    }

    // Rectangle {
    //     anchors.top: parent.top
    //     anchors.left: parent.left
    //     anchors.right: parent.right
    //     height: parent.radius
    //     color: parent.color
    // }

    // Pill {
    //     id: menuButton
    //     anchors.horizontalCenter: parent.horizontalCenter
    //     anchors.verticalCenter: parent.verticalCenter
    //     icon: "menu"
    //     iconColor: Theme.iconColor
    //     text: ""
    //     onClicked: details.toggle()
    // }

    Item {
        id: islandFace
        anchors.fill: parent
        opacity: root.overlayVisible ? 0 : 1

        Behavior on opacity { NumberAnimation { duration: 100 } }

        Workspaces {
            anchors.left: parent.left
            anchors.leftMargin: Theme.spacing
            anchors.verticalCenter: parent.verticalCenter
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: Theme.spacing
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacing

            SystemClock {
                id: clock
                precision: SystemClock.Precision.Minutes
            }

            BatteryIcon {
                model: batteryModel
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDateTime(clock.date, "MMM d h:mm AP").toUpperCase()
                color: Theme.textColor
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                font.weight: 600
                font.letterSpacing: Theme.letterSpacing
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.islandShown && !root.overlayVisible
        onClicked: root.toggleDetails()
    }

    PanelWindow {
        id: overlay
        visible: root.overlayVisible
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"

        WlrLayershell.namespace: "custom-island"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.showExpandedDetails ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Ignore

        MouseArea {
            anchors.fill: parent
            enabled: root.showExpandedDetails
            onClicked: root.closeDetails()
        }

        Rectangle {
            id: expandingCard

            readonly property real collapsedWidth: Math.max(1, overlay.width / 4)
            readonly property real collapsedHeight: Theme.barHeight * 1.25
            readonly property real expandedWidth: Math.min(560, overlay.width - Theme.spacing * 6)
            readonly property real expandedHeight: Math.min(details.implicitHeight, overlay.height - Theme.spacing * 12)
            readonly property real targetY: root.expanded ? (overlay.height - expandedHeight) / 2 : 0

            width: root.expanded ? expandedWidth : collapsedWidth
            height: root.expanded ? expandedHeight : collapsedHeight
            anchors.horizontalCenter: parent.horizontalCenter
            y: targetY
            radius: root.expanded ? Theme.radius * 1.4 : Theme.radius
            color: Theme.backgroundColor
            border.color: root.expanded ? Theme.primaryColor : "transparent"
            border.width: root.expanded ? 1 : 0
            clip: true
            focus: root.showExpandedDetails

            Behavior on y { NumberAnimation { duration: 420; easing.type: Easing.InOutCubic } }
            Behavior on width { NumberAnimation { duration: 420; easing.type: Easing.InOutCubic } }
            Behavior on height { NumberAnimation { duration: 420; easing.type: Easing.InOutCubic } }
            Behavior on radius { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

            MouseArea { anchors.fill: parent }

            Item {
                id: overlayIslandFace
                anchors.fill: parent
                opacity: root.showExpandedDetails ? 0 : 1

                Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                Workspaces {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacing
                    anchors.verticalCenter: parent.verticalCenter
                }

                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.spacing
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacing

                    BatteryIcon {
                        model: batteryModel
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Qt.formatDateTime(clock.date, "MMM d h:mm AP").toUpperCase()
                        color: Theme.textColor
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                        font.weight: 600
                        font.letterSpacing: Theme.letterSpacing
                    }
                }
            }

            IslandPopup {
                id: details
                width: parent.width
                opacity: root.showExpandedDetails ? 1 : 0
                volumeModel: root.volumeModel
                onCloseRequested: root.closeDetails()

                Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            }

            Keys.onEscapePressed: root.closeDetails()
        }
    }
}
