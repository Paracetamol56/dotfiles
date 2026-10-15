import QtQuick
import qs.common
import qs.components
import qs.services

// VPN panel (NetworkManager): a switch per VPN connection, live status, and import.
// Opened from the shield icon next to Wi-Fi in the bar.
Modal {
    id: root

    name: "vpn"
    align: "right"
    cardWidth: 380
    cardHeight: list.y + list.height + 28

    kanji: "仮想網"

    actions: headerActions
    title: "VPN"
    subtitle: Vpn.activeConnection ? `Connected to ${Vpn.activeConnection.name}` : Vpn.connections.length ? "Not connected" : "No VPN set up yet"

    onOpenChanged: if (open) Vpn.refresh()

    function typeName(type) {
        return ({ wireguard: "WireGuard", openvpn: "OpenVPN", openconnect: "OpenConnect", vpnc: "Cisco VPNC", strongswan: "IPsec", l2tp: "L2TP", pptp: "PPTP" })[type] ?? type;
    }

    // Import, right of the subtitle
    Button {
        id: headerActions
        anchors.top: root.header.top
        anchors.topMargin: root.subtitleRow.y + (root.subtitleRow.height - height) / 2
        anchors.right: root.header.right
        icon: Icons.plus
        tooltip: "Import a WireGuard (.conf) or OpenVPN (.ovpn) configuration"
        onClicked: Vpn.importFile()
    }

    Widget {
        id: list
        blurSource: root.backdrop
        anchors.top: root.header.bottom
        anchors.topMargin: 24
        anchors.left: root.header.left
        anchors.right: root.header.right
        height: Math.max(content.implicitHeight, 70) + padding * 2
        padding: 8

        // Nothing configured: how to add one
        Label {
            visible: Vpn.connections.length === 0
            anchors.centerIn: parent
            width: parent.width - 20
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            elide: Text.ElideNone
            text: "Import a WireGuard .conf (or an OpenVPN .ovpn) with the + button"
            font.pixelSize: 11
            color: Theme.overlay1
        }

        Column {
            id: content
            width: parent.width
            spacing: 2

            Repeater {
                model: Vpn.connections

                Item {
                    id: row

                    required property var modelData
                    readonly property string pending: Vpn.pending[modelData.uuid] ?? ""
                    readonly property bool on: modelData.active

                    width: parent.width
                    height: 48

                    Label {
                        id: icon
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.on ? Icons.shieldCheck : Icons.shield
                        font.family: Icons.font
                        font.pixelSize: 18
                        color: row.on && row.modelData.state === "activated" ? Theme.green : Theme.subtext1
                    }

                    Column {
                        anchors.left: icon.right
                        anchors.leftMargin: 12
                        anchors.right: toggle.left
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter

                        Label {
                            width: parent.width
                            text: row.modelData.name
                            font.pixelSize: 12
                        }

                        Label {
                            width: parent.width
                            font.pixelSize: 10
                            color: row.on && row.modelData.state === "activated" ? Theme.green : Theme.overlay1
                            text: {
                                const type = root.typeName(row.modelData.type);
                                if (row.pending === "up" || row.modelData.state === "activating")
                                    return `${type} · Connecting…`;
                                if (row.pending === "down" || row.modelData.state === "deactivating")
                                    return `${type} · Disconnecting…`;
                                return `${type} · ${row.on ? "Connected" : "Off"}`;
                            }
                        }
                    }

                    Toggle {
                        id: toggle
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        checked: row.pending ? row.pending === "up" : row.on
                        opacity: row.pending ? 0.6 : 1
                        onToggled: if (!row.pending) Vpn.setActive(row.modelData, !row.on)
                    }
                }
            }

            // nmcli's error, e.g. a missing password or plugin
            Label {
                visible: Vpn.error !== ""
                width: parent.width
                leftPadding: 12
                rightPadding: 12
                topPadding: 6
                wrapMode: Text.WordWrap
                elide: Text.ElideNone
                text: Vpn.error
                font.pixelSize: 10
                color: Theme.red
            }
        }
    }
}
