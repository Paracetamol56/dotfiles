import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "Wallpaper.qml"
import qs.bar
import qs.services
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
import qs.panels.notifications
import qs.panels.polkit
import qs.panels.lock
import qs.panels.overview
import qs.panels.wallpaper
import qs.panels.eyerest
import qs.panels.zen

ShellRoot {
  id: root

  // Start the polkit agent with the shell (singletons are otherwise created on first use)
  readonly property bool polkitReady: Polkit.registered

  // Wallpaper {}

  // Desktop wallpaper (replaces hyprpaper)
  Variants {
    model: Quickshell.screens

    WallpaperWindow {}
  }

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

  Variants {
    model: Quickshell.screens

    NotificationModal {}
  }

  Variants {
    model: Quickshell.screens

    NotificationPopups {}
  }

  Variants {
    model: Quickshell.screens

    OsdPopup {}
  }

  Variants {
    model: Quickshell.screens

    PolkitPopup {}
  }

  Variants {
    model: Quickshell.screens

    Overview {}
  }

  // Zen mode's black backdrop (services/Zen.qml, SUPER + SHIFT + Z)
  Variants {
    model: Quickshell.screens

    ZenWindow {}
  }

  // Eye-rest reminder every 30 minutes (services/EyeRest.qml)
  Variants {
    model: Quickshell.screens

    EyeRestWindow {}
  }

  // Session lock (one instance; it creates a surface per screen)
  LockScreen {}
}
