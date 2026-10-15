import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.common
import qs.components
import qs.services
import "../../lib/MathEval.js" as MathEval

// App launcher, centred on the screen. Opened from the rocket in the bar or SUPER + R.
// Left: apps (most launched first when empty), a maths result, and fallbacks to run the text
// as a command or search the web. Right: recent files. ↑/↓ move, Tab switches column,
// Enter or click opens. "> cmd" runs a command in a terminal.
Modal {
    id: root

    name: "launcher"
    align: "middle"
    cardWidth: 880
    cardHeight: results.y + results.height + 28

    property string query: ""
    // Selected row in each column, and which column has the keyboard (0 = apps, 1 = files)
    property int current: 0
    property int currentFile: 0
    property int column: 0
    // Launch counts by desktop entry id, kept between sessions
    property var usage: ({})
    // Commands on $PATH, for the "run in terminal" fallback
    property var executables: ({})
    // [{ path, name, mime, modified }] newest first, only files that still exist
    property var recentFiles: []

    readonly property string trimmed: query.trim()
    // "> htop": explicit command
    readonly property bool commandMode: trimmed.startsWith(">")
    readonly property string command: commandMode ? trimmed.slice(1).trim() : trimmed

    readonly property var calc: {
        if (commandMode)
            return "";
        const r = MathEval.evaluate(trimmed.replace(/^=\s*/, ""));
        return r && r.isCalculation ? MathEval.format(r.value) : "";
    }

    // A web address typed directly: opened as-is rather than searched
    readonly property string url: commandMode ? "" : toUrl(trimmed)

    readonly property var apps: DesktopEntries.applications.values.filter(e => !e.noDisplay)
    readonly property var matches: {
        const q = trimmed.toLowerCase();
        if (commandMode)
            return [];
        if (!q)
            return apps.slice().sort((a, b) => (usage[b.id] ?? 0) - (usage[a.id] ?? 0) || a.name.localeCompare(b.name));
        // Ties: most launched, then the shorter name (the app itself over long utility names)
        return apps.map(e => ({ e, s: score(e, q) })).filter(x => x.s > 0).sort((a, b) => b.s - a.s || (usage[b.e.id] ?? 0) - (usage[a.e.id] ?? 0) || a.e.name.length - b.e.name.length || a.e.name.localeCompare(b.e.name)).map(x => x.e);
    }

    // Left column rows: calculation, apps, then the fallbacks
    readonly property var rows: {
        if (commandMode)
            return command ? [{ run: command }] : [];
        if (!trimmed)
            return matches.map(e => ({ entry: e }));
        const firstWord = trimmed.split(/\s+/)[0];
        const runRow = firstWord in executables ? [{ run: trimmed }] : [];
        // An address goes first, and replaces the web search
        if (url)
            return [{ url }].concat(matches.map(e => ({ entry: e })), runRow);
        const webRow = [{ web: trimmed }];
        const head = calc ? [{ calc }] : [];
        // Nothing matched: the fallbacks come first
        if (matches.length === 0)
            return head.concat(runRow, webRow);
        return head.concat(matches.map(e => ({ entry: e })), runRow, webRow);
    }

    readonly property var files: {
        const q = trimmed.toLowerCase();
        const list = q && !commandMode ? recentFiles.filter(f => f.name.toLowerCase().includes(q)) : recentFiles;
        return list.slice(0, 30);
    }

    kanji: "アプリ"

    title: "Applications"
    subtitle: `${apps.length} apps · maths · "> cmd" runs a command · Tab: recent files`

    // "github.com/x" → "https://github.com/x". Bare domains only count with a common ending, so
    // file names like notes.md or photo.png aren't taken for websites. localhost / IPs use http.
    function toUrl(text) {
        if (/^https?:\/\/\S+$/i.test(text))
            return text;
        if (/\s/.test(text))
            return "";
        const local = /^(localhost|\d{1,3}(\.\d{1,3}){3})(:\d+)?(\/\S*)?$/i;
        if (local.test(text))
            return "http://" + text;
        const domain = /^([a-z0-9-]+\.)+(com|org|net|io|dev|app|ai|co|me|fr|de|uk|eu|be|ch|nl|es|it|ca|us|jp|gg|tv|xyz|info|edu|gov|sh|so|rs|wiki|page|site|tech|fm|ly|to|cc)(:\d+)?(\/\S*)?$/i;
        return domain.test(text) ? "https://" + text : "";
    }

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
        } else if (row.run) {
            // --hold keeps the window open so the output can be read
            Quickshell.execDetached(["kitty", "--hold", "sh", "-c", row.run]);
        } else if (row.url) {
            Quickshell.execDetached(["xdg-open", row.url]);
        } else if (row.web) {
            // DuckDuckGo, so bangs work: !g, !w, !aur, !gh…
            Quickshell.execDetached(["xdg-open", "https://duckduckgo.com/?q=" + encodeURIComponent(row.web)]);
        } else {
            const e = row.entry;
            if (e.runInTerminal)
                Quickshell.execDetached(["kitty", "-e", "sh", "-c", e.execString.replace(/%[fFuUdDnNickvm]/g, "")]);
            else
                e.execute();
            // A new object, so the ordering bindings notice the change
            usage = Object.assign({}, usage, { [e.id]: (usage[e.id] ?? 0) + 1 });
            usageFile.setText(JSON.stringify(usage));
        }
        Panels.close();
    }

    function openFile(i) {
        const f = files[i];
        if (!f)
            return;
        Quickshell.execDetached(["xdg-open", f.path]);
        Panels.close();
    }

    function activate() {
        column === 0 ? launch(current) : openFile(currentFile);
    }

    function move(step) {
        if (column === 0)
            current = Math.max(0, Math.min(rows.length - 1, current + step));
        else
            currentFile = Math.max(0, Math.min(files.length - 1, currentFile + step));
    }

    function fileIcon(mime) {
        if (/^image\//.test(mime))
            return Icons.fileImage;
        if (/^video\//.test(mime))
            return Icons.fileVideo;
        if (/^audio\//.test(mime))
            return Icons.fileAudio;
        if (/zip|tar|compressed|archive|7z|rar/.test(mime))
            return Icons.fileArchive;
        if (/^text\/|json|xml|javascript|x-shellscript|x-python/.test(mime))
            return Icons.fileCode;
        if (/pdf|document|opendocument|msword/.test(mime))
            return Icons.fileText;
        return Icons.file;
    }

    function ago(date) {
        const s = (Date.now() - date) / 1000;
        if (s < 3600)
            return `${Math.max(1, Math.round(s / 60))} min ago`;
        if (s < 86400)
            return `${Math.round(s / 3600)} h ago`;
        if (s < 86400 * 30)
            return `${Math.round(s / 86400)} d ago`;
        return Qt.formatDate(date, "d MMM yyyy");
    }

    onOpenChanged: {
        if (open) {
            search.text = "";
            current = 0;
            currentFile = 0;
            column = 0;
            recentList.reload();
            // After the modal's own focus item has taken focus
            Qt.callLater(() => search.forceActiveFocus());
        }
    }
    onQueryChanged: {
        current = 0;
        currentFile = 0;
    }

    FileView {
        id: usageFile
        path: Quickshell.statePath("launcher-usage.json")
        printErrors: false
        onLoaded: {
            try {
                root.usage = JSON.parse(text());
            } catch (e) {}
        }
    }

    // Every command on $PATH, once at startup
    Process {
        running: true
        command: ["bash", "-c", "compgen -c | sort -u"]
        stdout: StdioCollector {
            onStreamFinished: {
                const set = {};
                for (const c of text.split("\n"))
                    if (c)
                        set[c] = true;
                root.executables = set;
            }
        }
    }

    // GTK's recent files list, newest first, then filtered to files that still exist
    FileView {
        id: recentList
        path: Quickshell.env("HOME") + "/.local/share/recently-used.xbel"
        printErrors: false
        onLoaded: {
            const entries = [];
            const re = /<bookmark href="file:\/\/([^"]+)"[^>]*modified="([^"]+)"[\s\S]*?<mime:mime-type type="([^"]+)"/g;
            let m;
            while ((m = re.exec(text())) !== null) {
                const path = decodeURIComponent(m[1]);
                entries.push({ path, name: path.split("/").pop(), modified: new Date(m[2]), mime: m[3] });
            }
            entries.sort((a, b) => b.modified - a.modified);
            const latest = entries.slice(0, 120);
            root.pendingFiles = latest;
            existCheck.command = ["sh", "-c", 'for f; do [ -e "$f" ] && echo "$f"; done', "sh"].concat(latest.map(f => f.path));
            existCheck.running = true;
        }
    }

    property var pendingFiles: []

    Process {
        id: existCheck
        stdout: StdioCollector {
            onStreamFinished: {
                const present = {};
                for (const p of text.split("\n"))
                    present[p] = true;
                root.recentFiles = root.pendingFiles.filter(f => present[f.path]);
            }
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
        border.width: search.activeFocus ? 2 : 1
        border.color: search.activeFocus ? Qt.alpha(Theme.accent, 0.7) : Theme.surface0

        Label {
            id: searchIcon
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: root.commandMode ? Icons.squareTerminal : Icons.search
            font.family: Icons.font
            font.pixelSize: 16
            color: root.commandMode ? Theme.green : Theme.accent
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
            Keys.onUpPressed: root.move(-1)
            Keys.onDownPressed: root.move(1)
            Keys.onTabPressed: root.column = root.files.length ? 1 - root.column : 0
            Keys.onBacktabPressed: root.column = root.files.length ? 1 - root.column : 0
            onAccepted: root.activate()

            Label {
                visible: search.text === ""
                anchors.verticalCenter: parent.verticalCenter
                text: "Search apps and files, 2^10 / 3, > htop…"
                font.pixelSize: 15
                color: Theme.overlay0
            }
        }
    }

    // ── Apps ─────────────────────────────────────────────

    Widget {
        id: results
        blurSource: root.backdrop
        anchors.top: searchBox.bottom
        anchors.topMargin: 12
        anchors.left: root.header.left
        width: 520
        height: 8 * 48 + padding * 2
        padding: 6

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
                readonly property bool active: index === root.current && root.column === 0
                readonly property bool isEntry: !!modelData.entry

                width: ListView.view.width
                height: 48
                radius: Theme.radius
                color: active ? Qt.alpha(Theme.accent, 0.18) : index === root.current ? Qt.alpha(Theme.surface1, 0.35) : "transparent"

                // App icon, or a Lucide icon for the special rows
                IconImage {
                    id: appIcon
                    visible: row.isEntry
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    implicitSize: 30
                    source: row.isEntry ? Quickshell.iconPath(row.modelData.entry.icon ?? "", "application-x-executable") : ""
                }

                Label {
                    visible: !row.isEntry
                    anchors.centerIn: appIcon
                    text: row.modelData.calc ? "=" : row.modelData.run ? Icons.squareTerminal : row.modelData.url ? Icons.externalLink : Icons.globe
                    font.family: row.modelData.calc ? Theme.fontFamily : Icons.font
                    font.pixelSize: row.modelData.calc ? 22 : 20
                    font.weight: Font.Bold
                    color: row.modelData.calc ? Theme.accent : row.modelData.run ? Theme.green : Theme.blue
                }

                Column {
                    anchors.left: appIcon.right
                    anchors.leftMargin: 12
                    anchors.right: hint.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter

                    Label {
                        width: parent.width
                        text: {
                            const r = row.modelData;
                            if (r.calc)
                                return r.calc;
                            if (r.run)
                                return r.run;
                            if (r.url)
                                return `Open ${r.url.replace(/^https?:\/\//, "")}`;
                            if (r.web)
                                return `Search the web for “${r.web}”`;
                            return r.entry.name;
                        }
                        font.pixelSize: row.modelData.calc ? 18 : 13
                        font.weight: row.modelData.calc ? Font.Bold : Font.Normal
                        color: Theme.text
                    }

                    Label {
                        width: parent.width
                        visible: text !== ""
                        text: {
                            const r = row.modelData;
                            if (r.run)
                                return "Run in a terminal";
                            if (r.url)
                                return r.url;
                            if (r.web)
                                return "DuckDuckGo · bangs like !g !w !aur work";
                            return r.entry?.comment || r.entry?.genericName || "";
                        }
                        font.pixelSize: 10
                        color: Theme.overlay1
                    }
                }

                Label {
                    id: hint
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    visible: row.modelData.calc !== undefined
                    text: "Enter to copy"
                    font.pixelSize: 10
                    color: Theme.overlay1
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: {
                        root.column = 0;
                        root.current = row.index;
                    }
                    onClicked: root.launch(row.index)
                }
            }
        }
    }

    // ── Recent files ─────────────────────────────────────

    Widget {
        id: recent
        blurSource: root.backdrop
        anchors.top: results.top
        anchors.left: results.right
        anchors.leftMargin: 16
        anchors.right: root.header.right
        height: results.height
        padding: 6

        Row {
            id: recentTitle
            x: 8
            y: 4
            spacing: 8

            Label {
                text: Icons.fileClock
                font.family: Icons.font
                font.pixelSize: 13
                color: root.column === 1 ? Theme.accent : Theme.peach
            }

            Label {
                text: "Recent files"
                font.pixelSize: 11
                font.weight: Font.Bold
                color: Theme.subtext1
            }
        }

        Label {
            visible: root.files.length === 0
            anchors.centerIn: parent
            text: root.trimmed ? "No recent file matches" : "No recent files"
            font.pixelSize: 11
            color: Theme.overlay1
        }

        ListView {
            anchors.top: recentTitle.bottom
            anchors.topMargin: 8
            anchors.bottom: parent.bottom
            width: parent.width
            clip: true
            model: root.files
            currentIndex: root.currentFile
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: 0
            onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

            delegate: Rectangle {
                id: fileRow

                required property var modelData
                required property int index
                readonly property bool active: index === root.currentFile && root.column === 1

                width: ListView.view.width
                height: 40
                radius: Theme.radius
                color: active ? Qt.alpha(Theme.accent, 0.18) : fileMouse.containsMouse ? Qt.alpha(Theme.surface1, 0.35) : "transparent"

                Label {
                    id: fileIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.fileIcon(fileRow.modelData.mime)
                    font.family: Icons.font
                    font.pixelSize: 16
                    color: Theme.peach
                }

                Column {
                    anchors.left: fileIcon.right
                    anchors.leftMargin: 10
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter

                    Label {
                        width: parent.width
                        text: fileRow.modelData.name
                        font.pixelSize: 12
                    }

                    Label {
                        width: parent.width
                        text: root.ago(fileRow.modelData.modified) + " · " + fileRow.modelData.path.replace(Quickshell.env("HOME"), "~").replace(/\/[^/]+$/, "")
                        font.pixelSize: 9
                        color: Theme.overlay1
                        elide: Text.ElideMiddle
                    }
                }

                MouseArea {
                    id: fileMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: {
                        root.column = 1;
                        root.currentFile = fileRow.index;
                    }
                    onClicked: root.openFile(fileRow.index)
                }
            }
        }
    }
}
