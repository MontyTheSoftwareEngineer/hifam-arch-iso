import QtQuick
import Quickshell
import "../" as Root

// Month calendar popup anchored to the clock pill. Arrows step through
// months; today's date is highlighted whenever the visible month matches.
PopupWindow {
    id: root

    property Item target: null
    property var viewDate: new Date()
    readonly property int viewYear: viewDate.getFullYear()
    readonly property int viewMonth: viewDate.getMonth()

    readonly property var today: new Date()
    readonly property var monthNames: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
    readonly property var dayNames: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

    // 42 cells (6 weeks) covering the leading/trailing days from adjacent
    // months so the grid never reflows between months.
    readonly property var cells: {
        var firstOfMonth = new Date(viewYear, viewMonth, 1)
        var startOffset = firstOfMonth.getDay()
        var daysInMonth = new Date(viewYear, viewMonth + 1, 0).getDate()
        var daysInPrevMonth = new Date(viewYear, viewMonth, 0).getDate()
        var out = []
        for (var i = 0; i < 42; i++) {
            var dayNum = i - startOffset + 1
            var inMonth = dayNum >= 1 && dayNum <= daysInMonth
            var display = inMonth ? dayNum
                : (dayNum < 1 ? daysInPrevMonth + dayNum : dayNum - daysInMonth)
            var isToday = inMonth && display === today.getDate()
                && viewMonth === today.getMonth() && viewYear === today.getFullYear()
            out.push({ day: display, inMonth: inMonth, isToday: isToday })
        }
        return out
    }

    function prevMonth() { viewDate = new Date(viewYear, viewMonth - 1, 1) }
    function nextMonth() { viewDate = new Date(viewYear, viewMonth + 1, 1) }
    function goToday() { viewDate = new Date(today.getFullYear(), today.getMonth(), 1) }

    function open() {
        goToday()
        visible = true
    }

    function toggle() {
        if (visible) visible = false
        else open()
    }

    anchor.item: target
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.adjustment: PopupAdjustment.Slide
    anchor.margins.top: Root.Theme.spacing

    color: "transparent"
    visible: false
    grabFocus: true

    implicitWidth: 240
    implicitHeight: content.implicitHeight + Root.Theme.spacing * 2

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
            anchors.margins: Root.Theme.spacing
            anchors.top: parent.top
            spacing: Root.Theme.spacing / 2

            Row {
                width: parent.width
                height: Root.Theme.moduleHeight

                Text {
                    id: prevArrow
                    width: 24
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: "‹"
                    color: Root.Theme.iconColor
                    font.pixelSize: Root.Theme.fontSize + 4
                    font.bold: true
                    MouseArea { anchors.fill: parent; onClicked: root.prevMonth() }
                }
                Text {
                    width: parent.width - prevArrow.width - nextArrow.width
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: root.monthNames[root.viewMonth] + " " + root.viewYear
                    color: Root.Theme.textColor
                    font.family: Root.Theme.font
                    font.pixelSize: Root.Theme.fontSize
                    font.weight: 600
                    MouseArea { anchors.fill: parent; onClicked: root.goToday() }
                }
                Text {
                    id: nextArrow
                    width: 24
                    height: parent.height
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: "›"
                    color: Root.Theme.iconColor
                    font.pixelSize: Root.Theme.fontSize + 4
                    font.bold: true
                    MouseArea { anchors.fill: parent; onClicked: root.nextMonth() }
                }
            }

            Rectangle { width: parent.width; height: 1; color: Root.Theme.primaryColor }

            Grid {
                id: grid
                width: parent.width
                columns: 7

                Repeater {
                    model: root.dayNames
                    delegate: Text {
                        required property string modelData
                        width: grid.width / 7
                        height: 22
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: modelData
                        color: Root.Theme.primaryColor
                        font.family: Root.Theme.font
                        font.pixelSize: Root.Theme.fontSize - 1
                        font.weight: 600
                    }
                }

                Repeater {
                    model: root.cells
                    delegate: Rectangle {
                        required property var modelData
                        width: grid.width / 7
                        height: 26
                        radius: Root.Theme.radius
                        color: modelData.isToday ? Root.Theme.secondaryColor : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: modelData.day
                            color: modelData.isToday ? Root.Theme.highlightedTextColor
                                : (modelData.inMonth ? Root.Theme.textColor : Root.Theme.primaryColor)
                            font.family: Root.Theme.font
                            font.pixelSize: Root.Theme.fontSize
                            font.weight: modelData.isToday ? 700 : 400
                        }
                    }
                }
            }
        }
    }
}
