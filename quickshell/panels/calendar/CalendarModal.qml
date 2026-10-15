import QtQuick
import Quickshell
import qs.common
import qs.components
import "../../lib/CalendarUtil.js" as Cal

// Calendar: a month grid. Opened from the date in the bar.
Modal {
    id: root

    name: "calendar"
    cardWidth: 520
    cardHeight: grid.y + grid.height + 28

    readonly property date today: clock.date

    kanji: "暦"

    title: Qt.formatDate(today, "dddd d ") + `<font color="${Theme.accent}">${Qt.formatDate(today, "MMMM")}</font>`
    subtitle: {
        const y = today.getFullYear(), doy = Cal.dayOfYear(today), total = Cal.daysInYear(y);
        return `Week ${Cal.isoWeek(today)} · day ${doy} of ${total} · ${total - doy} days left in ${y}`;
    }

    // Each time it opens, start again from the current month
    onOpenChanged: if (open) grid.month = today

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    MonthGrid {
        id: grid
        blurSource: root.backdrop
        anchors.top: root.header.bottom
        anchors.topMargin: 24
        anchors.left: root.header.left
        anchors.right: root.header.right
        height: 312
        today: root.today
    }
}
