import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "Wallpaper.qml"
import "bar"
import "dashboard"

ShellRoot {
  id: root

  // Wallpaper {}

  Variants {
    model: Quickshell.screens

    Bar {}
  }

  Variants {
    model: Quickshell.screens

    Dashboard {}
  }
}
