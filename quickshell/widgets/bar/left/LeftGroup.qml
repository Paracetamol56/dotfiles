import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
  id: root
  required property var cfg
  required property var st

  height:        cfg.pillH
  implicitWidth: row.implicitWidth
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
    anchors.leftMargin:  0
    spacing:            8

    // ── Launcher ────────────────────────────────────────────
    Rectangle {
      width:  cfg.btnSize
      height: cfg.btnSize
      radius: cfg.pillR
      property bool hovered: lMa.containsMouse

      color: hovered ? Qt.rgba(137/255,180/255,250/255, 0.20)
      : Qt.rgba(137/255,180/255,250/255, 0.08)
      border.width: 1
      border.color: hovered ? Qt.rgba(137/255,180/255,250/255, 0.50)
      : Qt.rgba(137/255,180/255,250/255, 0.18)
      Behavior on color        { ColorAnimation { duration: 150 } }
      Behavior on border.color { ColorAnimation { duration: 150 } }

      Text {
        anchors.centerIn: parent
        text:           "󱓟"
        font.family:    "Iosevka Nerd Font"
        font.pixelSize: cfg.iconPx + 2
        color: parent.hovered ? "#89b4fa" : "#74c7ec"
        Behavior on color { ColorAnimation { duration: 150 } }
      }
      MouseArea {
        id: lMa
        anchors.fill: parent
        hoverEnabled: true
        onClicked: Quickshell.execDetached(["bash", "-c",
        "~/.config/rofi/scripts/rofi.sh app"])
      }
    }

    // ── Divider ──────────────────────────────────────────────
    Rectangle {
      width: 1; height: cfg.pillH - 10
      color: Qt.rgba(1,1,1, 0.10)
    }

    // ── Workspaces ───────────────────────────────────────────
    RowLayout {
      spacing: 0
      Repeater {
        model: [1,2,3,4,5,6,7,8]

        delegate: Item {
          id: wsTile
          required property int modelData

          property bool isActive: st.activeWs === modelData
          property bool isOpen:   st.workspaces.indexOf(modelData) !== -1
          property bool hovered:  tileMa.containsMouse

          width:  cfg.btnSize - 2
          height: cfg.btnSize - 2

          Rectangle {
            anchors.centerIn: parent
            width:   parent.width
            height:  parent.height
            radius:  cfg.pillR
            visible: wsTile.isActive
            color:   "#89b4fa"
          }

          Text {
            anchors.centerIn: parent
            text:           wsTile.modelData.toString()
            font.family:    "JetBrains Mono"
            font.pixelSize: 12
            font.weight:    Font.Bold
            color: wsTile.isActive ? "#1e1e2e"
            : wsTile.isOpen   ? "#89b4fa"
            : wsTile.hovered  ? "#a6adc8"
            :                   "#45475a"
            Behavior on color { ColorAnimation { duration: 120 } }
          }

          MouseArea {
            id: tileMa
            anchors.fill: parent
            hoverEnabled: true
            onClicked: Quickshell.execDetached([
              "hyprctl", "dispatch", "workspace",
              wsTile.modelData.toString()
            ])
            onWheel: (w) => Quickshell.execDetached([
              "hyprctl", "dispatch", "workspace",
              w.angleDelta.y > 0 ? "-1" : "+1"
            ])
          }
        }
      }
    }
  }
}
