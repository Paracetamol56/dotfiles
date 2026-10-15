import QtQuick
import Quickshell
import Quickshell.Io
import qs.common
import qs.components
import qs.services

// Emoji and kaomoji picker, centred on the screen (SUPER + S).
// Tabs for Recent, the Unicode emoji groups and Kaomoji (with sub-categories). Typing
// searches all emoji, or the kaomoji on that tab. Arrows move, Tab / Shift+Tab switch
// category, Enter or click copies.
Modal {
    id: root

    name: "emoji"
    align: "middle"
    cardWidth: 640
    cardHeight: grid.y + grid.height + 28

    // [{ name, kaomoji?, items: [[text, name]] }] from scripts/emoji-list.py
    property var categories: []
    property var recent: []       // texts, newest first
    property string query: ""
    property string tab: "Recent"
    property string kaomojiGroup: "Happy"
    property int current: 0

    // Tab bar: emoji as icons
    readonly property var tabs: [
        { key: "Recent", icon: "🕘" }, { key: "Smileys", icon: "😀" }, { key: "People", icon: "👋" },
        { key: "Nature", icon: "🌿" }, { key: "Food", icon: "🍔" }, { key: "Travel", icon: "✈️" },
        { key: "Activities", icon: "⚽" }, { key: "Objects", icon: "💡" }, { key: "Symbols", icon: "🔣" },
        { key: "Flags", icon: "🏁" }, { key: "Kaomoji", icon: "(◕‿◕)" }
    ]
    readonly property var emojiCats: categories.filter(c => !c.kaomoji)
    readonly property var kaomojiCats: categories.filter(c => c.kaomoji)
    readonly property var allEmoji: emojiCats.reduce((a, c) => a.concat(c.items), [])
    readonly property var allKaomoji: kaomojiCats.reduce((a, c) => a.concat(c.items), [])
    // Recently used, split so wide kaomoji don't land in the square emoji cells
    readonly property var recentEmoji: recent.map(t => allEmoji.find(x => x[0] === t)).filter(x => x)
    readonly property var recentKaomoji: recent.map(t => allKaomoji.find(x => x[0] === t)).filter(x => x)
    // Kaomoji chips: "Recent" first when there are some
    readonly property var kaomojiGroups: (recentKaomoji.length ? [{ name: "Recent", items: recentKaomoji }] : []).concat(kaomojiCats)

    readonly property var shown: {
        const q = query.trim().toLowerCase();
        if (q) {
            const pool = tab === "Kaomoji" ? allKaomoji : allEmoji;
            const words = q.split(/\s+/);
            // Whole-word matches first ("cat" → cat face before scatter), then shorter names
            return pool.filter(x => words.every(w => x[1].includes(w))).sort((a, b) => {
                const wa = words.every(w => new RegExp(`\\b${w}`).test(a[1])), wb = words.every(w => new RegExp(`\\b${w}`).test(b[1]));
                return wb - wa || a[1].length - b[1].length;
            });
        }
        if (tab === "Recent")
            return recentEmoji.length ? recentEmoji : (emojiCats[0]?.items ?? []);
        if (tab === "Kaomoji")
            return (kaomojiGroups.find(c => c.name === kaomojiGroup) ?? kaomojiGroups[0])?.items ?? [];
        return emojiCats.find(c => c.name === tab)?.items ?? [];
    }
    // Kaomoji are wide: three per row instead of square emoji cells
    readonly property bool wide: tab === "Kaomoji"
    readonly property int columns: wide ? 3 : Math.floor((grid.width - grid.padding * 2) / 48)

    kanji: "絵文字"

    title: "Emoji"
    subtitle: root.categories.length ? `${allEmoji.length} emoji · ${allKaomoji.length} kaomoji` : "Loading…"

    function pick(i) {
        const e = shown[i];
        if (!e)
            return;
        Quickshell.execDetached(["wl-copy", e[0]]);
        recent = [e[0]].concat(recent.filter(x => x !== e[0])).slice(0, 32);
        recentFile.setText(JSON.stringify(recent));
        Panels.close();
    }

    function move(step) {
        current = Math.max(0, Math.min(shown.length - 1, current + step));
    }

    function switchTab(step) {
        const i = tabs.findIndex(t => t.key === tab);
        tab = tabs[(i + step + tabs.length) % tabs.length].key;
    }

    onOpenChanged: {
        if (open) {
            search.text = "";
            tab = "Recent";
            kaomojiGroup = recentKaomoji.length ? "Recent" : "Happy";
            current = 0;
            Qt.callLater(() => search.forceActiveFocus());
        }
    }
    onQueryChanged: current = 0
    onTabChanged: current = 0
    onKaomojiGroupChanged: current = 0

    Process {
        running: true
        command: ["python3", "-I", Theme.scripts + "/emoji-list.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.categories = JSON.parse(text);
                } catch (e) {}
            }
        }
    }

    FileView {
        id: recentFile
        path: Quickshell.statePath("emoji-recent.json")
        printErrors: false
        onLoaded: {
            try {
                root.recent = JSON.parse(text());
            } catch (e) {}
        }
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
            Keys.onLeftPressed: root.move(-1)
            Keys.onRightPressed: root.move(1)
            Keys.onUpPressed: root.move(-root.columns)
            Keys.onDownPressed: root.move(root.columns)
            Keys.onTabPressed: root.switchTab(1)
            Keys.onBacktabPressed: root.switchTab(-1)
            onAccepted: root.pick(root.current)

            Label {
                visible: search.text === ""
                anchors.verticalCenter: parent.verticalCenter
                text: root.tab === "Kaomoji" ? "Search kaomoji: shrug, cat, table…" : "Search emoji: heart, cat, fire…"
                font.pixelSize: 15
                color: Theme.overlay0
            }
        }
    }

    // ── Category tabs ────────────────────────────────────

    Row {
        id: tabBar
        anchors.top: searchBox.bottom
        anchors.topMargin: 12
        anchors.left: root.header.left
        spacing: 4

        Repeater {
            model: root.tabs

            Rectangle {
                id: tabButton
                required property var modelData
                readonly property bool active: root.tab === modelData.key

                width: modelData.key === "Kaomoji" ? 64 : 44
                height: 36
                radius: Theme.radius
                color: active ? Qt.alpha(Theme.accent, 0.25) : tabMouse.containsMouse ? Qt.alpha(Theme.surface1, 0.5) : Qt.alpha(Theme.surface0, 0.4)

                Text {
                    anchors.centerIn: parent
                    text: tabButton.modelData.icon
                    font.family: tabButton.modelData.key === "Kaomoji" ? Theme.fontFamily : "Noto Color Emoji"
                    font.pixelSize: tabButton.modelData.key === "Kaomoji" ? 11 : 18
                    color: Theme.text
                }

                MouseArea {
                    id: tabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.tab = tabButton.modelData.key
                }

                Tooltip {
                    target: tabButton
                    hovered: tabMouse.containsMouse
                    text: tabButton.modelData.key
                }
            }
        }
    }

    // Kaomoji sub-categories, only on that tab
    Flow {
        id: chips
        visible: root.tab === "Kaomoji" && !root.query
        anchors.top: tabBar.bottom
        anchors.topMargin: visible ? 10 : 0
        anchors.left: root.header.left
        anchors.right: root.header.right
        height: visible ? implicitHeight : 0
        spacing: 6

        Repeater {
            model: root.kaomojiGroups

            Rectangle {
                id: chip
                required property var modelData
                readonly property bool active: root.kaomojiGroup === modelData.name

                width: chipLabel.implicitWidth + 20
                height: 26
                radius: 13
                color: active ? Qt.alpha(Theme.accent, 0.25) : chipMouse.containsMouse ? Qt.alpha(Theme.surface1, 0.5) : Qt.alpha(Theme.surface0, 0.4)

                Label {
                    id: chipLabel
                    anchors.centerIn: parent
                    text: chip.modelData.name
                    font.pixelSize: 11
                    color: chip.active ? Theme.accent : Theme.subtext0
                }

                MouseArea {
                    id: chipMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.kaomojiGroup = chip.modelData.name
                }
            }
        }
    }

    // ── Grid ─────────────────────────────────────────────

    Widget {
        id: grid
        blurSource: root.backdrop
        anchors.top: chips.bottom
        anchors.topMargin: 12
        anchors.left: root.header.left
        anchors.right: root.header.right
        height: 7 * 48 + padding * 2
        padding: 8

        Label {
            visible: root.shown.length === 0
            anchors.centerIn: parent
            text: !root.categories.length ? "Loading emoji…" : root.query ? `Nothing matches “${root.query}”` : "Nothing here yet"
            color: Theme.overlay1
        }

        GridView {
            id: view
            anchors.fill: parent
            clip: true
            cellWidth: width / root.columns
            cellHeight: 48
            model: root.shown
            currentIndex: root.current
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: 0
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)

            delegate: Item {
                id: cell
                required property var modelData
                required property int index
                readonly property bool active: index === root.current

                width: view.cellWidth
                height: view.cellHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: Theme.radius
                    color: cell.active ? Qt.alpha(Theme.accent, 0.25) : cellMouse.containsMouse ? Qt.alpha(Theme.surface1, 0.5) : "transparent"
                }

                Text {
                    anchors.centerIn: parent
                    width: parent.width - 8
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: cell.modelData[0]
                    // Emoji font for emoji; the bar font (with CJK fallback) for kaomoji
                    font.family: root.wide ? Theme.fontFamily : "Noto Color Emoji"
                    font.pixelSize: root.wide ? 14 : 26
                    color: Theme.text
                }

                MouseArea {
                    id: cellMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.current = cell.index
                    onClicked: root.pick(cell.index)
                }
            }
        }
    }
}
