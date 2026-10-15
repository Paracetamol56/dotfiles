pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The running distribution, from /etc/os-release, and its Nerd Font logo (the linux-* glyphs
// in FiraCode Nerd Font, U+F300–F381). Falls back to ID_LIKE (e.g. a Debian derivative
// without its own logo gets Debian's), then to Tux.
Singleton {
    id: root

    property string id: ""
    property string name: ""
    property var idLike: []

    // os-release ID → glyph
    readonly property var logos: ({
            alpine: "\u{f300}", arch: "\u{f303}", centos: "\u{f304}", debian: "\u{f306}", devuan: "\u{f307}",
            elementary: "\u{f309}", fedora: "\u{f30a}", freebsd: "\u{f30c}", gentoo: "\u{f30d}", linuxmint: "\u{f30e}",
            mageia: "\u{f310}", manjaro: "\u{f312}", nixos: "\u{f313}", opensuse: "\u{f314}", raspbian: "\u{f315}",
            rhel: "\u{f316}", slackware: "\u{f318}", ubuntu: "\u{f31b}", almalinux: "\u{f31d}", artix: "\u{f31f}",
            deepin: "\u{f321}", endeavouros: "\u{f322}", kali: "\u{f327}", openbsd: "\u{f328}", parrot: "\u{f329}",
            pop: "\u{f32a}", rocky: "\u{f32b}", solus: "\u{f32d}", void: "\u{f32e}", zorin: "\u{f32f}",
            neon: "\u{f331}", garuda: "\u{f337}", mx: "\u{f33f}", tails: "\u{f343}", archcraft: "\u{f345}",
            arcolinux: "\u{f346}", postmarketos: "\u{f374}", "opensuse-tumbleweed": "\u{f37d}", "opensuse-leap": "\u{f37e}",
            nobara: "\u{f380}"
        })
    readonly property string icon: logos[id] ?? idLike.map(x => logos[x]).find(x => x) ?? "\u{f31a}"

    FileView {
        path: "/etc/os-release"
        onLoaded: {
            // KEY=value or KEY="value"
            const get = key => (text().match(new RegExp(`^${key}=(.*)$`, "m"))?.[1] ?? "").replace(/^"(.*)"$/, "$1");
            root.id = get("ID").toLowerCase();
            root.name = get("PRETTY_NAME") || get("NAME");
            root.idLike = get("ID_LIKE").toLowerCase().split(/\s+/).filter(x => x);
        }
    }
}
