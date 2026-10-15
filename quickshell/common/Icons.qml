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
    readonly property string skipBack: "\ue15f" // skip-back
    readonly property string skipForward: "\ue160" // skip-forward
    readonly property string disc3: "\ue494" // disc-3
    readonly property string audioLines: "\ue55a" // audio-lines
    readonly property string sun: "\ue178" // sun
    readonly property string moon: "\ue11e" // moon
    readonly property string cloud: "\ue088" // cloud
    readonly property string cloudSun: "\ue216" // cloud-sun
    readonly property string cloudMoon: "\ue215" // cloud-moon
    readonly property string cloudRain: "\ue08e" // cloud-rain
    readonly property string cloudDrizzle: "\ue08a" // cloud-drizzle
    readonly property string cloudSnow: "\ue090" // cloud-snow
    readonly property string cloudLightning: "\ue08c" // cloud-lightning
    readonly property string cloudFog: "\ue214" // cloud-fog
    readonly property string wind: "\ue1b0" // wind
    readonly property string droplets: "\ue0b5" // droplets
    readonly property string mapPin: "\ue111" // map-pin
    readonly property string scan: "\ue257" // scan
    readonly property string squareDashed: "\ue1cb" // square-dashed
    readonly property string monitor: "\ue11d" // monitor
    readonly property string circleStop: "\ue083" // circle-stop
    readonly property string camera: "\ue064" // camera
    readonly property string sunrise: "\ue179" // sunrise
    readonly property string sunset: "\ue17a" // sunset
    readonly property string telescope: "\ue5c5" // telescope
    readonly property string sparkles: "\ue412" // sparkles
    readonly property string hourglass: "\ue296" // hourglass
    readonly property string compass: "\ue09b" // compass
    readonly property string sunMoon: "\ue2b2" // sun-moon
    readonly property string moonStar: "\ue410" // moon-star
    readonly property string orbit: "\ue3e7" // orbit
    readonly property string refreshCw: "\ue145" // refresh-cw
    readonly property string download: "\ue0b2" // download
    readonly property string lock: "\ue10b" // lock
    readonly property string logOut: "\ue10e" // log-out
    readonly property string snowflake: "\ue165" // snowflake
    readonly property string rotateCcw: "\ue148" // rotate-ccw
    readonly property string mouse: "\ue28e" // mouse
    readonly property string keyboard: "\ue284" // keyboard
    readonly property string lightbulb: "\ue1c2" // lightbulb
    readonly property string smartphone: "\ue163" // smartphone
    readonly property string speaker: "\ue166" // speaker
    readonly property string watch: "\ue1ad" // watch
    readonly property string laptop: "\ue1cd" // laptop
    readonly property string search: "\ue151" // search
    readonly property string x: "\ue1b2" // x
    readonly property string loaderCircle: "\ue10a" // loader-circle
    readonly property string ethernetPort: "\ue620" // ethernet-port
    readonly property string network: "\ue125" // network
    readonly property string mic: "\ue118" // mic
    readonly property string micOff: "\ue119" // mic-off
    readonly property string check: "\ue06c" // check
    readonly property string audioWaveform: "\ue55b" // audio-waveform
    readonly property string hardDrive: "\ue0ed" // hard-drive
    readonly property string arrowDown: "\ue042" // arrow-down
    readonly property string arrowUp: "\ue04a" // arrow-up
    readonly property string leaf: "\ue2de" // leaf
    readonly property string zap: "\ue1b4" // zap
    readonly property string gauge: "\ue1bf" // gauge
    readonly property string activity: "\ue038" // activity
    readonly property string list: "\ue106" // list
    readonly property string factory: "\ue29f" // factory
    readonly property string gpu: "\ue66a" // gpu
    readonly property string file: "\ue0c0" // file
    readonly property string fileImage: "\ue31c" // file-image
    readonly property string fileVideo: "\ue321" // file-video
    readonly property string fileAudio: "\ue31a" // file-audio
    readonly property string fileCode: "\ue0c3" // file-code
    readonly property string fileArchive: "\ue30d" // file-archive
    readonly property string fileClock: "\ue315" // file-clock
    readonly property string squareTerminal: "\ue20a" // square-terminal
    readonly property string externalLink: "\ue0b9" // external-link
    readonly property string shield: "\ue158" // shield
    readonly property string shieldOff: "\ue15a" // shield-off
    readonly property string plus: "\ue13d" // plus
    readonly property string fileUp: "\ue32a" // file-up
    readonly property string bell: "\ue059" // bell
    readonly property string bellOff: "\ue05a" // bell-off
    readonly property string bellRing: "\ue224" // bell-ring
    readonly property string trash2: "\ue18e" // trash-2
}
