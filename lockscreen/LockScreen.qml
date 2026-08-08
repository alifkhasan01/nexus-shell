pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Wayland._Screencopy
import Quickshell.Services.Pam
import "../" as Root

// ── Lock Screen ────────────────────────────────────────────────────────────
// Bergaya caelestia: blur screencopy background, jam dua-warna besar,
// tanggal, profile picture, password dots animated, state message.
//
// Trigger: quickshell ipc call lockscreen lock
// Hyprland: bind = $mod, L, exec, quickshell ipc call lockscreen lock

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

    // ── Session Lock ─────────────────────────────────────────────────────
    WlSessionLock {
        id: sessionLock

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

                // ── Layout utama ──────────────────────────────────────
                RowLayout {
                    anchors.centerIn: parent
                    width: Math.min(parent.width * 0.92, 1200)
                    height: parent.height * 0.75
                    spacing: 40

                    Item { Layout.fillWidth: true; Layout.fillHeight: true }

                    // ── Tengah ────────────────────────────────────────
                    ColumnLayout {
                        Layout.preferredWidth: 340
                        Layout.fillHeight: true
                        spacing: 0

                        Item { Layout.fillHeight: true }

                        // Jam dua warna
                        Row {
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

                        Item { Layout.fillHeight: true }
                    }

                    Item { Layout.fillWidth: true; Layout.fillHeight: true }
                }
            }   // ── end Item (focus handler)
        }       // ── end WlSessionLockSurface
    }           // ── end WlSessionLock

    // ── IPC Handler ──────────────────────────────────────────────────────
    IpcHandler {
        target: "lockscreen"

        function lock(): void {
            root._buffer       = ""
            root._message      = ""
            root._checking     = false
            root._messageIsErr = false
            sessionLock.locked = true
        }
    }
}
