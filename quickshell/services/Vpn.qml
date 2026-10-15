pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// VPN connections from NetworkManager (nmcli): WireGuard and plugin-based VPNs (OpenVPN…).
// Kept up to date by `nmcli monitor`, which prints a line on every network change.
Singleton {
    id: root

    // [{ name, uuid, type, active, state }] — type is "wireguard" or the plugin's name
    property var connections: []
    readonly property var activeConnection: connections.find(c => c.active && c.state === "activated") ?? null
    readonly property bool connected: activeConnection !== null
    // uuid → "up" / "down" while nmcli is working on it
    property var pending: ({})
    // Last error from nmcli, shown in the panel
    property string error: ""

    function refresh() {
        list.running = true;
    }

    // Splits an `nmcli -t` line on ":", keeping escaped "\:" (and "\\") inside fields
    function fields(line) {
        const out = [];
        let cur = "";
        for (let i = 0; i < line.length; i++) {
            if (line[i] === "\\" && i + 1 < line.length) {
                cur += line[++i];
            } else if (line[i] === ":") {
                out.push(cur);
                cur = "";
            } else {
                cur += line[i];
            }
        }
        out.push(cur);
        return out;
    }

    function setActive(connection, on) {
        error = "";
        pending = Object.assign({}, pending, { [connection.uuid]: on ? "up" : "down" });
        const proc = toggler.createObject(root, { uuid: connection.uuid, name: connection.name });
        proc.command = ["nmcli", "connection", on ? "up" : "down", "uuid", connection.uuid];
        proc.running = true;
    }

    // Import a WireGuard .conf or an OpenVPN .ovpn picked with a file dialog
    function importFile() {
        error = "";
        importer.running = true;
    }

    // Refresh shortly after changes settle, rather than once per monitor line
    Timer {
        id: debounce
        interval: 300
        onTriggered: root.refresh()
    }

    Process {
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser {
            onRead: debounce.restart()
        }
    }

    Component.onCompleted: refresh()

    // NAME:UUID:TYPE:ACTIVE:STATE, with ":" in names escaped as "\:"
    Process {
        id: list
        command: ["nmcli", "-t", "-f", "NAME,UUID,TYPE,ACTIVE,STATE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.connections = text.split("\n").filter(l => l).map(l => {
                    const f = root.fields(l);
                    return { name: f[0], uuid: f[1], type: f[2], active: f[3] === "yes", state: f[4] };
                }).filter(c => c.type === "vpn" || c.type === "wireguard");
                vpnTypes.running = root.connections.some(c => c.type === "vpn");
            }
        }
    }

    // Plugin VPNs only say "vpn": ask for the service type (openvpn, openconnect…)
    Process {
        id: vpnTypes
        command: ["sh", "-c", "nmcli -t -f connection.uuid,vpn.service-type connection show $(nmcli -t -f UUID,TYPE connection show | awk -F: '$2==\"vpn\"{print $1}') 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const types = {};
                let uuid = "";
                for (const l of text.split("\n")) {
                    const [k, v] = [l.slice(0, l.indexOf(":")), l.slice(l.indexOf(":") + 1)];
                    if (k === "connection.uuid")
                        uuid = v;
                    else if (k === "vpn.service-type" && uuid)
                        types[uuid] = v.split(".").pop();
                }
                root.connections = root.connections.map(c => c.type === "vpn" && types[c.uuid] ? Object.assign({}, c, { type: types[c.uuid] }) : c);
            }
        }
    }

    // One process per toggle, so several can run at once; reports nmcli's own error
    Component {
        id: toggler

        Process {
            property string uuid
            property string name

            stderr: StdioCollector {
                id: err
            }
            onExited: code => {
                const p = Object.assign({}, root.pending);
                delete p[uuid];
                root.pending = p;
                if (code !== 0)
                    root.error = `${name}: ${(err.text.trim().split("\n").pop() || "nmcli failed").replace(/^Error: /, "")}`;
                root.refresh();
                destroy();
            }
        }
    }

    // zenity picks the file; WireGuard needs nothing extra, OpenVPN needs its NM plugin
    Process {
        id: importer
        command: ["sh", "-c", `
            f=$(zenity --file-selection --title="Import a VPN configuration" --file-filter="VPN configs | *.conf *.ovpn" 2>/dev/null) || exit 0
            case "$f" in
              *.ovpn) [ -e /usr/lib/NetworkManager/VPN/nm-openvpn-service.name ] || { echo "OpenVPN needs the networkmanager-openvpn package" >&2; exit 1; }
                      nmcli connection import type openvpn file "$f" ;;
              *)      nmcli connection import type wireguard file "$f" ;;
            esac`]
        stderr: StdioCollector {
            id: importErr
        }
        onExited: code => {
            if (code !== 0)
                root.error = (importErr.text.trim().split("\n").pop() || "Import failed").replace(/^Error: /, "");
            root.refresh();
        }
    }
}
