.pragma library

// Date helpers for the calendar modal

function sameDay(a, b) {
    return a && b && a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
}

function addDays(d, n) {
    return new Date(d.getFullYear(), d.getMonth(), d.getDate() + n);
}

function dayOfYear(d) {
    return Math.round((new Date(d.getFullYear(), d.getMonth(), d.getDate()) - new Date(d.getFullYear(), 0, 1)) / 86400000) + 1;
}

function daysInYear(y) {
    return (y % 4 === 0 && y % 100 !== 0) || y % 400 === 0 ? 366 : 365;
}

// ISO 8601 week number (weeks start on Monday, week 1 holds the first Thursday)
function isoWeek(d) {
    const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
    t.setUTCDate(t.getUTCDate() + 4 - (t.getUTCDay() || 7));
    return Math.ceil(((t - Date.UTC(t.getUTCFullYear(), 0, 1)) / 86400000 + 1) / 7);
}

// The 42 days (6 weeks, Monday first) shown for the month containing `d`
function monthGrid(d) {
    const first = new Date(d.getFullYear(), d.getMonth(), 1);
    const start = addDays(first, -((first.getDay() + 6) % 7));
    const days = [];
    for (let i = 0; i < 42; i++)
        days.push(addDays(start, i));
    return days;
}
