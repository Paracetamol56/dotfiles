import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.services

// The wallpaper on one screen: services/Wallpaper.qml's image, cropped to fill, behind
// everything. A new image cross-fades in over the old one.
PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "quickshell-wallpaper"
    color: Theme.crust

    // Two images: the incoming one fades in over the outgoing one
    property bool showingA: true

    function load(path) {
        const next = showingA ? imageB : imageA;
        next.source = path ? "file://" + path : "";
    }

    Component.onCompleted: imageA.source = Wallpaper.path ? "file://" + Wallpaper.path : ""

    Connections {
        target: Wallpaper
        function onPathChanged() {
            root.load(Wallpaper.path);
        }
    }

    Image {
        id: imageA
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        // Decode at screen size, not the image's full size
        sourceSize.width: root.width
        sourceSize.height: root.height
        opacity: root.showingA ? 1 : 0
        onStatusChanged: if (status === Image.Ready && !root.showingA && source !== "") root.showingA = true

        Behavior on opacity {
            NumberAnimation {
                duration: 600
                easing.type: Easing.InOutQuad
            }
        }
    }

    Image {
        id: imageB
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: root.width
        sourceSize.height: root.height
        opacity: root.showingA ? 0 : 1
        onStatusChanged: if (status === Image.Ready && root.showingA && source !== "") root.showingA = false

        Behavior on opacity {
            NumberAnimation {
                duration: 600
                easing.type: Easing.InOutQuad
            }
        }
    }
}
