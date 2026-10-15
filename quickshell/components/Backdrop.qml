import QtQuick
import QtQuick.Effects
import qs.common

// Dashboard background, translated from the Svelte/Tailwind hero section:
//   .dots  surface2 dot grid at 60%, masked by `ellipse 70% 60% at 50% 40%`
//   .glow  mauve dot grid revealed in a 14rem circle around the cursor while active
//   blob   rounded-full mauve/25 → blue/20 gradient at the top, blur-3xl
// Both masks are linear radial fades, so each dot's opacity is computed directly.
Item {
    id: root

    // Hovered: fades the glow in (Tailwind `transition-opacity duration-500`)
    property bool active: false
    // Cursor position, in this item's coordinates
    property real glowX: width / 2
    property real glowY: height / 2

    clip: true

    // .backdrop mask: radial-gradient(ellipse 70% 60% at 50% 40%, black, transparent)
    function ellipse(x, y) {
        const dx = (x - width * 0.5) / (width * 0.7);
        const dy = (y - height * 0.4) / (height * 0.6);
        return Math.max(0, 1 - Math.sqrt(dx * dx + dy * dy));
    }

    // ── Blurred gradient blob at the top (under the dots) ─

    Rectangle {
        id: blob
        // h-72, w-[min(48rem,100%)], left-1/2 -translate-x-1/2, top-0
        width: Math.min(768, root.width)
        height: 288
        anchors.horizontalCenter: parent.horizontalCenter
        // Raised above top-0 so the glow sits behind the header
        y: -100
        radius: height / 2
        visible: false
        gradient: Gradient {
            orientation: Gradient.Horizontal

            GradientStop {
                position: 0
                color: Qt.alpha(Theme.mauve, 0.25)
            }
            GradientStop {
                position: 1
                color: Qt.alpha(Theme.blue, 0.2)
            }
        }
    }

    // blur-3xl is a 64px blur; the multiplier spreads it further, closer to CSS
    MultiEffect {
        x: blob.x
        y: blob.y
        width: blob.width
        height: blob.height
        source: blob
        autoPaddingEnabled: true
        blurEnabled: true
        blurMax: 64
        blur: 1
        blurMultiplier: 2
    }

    // ── Dots ─────────────────────────────────────────────

    DotGrid {
        anchors.fill: parent
        color: Theme.surface2
        dotRadius: 1
        opacity: 0.6
        mask: (x, y) => root.ellipse(x, y)
    }

    // The fade lives on a wrapper: a Canvas that starts at opacity 0 never paints
    Item {
        anchors.fill: parent
        opacity: root.active ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 500
            }
        }

        DotGrid {
            anchors.fill: parent
            color: Theme.mauve
            dotRadius: 1.5
            // .glow mask: radial-gradient(circle 14rem at var(--x) var(--y), black, transparent).
            // Re-created whenever the cursor moves, which repaints the grid
            mask: {
                const gx = root.glowX, gy = root.glowY;
                return (x, y) => root.ellipse(x, y) * Math.max(0, 1 - Math.hypot(x - gx, y - gy) / 224);
            }
        }
    }
}
