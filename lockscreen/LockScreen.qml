pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Wayland._Screencopy
import Quickshell.Services.Pam
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import "../" as Root

// ── Lock Screen ────────────────────────────────────────────────────────────
// Bergaya caelestia: blur screencopy background, jam dua-warna besar,
// tanggal, profile picture, password dots animated, state message.
//
// Trigger: GlobalShortcut quickshell:lock  →  lockScreenRef.lock()
// Hyprland: bind = $mod, L, global, quickshell:lock

Scope {
    id: root

    // ── PS button icons untuk password indicator ─────────────────────
    readonly property var psIcons:  ["\uf111", "\uf00d", "\uf0d8", "\uf0c8"]
    readonly property var psColors: ["#89b4fa", "#f38ba8", "#a6e3a1", "#cba6f7"]
    // (blue, red, green, mauve — hardcode agar bisa diakses dari delegate)

    // ── PAM state (dibagikan ke semua surface) ──────────────────────────
    property string _buffer:        ""
    property string _message:       ""
    property bool   _messageIsErr:  false
    property bool   _checking:      false

    // ── Kutipan motivasi ────────────────────────────────────────────────
    // Dicari dari artikel online (Kompas, CNN, Brilio, dll) — campuran
    // bijak, santai, dan lucu biar gak kaku.
    readonly property var quotes: [
        "Hidup bukan seperti menunggu badai berlalu, tapi belajar menari di tengah hujan.",
        "Mimpi besar dimulai dari langkah kecil.",
        "Jangan takut gagal, takutlah untuk tidak mencoba.",
        "Setiap hari adalah kesempatan baru untuk memulai lagi.",
        "Kamu lebih kuat dari yang kamu kira.",
        "Waktu terbaik untuk memulai adalah sekarang.",
        "Perjalanan ribuan mil dimulai dari satu langkah.",
        "Tetap bergerak walau perlahan.",
        "Sukses datang pada mereka yang berani mencoba.",
        "Jangan pernah menyerah pada apa yang benar-benar kamu inginkan.",
        "Kebahagiaan bukan tujuan, melainkan perjalanan.",
        "Rintangan ada untuk membuatmu lebih kuat.",
        "Capek itu wajar. Semangat? Opsional.",
        "Kalau hidupmu stuck, anggap saja lagi buffering.",
        "Kalem. Rezekimu nggak pakai deadline.",
        "Tenang... hidup begini ke semua orang.",
        "Kalau kamu capek dikasih kuat, gapapa. Superhero aja kadang cuti.",
        "Tarik napas. Jangan tarik mantan.",
        "Santai tapi jangan santuy dalam kerja.",
        "Jangan jadi penonton, jadilah pemain utama.",
        "Hari ini gagal, besok bangkit dengan gaya.",
        "Hidup itu kayak sandal jepit: hilang satu, langsung pincang.",
        "Kerja keras, main santai, hasil maksimal.",
        "Masih ada harapan selama kita terus berusaha.",
    ]

    // ── System status (dibagikan ke status row) ─────────────────────────
    property var device:   UPower.displayDevice
    property int battPercent: device?.percentage ? Math.round(device.percentage * 100) : 0
    property bool charging:   device?.state === UPowerDeviceState.Charging

    property var _defaultSink: Pipewire.defaultAudioSink
    property real volLevel: _defaultSink?.audio ? _defaultSink.audio.volume : 0
    property bool  volMuted: _defaultSink?.audio ? _defaultSink.audio.muted : true

    property string netType: "none"
    property string netName: ""
    property int    netStrength: 0
    function _refreshNet() { netPoll.running = true }

    // ── Auto-suspend: kalau masih terkunci & idle, tidur setelah N menit ──
    readonly property int autoSuspendMinutes: 15

    // ── Media player aktif ───────────────────────────────────────────────
    property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    property bool hasMedia: root.player !== null &&
                            root.player?.trackTitle !== "" &&
                            root.player?.trackTitle !== undefined

    function _handleKey(event) {
        // Blok input hanya saat sedang checking — bukan berdasarkan pamCtx.active
        // agar setelah gagal user langsung bisa mengetik lagi
        if (root._checking) { event.accepted = true; return }

        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (root._buffer.length === 0) { event.accepted = true; return }
            root._checking = true
            root._message  = ""
            root._messageIsErr = false
            pamCtx.start()
        } else if (event.key === Qt.Key_Backspace) {
            if (event.modifiers & Qt.ControlModifier)
                root._buffer = ""
            else
                root._buffer = root._buffer.slice(0, -1)
        } else if (event.text.length > 0 && !/[\x00-\x1F\x7F]/.test(event.text)) {
            root._buffer += event.text
        }
        event.accepted = true
    }

    // ── PAM Context ─────────────────────────────────────────────────────
    PamContext {
        id: pamCtx
        config: "system-auth"

        onMessageChanged: {
            root._message      = message
            root._messageIsErr = messageIsError
        }

        onResponseRequiredChanged: {
            if (responseRequired) {
                respond(root._buffer)
                root._buffer = ""
            }
        }

        onCompleted: result => {
            root._checking = false
            root._buffer   = ""

            if (result === PamResult.Success) {
                sessionLock.locked = false
            } else {
                root._message      = result === PamResult.MaxTries
                                     ? "Terlalu banyak percobaan"
                                     : "Password salah"
                root._messageIsErr = true
                msgReset.restart()
                // Pastikan PAM context sepenuhnya selesai agar bisa di-start ulang
                if (pamCtx.active) pamCtx.abort()
            }
        }
    }

    Timer {
        id: msgReset
        interval: 3000
        onTriggered: { root._message = ""; root._messageIsErr = false }
    }

    Process {
        id: netPoll
        command: ["sh", "-c",
            "t=$(nmcli -t -f TYPE,STATE,CONNECTION dev | grep ':connected:' | head -1); " +
            "[ -z \"$t\" ] && exit 0; " +
            "ty=$(printf '%s' \"$t\" | cut -d: -f1); " +
            "cn=$(printf '%s' \"$t\" | cut -d: -f3-); " +
            "sg=0; " +
            "if [ \"$ty\" = wifi ]; then " +
            "sg=$(nmcli -t -f IN-USE,SIGNAL dev wifi list | grep '^\\*' | head -1 | cut -d: -f2); " +
            "fi; " +
            "printf '%s:connected:%s:%s\\n' \"$ty\" \"$cn\" \"${sg:-0}\""
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = text.trim()
                if (raw === "") { root.netType = "none"; root.netName = ""; return }
                const parts = raw.split(":")
                const type  = parts[0] || ""
                const sig   = parseInt(parts[parts.length - 1]) || 0
                const conn  = parts.slice(2, parts.length - 1).join(":") || ""
                if (type === "ethernet" || type === "bond" || type === "vlan") {
                    root.netType = "ethernet"; root.netName = conn
                } else if (type === "wifi") {
                    root.netType = "wifi"; root.netStrength = sig; root.netName = conn
                } else {
                    root.netType = "none"; root.netName = ""
                }
            }
        }
    }

    Timer {
        interval: 10000; running: true; repeat: true
        triggeredOnStart: true
        onTriggered: netPoll.running = true
    }

    // ── Auto-suspend ────────────────────────────────────────────────────
    Process {
        id: suspendProc
        // command diisi saat dipanggil
    }

    Timer {
        id: autoSuspendTimer
        interval: root.autoSuspendMinutes * 60 * 1000
        onTriggered: {
            suspendProc.command = ["systemctl", "suspend"]
            suspendProc.running = true
        }
    }

    // ── Session Lock ─────────────────────────────────────────────────────
    WlSessionLock {
        id: sessionLock

        // Mulai/hentikan hitungan auto-suspend mengikuti status lock
        onLockedChanged: {
            if (locked)
                autoSuspendTimer.restart()
            else
                autoSuspendTimer.stop()
        }

        WlSessionLockSurface {
            id: surface

            color: "transparent"

            // Item ini yang memegang focus keyboard — HARUS jadi child
            // langsung dari contentItem supaya WlSessionLockSurface
            // meneruskan keyboard events ke sini.
            Item {
                anchors.fill: parent
                focus: true

                // Paksa focus setiap kali surface muncul
                Component.onCompleted: forceActiveFocus()
                onVisibleChanged: if (visible) forceActiveFocus()

                Keys.onPressed: event => root._handleKey(event)

                // ── Blur screencopy background ────────────────────────
                ScreencopyView {
                    id: bgCopy
                    anchors.fill: parent
                    captureSource: surface.screen

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        anchors.fill: bgCopy
                        source: bgCopy
                        autoPaddingEnabled: false
                        blurEnabled: true
                        blur: 1.0
                        blurMax: 48
                        blurMultiplier: 2.0
                    }
                }

                // Overlay gelap
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, 0.45)
                }

                // ── Media card (top center) — gaya dashboard ────────────────
                Rectangle {
                    id: mediaCard
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 42
                    width: Math.min(400, parent.width * 0.92)
                    height: 92
                    radius: 16
                    color: Qt.rgba(Root.Colors.surface0.r, Root.Colors.surface0.g,
                                   Root.Colors.surface0.b, 0.75)
                    border.color: Root.Colors.surface2
                    border.width: 1
                    visible: hasMedia

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        // ── Cover art ────────────────────────────────────
                        Rectangle {
                            width: 64
                            height: 64
                            radius: 12
                            color: Root.Colors.surface1
                            clip: true

                            Image {
                                id: mediaArtImg
                                anchors.fill: parent
                                source: root.player?.trackArtUrl ?? ""
                                sourceSize.width: 128
                                sourceSize.height: 128
                                fillMode: Image.PreserveAspectCrop
                                smooth: true
                                visible: source !== ""
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: mediaArtImg.source === ""
                                text: "󰝚"
                                font.pixelSize: 24
                                color: Root.Colors.subtext
                            }
                        }

                        // ── Info + kontrol ────────────────────────────────
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: root.player?.trackTitle ?? "Unknown Title"
                                color: Root.Colors.text
                                font.pixelSize: 14
                                font.bold: true
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: root.player?.trackArtist ?? "Unknown Artist"
                                color: Root.Colors.subtext
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 14
                                Layout.topMargin: 2

                                Text {
                                    text: "󰒮"
                                    font.family: "CaskaydiaCove Nerd Font"
                                    font.pixelSize: 16
                                    color: Root.Colors.text
                                    opacity: root.player?.canGoPrevious ? 1 : 0.35
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -6
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: if (root.player?.canGoPrevious) root.player.previous()
                                    }
                                }
                                Text {
                                    text: root.player?.playbackState === MprisPlaybackState.Playing ? "󰏤" : "󰐊"
                                    font.family: "CaskaydiaCove Nerd Font"
                                    font.pixelSize: 18
                                    color: Root.Colors.blue
                                    opacity: root.player?.canControl ? 1 : 0.45
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -6
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (!root.player?.canControl) return
                                            if (root.player.playbackState === MprisPlaybackState.Playing) {
                                                root.player.pause()
                                            } else {
                                                root.player.play()
                                            }
                                        }
                                    }
                                }
                                Text {
                                    text: "󰒭"
                                    font.family: "CaskaydiaCove Nerd Font"
                                    font.pixelSize: 16
                                    color: Root.Colors.text
                                    opacity: root.player?.canGoNext ? 1 : 0.35
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -6
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: if (root.player?.canGoNext) root.player.next()
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Layout utama ──────────────────────────────────────
                RowLayout {
                    anchors.centerIn: parent
                    width: Math.min(parent.width * 0.92, 1200)
                    height: parent.height * 0.75
                    spacing: 40

                    Item { Layout.fillWidth: true; Layout.fillHeight: true }

                    // ── Tengah ────────────────────────────────────────
                    Rectangle {
                        Layout.preferredWidth: 500
                        Layout.preferredHeight: Math.min(parent.height * 0.62, 520)
                        radius: 20
                        color: Qt.rgba(Root.Colors.base.r, Root.Colors.base.g,
                                       Root.Colors.base.b, 0.4)
                        border.color: Root.Colors.lavender
                        border.width: 1.5

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 0

                        Item { Layout.fillHeight: true }

                        // Jam dua warna
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 0

                            Text {
                                id: hoursText
                                font.pixelSize: 96
                                font.weight: Font.Bold
                                color: Root.Colors.lavender
                                lineHeight: 0.85
                                Timer {
                                    interval: 1000; running: true
                                    repeat: true; triggeredOnStart: true
                                    onTriggered: hoursText.text = Qt.formatDateTime(new Date(), "hh")
                                }
                            }
                            Text {
                                font.pixelSize: 96
                                font.weight: Font.Bold
                                color: Root.Colors.text
                                lineHeight: 0.85
                                text: ":"
                            }
                            Text {
                                id: minsText
                                font.pixelSize: 96
                                font.weight: Font.Bold
                                color: Root.Colors.blue
                                lineHeight: 0.85
                                Timer {
                                    interval: 1000; running: true
                                    repeat: true; triggeredOnStart: true
                                    onTriggered: minsText.text = Qt.formatDateTime(new Date(), "mm")
                                }
                            }
                            Text {
                                id: secsText
                                font.pixelSize: 34
                                font.weight: Font.Bold
                                color: Root.Colors.subtext
                                lineHeight: 0.85
                                Layout.alignment: Qt.AlignBottom
                                Layout.leftMargin: 8
                                Timer {
                                    interval: 1000; running: true
                                    repeat: true; triggeredOnStart: true
                                    onTriggered: secsText.text = Qt.formatDateTime(new Date(), "ss")
                                }
                            }
                        }

                        // Tanggal
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 6
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: Root.Colors.subtext
                            text: Qt.formatDateTime(new Date(), "dddd • d MMMM yyyy").toUpperCase()
                            Timer {
                                interval: 60000; running: true
                                repeat: true; triggeredOnStart: true
                                onTriggered: parent.text = Qt.formatDateTime(new Date(), "dddd • d MMMM yyyy").toUpperCase()
                            }
                        }

                        Item { Layout.preferredHeight: 28 }

                        // Profile picture
                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            width: 88; height: 88

                            // Border ring
                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: "transparent"
                                border.color: Root.Colors.lavender
                                border.width: 2
                            }

                            // Background lingkaran (fallback color)
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 3
                                radius: width / 2
                                color: Root.Colors.surface1
                            }

                            // Gambar dikrop bulat via layer + MultiEffect mask
                            Image {
                                id: faceImg
                                anchors.fill: parent
                                anchors.margins: 3
                                source: "file:///home/xans/.face"
                                fillMode: Image.PreserveAspectCrop
                                smooth: true
                                mipmap: true
                                visible: status === Image.Ready

                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    maskEnabled: true
                                    maskSource: ShaderEffectSource {
                                        sourceItem: Rectangle {
                                            width: faceImg.width
                                            height: faceImg.height
                                            radius: width / 2
                                            color: "white"
                                            visible: false
                                        }
                                    }
                                }
                            }

                            // Fallback icon — tampil kalau gambar gagal load
                            Text {
                                anchors.centerIn: parent
                                visible: faceImg.status !== Image.Ready
                                text: "󰀄"
                                font.family: "CaskaydiaCove Nerd Font"
                                font.pixelSize: 44
                                color: Root.Colors.subtext
                            }
                        }

                        // Username
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 10
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: Root.Colors.text
                            text: "xans"
                        }

                        Item { Layout.preferredHeight: 20 }

                        // ── Password pill ─────────────────────────────
                        Rectangle {
                            id: inputPill
                            Layout.alignment: Qt.AlignHCenter
                            height: 48
                            radius: height / 2
                            color: Root.Colors.surface0

                            implicitWidth: root._buffer.length > 0
                                           ? Math.min(root._buffer.length * 16 + 100, 300)
                                           : 220
                            Behavior on implicitWidth {
                                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                            }

                            border.color: root._messageIsErr ? Root.Colors.red
                                        : root._checking     ? Root.Colors.blue
                                        : Root.Colors.surface2
                            border.width: 1.5
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            SequentialAnimation {
                                id: shakeAnim
                                NumberAnimation { target: inputPill; property: "x"; to: inputPill.x - 14; duration: 45 }
                                NumberAnimation { target: inputPill; property: "x"; to: inputPill.x + 26; duration: 65 }
                                NumberAnimation { target: inputPill; property: "x"; to: inputPill.x - 20; duration: 65 }
                                NumberAnimation { target: inputPill; property: "x"; to: inputPill.x + 14; duration: 65 }
                                NumberAnimation { target: inputPill; property: "x"; to: inputPill.x - 8;  duration: 65 }
                                NumberAnimation { target: inputPill; property: "x"; to: inputPill.x;      duration: 45 }
                            }

                            Connections {
                                target: root
                                function on_MessageIsErrChanged() {
                                    if (root._messageIsErr) shakeAnim.start()
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                spacing: 8

                                // Ikon kunci
                                Text {
                                    font.family: "CaskaydiaCove Nerd Font"
                                    font.pixelSize: 16
                                    color: root._messageIsErr ? Root.Colors.red
                                         : root._checking     ? Root.Colors.blue
                                         : Root.Colors.subtext
                                    text: "󰍁"
                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    RotationAnimator on rotation {
                                        running: root._checking
                                        from: 0; to: 360
                                        duration: 900
                                        loops: Animation.Infinite
                                    }
                                }

                                // Area dots / placeholder — tidak ada text lain
                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    clip: true

                                    // Placeholder — HANYA tampil saat buffer kosong
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Enter password"
                                        font.pixelSize: 13
                                        color: Root.Colors.surface2
                                        visible: root._buffer.length === 0 && !root._checking
                                    }

                                    // PS button icons per karakter — cycle ○ × △ □
                                    Row {
                                        id: dotsRow
                                        anchors.centerIn: parent
                                        spacing: 4
                                        visible: root._buffer.length > 0

                                        Repeater {
                                            model: root._buffer.length
                                            delegate: Text {
                                                required property int index
                                                font.family: "CaskaydiaCove Nerd Font"
                                                font.pixelSize: 14
                                                text: root.psIcons[index % 4]
                                                color: root.psColors[index % 4]
                                                scale: 0
                                                Component.onCompleted: scaleAnim.start()
                                                NumberAnimation {
                                                    id: scaleAnim
                                                    target: parent
                                                    property: "scale"
                                                    from: 0; to: 1
                                                    duration: 150
                                                    easing.type: Easing.OutBack
                                                }
                                            }
                                        }
                                    }
                                }

                                // Tombol enter
                                Rectangle {
                                    width: 28; height: 28; radius: 14
                                    color: root._buffer.length > 0
                                           ? Root.Colors.lavender
                                           : Root.Colors.surface1
                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰁔"
                                        font.family: "CaskaydiaCove Nerd Font"
                                        font.pixelSize: 14
                                        color: root._buffer.length > 0
                                               ? Root.Colors.base
                                               : Root.Colors.surface2
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: root._buffer.length > 0 && !root._checking
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root._checking = true
                                            pamCtx.start()
                                        }
                                    }
                                }
                            }
                        }

                        // State message
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 10
                            Layout.preferredWidth: 300
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            text: root._message
                            font.pixelSize: 12
                            color: root._messageIsErr ? Root.Colors.red : Root.Colors.subtext
                            visible: root._message !== ""
                            opacity: root._message !== "" ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                        }

                        // Kutipan motivasi — fade in/out setiap 8 detik
                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 16
                            Layout.preferredWidth: 360
                            Layout.preferredHeight: 48

                            Rectangle {
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.leftMargin: -14
                                width: 2
                                radius: 1
                                color: Root.Colors.lavender
                                opacity: 0.5
                            }

                            Text {
                                id: quoteText
                                anchors.fill: parent
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                wrapMode: Text.WordWrap
                                text: root.quotes[0]
                                font.pixelSize: 14
                                font.italic: true
                                font.bold: true
                                color: Root.Colors.text
                                opacity: 1
                                Behavior on opacity { NumberAnimation { duration: 400 } }
                            }

                            SequentialAnimation {
                                id: quoteAnim
                                NumberAnimation { target: quoteText; property: "opacity"; to: 0; duration: 400 }
                                ScriptAction {
                                    script: {
                                        quoteText.text = root.quotes[
                                            Math.floor(Math.random() * root.quotes.length)]
                                    }
                                }
                                NumberAnimation { target: quoteText; property: "opacity"; to: 1; duration: 400 }
                            }

                            Timer {
                                interval: 8000; repeat: true
                                triggeredOnStart: true
                                onTriggered: quoteAnim.start()
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                    }   // ── end Rectangle (tengah)

                    Item { Layout.fillWidth: true; Layout.fillHeight: true }
                }

                // ── Status row (bottom) ────────────────────────────────
                Row {
                    id: statusRow
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 30
                    spacing: 7

                        // ── Baterai ─────────────────────────────────────
                        Rectangle {
                            height: 30
                            radius: 15
                            color: Qt.rgba(Root.Colors.surface0.r, Root.Colors.surface0.g,
                                           Root.Colors.surface0.b, 0.65)
                            width: battLabel.implicitWidth + 22

                            Text {
                                id: battLabel
                                anchors.centerIn: parent
                                font.family: "CaskaydiaCove Nerd Font"
                                font.pixelSize: 13
                                color: root.charging ? Root.Colors.yellow
                                     : root.battPercent <= 20 ? Root.Colors.red
                                     : Root.Colors.text
                                text: {
                                    const icon = root.charging ? "󰂄"
                                              : root.battPercent >= 90 ? "󰁹"
                                              : root.battPercent >= 60 ? "󰂀"
                                              : root.battPercent >= 35 ? "󰁾"
                                              : root.battPercent >= 15 ? "󰁻"
                                              : "󰂃"
                                    return icon + " " + root.battPercent + "%"
                                }
                            }
                        }

                        // ── Jaringan ────────────────────────────────────
                        Rectangle {
                            height: 30
                            radius: 15
                            color: Qt.rgba(Root.Colors.surface0.r, Root.Colors.surface0.g,
                                           Root.Colors.surface0.b, 0.65)
                            width: netLabel.implicitWidth + 22
                            visible: root.netType !== "none"

                            Text {
                                id: netLabel
                                anchors.centerIn: parent
                                font.family: "CaskaydiaCove Nerd Font"
                                font.pixelSize: 13
                                color: root.netType === "ethernet" ? Root.Colors.green
                                     : Root.Colors.text
                                text: {
                                    let icon
                                    if (root.netType === "ethernet") icon = "󰈀"
                                    else if (root.netStrength >= 75) icon = "󰤨"
                                    else if (root.netStrength >= 50) icon = "󰤥"
                                    else if (root.netStrength >= 25) icon = "󰤢"
                                    else icon = "󰤟"
                                    return icon + " " + root.netName
                                }
                            }
                        }

                        // ── Volume ──────────────────────────────────────
                        Rectangle {
                            height: 30
                            radius: 15
                            color: Qt.rgba(Root.Colors.surface0.r, Root.Colors.surface0.g,
                                           Root.Colors.surface0.b, 0.65)
                            width: volLabel.implicitWidth + 22

                            Text {
                                id: volLabel
                                anchors.centerIn: parent
                                font.family: "CaskaydiaCove Nerd Font"
                                font.pixelSize: 13
                                color: root.volMuted ? Root.Colors.subtext : Root.Colors.text
                                text: {
                                    const pct = Math.round(root.volLevel * 100)
                                    if (root.volMuted || pct === 0) return "󰝟 " + pct + "%"
                                    return (pct < 50 ? "󰕿" : "󰕾") + " " + pct + "%"
                                }
                            }
                        }
                    }
                }
            }   // ── end Item (focus handler)       // ── end WlSessionLockSurface
    }           // ── end WlSessionLock

    // ── Fungsi publik: dipanggil dari shell.qml via lockScreenRef.lock() ──
    function lock(): void {
        root._buffer       = ""
        root._message      = ""
        root._checking     = false
        root._messageIsErr = false
        sessionLock.locked = true
    }
}
