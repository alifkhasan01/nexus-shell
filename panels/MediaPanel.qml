import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import "../" as Root

PanelWindow {
    id: root

    property bool open: false
    signal closeRequested()

    anchors { top: true; left: true; right: true; bottom: true }
    color: "transparent"
    visible: showPanel

    property bool showPanel: false
    onOpenChanged: if (open) showPanel = true

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-media"
    WlrLayershell.exclusiveZone: 0

    // ── Media player ───────────────────────────────────────────────────────
    property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    property bool hasPlayer: player !== null

    // ── Equalizer state ────────────────────────────────────────────────────
    // 10-band: 31 63 125 250 500 1k 2k 4k 8k 16k
    property var eqBands: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    property var eqLabels: ["31", "63", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"]
    property string activePreset: "Flat"
    property var presets: ["Flat", "Bass", "Treble", "Vocal", "Pop", "Rock", "Jazz", "Classic"]

    // Gain values per preset (index matches eqBands)
    property var presetValues: ({
        "Flat":    [ 0,  0,  0,  0,  0,  0,  0,  0,  0,  0],
        "Bass":    [ 6,  5,  3,  1,  0,  0, -1, -1, -2, -2],
        "Treble":  [-2, -2, -1,  0,  0,  1,  3,  4,  5,  6],
        "Vocal":   [-2, -1,  0,  1,  3,  4,  4,  3,  1,  0],
        "Pop":     [-1,  2,  3,  2,  0, -1,  2,  3,  2,  1],
        "Rock":    [ 5,  4,  3, -1, -2,  0,  1,  3,  4,  3],
        "Jazz":    [ 3,  2,  1,  2,  0, -1,  0,  2,  3,  2],
        "Classic": [ 0,  0,  0,  0, -2, -2,  0,  3,  4,  4]
    })

    // ── EasyEffects process ────────────────────────────────────────────────
    Process {
        id: eqProc
        running: false
    }

    function loadPreset(name) {
        activePreset = name
        const vals = presetValues[name]
        if (vals) {
            // Update slider values
            const newBands = []
            for (let i = 0; i < 10; i++) newBands.push(vals[i])
            eqBands = newBands
        }
        eqProc.command = ["easyeffects", "--load-preset", name]
        eqProc.running = false
        eqProc.running = true
    }

    // Simpan custom EQ lalu load ke EasyEffects
    Process { id: saveProc; running: false }

    function applyCustomEq() {
        // Schema EasyEffects 7/8: band harus nested di "left"/"right",
        // preset disimpan di ~/.local/share/easyeffects/output/
        const bands = eqBands
        const freq = [31, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
        let bandObj = ""
        for (let i = 0; i < 10; i++) {
            bandObj += `"band${i}": { "frequency": ${freq[i]}.0, "gain": ${bands[i].toFixed(1)}, "mode": "RLC(BT)", "mute": false, "q": 1.5047, "slope": "x1", "solo": false, "type": "Bell" }`
            if (i < 9) bandObj += ",\n        "
        }
        const json = `{
  "output": {
    "blocklist": [],
    "equalizer#0": {
      "bypass": false,
      "input-gain": 0.0,
      "output-gain": 0.0,
      "mode": "IIR",
      "num-bands": 10,
      "split-channels": false,
      "left": {
        ${bandObj}
      },
      "right": {
        ${bandObj}
      }
    },
    "plugins_order": ["equalizer#0"]
  }
}`
        saveProc.command = ["sh", "-c",
            `mkdir -p ~/.local/share/easyeffects/output && printf '%s' '${json.replace(/'/g, `'\\''`)}' > ~/.local/share/easyeffects/output/Custom.json && easyeffects --load-preset Custom`
        ]
        saveProc.running = false
        saveProc.running = true
        activePreset = ""
    }

    // ── Progress timer ─────────────────────────────────────────────────────
    Timer {
        interval: 1000
        running: root.hasPlayer && root.player.playbackState === MprisPlaybackState.Playing
        repeat: true
        onTriggered: {} // triggers binding re-eval for position display
    }

    // ── Klik luar untuk tutup ──────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        onClicked: root.closeRequested()
    }

    // ── Card utama ─────────────────────────────────────────────────────────
    Rectangle {
        id: card

        anchors.top: parent.top
        anchors.topMargin: 5
        anchors.horizontalCenter: parent.horizontalCenter

        width: 480
        height: contentCol.implicitHeight + 32
        radius: 20
        color: Root.Colors.mantle
        border.color: Root.Colors.surface1
        border.width: 1

        // ── Animasi slide dari atas ────────────────────────────────────────
        opacity: 0
        transform: Translate { id: cardTranslate; y: -40 }

        states: State {
            name: "open"
            when: root.open
            PropertyChanges { target: card; opacity: 1 }
            PropertyChanges { target: cardTranslate; y: 0 }
        }

        transitions: [
            Transition {
                from: ""; to: "open"
                ParallelAnimation {
                    NumberAnimation {
                        target: cardTranslate; property: "y"
                        duration: Root.Appearance.animation.elementMoveEnter.duration
                        easing.type: Root.Appearance.animation.elementMoveEnter.type
                        easing.bezierCurve: Root.Appearance.animation.elementMoveEnter.bezierCurve
                    }
                    OpacityAnimator {
                        target: card
                        duration: Root.Appearance.animation.elementMoveEnter.duration
                    }
                }
            },
            Transition {
                from: "open"; to: ""
                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation {
                            target: cardTranslate; property: "y"
                            duration: Root.Appearance.animation.elementMoveExit.duration
                            easing.type: Root.Appearance.animation.elementMoveExit.type
                            easing.bezierCurve: Root.Appearance.animation.elementMoveExit.bezierCurve
                        }
                        OpacityAnimator {
                            target: card
                            duration: Root.Appearance.animation.elementMoveExit.duration
                        }
                    }
                    ScriptAction { script: root.showPanel = false }
                }
            }
        ]

        Behavior on color { ColorAnimation {
            duration: Root.Appearance.animation.elementMoveFast.duration
            easing.type: Root.Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
        }}

        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            id: contentCol
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                topMargin: 16
                leftMargin: 20
                rightMargin: 20
            }
            spacing: 16

            // ── MEDIA PLAYER ───────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                // Album art
                Rectangle {
                    width: 72
                    height: 72
                    radius: 36
                    color: Root.Colors.surface1
                    clip: true
                    Behavior on color { ColorAnimation {
                        duration: Root.Appearance.animation.elementMoveFast.duration
                        easing.type: Root.Appearance.animation.elementMoveFast.type
                        easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
                    }}

                    Image {
                        anchors.fill: parent
                        source: root.hasPlayer ? root.player.trackArtUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        visible: source !== ""

                        RotationAnimator on rotation {
                            running: root.hasPlayer &&
                                     root.player.playbackState === MprisPlaybackState.Playing &&
                                     visible
                            from: 0; to: 360
                            duration: 16000
                            loops: Animation.Infinite
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: !root.hasPlayer || root.player.trackArtUrl === ""
                        text: "󰝚"
                        font.pixelSize: 28
                        color: Root.Colors.subtext
                    }
                }

                // Info + controls
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        Layout.fillWidth: true
                        text: root.hasPlayer ? (root.player.trackTitle || "Tidak ada judul") : "Tidak ada media"
                        color: Root.Colors.text
                        font.pixelSize: 15
                        font.bold: true
                        elide: Text.ElideRight
                        Behavior on color { ColorAnimation {
                            duration: Root.Appearance.animation.elementMoveFast.duration
                            easing.type: Root.Appearance.animation.elementMoveFast.type
                            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
                        }}
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.hasPlayer ? (root.player.trackArtist || "Unknown Artist") : ""
                        color: Root.Colors.subtext
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        Behavior on color { ColorAnimation {
                            duration: Root.Appearance.animation.elementMoveFast.duration
                            easing.type: Root.Appearance.animation.elementMoveFast.type
                            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
                        }}
                    }

                    // Progress bar
                    Item {
                        Layout.fillWidth: true
                        height: 4
                        visible: root.hasPlayer

                        Rectangle {
                            anchors.fill: parent
                            radius: 2
                            color: Root.Colors.surface2
                        }

                        Rectangle {
                            height: parent.height
                            radius: 2
                            color: Root.Colors.blue
                            width: {
                                if (!root.hasPlayer || root.player.length <= 0) return 0
                                return parent.width * (root.player.position / root.player.length)
                            }
                            Behavior on width { NumberAnimation {
                                duration: 200
                                easing.type: Easing.Linear
                            }}
                        }

                        // Scrubbing
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: (mouse) => {
                                if (!root.hasPlayer || root.player.length <= 0) return
                                root.player.position = root.player.length * (mouse.x / width)
                            }
                        }
                    }

                    // Time row
                    RowLayout {
                        Layout.fillWidth: true
                        visible: root.hasPlayer && root.player.length > 0
                        spacing: 0

                        Text {
                            text: {
                                if (!root.hasPlayer) return "0:00"
                                const s = Math.floor(root.player.position)
                                return Math.floor(s/60) + ":" + String(s%60).padStart(2,"0")
                            }
                            font.pixelSize: 10
                            color: Root.Colors.subtext
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: {
                                if (!root.hasPlayer || root.player.length <= 0) return ""
                                const s = Math.floor(root.player.length)
                                return Math.floor(s/60) + ":" + String(s%60).padStart(2,"0")
                            }
                            font.pixelSize: 10
                            color: Root.Colors.subtext
                        }
                    }

                    // Playback controls
                    RowLayout {
                        spacing: 20
                        visible: root.hasPlayer

                        Text {
                            text: "󰒮"
                            font.pixelSize: 18
                            color: Root.Colors.text
                            opacity: root.hasPlayer && root.player.canGoPrevious ? 1.0 : 0.3
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -8
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (root.hasPlayer && root.player.canGoPrevious) root.player.previous()
                            }
                        }
                        Text {
                            text: root.hasPlayer && root.player.playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊"
                            font.pixelSize: 22
                            color: Root.Colors.blue
                            opacity: root.hasPlayer && root.player.canControl ? 1.0 : 0.3
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -8
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!root.hasPlayer || !root.player.canControl) return
                                    if (root.player.playbackState === MprisPlaybackState.Playing)
                                        root.player.pause()
                                    else
                                        root.player.play()
                                }
                            }
                        }
                        Text {
                            text: "󰒭"
                            font.pixelSize: 18
                            color: Root.Colors.text
                            opacity: root.hasPlayer && root.player.canGoNext ? 1.0 : 0.3
                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -8
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (root.hasPlayer && root.player.canGoNext) root.player.next()
                            }
                        }
                    }
                }
            }

            // ── DIVIDER ────────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Root.Colors.surface1
            }

            // ── EQUALIZER HEADER ───────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: "Equalizer"
                    font.pixelSize: 13
                    font.bold: true
                    color: Root.Colors.text
                }

                Item { Layout.fillWidth: true }

                // Active preset badge
                Rectangle {
                    visible: root.activePreset !== ""
                    width: presetBadge.implicitWidth + 16
                    height: 22
                    radius: 6
                    color: Root.Colors.blue
                    opacity: 0.85

                    Text {
                        id: presetBadge
                        anchors.centerIn: parent
                        text: root.activePreset
                        font.pixelSize: 11
                        font.bold: true
                        color: Root.Colors.mantle
                    }
                }
            }

            // ── EQ SLIDERS ─────────────────────────────────────────────────
            Item {
                Layout.fillWidth: true
                height: 130

                // EQ curve canvas — background di belakang slider
                Canvas {
                    id: eqCurve
                    anchors.fill: parent
                    anchors.bottomMargin: 22

                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)

                        const bands = root.eqBands
                        const n = bands.length
                        const padX = 12
                        const step = (width - padX * 2) / (n - 1)
                        const mid = height / 2
                        const scale = height / 28  // ±14dB range

                        ctx.beginPath()
                        ctx.strokeStyle = Qt.rgba(
                            Root.Colors.blue.r,
                            Root.Colors.blue.g,
                            Root.Colors.blue.b,
                            0.5
                        )
                        ctx.lineWidth = 2
                        ctx.lineJoin = "round"
                        ctx.lineCap = "round"

                        for (let i = 0; i < n; i++) {
                            const x = padX + i * step
                            const y = mid - bands[i] * scale
                            if (i === 0) ctx.moveTo(x, y)
                            else ctx.lineTo(x, y)
                        }
                        ctx.stroke()

                        // Fill under curve
                        ctx.lineTo(padX + (n-1)*step, mid)
                        ctx.lineTo(padX, mid)
                        ctx.closePath()
                        ctx.fillStyle = Qt.rgba(
                            Root.Colors.blue.r,
                            Root.Colors.blue.g,
                            Root.Colors.blue.b,
                            0.08
                        )
                        ctx.fill()
                    }

                    Connections {
                        target: root
                        function onEqBandsChanged() { eqCurve.requestPaint() }
                    }

                    Component.onCompleted: requestPaint()
                }

                // Sliders row
                Row {
                    anchors.fill: parent
                    spacing: 0

                    Repeater {
                        model: 10

                        delegate: Item {
                            required property int index
                            width: parent.width / 10
                            height: parent.height

                            // Slider track
                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: parent.top
                                anchors.bottom: freqLabel.top
                                anchors.bottomMargin: 4
                                width: 4
                                radius: 2
                                color: Root.Colors.surface1

                                // Fill portion
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: parent.width
                                    radius: parent.radius
                                    color: Root.Colors.blue
                                    opacity: 0.7

                                    // Calculate fill from center
                                    property real gain: root.eqBands[index] ?? 0
                                    property real trackH: parent.height
                                    property real mid: trackH / 2
                                    property real scale: trackH / 28

                                    y: gain >= 0 ? mid - gain * scale : mid
                                    height: Math.abs(gain) * scale
                                }
                            }

                            // Slider handle
                            Rectangle {
                                id: sliderHandle
                                width: 14
                                height: 14
                                radius: 7
                                color: Root.Colors.blue
                                anchors.horizontalCenter: parent.horizontalCenter

                                property real trackTop: 0
                                property real trackBottom: parent.height - freqLabel.height - 4 - height
                                property real trackH: trackBottom - trackTop
                                property real mid: trackTop + trackH / 2
                                property real scale: trackH / 28  // ±14dB

                                y: {
                                    const gain = root.eqBands[index] ?? 0
                                    return mid - gain * scale - height / 2
                                }

                                Behavior on y { NumberAnimation {
                                    duration: Root.Appearance.animation.elementMoveFast.duration
                                    easing.type: Root.Appearance.animation.elementMoveFast.type
                                    easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
                                }}

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -8
                                    cursorShape: Qt.SizeVerCursor
                                    drag.target: sliderHandle
                                    drag.axis: Drag.YAxis
                                    drag.minimumY: sliderHandle.trackTop - sliderHandle.height / 2
                                    drag.maximumY: sliderHandle.trackBottom - sliderHandle.height / 2

                                    onPositionChanged: {
                                        if (!drag.active) return
                                        const mid = sliderHandle.mid
                                        const scale = sliderHandle.scale
                                        const gain = -(sliderHandle.y + sliderHandle.height/2 - mid) / scale
                                        const clamped = Math.max(-12, Math.min(12, gain))
                                        const rounded = Math.round(clamped * 2) / 2

                                        const newBands = root.eqBands.slice()
                                        newBands[index] = rounded
                                        root.eqBands = newBands
                                        root.activePreset = ""
                                        eqCurve.requestPaint()
                                    }

                                    onReleased: root.applyCustomEq()
                                }
                            }

                            // Frequency label
                            Text {
                                id: freqLabel
                                anchors.bottom: parent.bottom
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.eqLabels[index]
                                font.pixelSize: 9
                                color: Root.Colors.subtext
                            }
                        }
                    }
                }
            }

            // ── PRESET BUTTONS ─────────────────────────────────────────────
            Grid {
                Layout.fillWidth: true
                columns: 4
                spacing: 6
                bottomPadding: 4

                Repeater {
                    model: root.presets

                    delegate: Rectangle {
                        required property string modelData
                        required property int index

                        width: (contentCol.width - 3 * 6) / 4
                        height: 32
                        radius: 8
                        color: root.activePreset === modelData
                            ? Root.Colors.blue
                            : (presetMa.containsMouse ? Root.Colors.surface2 : Root.Colors.surface1)

                        Behavior on color { ColorAnimation {
                            duration: Root.Appearance.animation.elementMoveFast.duration
                            easing.type: Root.Appearance.animation.elementMoveFast.type
                            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
                        }}

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: 11
                            font.bold: root.activePreset === modelData
                            color: root.activePreset === modelData
                                ? Root.Colors.mantle
                                : Root.Colors.text
                            Behavior on color { ColorAnimation {
                                duration: Root.Appearance.animation.elementMoveFast.duration
                                easing.type: Root.Appearance.animation.elementMoveFast.type
                                easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
                            }}
                        }

                        MouseArea {
                            id: presetMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.loadPreset(modelData)
                        }
                    }
                }
            }
        }
    }
}
