import QtQuick
import Quickshell
import Quickshell.Io
import qs.common
import qs.components
import qs.services

// Clipboard history from cliphist, centred on the screen (SUPER + V). Type to search,
// ↑/↓ to move, Enter or click to copy back, Delete to remove an entry. Images show as
// thumbnails, decoded once into Quickshell's cache folder (removed along with their entry).
Modal {
    id: root

    name: "clipboard"
    align: "middle"
    cardWidth: 640
    cardHeight: list.y + list.height + 28

    // [{ line, id, text, image: { size, type, w, h } | null }], newest first
    property var entries: []
    property string query: ""
    property int current: 0
    property bool confirmClear: false
    // When the clear button was armed: a confirm click only counts after a pause, so a
    // double-click can't wipe the history by accident
    property real armedAt: 0

    readonly property string thumbDir: Quickshell.cachePath("clipboard")
    readonly property var shown: {
        const q = query.trim().toLowerCase();
        return q ? entries.filter(e => e.text.toLowerCase().includes(q)) : entries;
    }

    kanji: "複写"

    actions: clear
    title: "Clipboard"
    subtitle: `${entries.length} entries · Enter copies · Delete removes`

    function refresh() {
        list_.running = true;
    }

    function copy(i) {
        const e = shown[i];
        if (!e)
            return;
        // The id as an argument: on stdin, cliphist reads the newline as part of the id
        Quickshell.execDetached(["sh", "-c", 'cliphist decode "$1" | wl-copy', "sh", e.id]);
        Panels.close();
    }

    function remove(i) {
        const e = shown[i];
        if (!e)
            return;
        // Also drop its cached thumbnail, so deleted images don't linger on disk
        deleter.command = ["sh", "-c", 'printf "%s" "$1" | cliphist delete; rm -f "$2"/"$3".*', "sh", e.line, thumbDir, e.id];
        deleter.running = true;
        entries = entries.filter(x => x.id !== e.id);
        current = Math.min(current, shown.length - 1);
    }

    onOpenChanged: {
        if (open) {
            search.text = "";
            current = 0;
            confirmClear = false;
            refresh();
            Qt.callLater(() => search.forceActiveFocus());
        }
    }
    onQueryChanged: current = 0

    Process {
        id: list_
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.entries = text.split("\n").filter(l => l.includes("\t")).map(line => {
                    const tab = line.indexOf("\t");
                    const id = line.slice(0, tab), body = line.slice(tab + 1);
                    const m = /^\[\[ binary data (.+?) (\w+) (\d+)x(\d+) \]\]$/.exec(body);
                    return { line, id, text: body, image: m ? { size: m[1], type: m[2], w: Number(m[3]), h: Number(m[4]) } : null };
                });
            }
        }
    }

    Process {
        id: deleter
    }

    Process {
        id: wiper
        command: ["sh", "-c", 'cliphist wipe; rm -rf "$1"', "sh", root.thumbDir]
        onExited: root.refresh()
    }

    // ── Search ───────────────────────────────────────────

    Rectangle {
        id: searchBox
        anchors.top: root.header.bottom
        anchors.topMargin: 20
        anchors.left: root.header.left
        anchors.right: root.header.right
        height: 44
        radius: Theme.radius
        color: Qt.alpha(Theme.crust, 0.6)
        border.width: search.activeFocus ? 2 : 1
        border.color: search.activeFocus ? Qt.alpha(Theme.accent, 0.7) : Theme.surface0

        Label {
            id: searchIcon
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: Icons.search
            font.family: Icons.font
            font.pixelSize: 16
            color: Theme.accent
        }

        TextInput {
            id: search
            anchors.left: searchIcon.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.text
            selectionColor: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: 15
            clip: true
            onTextChanged: root.query = text

            Keys.onEscapePressed: Panels.close()
            Keys.onUpPressed: root.current = Math.max(0, root.current - 1)
            Keys.onDownPressed: root.current = Math.min(root.shown.length - 1, root.current + 1)
            Keys.onDeletePressed: event => {
                // Delete removes the selected entry; with text selected it edits the search
                if (search.selectedText === "" && search.cursorPosition === search.text.length)
                    root.remove(root.current);
                else
                    event.accepted = false;
            }
            onAccepted: root.copy(root.current)

            Label {
                visible: search.text === ""
                anchors.verticalCenter: parent.verticalCenter
                text: "Search the clipboard history…"
                font.pixelSize: 15
                color: Theme.overlay0
            }
        }
    }

    // Wipe everything, right of the subtitle like the notifications' Clear all: a first click
    // arms it, a second, separate click (after 0.6 s, within 4 s) confirms. Clicks in between
    // are ignored, so a double-click can't wipe anything.
    Button {
        id: clear
        anchors.top: root.header.top
        anchors.topMargin: root.subtitleRow.y + (root.subtitleRow.height - height) / 2
        anchors.right: root.header.right
        icon: Icons.trash2
        text: root.confirmClear ? "Click again" : ""
        checked: root.confirmClear
        enabled: root.entries.length > 0
        tooltip: "Delete the whole clipboard history (can't be undone)"
        onClicked: {
            if (!root.confirmClear) {
                root.confirmClear = true;
                root.armedAt = Date.now();
                confirmTimer.restart();
                return;
            }
            if (Date.now() - root.armedAt < 600)
                return;
            root.confirmClear = false;
            wiper.running = true;
        }
    }

    Timer {
        id: confirmTimer
        interval: 4000
        onTriggered: root.confirmClear = false
    }

    // ── History ──────────────────────────────────────────

    Widget {
        id: list
        blurSource: root.backdrop
        anchors.top: searchBox.bottom
        anchors.topMargin: 12
        anchors.left: root.header.left
        anchors.right: root.header.right
        height: 440
        padding: 6

        Label {
            visible: root.shown.length === 0
            anchors.centerIn: parent
            text: root.entries.length ? `Nothing matches “${root.query}”` : "The clipboard history is empty"
            color: Theme.overlay1
        }

        ListView {
            id: view
            anchors.fill: parent
            clip: true
            model: root.shown
            currentIndex: root.current
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: 0
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

            delegate: Rectangle {
                id: row

                required property var modelData
                required property int index
                readonly property bool active: index === root.current
                readonly property bool isImage: modelData.image !== null
                readonly property string thumb: isImage ? `${root.thumbDir}/${modelData.id}.${modelData.image.type}` : ""

                width: ListView.view.width
                height: isImage ? 84 : 40
                radius: Theme.radius
                color: active ? Qt.alpha(Theme.accent, 0.18) : rowMouse.containsMouse ? Qt.alpha(Theme.surface1, 0.35) : "transparent"

                // Decode the image once into the cache, then show it
                Process {
                    id: decode
                    running: false
                    command: ["sh", "-c", 'mkdir -p "$1" && { [ -s "$2" ] || cliphist decode "$3" > "$2"; }', "sh", root.thumbDir, row.thumb, row.modelData.id]
                    onExited: thumbImage.source = "file://" + row.thumb
                }
                Component.onCompleted: if (isImage) decode.running = true

                Image {
                    id: thumbImage
                    visible: row.isImage
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 112
                    height: 72
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    sourceSize.width: 224
                    sourceSize.height: 144
                }

                Label {
                    anchors.left: row.isImage ? thumbImage.right : parent.left
                    anchors.leftMargin: 12
                    anchors.right: removeButton.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.isImage ? `Image · ${row.modelData.image.type.toUpperCase()} · ${row.modelData.image.w}×${row.modelData.image.h} · ${row.modelData.image.size}` : row.modelData.text.replace(/\s+/g, " ")
                    font.pixelSize: 12
                    color: row.isImage ? Theme.subtext0 : Theme.text
                }

                // Remove, while hovered
                Label {
                    id: removeButton
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    visible: rowMouse.containsMouse || removeMouse.containsMouse
                    text: Icons.x
                    font.family: Icons.font
                    font.pixelSize: 14
                    color: removeMouse.containsMouse ? Theme.red : Theme.overlay1

                    MouseArea {
                        id: removeMouse
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.remove(row.index)
                    }
                }

                MouseArea {
                    id: rowMouse
                    anchors.fill: parent
                    z: -1
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.current = row.index
                    onClicked: root.copy(row.index)
                }
            }
        }
    }
}
