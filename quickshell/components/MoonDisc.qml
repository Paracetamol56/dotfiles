import QtQuick
import qs.common

// The moon as seen tonight: dark disc, lit part (limb + terminator) and a halo.
// `moon` is an Astro.moon() result.
Canvas {
    id: root

    required property var moon

    implicitWidth: 60
    implicitHeight: 60

    onMoonChanged: requestPaint()
    onWidthChanged: requestPaint()

    function rgba(c, a) {
        return `rgba(${Math.round(c.r * 255)}, ${Math.round(c.g * 255)}, ${Math.round(c.b * 255)}, ${a ?? c.a})`;
    }

    // Lit part = the limb's half circle + the terminator, a half ellipse whose
    // width follows the phase (cos of the moon's age angle)
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const r = width / 2 - 4, cx = width / 2, cy = height / 2;
        const m = root.moon;
        const k = Math.cos(2 * Math.PI * m.age / 29.530588853);
        const side = m.waxing ? 1 : -1; // lit on the right while waxing (northern hemisphere)

        const halo = ctx.createRadialGradient(cx, cy, r * 0.8, cx, cy, r + 4);
        halo.addColorStop(0, rgba(Theme.lavender, 0.25 * m.illumination));
        halo.addColorStop(1, rgba(Theme.lavender, 0));
        ctx.fillStyle = halo;
        ctx.beginPath();
        ctx.arc(cx, cy, r + 4, 0, 2 * Math.PI);
        ctx.fill();

        ctx.fillStyle = rgba(Theme.surface0, 1);
        ctx.beginPath();
        ctx.arc(cx, cy, r, 0, 2 * Math.PI);
        ctx.fill();

        ctx.fillStyle = rgba(Theme.rosewater, 1);
        ctx.beginPath();
        for (let i = 0; i <= 32; i++) {
            const a = -Math.PI / 2 + Math.PI * i / 32;
            ctx.lineTo(cx + side * r * Math.cos(a), cy + r * Math.sin(a));
        }
        for (let i = 32; i >= 0; i--) {
            const a = -Math.PI / 2 + Math.PI * i / 32;
            ctx.lineTo(cx + side * r * k * Math.cos(a), cy + r * Math.sin(a));
        }
        ctx.closePath();
        ctx.fill();
    }
}
