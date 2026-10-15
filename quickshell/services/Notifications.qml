pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// The desktop's notification server (replaces dunst). Every notification is kept in the
// history (newest 50) and, unless Do Not Disturb is on, also shown as a popup. Critical ones
// pop up even in DND and stay until dismissed.
Singleton {
    id: root

    readonly property int historyLength: 50
    readonly property int popupTimeout: 5000
    readonly property int maxPopups: 4

    property bool dnd: false
    property int unread: 0
    // Notifications currently shown as popups, newest first
    property var popups: []
    // Arrival time by notification id (the protocol doesn't carry one)
    property var times: ({})

    // Newest first
    readonly property var history: server.trackedNotifications.values.slice().reverse()

    function isCritical(n) {
        return n.urgency === NotificationUrgency.Critical;
    }

    // A "value" hint (0–100) means a progress bar, e.g. keyboard brightness
    function progress(n) {
        const v = n.hints?.value;
        return v === undefined ? -1 : Math.max(0, Math.min(100, Number(v))) / 100;
    }

    // Popup lifetime: the app's own timeout if it gave one; critical ones stay
    function timeout(n) {
        if (isCritical(n))
            return 0;
        return n.expireTimeout > 0 ? n.expireTimeout : popupTimeout;
    }

    function hidePopup(n) {
        popups = popups.filter(p => p !== n);
    }

    function dismiss(n) {
        hidePopup(n);
        n.dismiss();
    }

    function clearAll() {
        popups = [];
        for (const n of server.trackedNotifications.values.slice())
            n.dismiss();
    }

    // The "default" action (clicking the notification), else the first one
    function invokeDefault(n) {
        const action = n.actions.find(a => a.identifier === "default") ?? n.actions[0];
        if (action)
            action.invoke();
        dismiss(n);
    }

    function toggleDnd() {
        dnd = !dnd;
        stateFile.setText(JSON.stringify({ dnd }));
    }

    function markRead() {
        unread = 0;
    }

    NotificationServer {
        id: server

        keepOnReload: true
        actionsSupported: true
        imageSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        persistenceSupported: true

        onNotification: n => {
            // Transient ones (OSD-style updates) only pop up, they don't go to the history
            n.tracked = !n.transient;
            root.times = Object.assign({}, root.times, { [n.id]: new Date() });
            n.closed.connect(() => root.hidePopup(n));

            if (!root.dnd || root.isCritical(n)) {
                // A notification replacing an earlier one (same id) takes its place
                root.popups = [n].concat(root.popups.filter(p => p !== n && p.id !== n.id)).slice(0, root.maxPopups);
            }
            if (n.tracked)
                root.unread++;

            // Keep the history to the newest 50
            const all = trackedNotifications.values;
            for (let i = 0; i < all.length - root.historyLength; i++)
                all[i].dismiss();
        }
    }

    // Do Not Disturb survives restarts
    FileView {
        id: stateFile
        path: Quickshell.statePath("notifications.json")
        printErrors: false
        onLoaded: {
            try {
                root.dnd = JSON.parse(text()).dnd ?? false;
            } catch (e) {}
        }
    }
}
