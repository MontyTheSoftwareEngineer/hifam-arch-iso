import QtQuick

Rectangle {
    id: root
    signal clicked()
    property string icon: ""
    property color iconColor: "red"
    property string text: ""

    implicitWidth: row.width
    implicitHeight: Theme.moduleHeight
    radius: Theme.radius
    color: Theme.primaryColor

    Row {
        id: row
        height: parent.height
        spacing: Theme.spacing

        Rectangle {
            width: iconLabel.implicitWidth + 10
            height: parent.height
            color: Theme.secondaryColor
            radius: Theme.radius

            Text {
                id: iconLabel
                anchors.centerIn: parent
                text: root.icon
                color: root.iconColor
                font.family: Theme.iconFont
                font.pixelSize: Theme.iconSize
                font.variableAxes: Theme.iconAxes
            }
        }

        Text {
            id: textLabel
            leftPadding: 6
            rightPadding: 6
            text: root.text
            anchors.verticalCenter: parent.verticalCenter
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            font.weight: 600
            font.letterSpacing: Theme.letterSpacing
        }
    }
    MouseArea {
        anchors.fill: parent
        onClicked: {
            root.clicked()
        }
    }
}
