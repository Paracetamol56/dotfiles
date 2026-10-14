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

  Variants {
    model: Quickshell.screens

    CalendarModal {}
  }

  Variants {
    model: Quickshell.screens

    UpdatesModal {}
  }

  Variants {
    model: Quickshell.screens

    PowerModal {}
  }

  Variants {
    model: Quickshell.screens

    NetworkModal {}
  }

  Variants {
    model: Quickshell.screens

    BluetoothModal {}
  }

  Variants {
    model: Quickshell.screens

    AudioModal {}
  }

  Variants {
    model: Quickshell.screens

    LauncherModal {}
  }
}
