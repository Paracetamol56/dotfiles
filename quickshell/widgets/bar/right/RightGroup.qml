import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
  id: root
  required property var cfg
  required property var st

  height:        cfg.pillH
  implicitWidth: row.implicitWidth + 4
  radius:        cfg.pillR
  color:         "#1e1e2e"
  border.width:  1
  border.color:  Qt.rgba(1,1,1, 0.07)
  clip:          true

  RowLayout {
    id: row
    anchors.left:       parent.left
    anchors.top:        parent.top
    anchors.bottom:     parent.bottom
    anchors.leftMargin: 4
    spacing:            8

    // ── Volume ──────────────────────────────────────────────────
    Item {
      width: cfg.btnSize; height: cfg.btnSize
      property bool hovered: vMa.containsMouse
      Text {
        anchors.centerIn: parent
        text: st.volIcon
        font.family: "Iosevka Nerd Font"; font.pixelSize: cfg.iconPx
        color: parent.hovered ? "#89dceb" : "#89b4fa"
        Behavior on color { ColorAnimation { duration: 150 } }
      }
      MouseArea {
        id: vMa; anchors.fill: parent; hoverEnabled: true
        onWheel: (w) => Quickshell.execDetached([
          "wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@",
          w.angleDelta.y > 0 ? "5%+" : "5%-"
        ])
        onClicked: Quickshell.execDetached(["wpctl","set-mute","@DEFAULT_AUDIO_SINK@","toggle"])
      }
    }

    // ── Brightness ──────────────────────────────────────────────
    Item {
      width: cfg.btnSize; height: cfg.btnSize
      property bool hovered: bMa.containsMouse
      Text {
        anchors.centerIn: parent
        text: "󰃟"
        font.family: "Iosevka Nerd Font"; font.pixelSize: cfg.iconPx
        color: parent.hovered ? "#f9e2af" : "#fab387"
        Behavior on color { ColorAnimation { duration: 150 } }
      }
      MouseArea {
        id: bMa; anchors.fill: parent; hoverEnabled: true
        onWheel: (w) => Quickshell.execDetached([
          "brightnessctl", "set",
          w.angleDelta.y > 0 ? "5%+" : "5%-"
        ])
      }
    }

    // ── Battery ─────────────────────────────────────────────────
    Item {
      width: cfg.btnSize; height: cfg.btnSize
      property bool hovered: batMa.containsMouse
      property int  batInt:  parseInt(st.batPercent) || 0
      Text {
        anchors.centerIn: parent
        text: st.batIcon
        font.family: "Iosevka Nerd Font"; font.pixelSize: cfg.iconPx
        color: st.isCharging       ? "#a6e3a1"
             : parent.batInt <= 15 ? "#f38ba8"
             : parent.batInt <= 30 ? "#fab387"
             : parent.hovered      ? "#f9e2af"
             :                       "#a6e3a1"
        Behavior on color { ColorAnimation { duration: 150 } }
      }
      MouseArea { id: batMa; anchors.fill: parent; hoverEnabled: true }
    }

    // ── Divider ─────────────────────────────────────────────────
    Rectangle {
      width: 1; height: cfg.pillH - 10
      color: Qt.rgba(1,1,1, 0.10)
    }

    // ── Power button ─────────────────────────────────────────────
    Rectangle {
      width:  cfg.pillH; height: cfg.pillH
      radius: cfg.pillR
      property bool hovered: pwMa.containsMouse
      color: hovered ? Qt.rgba(243/255,139/255,168/255, 0.28)
                     : Qt.rgba(243/255,139/255,168/255, 0.12)
      border.width: 1
      border.color: hovered ? Qt.rgba(243/255,139/255,168/255, 0.55)
                            : Qt.rgba(243/255,139/255,168/255, 0.22)
      Behavior on color        { ColorAnimation { duration: 150 } }
      Behavior on border.color { ColorAnimation { duration: 150 } }
      Text {
        anchors.centerIn: parent
        text: "󰐥"
        font.family: "Iosevka Nerd Font"; font.pixelSize: cfg.iconPx + 1
        color: parent.hovered ? "#f38ba8" : "#eba0ac"
        Behavior on color { ColorAnimation { duration: 150 } }
      }
      MouseArea {
        id: pwMa; anchors.fill: parent; hoverEnabled: true
        onClicked: Quickshell.execDetached(["bash","-c",
          "~/.config/quickshell/scripts/power-menu.sh"])
      }
    }
  }
}
