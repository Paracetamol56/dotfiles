import QtQuick
import Quickshell.Bluetooth
import qs.common
import qs.components

// Bluetooth panel: adapter power, scanning, paired and nearby devices.
// Click a device to connect / disconnect (or pair it); hover a paired one to forget it.
Modal {
    id: root

    name: "bluetooth"
    align: "right"
    cardWidth: 380
    cardHeight: list.y + list.height + 28

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property bool powered: adapter?.enabled ?? false
    readonly property var devices: Bluetooth.devices.values
    // Connected first, then paired, then nearby ones by name
    readonly property var paired: devices.filter(d => d.paired || d.connected).sort((a, b) => b.connected - a.connected || a.name.localeCompare(b.name))
    readonly property var nearby: devices.filter(d => !d.paired && !d.connected && d.name).sort((a, b) => a.name.localeCompare(b.name))
    readonly property int connectedCount: devices.filter(d => d.connected).length
    // Whether this panel started the scan, so it stops it when closing
    property bool scanning: false
    // Device being paired from here, connected as soon as pairing succeeds
    property BluetoothDevice pairing: null

    Connections {
        target: root.pairing
        function onPairedChanged() {
            if (root.pairing?.paired) {
                root.pairing.connect();
                root.pairing = null;
            }
        }
    }

    title: "Bluetooth"
    subtitle: !adapter ? "No adapter found" : !powered ? "Off" : adapter.discovering ? "Scanning for devices…" : connectedCount ? `${connectedCount} device${connectedCount > 1 ? "s" : ""} connected` : "No device connected"

    onOpenChanged: {
        if (!open && scanning && adapter) {
            adapter.discovering = false;
            scanning = false;
        }
    }

    function deviceIcon(name) {
        name = name ?? "";
        if (/headset|headphone/.test(name))
            return Icons.headphones;
        if (/speaker|audio-card/.test(name))
            return Icons.speaker;
        if (/mouse/.test(name))
            return Icons.mouse;
        if (/keyboard/.test(name))
            return Icons.keyboard;
        if (/gaming|joystick/.test(name))
            return Icons.gamepad2;
        if (/phone/.test(name))
            return Icons.smartphone;
        if (/watch/.test(name))
            return Icons.watch;
        if (/computer|laptop/.test(name))
            return Icons.laptop;
        if (/display|video/.test(name))
            return Icons.monitor;
        return Icons.bluetooth;
    }

    // Scan + power, top right next to the title
    Row {
        anchors.top: root.header.top
        anchors.right: root.header.right
        spacing: 10

        Button {
            anchors.verticalCenter: parent.verticalCenter
            icon: Icons.search
            checked: root.adapter?.discovering ?? false
            enabled: root.powered
            onClicked: {
                root.scanning = !root.adapter.discovering;
                root.adapter.discovering = root.scanning;
            }
        }

        Toggle {
            anchors.verticalCenter: parent.verticalCenter
            checked: root.powered
            onToggled: if (root.adapter) root.adapter.enabled = !root.powered
        }
    }

    Widget {
        id: list
        blurSource: root.backdrop
        anchors.top: root.header.bottom
        anchors.topMargin: 24
        anchors.left: root.header.left
        anchors.right: root.header.right
        height: Math.min(Math.max(content.implicitHeight, 60), 420) + padding * 2
        padding: 8

        Label {
            visible: !root.powered || root.devices.length === 0
            anchors.centerIn: parent
            text: !root.powered ? "Bluetooth is off" : "No devices yet, scan to find some"
            color: Theme.overlay1
        }

        Flickable {
            anchors.fill: parent
            visible: root.powered
            clip: true
            contentHeight: content.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: content
                width: parent.width
                spacing: 2

                SectionLabel {
                    visible: root.paired.length > 0
                    text: "Paired"
                }

                Repeater {
                    model: root.paired
                    DeviceRow {}
                }

                SectionLabel {
                    visible: root.nearby.length > 0
                    text: "Nearby"
                }

                Repeater {
                    model: root.nearby
                    DeviceRow {}
                }
            }
        }
    }

    component SectionLabel: Label {
        leftPadding: 10
        topPadding: 6
        bottomPadding: 4
        font.pixelSize: 10
        color: Theme.overlay1
    }

    component DeviceRow: Rectangle {
        id: row

        required property BluetoothDevice modelData
        readonly property bool busy: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting || modelData.pairing

        width: parent.width
        height: 44
        radius: Theme.radius
        color: rowMouse.containsMouse || forgetMouse.containsMouse ? Qt.alpha(Theme.surface1, 0.5) : "transparent"

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
            text: root.deviceIcon(row.modelData.icon)
            font.family: Icons.font
            font.pixelSize: 18
            color: row.modelData.connected ? Theme.blue : Theme.subtext1
        }

        Column {
            anchors.left: icon.right
            anchors.leftMargin: 12
            anchors.right: forget.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter

            Label {
                width: parent.width
                text: row.modelData.name || row.modelData.address
                font.pixelSize: 12
                color: Theme.text
            }

            Label {
                width: parent.width
                font.pixelSize: 10
                color: row.modelData.connected ? Theme.blue : Theme.overlay1
                text: {
                    const d = row.modelData;
                    if (d.pairing)
                        return "Pairing…";
                    if (d.state === BluetoothDeviceState.Connecting)
                        return "Connecting…";
                    if (d.state === BluetoothDeviceState.Disconnecting)
                        return "Disconnecting…";
                    if (d.connected)
                        return "Connected" + (d.batteryAvailable ? ` · ${Math.round(d.battery * 100)}%` : "");
                    return d.paired ? "Paired" : "Click to pair";
                }
            }
        }

        // Forget a paired device; only while hovered
        Label {
            id: forget
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            visible: row.modelData.paired && (rowMouse.containsMouse || forgetMouse.containsMouse) && !row.busy
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
                onClicked: row.modelData.forget()
            }
        }

        MouseArea {
            id: rowMouse
            anchors.fill: parent
            z: -1
            hoverEnabled: true
            cursorShape: row.busy ? Qt.BusyCursor : Qt.PointingHandCursor
            onClicked: {
                const d = row.modelData;
                if (row.busy)
                    return;
                if (d.connected)
                    d.disconnect();
                else if (d.paired)
                    d.connect();
                else {
                    // New device: trust it so it reconnects later, pair, then connect once paired
                    d.trusted = true;
                    root.pairing = d;
                    d.pair();
                }
            }
        }
    }
}
