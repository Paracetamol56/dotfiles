import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import qs.common
import qs.components
import qs.services

// Workspace overview (SUPER + Tab): workspaces 1–8 with live previews of their windows.
// Click a window to focus it, click a workspace to go there, drag a window onto another
// workspace to move it. Arrows + Enter pick a window, Esc closes.
Modal {
    id: root

    name: "overview"
    align: "middle"
    cardWidth: Math.round((screen?.width ?? 1920) * 0.82)
    cardHeight: grid.y + grid.height + 28

    readonly property int columns: 4
    readonly property int rows: 2
    readonly property real gap: 14
    readonly property real cellWidth: (cardWidth - 56 - gap * (columns - 1)) / columns
    // Cells take the shape of this screen
    readonly property real cellHeight: cellWidth * (screen?.height ?? 1080) / (screen?.width ?? 1920)

    // Every window with its geometry, refreshed when the overview opens
    readonly property var windows: Hyprland.toplevels.values.filter(t => t.workspace && t.workspace.id >= 1 && t.workspace.id <= 8)
    property int current: 0

    kanji: "一覧"

    title: "Overview"
    subtitle: `${windows.length} window${windows.length === 1 ? "" : "s"} · click to focus · drag to move · Esc to close`

    function dispatch(cmd) {
        Hyprland.dispatch(cmd);
    }

    function focusWindow(t) {
        Panels.close();
        dispatch(`hl.dsp.focus({ window = "address:${t.address}" })`);
    }

    function moveWindow(t, workspace) {
        dispatch(`hl.dsp.window.move({ workspace = ${workspace}, window = "address:${t.address}", follow = false })`);
        Qt.callLater(Hyprland.refreshToplevels);
    }

    function goTo(workspace) {
        Panels.close();
        dispatch(`hl.dsp.focus({ workspace = ${workspace} })`);
    }

    onOpenChanged: {
        if (open) {
            Hyprland.refreshToplevels();
            Hyprland.refreshMonitors();
            const active = windows.findIndex(t => t.activated);
            current = Math.max(0, active);
        }
    }

    onKeyPressed: e => {
        if (!windows.length)
            return;
        if (e.key === Qt.Key_Right || e.key === Qt.Key_Down || e.key === Qt.Key_Tab)
            current = (current + 1) % windows.length;
        else if (e.key === Qt.Key_Left || e.key === Qt.Key_Up || e.key === Qt.Key_Backtab)
            current = (current - 1 + windows.length) % windows.length;
        else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter)
            focusWindow(windows[current]);
        else
            return;
        e.accepted = true;
    }

    Grid {
        id: grid
        anchors.top: root.header.bottom
        anchors.topMargin: 20
        anchors.left: root.header.left
        columns: root.columns
        spacing: root.gap

        Repeater {
            model: root.columns * root.rows

            Widget {
                id: cell

                required property int index
                readonly property int workspace: index + 1
                readonly property var ws: Hyprland.workspaces.values.find(w => w.id === workspace) ?? null
                // The monitor this workspace lives on, for scaling its windows
                readonly property var monitor: ws?.monitor?.lastIpcObject ?? null
                readonly property bool rotated: (monitor?.transform ?? 0) % 2 === 1
                readonly property real monitorWidth: monitor ? (rotated ? monitor.height : monitor.width) / (monitor.scale || 1) : (root.screen?.width ?? 1920)
                readonly property real monitorHeight: monitor ? (rotated ? monitor.width : monitor.height) / (monitor.scale || 1) : (root.screen?.height ?? 1080)
                readonly property real scale: Math.min(width / monitorWidth, height / monitorHeight)
                readonly property bool isActive: Hyprland.focusedMonitor?.activeWorkspace?.id === workspace

                blurSource: root.backdrop
                width: root.cellWidth
                height: root.cellHeight
                padding: 0

                // Highlight the current workspace and drop targets
                Rectangle {
                    anchors.fill: parent
                    radius: Theme.radius
                    color: "transparent"
                    border.width: drop.containsDrag ? 2 : cell.isActive ? 1 : 0
                    border.color: drop.containsDrag ? Theme.accent : Qt.alpha(Theme.accent, 0.6)
                    z: 10
                }

                // Workspace number (kanji, like the bar)
                Label {
                    x: 10
                    y: 6
                    z: 5
                    text: ["一", "二", "三", "四", "五", "六", "七", "八"][cell.index]
                    font.family: "Noto Sans CJK JP"
                    font.pixelSize: 14
                    color: cell.isActive ? Theme.accent : Theme.overlay1
                }

                // Empty space: go to this workspace
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.goTo(cell.workspace)
                }

                DropArea {
                    id: drop
                    anchors.fill: parent
                    keys: ["overview-window"]
                    onDropped: drag => {
                        const t = drag.source?.toplevel;
                        if (t && t.workspace?.id !== cell.workspace)
                            root.moveWindow(t, cell.workspace);
                    }
                }

                Repeater {
                    model: root.windows.filter(t => t.workspace?.id === cell.workspace)

                    Item {
                        id: win

                        required property var modelData
                        readonly property var toplevel: modelData
                        readonly property var ipc: modelData.lastIpcObject ?? ({})
                        readonly property int globalIndex: root.windows.indexOf(modelData)
                        readonly property bool selected: globalIndex === root.current
                        // Position inside the workspace's monitor, scaled into the cell
                        readonly property real homeX: ((ipc.at?.[0] ?? 0) - (cell.monitor?.x ?? 0)) * cell.scale
                        readonly property real homeY: ((ipc.at?.[1] ?? 0) - (cell.monitor?.y ?? 0)) * cell.scale

                        x: homeX
                        y: homeY
                        width: Math.max(24, (ipc.size?.[0] ?? 200) * cell.scale)
                        height: Math.max(18, (ipc.size?.[1] ?? 150) * cell.scale)
                        z: dragArea.drag.active ? 100 : 1

                        Drag.active: dragArea.drag.active
                        Drag.keys: ["overview-window"]
                        Drag.source: win
                        Drag.hotSpot.x: width / 2
                        Drag.hotSpot.y: height / 2

                        ClippingRectangle {
                            anchors.fill: parent
                            radius: Math.max(2, Theme.radius * cell.scale * 4)
                            color: Theme.surface0
                            border.width: win.selected || dragArea.containsMouse ? 2 : 0
                            border.color: Theme.accent

                            // Live preview while the overview is open
                            ScreencopyView {
                                anchors.fill: parent
                                captureSource: root.open ? win.toplevel.wayland : null
                                live: root.open
                            }

                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: Math.min(32, parent.height * 0.5)
                                source: Quickshell.iconPath(win.ipc.class ?? "", "application-x-executable")
                                opacity: 0.9
                            }
                        }

                        MouseArea {
                            id: dragArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                            drag.target: win
                            onEntered: root.current = win.globalIndex
                            onReleased: {
                                if (drag.active)
                                    win.Drag.drop();
                                // Back to its place (it moves for real if dropped elsewhere)
                                win.x = Qt.binding(() => win.homeX);
                                win.y = Qt.binding(() => win.homeY);
                            }
                            onClicked: root.focusWindow(win.toplevel)
                        }

                        Tooltip {
                            target: win
                            hovered: dragArea.containsMouse && !dragArea.drag.active
                            text: win.toplevel.title
                        }
                    }
                }
            }
        }
    }
}
