import QtQuick
import Quickshell.Networking
import qs.common
import qs.components

// Wi-Fi panel (NetworkManager): power, nearby networks, Ethernet status.
// Click a network to connect / disconnect; secured networks you haven't joined before
// ask for the password inline. Hover a saved network to forget it.
Modal {
    id: root

    name: "network"
    align: "right"
    cardWidth: 380
    cardHeight: list.y + list.height + 28

    readonly property var wifi: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wired: Networking.devices.values.find(d => d.type === DeviceType.Wired && d.connected) ?? null
    readonly property bool powered: Networking.wifiEnabled
    // Connected first, then saved ones, then by signal; hidden networks have no name
    readonly property var networks: (wifi?.networks.values ?? []).filter(n => n.name).sort((a, b) => b.connected - a.connected || b.known - a.known || strength(b) - strength(a))
    readonly property var active: networks.find(n => n.connected) ?? null

    // The network whose password field is open, and the last error
    property var askingPassword: null
    property string error: ""

    kanji: "無線"

    actions: headerActions
    title: "Wi-Fi"
    subtitle: !powered ? "Off" : active ? `Connected to ${active.name}` : "Not connected"

    // Scan for networks while the panel is open
    onOpenChanged: {
        if (wifi)
            wifi.scannerEnabled = open;
        if (!open) {
            askingPassword = null;
            error = "";
        }
    }

    // signalStrength may be 0–1 or a percentage
    function strength(n) {
        const s = n.signalStrength ?? 0;
        return s > 1 ? s / 100 : s;
    }

    function signalIcon(n) {
        const s = strength(n);
        return s >= 0.75 ? Icons.wifi : s >= 0.5 ? Icons.wifiHigh : s >= 0.25 ? Icons.wifiLow : Icons.wifiZero;
    }

    function secured(n) {
        return n.security !== undefined && n.security !== WifiSecurityType.Open && n.security !== WifiSecurityType.Owe;
    }

    function activate(n) {
        error = "";
        if (n.connected)
            n.disconnect();
        else if (n.known || !secured(n))
            n.connect();
        else
            askingPassword = askingPassword === n ? null : n;
    }

    // Power, right of the subtitle
    Toggle {
        id: headerActions
        anchors.top: root.header.top
        anchors.topMargin: root.subtitleRow.y + (root.subtitleRow.height - height) / 2
        anchors.right: root.header.right
        checked: root.powered
        onToggled: Networking.wifiEnabled = !root.powered
    }

    Widget {
        id: list
        blurSource: root.backdrop
        anchors.top: root.header.bottom
        anchors.topMargin: 24
        anchors.left: root.header.left
        anchors.right: root.header.right
        height: Math.min(Math.max(content.implicitHeight, 60), 440) + padding * 2
        padding: 8

        Label {
            visible: !root.powered || root.networks.length === 0
            anchors.centerIn: parent
            text: !root.powered ? "Wi-Fi is off" : "Looking for networks…"
            color: Theme.overlay1
        }

        Flickable {
            anchors.fill: parent
            visible: root.powered || root.wired
            clip: true
            contentHeight: content.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: content
                width: parent.width
                spacing: 2

                // Ethernet, only when plugged in
                Item {
                    visible: root.wired !== null
                    width: parent.width
                    height: visible ? 44 : 0

                    Label {
                        id: ethIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: Icons.ethernetPort
                        font.family: Icons.font
                        font.pixelSize: 18
                        color: Theme.green
                    }

                    Column {
                        anchors.left: ethIcon.right
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter

                        Label {
                            text: "Ethernet"
                            font.pixelSize: 12
                        }

                        Label {
                            text: `Connected · ${root.wired?.name ?? ""}`
                            font.pixelSize: 10
                            color: Theme.green
                        }
                    }
                }

                Repeater {
                    model: root.powered ? root.networks : []
                    NetworkRow {}
                }
            }
        }
    }

    component NetworkRow: Column {
        id: row

        required property var modelData
        readonly property var net: modelData
        readonly property bool busy: net.state === ConnectionState.Connecting || net.state === ConnectionState.Disconnecting
        readonly property bool asking: root.askingPassword === net

        width: parent.width

        // Show why a connection failed, under this network
        Connections {
            target: row.net
            function onConnectionFailed(reason) {
                root.error = "Couldn't connect" + (reason ? ` (${reason})` : "");
                root.askingPassword = row.net.known ? null : row.net;
            }
        }

        Rectangle {
            width: parent.width
            height: 44
            radius: Theme.radius
            color: rowMouse.containsMouse || forgetMouse.containsMouse || row.asking ? Qt.alpha(Theme.surface1, 0.5) : "transparent"

            Behavior on color {
                ColorAnimation {
                    duration: Theme.animDuration
                }
            }

            Label {
                id: icon
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: root.signalIcon(row.net)
                font.family: Icons.font
                font.pixelSize: 18
                color: row.net.connected ? Theme.sapphire : Theme.subtext1
            }

            Column {
                anchors.left: icon.right
                anchors.leftMargin: 12
                anchors.right: trailing.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter

                Label {
                    width: parent.width
                    text: row.net.name
                    font.pixelSize: 12
                }

                Label {
                    width: parent.width
                    font.pixelSize: 10
                    color: row.net.connected ? Theme.sapphire : Theme.overlay1
                    text: {
                        const n = row.net;
                        if (n.state === ConnectionState.Connecting)
                            return "Connecting…";
                        if (n.state === ConnectionState.Disconnecting)
                            return "Disconnecting…";
                        if (n.connected)
                            return "Connected";
                        if (n.known)
                            return "Saved";
                        return root.secured(n) ? "Secured" : "Open";
                    }
                }
            }

            // Lock for secured networks; × to forget a saved one while hovered
            Row {
                id: trailing
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Label {
                    id: forget
                    visible: row.net.known && (rowMouse.containsMouse || forgetMouse.containsMouse) && !row.busy
                    text: Icons.x
                    font.family: Icons.font
                    font.pixelSize: 14
                    color: forgetMouse.containsMouse ? Theme.red : Theme.overlay1

                    MouseArea {
                        id: forgetMouse
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: row.net.forget()
                    }
                }

                Label {
                    visible: root.secured(row.net)
                    text: Icons.lock
                    font.family: Icons.font
                    font.pixelSize: 12
                    color: Theme.overlay0
                }
            }

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                z: -1
                hoverEnabled: true
                cursorShape: row.busy ? Qt.BusyCursor : Qt.PointingHandCursor
                onClicked: if (!row.busy) root.activate(row.net)
            }
        }

        // Password field for a secured network joined for the first time
        Item {
            visible: row.asking
            width: parent.width
            height: visible ? 74 : 0

            Rectangle {
                id: field
                anchors.left: parent.left
                anchors.right: connect.left
                anchors.leftMargin: 12
                anchors.rightMargin: 8
                y: 6
                height: 32
                radius: Theme.radius
                color: Qt.alpha(Theme.crust, 0.7)
                border.width: password.activeFocus ? 2 : 1
                border.color: password.activeFocus ? Theme.accent : Theme.surface1

                TextInput {
                    id: password
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    color: Theme.text
                    selectionColor: Theme.accent
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    clip: true

                    onVisibleChanged: {
                        if (visible) {
                            text = "";
                            forceActiveFocus();
                        }
                    }
                    onAccepted: connect.clicked()
                    Keys.onEscapePressed: root.askingPassword = null

                    Label {
                        visible: password.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Password"
                        color: Theme.overlay0
                        font.pixelSize: 12
                    }
                }
            }

            Button {
                id: connect
                anchors.right: parent.right
                anchors.rightMargin: 4
                y: 6
                height: 32
                icon: Icons.wifi
                text: "Join"
                filled: true
                enabled: password.text.length >= 8
                onClicked: {
                    if (!enabled)
                        return;
                    root.error = "";
                    row.net.connectWithPsk(password.text);
                    root.askingPassword = null;
                }
            }

            Label {
                anchors.left: field.left
                anchors.top: field.bottom
                anchors.topMargin: 6
                text: root.error || "WPA passwords are at least 8 characters"
                font.pixelSize: 10
                color: root.error ? Theme.red : Theme.overlay0
            }
        }
    }
}
