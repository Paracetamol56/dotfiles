#!/usr/bin/env python3
"""Applies one Catppuccin flavor + accent to the whole desktop.

    theme/apply.py                 re-apply what theme.json says
    theme/apply.py mocha blue      switch flavor and/or accent (saved to theme.json)
    theme/apply.py --rgb           only set the RGB lighting (at login, from execs.lua)
    theme/apply.py --led 60        set the LED brightness (0-100, saved to theme.json)

Writes:  hypr/hyprland/colors.lua · kitty/current-theme.conf · btop color_theme ·
         starship palette · qt6ct colours + settings · fastfetch (from its template) ·
         zsh colours (autosuggestions, completion headers, syntax highlighting)
Sets the keyboard/mouse/motherboard LEDs to the accent (Latte's, the most saturated) with OpenRGB (in the background).
Then reloads Hyprland and kitty. Quickshell watches theme.json and recolours by itself.
GTK stays on the installed Catppuccin-Mocha-Standard-Mauve-Dark theme.
"""

import json
import os
import re
import fcntl
import shutil
import subprocess
import sys

HOME = os.path.expanduser("~")
CONFIG = os.path.join(HOME, ".config")
HERE = os.path.dirname(os.path.abspath(__file__))
FLAVORS = ("latte", "frappe", "macchiato", "mocha")
ACCENTS = ("rosewater", "flamingo", "pink", "mauve", "red", "maroon", "peach", "yellow",
           "green", "teal", "sky", "sapphire", "blue", "lavender")

palettes = json.load(open(os.path.join(HERE, "catppuccin.json")))
choice_path = os.path.join(HERE, "theme.json")
choice = json.load(open(choice_path))


