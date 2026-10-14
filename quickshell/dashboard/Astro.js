.pragma library

// Sun, moon and planet maths, computed locally. Sun: NOAA's low-precision solar position
// (sunrise/sunset within a minute of sunrise-sunset.org). Moon: mean synodic month.
// Planets: JPL's approximate Keplerian elements (1800–2050), within ~0.1° of JPL Horizons.

const RAD = Math.PI / 180;
const SYNODIC = 29.530588853; // days between new moons
const KNOWN_NEW_MOON = Date.UTC(2000, 0, 6, 18, 14);

// Days since J2000
function j2000(date) {
    return date.getTime() / 86400000 + 2440587.5 - 2451545.0;
}

// Elevation and azimuth (degrees) of a body at right ascension / declination (radians)
function altAz(ra, dec, date, lat, lon) {
    const n = j2000(date);
    const gmst = (18.697374558 + 24.06570982441908 * n) % 24;
    const ha = (gmst * 15 + lon) * RAD - ra;
    const phi = lat * RAD;
    const alt = Math.asin(Math.sin(phi) * Math.sin(dec) + Math.cos(phi) * Math.cos(dec) * Math.cos(ha));
    const az = Math.atan2(-Math.sin(ha), Math.tan(dec) * Math.cos(phi) - Math.sin(phi) * Math.cos(ha));
    return { alt: alt / RAD, az: (az / RAD + 360) % 360 };
}

// Sun elevation, azimuth and declination (degrees) at `date` seen from lat/lon
function sun(date, lat, lon) {
    const n = j2000(date);
    const L = (280.460 + 0.9856474 * n) % 360;
    const g = ((357.528 + 0.9856003 * n) % 360) * RAD;
    const lambda = (L + 1.915 * Math.sin(g) + 0.020 * Math.sin(2 * g)) * RAD;
    const eps = (23.439 - 0.0000004 * n) * RAD;
    const dec = Math.asin(Math.sin(eps) * Math.sin(lambda));
    const ra = Math.atan2(Math.cos(eps) * Math.sin(lambda), Math.cos(lambda));
    const pos = altAz(ra, dec, date, lat, lon);
    pos.dec = dec / RAD;
    return pos;
}

// Today's sun as a cosine wave: peak at solar noon (upper culmination, 90 - lat + dec),
// trough twelve hours away (lower culmination, lat + dec - 90). Close to the real curve.
function sunWave(date, lat, lon) {
    const c = dayCurve(date, lat, lon, 5);
    const noon = c.reduce((a, b) => b.alt > a.alt ? b : a).t;
    const dec = sun(noon, lat, lon).dec;
    const max = 90 - lat + dec, min = lat + dec - 90;
    return {
        noon,
        max,
        min,
        at: t => (max + min) / 2 + (max - min) / 2 * Math.cos(2 * Math.PI * (t.getTime() - noon.getTime()) / 86400000)
    };
}

// Elevation every `step` minutes over the local day containing `date`: [{ t: Date, alt }]
function dayCurve(date, lat, lon, step) {
    const start = new Date(date.getFullYear(), date.getMonth(), date.getDate());
    const points = [];
    for (let m = 0; m <= 24 * 60; m += step) {
        const t = new Date(start.getTime() + m * 60000);
        points.push({ t, alt: sun(t, lat, lon).alt });
    }
    return points;
}

// First time the curve crosses `threshold` going up (rising) or down, interpolated; null if never
function crossing(curve, threshold, rising) {
    for (let i = 1; i < curve.length; i++) {
        const a = curve[i - 1], b = curve[i];
        if (rising ? a.alt < threshold && b.alt >= threshold : a.alt > threshold && b.alt <= threshold) {
            const f = (threshold - a.alt) / (b.alt - a.alt);
            return new Date(a.t.getTime() + f * (b.t.getTime() - a.t.getTime()));
        }
    }
    return null;
}

// Sunrise/sunset use the standard -0.833° (refraction + the sun's radius)
var HORIZON = -0.833;

function dayLength(date, lat, lon) {
    const c = dayCurve(date, lat, lon, 2);
    const up = crossing(c, HORIZON, true), down = crossing(c, HORIZON, false);
    return up && down ? (down - up) / 60000 : 0; // minutes
}

