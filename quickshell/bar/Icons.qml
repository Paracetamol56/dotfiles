pragma Singleton

import QtQuick
import Quickshell

// Lucide icons (lucide-static 1.56.0, assets/fonts/lucide.ttf, ISC licence).
// Codepoints generated from the package's font/info.json.
Singleton {
    readonly property string font: loader.name

    FontLoader {
        id: loader
        source: Qt.resolvedUrl("../assets/fonts/lucide.ttf")
    }

    readonly property string rocket: "\ue286" // rocket
    readonly property string power: "\ue140" // power
    readonly property string terminal: "\ue181" // terminal
    readonly property string globe: "\ue0e8" // globe
    readonly property string code: "\ue093" // code
    readonly property string codeXml: "\ue206" // code-xml
    readonly property string gamepad2: "\ue0df" // gamepad-2
    readonly property string music: "\ue122" // music
    readonly property string video: "\ue1a5" // video
    readonly property string clapperboard: "\ue29b" // clapperboard
    readonly property string palette: "\ue1dd" // palette
    readonly property string image: "\ue0f6" // image
    readonly property string messageCircle: "\ue116" // message-circle
    readonly property string fileText: "\ue0cc" // file-text
    readonly property string fileSpreadsheet: "\ue326" // file-spreadsheet
    readonly property string presentation: "\ue4ae" // presentation
    readonly property string folder: "\ue0d7" // folder
    readonly property string history: "\ue1f5" // history
    readonly property string shieldCheck: "\ue1ff" // shield-check
    readonly property string appWindow: "\ue426" // app-window
    readonly property string layoutGrid: "\ue0ff" // layout-grid
    readonly property string thermometer: "\ue186" // thermometer
    readonly property string thermometerSnowflake: "\ue187" // thermometer-snowflake
    readonly property string thermometerSun: "\ue188" // thermometer-sun
    readonly property string memoryStick: "\ue445" // memory-stick
    readonly property string cpu: "\ue0a9" // cpu
    readonly property string triangleAlert: "\ue193" // triangle-alert
    readonly property string coffee: "\ue096" // coffee
    readonly property string clock: "\ue087" // clock
    readonly property string calendar: "\ue063" // calendar
    readonly property string wifi: "\ue1ae" // wifi
    readonly property string wifiHigh: "\ue5f7" // wifi-high
    readonly property string wifiLow: "\ue5f8" // wifi-low
    readonly property string wifiZero: "\ue5f9" // wifi-zero
    readonly property string wifiOff: "\ue1af" // wifi-off
    readonly property string bluetooth: "\ue05c" // bluetooth
    readonly property string bluetoothConnected: "\ue1b8" // bluetooth-connected
    readonly property string bluetoothOff: "\ue1b9" // bluetooth-off
    readonly property string packageCheck: "\ue266" // package-check
    readonly property string packagePlus: "\ue268" // package-plus
    readonly property string play: "\ue13c" // play
    readonly property string pause: "\ue12e" // pause
    readonly property string volume: "\ue1a9" // volume
    readonly property string volume1: "\ue1aa" // volume-1
    readonly property string volume2: "\ue1ab" // volume-2
    readonly property string volumeX: "\ue1ac" // volume-x
    readonly property string headphones: "\ue0f1" // headphones
    readonly property string battery: "\ue053" // battery
    readonly property string batteryLow: "\ue056" // battery-low
    readonly property string batteryMedium: "\ue057" // battery-medium
    readonly property string batteryFull: "\ue055" // battery-full
    readonly property string batteryCharging: "\ue054" // battery-charging
    readonly property string batteryWarning: "\ue3ac" // battery-warning
}
