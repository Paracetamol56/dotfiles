import QtQuick

// CSS `background-image: radial-gradient(color R, transparent R); background-size: S S`:
// one hard-edged dot of radius R in the centre of every S×S tile.
// `mask(x, y)` returns each dot's opacity (0–1), standing in for a CSS mask-image.
Canvas {
    id: root

    property color color: "white"
    property real dotRadius: 1
    property real spacing: 28
    property var mask: (x, y) => 1

    onColorChanged: requestPaint()
    onDotRadiusChanged: requestPaint()
    onSpacingChanged: requestPaint()
    onMaskChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.fillStyle = root.color;
        const s = root.spacing;
        for (let y = s / 2; y < height; y += s) {
            for (let x = s / 2; x < width; x += s) {
                const a = root.mask(x, y);
                if (a <= 0)
                    continue;
                ctx.globalAlpha = a;
                ctx.beginPath();
                ctx.arc(x, y, root.dotRadius, 0, 2 * Math.PI);
                ctx.fill();
            }
        }
    }
}
