import QtQuick
import Quickshell.Wayland
import qs.services

// The session lock itself: locks while Lock.locked is true, with a LockSurface on every screen
WlSessionLock {
    locked: Lock.locked

    surface: Component {
        WlSessionLockSurface {
            LockSurface {
                anchors.fill: parent
            }
        }
    }
}
