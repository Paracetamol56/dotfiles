pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam

// Session lock state (replaces hyprlock): `qs ipc call lock lock`, used by hypridle,
// SUPER+Escape (loginctl lock-session) and the power menu. panels/lock/LockScreen.qml draws
// it. The password is checked with PAM using hyprlock's config (/etc/pam.d/hyprlock → login),
// so the same rules apply, faillock included.
//
// If the lock screen ever breaks: switch to a TTY (Ctrl+Alt+F3), log in and run
//   hyprctl --instance 0 dispatch exec hyprlock
// hyprlock then takes over the lock (misc:allow_session_lock_restore is on) and unlocks normally.
Singleton {
    id: root

    property bool locked: false
    // Shared by every screen's password field
    property string password: ""
    property bool checking: false
    property string message: ""
    property bool failed: false

    function lock() {
        password = "";
        message = "";
        failed = false;
        locked = true;
    }

    // Starts a PAM conversation; the password is sent when PAM asks for it
    function submit() {
        if (checking || password === "")
            return;
        checking = true;
        failed = false;
        message = "";
        pam.start();
    }

    PamContext {
        id: pam
        config: "hyprlock"

        onResponseRequiredChanged: {
            if (responseRequired)
                respond(root.password);
        }
        onMessageChanged: {
            // PAM's own text, e.g. faillock's "account temporarily locked"
            if (message && !responseRequired)
                root.message = message;
        }
        onCompleted: result => {
            root.checking = false;
            if (result === PamResult.Success) {
                root.password = "";
                root.message = "";
                root.locked = false;
            } else {
                root.failed = true;
                root.password = "";
                if (!root.message)
                    root.message = "Wrong password";
            }
        }
        onError: error => {
            root.checking = false;
            root.failed = true;
            root.password = "";
            root.message = "Couldn't check the password";
        }
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            root.lock();
        }
    }
}
