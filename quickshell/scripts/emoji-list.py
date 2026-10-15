#!/usr/bin/env python3
"""Prints the emoji picker's data as JSON: [{"name": category, "items": [[text, name], ...]}, ...]

Emoji come from Unicode's emoji-test.txt (bundled in assets/), grouped by its official
groups, then filtered to what the installed emoji font can draw so nothing shows blank:
single code points must be in the font, longer sequences (flags, 👨‍💻…) must be no newer
than the newest emoji in the font. Skin-tone variants are skipped to keep the grid short.
A hand-picked set of kaomoji follows as its own categories, minus any that use a character
no installed font has (checked with fontconfig), so those don't show as boxes either.
"""

import json
import os
import re
import subprocess
import sys
import unicodedata

ASSETS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets")
FONT = "/usr/share/fonts/noto/NotoColorEmoji.ttf"

# emoji-test.txt group → shorter tab name
GROUPS = {
    "Smileys & Emotion": "Smileys",
    "People & Body": "People",
    "Animals & Nature": "Nature",
    "Food & Drink": "Food",
    "Travel & Places": "Travel",
    "Activities": "Activities",
    "Objects": "Objects",
    "Symbols": "Symbols",
    "Flags": "Flags",
}
SKIN_TONES = {0x1F3FB, 0x1F3FC, 0x1F3FD, 0x1F3FE, 0x1F3FF}
LINE = re.compile(r"^([0-9A-F ]+?)\s*;\s*fully-qualified\s*#\s*\S+\s+E(\d+\.\d+)\s+(.*)$")


def font_support():
    """Code points in the emoji font, or None if it can't be read (then nothing is filtered)."""
    try:
        from fontTools.ttLib import TTFont

        return set(TTFont(FONT, lazy=True).getBestCmap().keys())
    except Exception:
        return None


def emoji_categories():
    cmap = font_support()
    entries, group = [], None
    with open(os.path.join(ASSETS, "emoji-test.txt"), encoding="utf-8") as f:
        for line in f:
            if line.startswith("# group:"):
                group = GROUPS.get(line.split(":", 1)[1].strip())
                continue
            m = LINE.match(line)
            if not m or not group:
                continue
            cps = [int(c, 16) for c in m.group(1).split()]
            if SKIN_TONES & set(cps):
                continue
            entries.append((group, cps, float(m.group(2)), m.group(3)))

    # Newest emoji version the font has, judged from single code points it contains
    newest = None
    if cmap is not None:
        singles = [v for _, cps, v, _ in entries if len(cps) == 1 and cps[0] in cmap]
        newest = max(singles) if singles else None

    def drawable(cps, version):
        if cmap is None:
            return True
        base = [c for c in cps if c not in (0xFE0F, 0x200D)]
        if len(base) == 1:
            return base[0] in cmap
        return all(c in cmap or 0x1F1E6 <= c <= 0x1F1FF or 0xE0020 <= c <= 0xE007F for c in base) and (newest is None or version <= newest)

    categories = {name: [] for name in GROUPS.values()}
    for group, cps, version, name in entries:
        if drawable(cps, version):
            categories[group].append(["".join(map(chr, cps)), name])
    return [{"name": n, "items": items} for n, items in categories.items() if items]


