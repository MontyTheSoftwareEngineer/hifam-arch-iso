import QtQuick
import Quickshell
import "Network"
import "Calendar"
import "Volume"
import "Battery"

ShellRoot {
    id: shell

    // Change these three values to tune idle and wallpaper behavior.
    property int idleScreenOffMinutes: 5
    property int idleLockMinutes: 10
    property string wallpaperPath: "/usr/share/hifam/images/back.png"

    BackgroundLayer {
        imagePath: shell.wallpaperPath
    }

    AppLauncher {}

    PowerMenu {}

    // Shared so the bar pill and the OSD popup always agree on state.
    VolumeModel {
        id: sharedVolumeModel
    }

    VolumeOSD {
        model: sharedVolumeModel
    }

    IdleService {
        screenOffMinutes: shell.idleScreenOffMinutes
        lockMinutes: shell.idleLockMinutes
    }
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: bar
            required property var modelData
            anchors { top: true; left: true; right: true }
            implicitHeight: Theme.barHeight * 1.2
            exclusionMode: ExclusionMode.Ignore
            aboveWindows: true
            color: Qt.rgba(0,0,0,0)

            Island {
                id: island
                volumeModel: sharedVolumeModel
            }

            LockScreen {
                wallpaperPath: shell.wallpaperPath
            }

            //Workspaces {
            //    id: ws
            //    anchors.left: parent.left
            //    anchors.leftMargin: Theme.spacing
            //    anchors.top: parent.top
            //}
        }
    }
}
