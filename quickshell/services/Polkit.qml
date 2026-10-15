pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Polkit

// The session's polkit agent: when an app needs admin rights (mounting a drive, pkexec,
// installers…), panels/polkit/PolkitPopup.qml asks for the password while `active`.
Singleton {
    id: root

    readonly property var flow: agent.flow
    readonly property bool active: agent.isActive
    readonly property bool registered: agent.isRegistered

    PolkitAgent {
        id: agent
    }
}
