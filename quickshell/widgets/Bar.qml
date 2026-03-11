import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import "bar"
import "bar/left"
import "bar/center"
import "bar/right"

PanelWindow {
    id: bar

    anchors { top: true; left: true; right: true }
    height:       24
    margins       { top: 6; bottom: 0; left: 6; right: 6 }
    exclusiveZone: 24
    color:         "transparent"

    // ── Shared constants ────────────────────────────────────────────
    readonly property int btnSize:  24
    readonly property int pillH:    24
    readonly property int pillR:    6
    readonly property int iconPx:   14
    readonly property int labelPx:  14
    readonly property int spacing:  10

    // ── Global state ────────────────────────────────────────────────
    BarState { id: state }

    // ── Layout ──────────────────────────────────────────────────────
    Item {
        anchors.fill: parent

        // LEFT
        RowLayout {
            anchors {
                left:           parent.left
                verticalCenter: parent.verticalCenter
                leftMargin:     4
            }
            spacing: bar.spacing

            LeftGroup    { cfg: bar; st: state }
            WindowTitle  { cfg: bar; st: state }
        }

        // CENTER
        RowLayout {
            anchors.centerIn: parent
            spacing: bar.spacing

            Stats          { cfg: bar; st: state }
            IdleInhibitor  { cfg: bar; st: state }
            Info           { cfg: bar; st: state }
        }

        // RIGHT
        RowLayout {
            anchors {
                right:          parent.right
                verticalCenter: parent.verticalCenter
                rightMargin:    4
            }
            spacing: bar.spacing

            Media       { cfg: bar; st: state }
            RightGroup {
                cfg: bar
                st:  state
            }
        }
    }
}
