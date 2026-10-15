import QtQuick
import qs.common
import qs.components

// One clock digit that rolls to the next: the old one slides up and out while the new one
// comes in from below. Fixed width (the widest digit) so the clock doesn't shift.
Item {
    id: root

    property string digit: "0"
    property int pixelSize: 120
    property color color: Theme.text
    // Hollow digits: only the glyph outline, in `color`
    property bool outline: false

    // The two labels take turns being the current one
    property bool showingA: true

    implicitWidth: metrics.advanceWidth
    implicitHeight: a.implicitHeight
    clip: true

    TextMetrics {
        id: metrics
        font: a.font
        text: "0"
    }

    onDigitChanged: {
        const incoming = showingA ? b : a;
        const outgoing = showingA ? a : b;
        incoming.text = digit;
        roll.incoming = incoming;
        roll.outgoing = outgoing;
        showingA = !showingA;
        roll.restart();
    }

    Label {
        id: a
        width: root.width
        horizontalAlignment: Text.AlignHCenter
        // Set once, not bound: afterwards onDigitChanged decides which label shows what
        Component.onCompleted: text = root.digit
        font.pixelSize: root.pixelSize
        font.weight: Font.Bold
        color: root.outline ? "transparent" : root.color
        style: root.outline ? Text.Outline : Text.Normal
        styleColor: root.color
    }

    Label {
        id: b
        width: root.width
        y: root.height
        horizontalAlignment: Text.AlignHCenter
        font: a.font
        color: a.color
        style: a.style
        styleColor: a.styleColor
    }

    ParallelAnimation {
        id: roll
        property Item incoming
        property Item outgoing

        NumberAnimation {
            target: roll.outgoing
            property: "y"
            from: 0
            to: -root.height
            duration: 350
            easing.type: Easing.InOutCubic
        }
        NumberAnimation {
            target: roll.incoming
            property: "y"
            from: root.height
            to: 0
            duration: 350
            easing.type: Easing.InOutCubic
        }
        NumberAnimation {
            target: roll.outgoing
            property: "opacity"
            from: 1
            to: 0
            duration: 350
        }
        NumberAnimation {
            target: roll.incoming
            property: "opacity"
            from: 0
            to: 1
            duration: 350
        }
    }
}
