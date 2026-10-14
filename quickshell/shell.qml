import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "Wallpaper.qml"
import "bar"

ShellRoot {
  id: root

  // Wallpaper {}

  Variants {
    model: Quickshell.screens

    Bar {}
  }
}
