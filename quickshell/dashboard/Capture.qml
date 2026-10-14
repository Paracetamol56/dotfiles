import QtQuick
import Quickshell
import "../bar"

// Screenshot (area / window / screen) and area recording.
// Each action closes the dashboard first so it isn't in the capture.
Widget {
    id: root

    function screenshot(mode) {
        Panels.closeDashboard();
        Quickshell.execDetached(["sh", "-c", `sleep 0.35; exec "${Theme.scripts}/screenshot.sh" ${mode}`]);
    }

    function clock(s) {
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    Column {
        anchors.fill: parent
        spacing: 8

        Row {
            width: parent.width
            spacing: 6

            Repeater {
                model: [
                    { mode: "area", icon: Icons.squareDashed, label: "Area" },
                    { mode: "window", icon: Icons.appWindow, label: "Window" },
                    { mode: "screen", icon: Icons.monitor, label: "Screen" }
                ]

                Tile {
                    required property var modelData
                    width: (parent.width - parent.spacing * 2) / 3
                    height: 46
                    icon: modelData.icon
                    label: modelData.label
                    onClicked: root.screenshot(modelData.mode)
                }
            }
        }

        // Record: turns red with a timer while recording; click again to stop
        Tile {
            width: parent.width
            height: parent.height - 46 - parent.spacing
            horizontal: true
            enabled: Recorder.available
            accent: Recorder.recording ? Theme.red : Theme.mauve
            icon: Recorder.recording ? Icons.circleStop : Icons.video
            label: !Recorder.available ? "Install wf-recorder" : Recorder.recording ? "Stop  " + root.clock(Recorder.elapsed) : "Record area"
            onClicked: {
                if (!Recorder.recording)
                    Panels.closeDashboard();
                Recorder.toggle();
            }
        }
    }

    // Icon button with a caption, under or beside the icon
    component Tile: Rectangle {
        id: tile

        property string icon
        property string label
        property bool horizontal: false
        property bool enabled: true
        property color accent: Theme.mauve
        signal clicked

        radius: Theme.radius
        color: tileMouse.containsMouse && enabled ? Qt.alpha(Theme.surface1, 0.6) : Qt.alpha(Theme.surface0, 0.6)

        Behavior on color {
            ColorAnimation {
                duration: Theme.animDuration
            }
        }

        Grid {
            anchors.centerIn: parent
            columns: tile.horizontal ? 2 : 1
            columnSpacing: 8
            rowSpacing: 3
            horizontalItemAlignment: Grid.AlignHCenter
            verticalItemAlignment: Grid.AlignVCenter

            Label {
                text: tile.icon
                font.family: Icons.font
                font.pixelSize: 16
                color: !tile.enabled ? Theme.overlay0 : tileMouse.containsMouse ? Theme.lavender : tile.accent
            }

            Label {
                text: tile.label
                font.pixelSize: 10
                color: !tile.enabled ? Theme.overlay0 : Theme.subtext1
            }
        }

        MouseArea {
            id: tileMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: tile.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.clicked()
        }
    }
}
