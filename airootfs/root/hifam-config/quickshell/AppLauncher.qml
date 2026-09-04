import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "AppLauncherSearch.js" as AppLauncherSearch

Item {
    id: root

    property bool opened: false
    property string filterText: ""
    property int selectedIndex: 0
    property int maxResults: 8
    property int panelWidth: 640
    property string promptText: "Search apps..."

    function entryName(entry) {
        return AppLauncherSearch.entryName(entry)
    }

    function entrySubtext(entry) {
        return AppLauncherSearch.entrySubtext(entry)
    }

    function iconSource(icon) {
        var value = String(icon || "")
        if (!value) return Quickshell.iconPath("application-x-executable", true)
        if (value.indexOf("file://") === 0 || value.indexOf("image://") === 0) return value
        if (value.charAt(0) === "/") return Util.fileUrl(value)
        var themed = Quickshell.iconPath(value, true)
        if (themed.length > 0) return themed
        return Quickshell.iconPath("application-x-executable", true)
    }

    function rebuildResults() {
        var entries = DesktopEntries.applications.values || []
        var rows = AppLauncherSearch.sortedEntries(entries, root.filterText)

        resultsModel.clear()
        for (var i = 0; i < rows.length && i < root.maxResults; i++) {
            var entry = rows[i].entry
            resultsModel.append({
                desktopId: String(entry.id || ""),
                name: root.entryName(entry),
                subtext: root.entrySubtext(entry),
                icon: root.iconSource(entry.icon),
                score: rows[i].score
            })
        }

        if (resultsModel.count === 0) {
            root.selectedIndex = -1
        } else if (root.selectedIndex < 0 || root.selectedIndex >= resultsModel.count) {
            root.selectedIndex = 0
        }

        if (root.selectedIndex >= 0) Qt.callLater(function() { resultList.positionViewAtIndex(root.selectedIndex, ListView.Contain) })
    }

    function open() {
        root.filterText = ""
        root.selectedIndex = 0
        root.opened = true
        root.rebuildResults()
        Qt.callLater(function() { searchField.forceActiveFocus() })
    }

    function close() {
        root.opened = false
    }

    function toggle() {
        if (root.opened) root.close()
        else root.open()
    }

    function moveSelection(delta) {
        if (resultsModel.count === 0) return
        var next = root.selectedIndex + delta
        if (next < 0) next = resultsModel.count - 1
        if (next >= resultsModel.count) next = 0
        root.selectedIndex = next
        resultList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
    }

    function launchSelected() {
        if (root.selectedIndex < 0 || root.selectedIndex >= resultsModel.count) return
        var row = resultsModel.get(root.selectedIndex)
        if (!row || !row.desktopId) return
        Quickshell.execDetached(["uwsm-app", "--", "gtk-launch", row.desktopId + ".desktop"])
        root.close()
    }

    onFilterTextChanged: root.rebuildResults()
    onOpenedChanged: if (opened) Qt.callLater(function() { searchField.forceActiveFocus() })

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { root.rebuildResults() }
    }

    ListModel {
        id: resultsModel
    }

    IpcHandler {
        target: "launcher"

        function open(): string {
            root.open()
            return "ok"
        }

        function close(): string {
            root.close()
            return "ok"
        }

        function toggle(): string {
            root.toggle()
            return root.opened ? "open" : "closed"
        }

        function ping(): string {
            return "ok"
        }
    }

    PanelWindow {
        id: panel
        visible: root.opened
        anchors { top: true; bottom: true; left: true; right: true }
        color: Qt.rgba(0, 0, 0, 0.38)

        WlrLayershell.namespace: "custom-launcher"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        exclusionMode: ExclusionMode.Ignore

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }

        Rectangle {
            id: card
            width: root.panelWidth
            height: Math.min(contentColumn.implicitHeight + 32, parent.height - 80)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 110
            radius: Theme.radius
            color: Theme.backgroundColor
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.12)
            clip: true

            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                id: contentColumn
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: root.promptText
                    text: root.filterText
                    selectByMouse: true
                    color: Theme.textColor
                    placeholderTextColor: Qt.rgba(1, 1, 1, 0.45)
                    font.pixelSize: 18
                    background: Rectangle {
                        radius: Theme.radius
                        color: Qt.rgba(1, 1, 1, 0.06)
                        border.width: 1
                        border.color: searchField.activeFocus ? Theme.primaryColor : Qt.rgba(1, 1, 1, 0.08)
                    }

                    onTextEdited: root.filterText = text

                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Escape) {
                            root.close()
                            event.accepted = true
                        } else if (event.key === Qt.Key_Down) {
                            root.moveSelection(1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Up) {
                            root.moveSelection(-1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.launchSelected()
                            event.accepted = true
                        }
                    }
                }

                ListView {
                    id: resultList
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(contentHeight, root.maxResults * 62)
                    clip: true
                    model: resultsModel
                    spacing: 8
                    currentIndex: root.selectedIndex
                    interactive: contentHeight > height
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        required property int index
                        required property string desktopId
                        required property string name
                        required property string subtext
                        required property string icon

                        width: resultList.width
                        height: subtext.length > 0 ? 58 : 48
                        radius: Theme.radius
                        color: root.selectedIndex === index ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                        border.width: root.selectedIndex === index ? 1 : 0
                        border.color: root.selectedIndex === index ? Theme.primaryColor : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            Image {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                source: icon
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: name
                                    color: Theme.textColor
                                    font.pixelSize: 15
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    visible: subtext.length > 0
                                    text: subtext
                                    color: Qt.rgba(1, 1, 1, 0.58)
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: root.selectedIndex = index
                            onClicked: {
                                root.selectedIndex = index
                                root.launchSelected()
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: resultsModel.count === 0
                    text: "No applications found"
                    color: Qt.rgba(1, 1, 1, 0.58)
                    font.pixelSize: 13
                }
            }
        }
    }
}
