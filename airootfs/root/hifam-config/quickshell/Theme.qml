pragma Singleton

import QtQuick
import Quickshell

Singleton {
    property color primaryColor: "#7a7a7a"
    property color secondaryColor: "#65e1e6"
    property color backgroundColor: "#1E1E1E"
    property color textColor: "#FFFFFF"
    property color iconColor: "#FFFFFF"
    property color highlightedTextColor: "#1E1E1E"
    property color highlightedIconColor: "#1E1E1E"

    property int barHeight: 28
    property int moduleHeight: 28
    property int spacing: 8
    property int radius: 10

    property string font: "SF Mono"
    property real fontSize: 12.5
    property real letterSpacing: -0.5

    property string iconFont: "Material Symbols Rounded"
    property int iconSize: 14

    property var iconAxes: ({
        "FILL": 0,
        "wght": 700,
        "GRAD": 0,
        "opsz": 20,
    })
}