// Moon: age in days, illuminated fraction, waxing?, phase name, days to next full / new
function moon(date) {
    const age = (((date.getTime() - KNOWN_NEW_MOON) / 86400000) % SYNODIC + SYNODIC) % SYNODIC;
    const illumination = (1 - Math.cos(2 * Math.PI * age / SYNODIC)) / 2;
    const names = ["New Moon", "Waxing Crescent", "First Quarter", "Waxing Gibbous", "Full Moon", "Waning Gibbous", "Last Quarter", "Waning Crescent"];
    const name = names[Math.floor((age / SYNODIC) * 8 + 0.5) % 8];
    return {
        age,
        illumination,
        waxing: age < SYNODIC / 2,
        name,
        toFull: (SYNODIC / 2 - age + SYNODIC) % SYNODIC,
        toNew: SYNODIC - age
    };
}

// ── Planets ──────────────────────────────────────────

// JPL "Approximate Positions of the Planets", table 1: [value at J2000, rate per century]
// for a (AU), e, I, L, longitude of perihelion, longitude of the ascending node (degrees)
var ORBITS = {
    Mercury: [[0.38709927, 0.00000037], [0.20563593, 0.00001906], [7.00497902, -0.00594749], [252.25032350, 149472.67411175], [77.45779628, 0.16047689], [48.33076593, -0.12534081]],
    Venus: [[0.72333566, 0.00000390], [0.00677672, -0.00004107], [3.39467605, -0.00078890], [181.97909950, 58517.81538729], [131.60246718, 0.00268329], [76.67984255, -0.27769418]],
    Earth: [[1.00000261, 0.00000562], [0.01671123, -0.00004392], [-0.00001531, -0.01294668], [100.46457166, 35999.37244981], [102.93768193, 0.32327364], [0, 0]],
    Mars: [[1.52371034, 0.00001847], [0.09339410, 0.00007882], [1.84969142, -0.00813131], [-4.55343205, 19140.30268499], [-23.94362959, 0.44441088], [49.55953891, -0.29257343]],
    Jupiter: [[5.20288700, -0.00011607], [0.04838624, -0.00013253], [1.30439695, -0.00183714], [34.39644051, 3034.74612775], [14.72847983, 0.21252668], [100.47390909, 0.20469106]],
    Saturn: [[9.53667594, -0.00125060], [0.05386179, -0.00050991], [2.48599187, 0.00193609], [49.95424423, 1222.49362201], [92.59887831, -0.41897216], [113.66242448, -0.28867794]]
};

// Heliocentric ecliptic position (AU) at T Julian centuries since J2000
function heliocentric(name, T) {
    const [a, e, I, L, peri, node] = ORBITS[name].map(([v, rate]) => v + rate * T);
    const M = ((L - peri + 180) % 360 + 360) % 360 - 180;
    const w = (peri - node) * RAD, O = node * RAD, i = I * RAD;
    let E = M * RAD + e * Math.sin(M * RAD);
    for (let k = 0; k < 8; k++)
        E -= (E - e * Math.sin(E) - M * RAD) / (1 - e * Math.cos(E));
    const xp = a * (Math.cos(E) - e), yp = a * Math.sqrt(1 - e * e) * Math.sin(E);
    return [
        (Math.cos(w) * Math.cos(O) - Math.sin(w) * Math.sin(O) * Math.cos(i)) * xp + (-Math.sin(w) * Math.cos(O) - Math.cos(w) * Math.sin(O) * Math.cos(i)) * yp,
        (Math.cos(w) * Math.sin(O) + Math.sin(w) * Math.cos(O) * Math.cos(i)) * xp + (-Math.sin(w) * Math.sin(O) + Math.cos(w) * Math.cos(O) * Math.cos(i)) * yp,
        Math.sin(w) * Math.sin(i) * xp + Math.cos(w) * Math.sin(i) * yp
    ];
}

var PLANETS = ["Mercury", "Venus", "Mars", "Jupiter", "Saturn"];

// Elevation and azimuth of each naked-eye planet: [{ name, alt, az }]
function planets(date, lat, lon) {
    const T = j2000(date) / 36525;
    const earth = heliocentric("Earth", T);
    const eps = 23.43928 * RAD;
    return PLANETS.map(name => {
        const p = heliocentric(name, T);
        const x = p[0] - earth[0], y = p[1] - earth[1], z = p[2] - earth[2];
        const ye = y * Math.cos(eps) - z * Math.sin(eps), ze = y * Math.sin(eps) + z * Math.cos(eps);
        const pos = altAz(Math.atan2(ye, x), Math.atan2(ze, Math.hypot(x, ye)), date, lat, lon);
        pos.name = name;
        return pos;
    });
}
