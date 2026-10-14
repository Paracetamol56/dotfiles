import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../bar"
import "MathEval.js" as MathEval

// App launcher, centred on the screen. Opened from the rocket in the bar or SUPER + R.
// Type to filter apps (most launched first when empty); ↑/↓ + Enter or click to launch.
// A maths expression shows its result as the first row; Enter copies it.
Modal {
    id: root

    name: "launcher"
    align: "middle"
    cardWidth: 560
    cardHeight: results.y + results.height + 28

    property string query: ""
    property int current: 0
    // Launch counts by desktop entry id, kept between sessions
    property var usage: ({})

    readonly property var calc: {
        const r = MathEval.evaluate(query.replace(/^=\s*/, ""));
        return r && r.isCalculation ? MathEval.format(r.value) : "";
    }

    readonly property var apps: DesktopEntries.applications.values.filter(e => !e.noDisplay)
    readonly property var matches: {
        const q = query.trim().toLowerCase();
        if (!q)
            return apps.slice().sort((a, b) => (usage[b.id] ?? 0) - (usage[a.id] ?? 0) || a.name.localeCompare(b.name));
        // Ties: most launched, then the shorter name (the app itself over long utility names)
        return apps.map(e => ({ e, s: score(e, q) })).filter(x => x.s > 0).sort((a, b) => b.s - a.s || (usage[b.e.id] ?? 0) - (usage[a.e.id] ?? 0) || a.e.name.length - b.e.name.length || a.e.name.localeCompare(b.e.name)).map(x => x.e);
    }
    // Result rows: the calculation (if any) first, then apps
    readonly property var rows: (calc ? [{ calc }] : []).concat(matches.map(e => ({ entry: e })))

    title: "Applications"
    subtitle: `${apps.length} apps · type to search, or do some maths`

    // Name start > word start > anywhere in name > generic name / keywords > letters in order
    function score(e, q) {
        const name = e.name.toLowerCase();
        if (name.startsWith(q))
            return 100;
        if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q)))
            return 80;
        if (name.includes(q))
            return 60;
        const extra = `${e.genericName} ${e.keywords} ${e.id}`.toLowerCase();
        if (extra.includes(q))
            return 40;
        let i = 0;
        for (const ch of name)
            if (ch === q[i])
                i++;
        return i === q.length ? 20 : 0;
    }

    function launch(i) {
        const row = rows[i];
        if (!row)
            return;
        if (row.calc) {
            Quickshell.execDetached(["wl-copy", row.calc]);
        } else {
            const e = row.entry;
            if (e.runInTerminal)
                Quickshell.execDetached(["kitty", "-e", "sh", "-c", e.execString.replace(/%[fFuUdDnNickvm]/g, "")]);
            else
                e.execute();
            // A new object, so the ordering bindings notice the change
            root.usage = Object.assign({}, root.usage, { [e.id]: (root.usage[e.id] ?? 0) + 1 });
            usageFile.setText(JSON.stringify(root.usage));
        }
        Panels.close();
    }

    onOpenChanged: {
        if (open) {
            search.text = "";
            current = 0;
            // After the modal's own focus item has taken focus
            Qt.callLater(() => search.forceActiveFocus());
        }
    }
    onQueryChanged: current = 0

    FileView {
        id: usageFile
        path: Quickshell.statePath("launcher-usage.json")
        onLoaded: {
            try {
                root.usage = JSON.parse(text());
            } catch (e) {}
        }
    }

    // ── Search box ───────────────────────────────────────

    Rectangle {
        id: searchBox
        anchors.top: root.header.bottom
        anchors.topMargin: 20
        anchors.left: root.header.left
        anchors.right: root.header.right
        height: 44
        radius: Theme.radius
        color: Qt.alpha(Theme.crust, 0.6)
        border.width: 1
        border.color: search.activeFocus ? Qt.alpha(Theme.mauve, 0.7) : Theme.surface0

        Label {
            id: searchIcon
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: Icons.search
            font.family: Icons.font
            font.pixelSize: 16
            color: Theme.mauve
        }

        TextInput {
            id: search
            anchors.left: searchIcon.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.text
            selectionColor: Theme.mauve
            font.family: Theme.fontFamily
            font.pixelSize: 15
            clip: true
            onTextChanged: root.query = text

            Keys.onEscapePressed: Panels.close()
            Keys.onUpPressed: root.current = Math.max(0, root.current - 1)
            Keys.onDownPressed: root.current = Math.min(root.rows.length - 1, root.current + 1)
            Keys.onTabPressed: root.current = Math.min(root.rows.length - 1, root.current + 1)
            onAccepted: root.launch(root.current)

            Label {
                visible: search.text === ""
                anchors.verticalCenter: parent.verticalCenter
                text: "Search apps, or type 2^10 / 3…"
                font.pixelSize: 15
                color: Theme.overlay0
            }
        }
    }

    // ── Results ──────────────────────────────────────────

    Widget {
        id: results
        blurSource: root.backdrop
        anchors.top: searchBox.bottom
        anchors.topMargin: 12
        anchors.left: root.header.left
        anchors.right: root.header.right
        height: 8 * 48 + padding * 2
        padding: 6

        Label {
            visible: root.rows.length === 0
            anchors.centerIn: parent
            text: `Nothing matches “${root.query}”`
            color: Theme.overlay1
        }

        ListView {
            id: list
            anchors.fill: parent
            clip: true
            model: root.rows
            currentIndex: root.current
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: 0
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

            delegate: Rectangle {
                id: row

                required property var modelData
                required property int index
                readonly property bool active: index === root.current

                width: ListView.view.width
                height: 48
                radius: Theme.radius
                color: active ? Qt.alpha(Theme.mauve, 0.18) : "transparent"
                border.width: active ? 1 : 0
                border.color: Qt.alpha(Theme.mauve, 0.5)

                // Calculation result
                Item {
                    visible: !!row.modelData.calc
                    anchors.fill: parent

                    Label {
                        id: equals
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: "="
                        font.pixelSize: 22
                        font.weight: Font.Bold
                        color: Theme.mauve
                    }

                    Label {
                        anchors.left: equals.right
                        anchors.leftMargin: 14
                        anchors.right: copyHint.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.calc ?? ""
                        font.pixelSize: 18
                        font.weight: Font.Bold
                    }

                    Label {
                        id: copyHint
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Enter to copy"
                        font.pixelSize: 10
                        color: Theme.overlay1
                    }
                }

                // App
                Item {
                    visible: !!row.modelData.entry
                    anchors.fill: parent

                    IconImage {
                        id: icon
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        implicitSize: 30
                        source: Quickshell.iconPath(row.modelData.entry?.icon ?? "", "application-x-executable")
                    }

                    Column {
                        anchors.left: icon.right
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter

                        Label {
                            width: parent.width
                            text: row.modelData.entry?.name ?? ""
                            font.pixelSize: 13
                            color: Theme.text
                        }

                        Label {
                            width: parent.width
                            visible: text !== ""
                            text: row.modelData.entry?.comment || row.modelData.entry?.genericName || ""
                            font.pixelSize: 10
                            color: Theme.overlay1
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.current = row.index
                    onClicked: root.launch(row.index)
                }
            }
        }
    }
}
