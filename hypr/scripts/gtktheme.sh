#!/bin/bash
# GTK theme, icons, cursor and font for the session. Run once after installing (or changing)
# them; the values persist in gsettings. Needs the AUR packages catppuccin-gtk-theme-mocha and
# catppuccin-cursors-mocha (the cursor theme is also set for Hyprland in hyprland/env.lua).

SCHEME='prefer-dark'
THEME='catppuccin-mocha-mauve-standard+default'
ICONS='Papirus'
CURSOR='catppuccin-mocha-dark-cursors'
SIZE=18
FONT='FiraCode Nerd Font'

SCHEMA='gsettings set org.gnome.desktop.interface'

apply_themes() {
  ${SCHEMA} color-scheme "$SCHEME"
  ${SCHEMA} gtk-theme "$THEME"
  ${SCHEMA} icon-theme "$ICONS"
  ${SCHEMA} cursor-theme "$CURSOR"
  ${SCHEMA} cursor-size "$SIZE"
  ${SCHEMA} font-name "$FONT"
}

apply_cursor() {
  if [[ ! -d /usr/share/icons/$CURSOR && ! -d ~/.local/share/icons/$CURSOR && ! -d ~/.icons/$CURSOR ]]; then
    echo "Cursor theme $CURSOR isn't installed: paru -S catppuccin-cursors-mocha" >&2
    return 1
  fi
  hyprctl setcursor "$CURSOR" "$SIZE" >/dev/null
  mkdir -p ~/.icons/default
  printf '[Icon Theme]\nInherits=%s\n' "$CURSOR" >~/.icons/default/index.theme
}

apply_themes
apply_cursor
