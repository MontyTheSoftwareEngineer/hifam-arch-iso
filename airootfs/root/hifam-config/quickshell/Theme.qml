pragma Singleton

import QtQuick
import Quickshell

Singleton {
    property color primaryColor: "#6200EE"
    property color secondaryColor: "#03DAC6"
    property color backgroundColor: "#000000"
    property color textColor: "#000000"
    property color iconColor: "white"

    property int barHeight: 28
    property int moduleHeight: 28
    property int spacing: 8
    property int radius: 8

    property string font: "SF Mono"
    property real fontSize: 12.5
    property real letterSpacing: -0.5

    property string iconFont: "Material Symbols Rounded"
    property int iconSize: 16

    property var iconAxes: ({
        "FILL": 0,
        "wght": 700,
        "GRAD": 0,
        "opsz": 20,
    })
}
