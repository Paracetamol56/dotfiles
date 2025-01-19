#!/bin/bash

SCHEME='prefer-dark'
THEME='catppuccin-mocha-mauve-standard+default'
ICONS='Caticons'
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

apply_themes
