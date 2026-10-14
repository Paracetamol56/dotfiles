import QtQuick
import "../bar"

// Line graph of recent samples, newest on the right. Each series: { values, color }.
// `max` 0 = scale to the largest value shown. `mirror`: the first series grows up from a
// centre line and the second grows down from it, on the same scale.
Canvas {
    id: root

    property var series: []
    property real max: 1
    property int length: 60
    property bool mirror: false

    onSeriesChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    function rgba(c, a) {
        return `rgba(${Math.round(c.r * 255)}, ${Math.round(c.g * 255)}, ${Math.round(c.b * 255)}, ${a})`;
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const w = width, h = height;
        // (no Array.flatMap in QML's JS engine)
        const top = max > 0 ? max : series.reduce((m, s) => Math.max(m, ...s.values), 1) * 1.15;

        // Baseline: the bottom, or the centre line when mirrored
        const base = mirror ? Math.round(h / 2) : h;
        const room = mirror ? h / 2 - 1 : h - 2;

        // Faint guides at 1/4, 1/2 and 3/4 (the mirror's centre line a bit stronger)
        ctx.lineWidth = 1;
        for (const f of [0.25, 0.5, 0.75]) {
            ctx.strokeStyle = rgba(mirror && f === 0.5 ? Theme.overlay0 : Theme.surface1, 0.5);
            ctx.beginPath();
            ctx.moveTo(0, Math.round(h * f) + 0.5);
            ctx.lineTo(w, Math.round(h * f) + 0.5);
            ctx.stroke();
        }

        series.forEach((s, n) => {
            const v = s.values;
            if (v.length < 2)
                return;
            // Mirrored: the second series goes down
            const dir = mirror && n === 1 ? -1 : 1;
            const X = i => w - (v.length - 1 - i) / (length - 1) * w;
            const Y = x => base - dir * Math.min(1, x / top) * room;

            ctx.beginPath();
            v.forEach((x, i) => i ? ctx.lineTo(X(i), Y(x)) : ctx.moveTo(X(i), Y(x)));
            ctx.lineTo(X(v.length - 1), base);
            ctx.lineTo(X(0), base);
            ctx.closePath();
            // Strongest at the peak, fading towards the baseline
            const fill = ctx.createLinearGradient(0, base - dir * room, 0, base);
            fill.addColorStop(0, rgba(s.color, 0.35));
            fill.addColorStop(1, rgba(s.color, 0.02));
            ctx.fillStyle = fill;
            ctx.fill();

            ctx.beginPath();
            v.forEach((x, i) => i ? ctx.lineTo(X(i), Y(x)) : ctx.moveTo(X(i), Y(x)));
            ctx.strokeStyle = rgba(s.color, 1);
            ctx.lineWidth = 1.5;
            ctx.stroke();
        });
    }
}