# name: [(kaomoji, description), ...]
KAOMOJI = {
    "Happy": [
        ("(＾▽＾)", "happy"), ("(◕‿◕)", "smile"), ("(｡◕‿◕｡)", "cute smile"), ("ヽ(•‿•)ノ", "cheer"),
        ("(≧◡≦)", "delighted"), ("(*^▽^*)", "joy"), ("٩(◕‿◕)۶", "yay"), ("(ﾉ◕ヮ◕)ﾉ*:･ﾟ✧", "sparkle joy"),
        ("☆*:.｡.o(≧▽≦)o.｡.:*☆", "excited"), ("(✿◠‿◠)", "flower smile"), ("(ᵔᴥᵔ)", "bear happy"), ("( ˘▽˘)っ♨", "content"),
        ("(￣▽￣)ノ", "wave"), ("(•̀ᴗ•́)و ̑̑", "determined"), ("ᕕ( ᐛ )ᕗ", "walking happy"), ("(づ｡◕‿‿◕｡)づ", "hug"),
    ],
    "Love": [
        ("(♥ω♥*)", "love eyes"), ("(｡♥‿♥｡)", "in love"), ("(づ￣ ³￣)づ", "kiss"), ("(っ˘з(˘⌣˘ )", "smooch"),
        ("♡( ◡‿◡ )", "heart smile"), ("(´∀｀)♡", "fond"), ("(≧◡≦) ♡", "love"), ("(*˘︶˘*).｡.:*♡", "dreamy"),
        ("(灬♥ω♥灬)", "blushing love"), ("( ˘ ³˘)♥", "blow kiss"), ("ʕ•ᴥ•ʔ♡", "bear love"), ("(⁄ ⁄•⁄ω⁄•⁄ ⁄)", "shy"),
    ],
    "Sad": [
        ("(╥﹏╥)", "crying"), ("(っ˘̩╭╮˘̩)っ", "sad"), ("(ಥ﹏ಥ)", "tears"), ("(T_T)", "cry"),
        ("(；﹏；)", "upset"), ("(´；ω；`)", "sobbing"), ("(ノ_<。)", "wipe tears"), ("( ╥ω╥ )", "teary"),
        ("(._.)", "down"), ("(︶︹︺)", "pout"), ("o(〒﹏〒)o", "wailing"), ("(｡•́︿•̀｡)", "sad puppy"),
    ],
    "Angry": [
        ("(╬ Ò﹏Ó)", "angry"), ("ヽ(`Д´)ﾉ", "furious"), ("(ノಠ益ಠ)ノ彡┻━┻", "rage flip"), ("(ಠ_ಠ)", "disapproval"),
        ("(¬_¬\")", "annoyed"), ("(╯°□°）╯︵ ┻━┻", "table flip"), ("┬─┬ノ( º _ ºノ)", "put table back"), ("(ง'̀-'́)ง", "fight me"),
        ("(＃`Д´)", "mad"), ("(｀皿´＃)", "grr"), ("ヽ( `д´*)ノ", "outraged"), ("(눈_눈)", "glare"),
    ],
    "Surprised": [
        ("(⊙_⊙)", "shocked"), ("(°ロ°) !", "gasp"), ("Σ(°△°|||)", "startled"), ("(O_O)", "stare"),
        ("(⊙＿⊙')", "wait what"), ("(゜゜)", "huh"), ("w(°ｏ°)w", "wow"), ("(ﾟДﾟ;)", "panic"),
        ("(o_O)", "confused stare"), ("∑(O_O;)", "whoa"),
    ],
    "Shrug & meh": [
        ("¯\\_(ツ)_/¯", "shrug"), ("┐(￣ヘ￣)┌", "whatever"), ("(￢_￢)", "side eye"), ("(・_・;)", "awkward"),
        ("(¬‿¬)", "smug"), ("( ͡° ͜ʖ ͡°)", "lenny"), ("(¯\\_(ツ)_/¯)", "double shrug"), ("(-_-)", "unimpressed"),
        ("(；一_一)", "sigh"), ("ಠ‿ಠ", "suspicious"), ("(•_•)", "neutral"), ("( ・_・)ノ⌒●~*", "throw"),
    ],
    "Animals": [
        ("(=^･ω･^=)", "cat"), ("ฅ^•ﻌ•^ฅ", "cat paws"), ("(=ↀωↀ=)", "big eyed cat"), ("U・ᴥ・U", "dog"),
        ("ʕ •ᴥ•ʔ", "bear"), ("ʕ·͡ᴥ·ʔ", "teddy"), ("(•ㅅ•)", "bunny"), ("/(•ㅅ•)\\", "bunny ears"),
        ("(・θ・)", "bird"), ("<・ )))><<", "fish"), ("ᘛ⁐̤ᕐᐷ", "mouse"), ("(◉Θ◉)", "owl"),
    ],
    "Actions": [
        ("(ﾉ◕ヮ◕)ﾉ*:･ﾟ✧", "magic"), ("(っ•́｡•́)♪♬", "singing"), ("ヾ(⌐■_■)ノ♪", "dancing"), ("(-_-) zzZ", "sleeping"),
        ("(￣ω￣;)", "sweating"), ("( ˘▽˘)っ♨", "tea"), ("(╯✧▽✧)╯", "hyped"), ("(งツ)ว", "punch"),
        ("(ノ°∀°)ノ⌒･*:.｡. .｡.:*･゜ﾟ･*☆", "throw sparkles"), ("φ(゜▽゜*)♪", "writing"), ("( ^_^)／", "high five"), ("(⌐■_■)", "cool"),
        ("(☞ﾟヮﾟ)☞", "you"), ("✧*｡٩(ˊᗜˋ*)و✧*｡", "victory"), ("(っ◔◡◔)っ ♥", "give love"), ("(╯°□°）╯︵ ┻━┻", "flip table"),
    ],
}


def kaomoji_categories():
    # Distinct visible non-ASCII characters, each checked once against the installed fonts
    chars = {c for items in KAOMOJI.values() for k, _ in items for c in k if ord(c) > 0x7E and not unicodedata.combining(c)}
    missing = set()
    for c in chars:
        fonts = subprocess.run(["fc-list", f":charset={ord(c):x}", "family"], capture_output=True, text=True).stdout
        if not fonts.strip():
            missing.add(c)
    return [
        {"name": name, "kaomoji": True, "items": [[k, d] for k, d in items if not missing & set(k)]}
        for name, items in KAOMOJI.items()
    ]


json.dump(emoji_categories() + kaomoji_categories(), sys.stdout, ensure_ascii=False)
