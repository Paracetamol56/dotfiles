pragma Singleton

import QtQuick
import Quickshell

// Month calendar for the date tooltip, styled like waybar's:
// month in lavender, weekdays and ISO week numbers in subtext0, today in red
Singleton {
    function isoWeek(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        t.setUTCDate(t.getUTCDate() + 4 - (t.getUTCDay() || 7));
        return Math.ceil(((t - Date.UTC(t.getUTCFullYear(), 0, 1)) / 86400000 + 1) / 7);
    }

    function month(now) {
        const y = now.getFullYear(), m = now.getMonth(), today = now.getDate();
        const first = (new Date(y, m, 1).getDay() + 6) % 7; // Monday = 0
        const days = new Date(y, m + 1, 0).getDate();
        const cell = s => `<td align="right">&nbsp;${s}&nbsp;</td>`;
        const dim = s => cell(`<font color="${Theme.subtext0}">${s}</font>`);

        let html = `<table cellspacing="0" style="font-family:'${Theme.fontFamily}'">`;
        html += `<tr><td colspan="8" align="center"><b><font color="${Theme.lavender}">${Qt.formatDate(now, "MMMM yyyy")}</font></b></td></tr>`;
        html += "<tr>" + ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"].map(dim).join("") + dim("") + "</tr>";

        for (let day = 1 - first; day <= days; day += 7) {
            html += "<tr>";
            for (let i = 0; i < 7; i++) {
                const d = day + i;
                if (d < 1 || d > days)
                    html += cell("");
                else if (d === today)
                    html += cell(`<b><font color="${Theme.red}">${d}</font></b>`);
                else
                    html += cell(d);
            }
            html += dim(isoWeek(new Date(y, m, Math.max(1, day + 3)))) + "</tr>";
        }
        return html + "</table>";
    }
}
