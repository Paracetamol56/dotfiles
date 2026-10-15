import QtQuick
import Quickshell.Io
import qs.common
import qs.components

// What's playing, in time and frequency: the waveform on top, and its Fourier
// decomposition below (48 log-spaced bands, 40 Hz – 16 kHz, -70..0 dB).
// Data comes from scripts/spectrum.py, which only runs while `running` is true.
Widget {
    id: root

    property bool running: false

    property var wave: []
    // Displayed levels: rise instantly, fall back slowly, so the bars don't flicker
    property var levels: []
    property var peaks: []
    readonly property bool silent: levels.every(v => v < 0.02)

    // Frequency axis: where a frequency sits on the log scale (0..1)
    function freqX(f) {
        return Math.log(f / 40) / Math.log(16000 / 40);
    }

    Process {
        running: root.running
        command: ["python3", "-I", Theme.scripts + "/spectrum.py"]
        stdout: SplitParser {
            onRead: line => {
                const parts = line.split(" ");
                if (parts[0] !== "w" || parts[2] !== "s")
                    return;
                root.wave = parts[1].split(",").map(Number);
                const next = parts[3].split(",").map(Number);
                root.levels = next.map((v, i) => Math.max(v, (root.levels[i] ?? 0) * 0.82));
                root.peaks = root.levels.map((v, i) => Math.max(v, (root.peaks[i] ?? 0) - 0.012));
                canvas.requestPaint();
            }
        }
    }

    onRunningChanged: {
        if (!running) {
            wave = [];
            levels = [];
            peaks = [];
            canvas.requestPaint();
        }
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        anchors.bottomMargin: 14

        function rgba(c, a) {
            return `rgba(${Math.round(c.r * 255)}, ${Math.round(c.g * 255)}, ${Math.round(c.b * 255)}, ${a})`;
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const w = width, h = height;
            const waveH = Math.round(h * 0.32), gap = 8, specTop = waveH + gap, specH = h - specTop;

            // ── Waveform ──
            ctx.strokeStyle = rgba(Theme.surface2, 0.6);
            ctx.lineWidth = 1;
            ctx.beginPath();
            ctx.moveTo(0, waveH / 2 + 0.5);
            ctx.lineTo(w, waveH / 2 + 0.5);
            ctx.stroke();

            const wave = root.wave;
            if (wave.length) {
                ctx.strokeStyle = rgba(Theme.lavender, 0.9);
                ctx.lineWidth = 1.5;
                ctx.beginPath();
                wave.forEach((v, i) => {
                    const x = i / (wave.length - 1) * w, y = waveH / 2 - v * (waveH / 2 - 2);
                    i ? ctx.lineTo(x, y) : ctx.moveTo(x, y);
                });
                ctx.stroke();
            }

            // ── Spectrum ──
            const levels = root.levels;
            const n = 48, slot = w / n, bar = Math.max(2, slot - 2);
            const fill = ctx.createLinearGradient(0, specTop + specH, 0, specTop);
            fill.addColorStop(0, rgba(Theme.blue, 0.9));
            fill.addColorStop(0.6, rgba(Theme.mauve, 0.95));
            fill.addColorStop(1, rgba(Theme.pink, 1));
            for (let i = 0; i < n; i++) {
                const v = levels[i] ?? 0;
                const bh = Math.max(2, v * specH);
                const x = i * slot + (slot - bar) / 2;
                ctx.fillStyle = v > 0.02 ? fill : rgba(Theme.surface1, 0.7);
                ctx.fillRect(x, specTop + specH - bh, bar, bh);
                // Peak hold
                const p = root.peaks[i] ?? 0;
                if (p > 0.03) {
                    ctx.fillStyle = rgba(Theme.text, 0.7);
                    ctx.fillRect(x, specTop + specH - p * specH - 2, bar, 1.5);
                }
            }
        }
    }

    // Frequency labels under the bars
    Repeater {
        model: [[50, "50"], [200, "200"], [1000, "1k"], [5000, "5k"], [15000, "15k"]]

        Label {
            required property var modelData
            x: root.freqX(modelData[0]) * (root.width - root.padding * 2) - implicitWidth / 2
            anchors.bottom: parent.bottom
            text: modelData[1]
            font.pixelSize: 9
            color: Theme.overlay0
        }
    }

    Label {
        visible: root.silent
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -6
        text: "Nothing playing"
        font.pixelSize: 10
        color: Theme.overlay1
    }
}