def set_lighting(colour):
    """Every OpenRGB device to one colour. Static where the device has it (a hardware mode:
    it sticks, and lights the motherboard's ARGB headers without knowing their LED counts),
    else Direct (the K70 has no Static). Takes a few seconds: OpenRGB scans the devices twice."""
    listing = subprocess.run(["openrgb", "--noautoconnect", "--list-detailed"],
                             capture_output=True, text=True).stdout
    args, device = [], None
    for line in listing.splitlines():
        if m := re.match(r"^(\d+): ", line):
            device = m.group(1)
        elif device is not None and line.strip().startswith("Modes:"):
            modes = line.lower().replace("[", "").replace("]", "").split()
            args += ["-d", device, "-m", "static" if "static" in modes else "direct", "-c", colour]
            device = None
    if args:
        subprocess.run(["openrgb", "--noautoconnect", *args], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def lighting_colour():
    # Always Latte's version of the accent: the most saturated one; the dark flavors' pastels
    # look washed out on LEDs. Dimmed by scaling the colour, which works in every mode
    c = palettes["latte"][choice["accent"]].lstrip("#")
    level = max(0, min(100, int(choice.get("led", 100)))) / 100
    return "".join(f"{round(int(c[i:i + 2], 16) * level):02x}" for i in (0, 2, 4))


def run_lighting():
    """One OpenRGB at a time, and only the newest waiting request runs (with the latest
    theme.json), so quick changes don't queue up 8-second runs."""
    run = os.environ.get("XDG_RUNTIME_DIR", "/tmp")
    pending = os.path.join(run, "theme-rgb.pending")
    with open(pending, "w") as f:
        f.write(str(os.getpid()))
    with open(os.path.join(run, "theme-rgb.lock"), "w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if open(pending).read() != str(os.getpid()):
            return
        choice.update(json.load(open(choice_path)))
        set_lighting(lighting_colour())


if sys.argv[1:2] == ["--led"] and len(sys.argv) == 3:
    choice["led"] = max(0, min(100, int(sys.argv[2])))
    json.dump(choice, open(choice_path, "w"), indent=2)
    sys.argv[1:] = ["--rgb"]

if sys.argv[1:] == ["--rgb"]:
    if shutil.which("openrgb"):
        run_lighting()
    sys.exit()

# Arguments, in any order: a flavor and/or an accent
for arg in sys.argv[1:]:
    if arg in FLAVORS:
        choice["flavor"] = arg
    elif arg in ACCENTS:
        choice["accent"] = arg
    else:
        sys.exit(f"unknown flavor/accent: {arg}\nflavors: {' '.join(FLAVORS)}\naccents: {' '.join(ACCENTS)}")
json.dump(choice, open(choice_path, "w"), indent=2)

flavor, accent = choice["flavor"], choice["accent"]
p = dict(palettes[flavor])
p["accent"] = p[accent]
dark = flavor != "latte"
hx = lambda name: p[name].lstrip("#")
rgb = lambda name: tuple(int(hx(name)[i:i + 2], 16) for i in (0, 2, 4))


def write(rel, text):
    path = os.path.join(CONFIG, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        f.write(text)
    print(f"  wrote {rel}")


def edit(rel, fn):
    path = os.path.join(CONFIG, rel)
    if not os.path.exists(path):
        print(f"  skip  {rel} (missing)")
        return
    old = open(path).read()
    new = fn(old)
    if new != old:
        open(path, "w").write(new)
        print(f"  wrote {rel}")


print(f"Catppuccin {flavor}, accent {accent} ({p['accent']})")

# ── Hyprland ────────────────────────────────────────────────────────────────
names = [n for n in palettes[flavor]]
write("hypr/hyprland/colors.lua", "\n".join([
    f"-- Generated by ~/.config/theme/apply.py (Catppuccin {flavor}, accent {accent}). Don't edit:",
    "-- change theme/theme.json or run theme/apply.py instead.",
    "",
    "local colors = {",
    *[f'\t{n} = "rgb({hx(n)})",' for n in names],
    f'\taccent = "rgb({hx("accent")})",',
    "}",
    "",
    "-- Also set as global variables for the other config files",
    "for key, value in pairs(colors) do",
    "\t_G[key] = value",
    "end",
    "",
    "return colors",
    "",
]))

# ── kitty ───────────────────────────────────────────────────────────────────
kitty = {
    "foreground": "text", "background": "base",
    "selection_foreground": "base", "selection_background": "rosewater",
    "cursor": "rosewater", "cursor_text_color": "base", "url_color": "rosewater",
    "active_border_color": "accent", "inactive_border_color": "overlay0", "bell_border_color": "yellow",
    "wayland_titlebar_color": "base",
    "active_tab_foreground": "crust", "active_tab_background": "accent",
    "inactive_tab_foreground": "text", "inactive_tab_background": "mantle", "tab_bar_background": "crust",
    "mark1_foreground": "base", "mark1_background": "lavender",
    "mark2_foreground": "base", "mark2_background": "mauve",
    "mark3_foreground": "base", "mark3_background": "sapphire",
    # The 16 terminal colours, as in catppuccin/kitty
    "color0": "surface1" if dark else "subtext1", "color8": "surface2" if dark else "subtext0",
    "color1": "red", "color9": "red", "color2": "green", "color10": "green",
    "color3": "yellow", "color11": "yellow", "color4": "blue", "color12": "blue",
    "color5": "pink", "color13": "pink", "color6": "teal", "color14": "teal",
    "color7": "subtext1" if dark else "surface2", "color15": "subtext0" if dark else "surface1",
    "color16": "peach", "color17": "rosewater",
}
write("kitty/current-theme.conf", "\n".join(
    [f"# Generated by ~/.config/theme/apply.py (Catppuccin {flavor}, accent {accent})", ""]
    + [f"{k:24s}{p[v]}" for k, v in kitty.items()] + [""]))

# ── btop (themes for all 4 flavors ship in btop/themes) ─────────────────────
edit("btop/btop.conf", lambda s: re.sub(r'^color_theme = ".*"$', f'color_theme = "{CONFIG}/btop/themes/catppuccin_{flavor}.theme"', s, flags=re.M))

# ── starship: one palette named "catppuccin", plus "accent" ─────────────────
def starship(s):
    block = "[palettes.catppuccin]\n" + "".join(f'{n} = "{p[n]}"\n' for n in names) + f'accent = "{p["accent"]}"\n'
    s = re.sub(r'^palette = ".*"$', 'palette = "catppuccin"', s, flags=re.M)
    return re.sub(r"\[palettes\.[a-z_]+\]\n(?:[a-z0-9_]+ = \"#[0-9a-fA-F]{6}\"\n)+", block, s)
edit("starship.toml", starship)

# ── Qt (qt6ct): palette roles in Qt's order ─────────────────────────────────
roles = ["text", "surface0", "surface2", "surface1", "crust", "mantle", "text", "red", "text", "base",
         "base", "crust", "accent", "base", "blue", "lavender", "mantle", "base", "surface0", "text", "overlay0"]
disabled = ["overlay0", "surface0", "surface2", "surface1", "crust", "mantle", "overlay0", "red", "overlay0", "base",
            "base", "crust", "surface1", "overlay0", "blue", "lavender", "mantle", "base", "surface0", "overlay0", "overlay0"]
qcolor = lambda name: "#ff" + hx(name)
write("qt6ct/colors/catppuccin.conf", "\n".join([
    "[ColorScheme]",
    "active_colors=" + ", ".join(map(qcolor, roles)),
    "disabled_colors=" + ", ".join(map(qcolor, disabled)),
    "inactive_colors=" + ", ".join(map(qcolor, roles)),
    "",
]))
font = '"FiraCode Nerd Font,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"'
write("qt6ct/qt6ct.conf", "\n".join([
    "[Appearance]",
    f"color_scheme_path={CONFIG}/qt6ct/colors/catppuccin.conf",
    "custom_palette=true",
    "icon_theme=Caticons",
    "standard_dialogs=default",
    "style=Fusion",
    "",
    "[Fonts]",
    f"fixed={font}",
    f"general={font}",
    "",
]))

# ── fastfetch: config.jsonc rendered from config.template.jsonc ({{name}} → r;g;b) ─
def fastfetch():
    src = os.path.join(CONFIG, "fastfetch/config.template.jsonc")
    if not os.path.exists(src):
        print("  skip  fastfetch (no config.template.jsonc)")
        return
    text = open(src).read().split("\n", 2)[2]  # drop the template's own header
    text = re.sub(r"\{\{(\w+)\}\}", lambda m: ";".join(map(str, rgb(m.group(1)))), text)
    write("fastfetch/config.jsonc", f"// Generated from config.template.jsonc by ~/.config/theme/apply.py; edit the template.\n{text}")
fastfetch()

# ── zsh: autosuggestion ghost text, completion menu, syntax highlighting ────
highlight = {
    "command": "green", "builtin": "green", "alias": "green", "function": "green",
    "precommand": "green,italic", "reserved-word": "mauve", "unknown-token": "red",
    "path": "text,underline", "globbing": "accent", "single-hyphen-option": "teal",
    "double-hyphen-option": "teal", "single-quoted-argument": "yellow",
    "double-quoted-argument": "yellow", "dollar-quoted-argument": "yellow",
    "commandseparator": "overlay2", "redirection": "overlay2", "comment": "overlay0",
}
style = lambda v: ",".join(f"fg={p[x]}" if x in p else x for x in v.split(","))
write("zsh/theme.zsh", "\n".join([
    f"# Generated by ~/.config/theme/apply.py (Catppuccin {flavor}, accent {accent}). Don't edit.",
    f'ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg={p["overlay0"]}"',
    # Completion group headers, e.g. "-- files --", in the accent
    f"zstyle ':completion:*:descriptions' format '%F{{{p['accent']}}}-- %d --%f'",
    "typeset -gA ZSH_HIGHLIGHT_STYLES",
    *[f"ZSH_HIGHLIGHT_STYLES[{k}]='{style(v)}'" for k, v in highlight.items()],
    "",
]))

# ── RGB lighting: in the background, OpenRGB takes a few seconds ────────────
if shutil.which("openrgb"):
    subprocess.Popen([sys.executable, os.path.abspath(__file__), "--rgb"], start_new_session=True,
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    print(f"  lighting → #{lighting_colour()} (Latte {accent}, OpenRGB, in the background)")

# ── Reload what can be reloaded live ───────────────────────────────────────
subprocess.run(["hyprctl", "reload"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
subprocess.run(["pkill", "-USR1", "-x", "kitty"], stderr=subprocess.DEVNULL)
print("Reloaded Hyprland and kitty; Quickshell follows theme.json. Restart btop to see its theme.")
