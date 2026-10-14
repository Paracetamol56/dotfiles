import QtQuick
import "../bar"

// Dashboard text: the bar's font and colour animation, without its text shadow
BarText {
    shadow: false
    font.weight: Font.Normal
    elide: Text.ElideRight
}
