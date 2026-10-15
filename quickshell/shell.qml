import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "Wallpaper.qml"
import qs.bar
import qs.panels.dashboard
import qs.panels.calendar
import qs.panels.launcher
import qs.panels.power
import qs.panels.updates
import qs.panels.network
import qs.panels.bluetooth
import qs.panels.audio
import qs.panels.performance
import qs.panels.clipboard
import qs.panels.emoji
import qs.panels.vpn

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

  Variants {
    model: Quickshell.screens

    PerformanceModal {}
  }

  Variants {
    model: Quickshell.screens

    ClipboardModal {}
  }

  Variants {
    model: Quickshell.screens

    EmojiModal {}
  }

  Variants {
    model: Quickshell.screens

    VpnModal {}
  }
}
