import QtQuick
import Quickshell
import qs.common
import qs.components
import qs.services
import "../../lib/Astro.js" as Astro

// Today's sun path, the moon phase and a few night-sky readings.
// Sun and moon are computed locally (Astro.js); moonrise/set, clouds and Kp come from Sky.
Widget {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property date now: clock.date
    readonly property real lat: Sky.lat
    readonly property real lon: Sky.lon

    readonly property var curve: Sky.located ? Astro.dayCurve(now, lat, lon, 5) : []
    readonly property var sunNow: Astro.sun(now, lat, lon)
    readonly property var moon: Astro.moon(now)
    readonly property var wave: Sky.located ? Astro.sunWave(now, lat, lon) : null

    // Planets above 5°: right now if it's dark, otherwise an hour after this evening's dusk
    readonly property var dusk: Astro.crossing(curve, -6, false)
    readonly property bool dark: sunNow.alt < -6
    readonly property var planetTime: dark || !dusk ? now : new Date(dusk.getTime() + 3600000)
    readonly property var planets: Sky.located ? Astro.planets(planetTime, lat, lon).filter(p => p.alt > 5) : []
    readonly property var planetLook: ({
            Mercury: ["\u263F", Theme.overlay2],
            Venus: ["\u2640", Theme.yellow],
            Mars: ["\u2642", Theme.red],
            Jupiter: ["\u2643", Theme.peach],
            Saturn: ["\u2644", Theme.rosewater]
        })

    readonly property var sunrise: Astro.crossing(curve, Astro.HORIZON, true)
    readonly property var sunset: Astro.crossing(curve, Astro.HORIZON, false)
    readonly property int dayMinutes: Sky.located ? Astro.dayLength(now, lat, lon) : 0
    readonly property int dayChange: Sky.located ? Math.round(dayMinutes - Astro.dayLength(new Date(now.getTime() - 86400000), lat, lon)) : 0

    // Evening golden hour: sun between 6° and -4°
    readonly property var goldenStart: Astro.crossing(curve, 6, false)
    readonly property var goldenEnd: Astro.crossing(curve, -4, false)
    // Astronomical night: sun below -18°, from this evening to tomorrow morning
    readonly property var darkStart: Astro.crossing(curve, -18, false)
    readonly property var darkEnd: Sky.located ? Astro.crossing(Astro.dayCurve(new Date(now.getTime() + 86400000), lat, lon, 5), -18, true) : null

    function hm(d) {
        return d ? Qt.formatTime(d, "HH:mm") : "--:--";
    }

    function duration(min) {
        return `${Math.floor(min / 60)}h ${String(Math.round(min % 60)).padStart(2, "0")}m`;
    }

    function compass(az) {
        return ["N", "NE", "E", "SE", "S", "SW", "W", "NW"][Math.round(az / 45) % 8];
    }

    // wttr.in gives "12:24 PM" (or "No moonrise")
    function to24(s) {
        const m = /(\d+):(\d+) (AM|PM)/.exec(s ?? "");
        if (!m)
            return "--:--";
        const h = Number(m[1]) % 12 + (m[3] === "PM" ? 12 : 0);
        return `${String(h).padStart(2, "0")}:${m[2]}`;
    }

    // Canvas colours as rgba() strings
    function rgba(c, a) {
        return `rgba(${Math.round(c.r * 255)}, ${Math.round(c.g * 255)}, ${Math.round(c.b * 255)}, ${a ?? c.a})`;
    }

    Label {
        visible: !Sky.located
        anchors.centerIn: parent
        text: Sky.weatherFailed ? "Location unavailable" : "Locating…"
        color: Theme.overlay1
        font.pixelSize: 11
    }

    Row {
        visible: Sky.located
        anchors.fill: parent
        spacing: 16

        // ── Sun path ─────────────────────────────────────

        Canvas {
            id: sunPath
            width: 250
            height: parent.height

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Connections {
                target: root
                function onWaveChanged() {
                    sunPath.requestPaint();
                }
                function onNowChanged() {
                    sunPath.requestPaint();
                }
            }

            // The sun as a smooth cosine wave between today's highest (solar noon) and lowest
            // elevations, one scale throughout; the horizon sits where the wave crosses 0°
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const wave = root.wave;
                if (!wave)
                    return;

                const w = width, h = height, top = 18, bottom = 4;
                const scale = (h - top - bottom) / (wave.max - wave.min);
                const Y = alt => top + (wave.max - alt) * scale;
                const horizon = Math.round(Y(0));
                const t0 = new Date(root.now.getFullYear(), root.now.getMonth(), root.now.getDate()).getTime();
                const X = t => (t - t0) / 86400000 * w;
                const T = x => new Date(t0 + x / w * 86400000);
                const trace = () => {
                    ctx.beginPath();
                    for (let x = 0; x <= w; x += 2)
                        x ? ctx.lineTo(x, Y(wave.at(T(x)))) : ctx.moveTo(x, Y(wave.at(T(x))));
                };

                // Daylight: area between the wave and the horizon, fading down
                ctx.save();
                ctx.beginPath();
                ctx.rect(0, 0, w, horizon);
                ctx.clip();
                trace();
                ctx.lineTo(w, horizon);
                ctx.lineTo(0, horizon);
                ctx.closePath();
                const fill = ctx.createLinearGradient(0, Y(wave.max), 0, horizon);
                fill.addColorStop(0, root.rgba(Theme.yellow, 0.28));
                fill.addColorStop(1, root.rgba(Theme.peach, 0.02));
                ctx.fillStyle = fill;
                ctx.fill();
                ctx.restore();

                // Night part of the wave, dimmed
                ctx.lineWidth = 1.5;
                ctx.strokeStyle = root.rgba(Theme.surface2, 1);
                trace();
                ctx.stroke();

                // Day part, warm
                ctx.save();
                ctx.beginPath();
                ctx.rect(0, 0, w, horizon);
                ctx.clip();
                ctx.lineWidth = 2;
                ctx.strokeStyle = root.rgba(Theme.yellow, 1);
                trace();
                ctx.stroke();
                ctx.restore();

                // Horizon
                ctx.strokeStyle = root.rgba(Theme.overlay0, 0.8);
                ctx.lineWidth = 1;
                ctx.setLineDash([3, 3]);
                ctx.beginPath();
                ctx.moveTo(0, horizon + 0.5);
                ctx.lineTo(w, horizon + 0.5);
                ctx.stroke();
                ctx.setLineDash([]);

                // Labels: the exact sunrise / sunset times, placed just outside where the
                // wave crosses the horizon (noon ± the hour angle where the cosine hits 0°)
                ctx.font = `10px '${Theme.fontFamily}'`;
                ctx.fillStyle = root.rgba(Theme.subtext0, 1);
                const mid = (wave.max + wave.min) / 2, amp = (wave.max - wave.min) / 2;
                const half = Math.acos(Math.max(-1, Math.min(1, -mid / amp))) / (2 * Math.PI) * 86400000;
                const noonX = X(wave.noon.getTime());
                if (root.sunrise) {
                    ctx.textAlign = "right";
                    ctx.fillText("↑ " + root.hm(root.sunrise), X(wave.noon.getTime() - half) - 6, horizon + 14);
                }
                if (root.sunset) {
                    ctx.textAlign = "left";
                    ctx.fillText("↓ " + root.hm(root.sunset), X(wave.noon.getTime() + half) + 6, horizon + 14);
                }
                ctx.textAlign = "center";
                ctx.fillText(`noon ${root.hm(wave.noon)} · ${Math.round(wave.max)}°`, noonX, Y(wave.max) - 8);

                // The sun right now, on the wave: a glowing dot by day, a dim one at night
                const day = root.sunNow.alt > 0;
                const x = X(root.now.getTime()), y = Y(wave.at(root.now));
                if (day) {
                    const glow = ctx.createRadialGradient(x, y, 0, x, y, 14);
                    glow.addColorStop(0, root.rgba(Theme.yellow, 0.55));
                    glow.addColorStop(1, root.rgba(Theme.yellow, 0));
                    ctx.fillStyle = glow;
                    ctx.beginPath();
                    ctx.arc(x, y, 14, 0, 2 * Math.PI);
                    ctx.fill();
                }
                ctx.fillStyle = root.rgba(day ? Theme.yellow : Theme.lavender, 1);
                ctx.beginPath();
                ctx.arc(x, y, 4, 0, 2 * Math.PI);
                ctx.fill();
            }
        }

        // ── Moon ─────────────────────────────────────────

        Column {
            id: moonColumn
            width: 124
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            MoonDisc {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 60
                height: 60
                moon: root.moon
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.moon.name
                font.weight: Font.Bold
                color: Theme.text
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: `${Math.round(root.moon.illumination * 100)}% lit · ${root.moon.waxing ? "full" : "new"} in ${Math.round(root.moon.waxing ? root.moon.toFull : root.moon.toNew)}d`
                font.pixelSize: 10
                color: Theme.subtext0
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: `↑ ${root.to24(Sky.astronomy?.moonrise)}   ↓ ${root.to24(Sky.astronomy?.moonset)}`
                font.pixelSize: 10
                color: Theme.overlay1
            }
        }

        // ── Readings ─────────────────────────────────────

        Column {
            width: parent.width - sunPath.width - moonColumn.width - parent.spacing * 2
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            Reading {
                icon: Icons.hourglass
                iconColor: Theme.peach
                label: "Day length"
                value: `${root.duration(root.dayMinutes)} (${root.dayChange >= 0 ? "+" : "−"}${Math.abs(root.dayChange)}m)`
            }

            Reading {
                icon: Icons.sunset
                iconColor: Theme.peach
                label: "Golden hour"
                value: `${root.hm(root.goldenStart)} – ${root.hm(root.goldenEnd)}`
            }

            Reading {
                icon: Icons.moonStar
                iconColor: Theme.lavender
                label: "Astro night"
                value: `${root.hm(root.darkStart)} – ${root.hm(root.darkEnd)}`
            }

            Reading {
                readonly property int c: Sky.nightClouds
                icon: Icons.telescope
                iconColor: c < 0 ? Theme.overlay1 : c < 20 ? Theme.green : c < 60 ? Theme.yellow : Theme.red
                label: "Tonight"
                value: c < 0 ? "–" : `${c < 20 ? "Clear" : c < 60 ? "Partly cloudy" : "Cloudy"} · ${c}%`
            }

            Reading {
                icon: Icons.orbit
                iconColor: Theme.accent
                label: root.dark ? "Planets" : "Planets " + root.hm(root.planetTime)
                value: root.planets.length ? root.planets.map(p => `<font color="${root.planetLook[p.name][1]}">${root.planetLook[p.name][0]}</font>`).join("&nbsp;&nbsp;") : "None up"
                valueFormat: Text.StyledText
                valueSize: 13
                tooltip: root.planets.map(p => `${root.planetLook[p.name][0]}  ${p.name}  ${Math.round(p.alt)}° ${root.compass(p.az)}`).join("\n")
            }

            Reading {
                readonly property real kp: Sky.kp
                icon: Icons.sparkles
                iconColor: kp < 0 ? Theme.overlay1 : kp < 4 ? Theme.teal : kp < 5 ? Theme.yellow : Theme.mauve
                label: "Aurora Kp"
                value: kp < 0 ? "–" : `${kp.toFixed(1)} · ${kp < 4 ? "Quiet" : kp < 5 ? "Active" : "Storm G" + Math.min(5, Math.floor(kp) - 4)}`
            }
        }
    }
}
