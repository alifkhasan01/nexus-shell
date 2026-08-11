pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Io
import "../" as Root
import "./" as Dash

// Tab Media di Dashboard — media player MPRIS + visualizer + volume.
// Content dipindah dari kolom tengah Dashboard.qml.

Item {
    id: mt

    Rectangle {
        id: mediaCard
        anchors.fill: parent
        radius: 14
        color: Root.Colors.base
        border.color: Root.Colors.surface1
        border.width: 1
        clip: true
        Behavior on color { ColorAnimation { duration: 200 } }
        Behavior on border.color { ColorAnimation { duration: 200 } }

        property var player: {
            const list = Mpris.players.values
            for (let i = 0; i < list.length; i++)
                if (list[i]?.isPlaying) return list[i]
            for (let i = 0; i < list.length; i++)
                if (list[i]?.trackTitle) return list[i]
            return list.length > 0 ? list[0] : null
        }
        property bool hasPlayer: player !== null

        // Sink aktif — Pipewire.defaultAudioSink sudah mengikuti preferred
        // default (termasuk sink bluetooth yang di-auto-promote di shell.qml).
        property var defaultSink: Pipewire.defaultAudioSink

        // Klasifikasi jenis output:
        //   0 = sound system (internal), 1 = bluetooth, 2 = usb, 3 = hdmi
        readonly property int outputKind: {
            const s = mediaCard.defaultSink
            if (!s) return 0
            const props = s.properties || {}
            const nm = (s.nickname || s.description || s.name || "").toLowerCase()
            if (props["device.api"] === "bluez5" ||
                props["device.bus"] === "bluetooth" ||
                (s.name || "").startsWith("bluez_output.") ||
                nm.includes("bluetooth") || nm.includes("a2dp"))
                return 1
            if (props["device.bus"] === "usb" || nm.includes("usb"))
                return 2
            if (props["device.bus"] === "hdmi" || nm.includes("hdmi"))
                return 3
            return 0
        }
        readonly property string outputKindText:
            ["Sound System", "Bluetooth", "USB", "HDMI"][mediaCard.outputKind] || "Sound System"
        readonly property string outputIcon:
            ["󰓃", "󰋋", "󰻇", "󰍹"][mediaCard.outputKind] || "󰃀"
        readonly property string outputName:
            mediaCard.defaultSink?.nickname
            || mediaCard.defaultSink?.description
            || mediaCard.defaultSink?.name
            || "Output"

        // Lacak perubahan pada sink aktif (BT connect/disconnect, ganti default)
        PwObjectTracker {
            objects: [mediaCard.defaultSink].filter(n => n != null)
        }

        // Set volume lewat pactl — lebih andal sampai ke hardware
        Process {
            id: pactlVolProc
            running: false
        }

        function setSinkVolume(value) {
            const s = mediaCard.defaultSink
            if (!s?.audio) return
            pactlVolProc.command = [
                "pactl", "set-sink-volume",
                s.name || "@DEFAULT_SINK@",
                Math.round(value * 100) + "%"
            ]
            pactlVolProc.running = true
        }

        // Set mute lewat pactl
        function setSinkMuted(muted) {
            const s = mediaCard.defaultSink
            if (!s?.audio) return
            pactlVolProc.command = [
                "pactl", "set-sink-mute",
                s.name || "@DEFAULT_SINK@",
                muted ? "1" : "0"
            ]
            pactlVolProc.running = true
        }

        function fmt(sec) {
            sec = Math.floor(sec || 0)
            const m = Math.floor(sec / 60)
            const s = sec % 60
            return m + ":" + (s < 10 ? "0" : "") + s
        }

        Timer {
            interval: 1000
            running: mediaCard.hasPlayer &&
                     mediaCard.player?.playbackState === MprisPlaybackState.Playing
            repeat: true
            onTriggered: mediaCard.player?.positionChanged()
        }

        // ── Background blur dari album art ─────────────────────────────
        Image {
            id: mediaArtBg
            anchors.fill: parent
            source: mediaCard.hasPlayer ? (mediaCard.player?.trackArtUrl ?? "") : ""
            sourceSize.width: 160
            sourceSize.height: 160
            fillMode: Image.PreserveAspectCrop
            smooth: true
            visible: mediaArtBg.status === Image.Ready && mediaCard.hasPlayer
            opacity: 0.5
            layer.enabled: visible
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1.0
                saturation: 0.3
                brightness: -0.2
            }
        }

        // Overlay agar teks tetap terbaca
        Rectangle {
            anchors.fill: parent
            color: Root.Colors.base
            opacity: mediaCard.hasPlayer ? 0.72 : 1
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        // ── Tidak ada player ──────────────────────────────────────────
        Column {
            anchors.centerIn: parent
            spacing: 8
            visible: !mediaCard.hasPlayer

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "󰝚"; font.pixelSize: 32; color: Root.Colors.subtext
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Tidak ada media"; font.pixelSize: 12; color: Root.Colors.subtext
            }
        }

        // ── Ada player ─────────────────────────────────────────────────
        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8
            visible: mediaCard.hasPlayer

            // Nama aplikasi sumber
            Item {
                width: parent.width; height: 16
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: (mediaCard.player?.identity
                           || mediaCard.player?.desktopEntry || "")
                    color: Root.Colors.subtext; font.pixelSize: 10
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            // CavaRing — visualizer, ambil sisa tinggi
            Dash.CavaRingDank {
                anchors.horizontalCenter: parent.horizontalCenter
                property int _avail: mediaCard.height - 16 - 44 - 24 - 44 - 34 - 24 - 40
                size: Math.max(80, Math.min(_avail, parent.width - 16))
                coverSource: mediaCard.player?.trackArtUrl ?? ""
            }

            // Info: judul + artis (compact)
            Item {
                width: parent.width; height: 44

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left:  parent.left
                    anchors.right: parent.right
                    spacing: 2

                    Text {
                        width: parent.width
                        text: mediaCard.player?.trackTitle ?? ""
                        color: Root.Colors.text; font.pixelSize: 13; font.bold: true
                        elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    Text {
                        width: parent.width
                        text: (mediaCard.player?.trackArtist ?? "")
                              + (mediaCard.player?.trackAlbum
                                 ? "  ·  " + mediaCard.player.trackAlbum : "")
                        color: Root.Colors.subtext; font.pixelSize: 11
                        elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
            }

            // Seek bar + waktu berjalan (1:32 / 4:23)
            Item {
                width: parent.width; height: 22

                RowLayout {
                    anchors.fill: parent
                    spacing: 8

                    Text {
                        text: mediaCard.fmt(mediaCard.player?.position ?? 0)
                        color: Root.Colors.text; font.pixelSize: 10
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Rectangle {
                        id: seekBar
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        height: 4; radius: 2
                        color: Root.Colors.surface1
                        Behavior on color { ColorAnimation { duration: 150 } }

                        readonly property real dur: mediaCard.player?.length   ?? 0
                        readonly property real pos: mediaCard.player?.position ?? 0

                        Rectangle {
                            width: seekBar.dur > 0
                                   ? parent.width * (seekBar.pos / seekBar.dur) : 0
                            height: parent.height; radius: parent.radius
                            color: Root.Colors.blue
                            Behavior on width {
                                NumberAnimation { duration: 950; easing.type: Easing.Linear }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => {
                                const p = mediaCard.player
                                if (p?.canSeek && seekBar.dur > 0)
                                    p.position = (mouse.x / seekBar.width) * seekBar.dur
                            }
                        }
                    }

                    Text {
                        text: mediaCard.fmt(mediaCard.player?.length ?? 0)
                        color: Root.Colors.subtext; font.pixelSize: 10
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
            }

            // Kontrol playback
            Item {
                width: parent.width; height: 44

                // Shuffle (kiri)
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    width: 30; height: 30; radius: 15
                    color: shufMa.containsMouse ? Root.Colors.surface1 : "transparent"
                    visible: mediaCard.player?.shuffleSupported ?? false
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text {
                        anchors.centerIn: parent; text: "󰒝"; font.pixelSize: 14
                        color: (mediaCard.player?.shuffle ?? false)
                               ? Root.Colors.blue : Root.Colors.subtext
                    }
                    MouseArea {
                        id: shufMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { const p = mediaCard.player; if (p) p.shuffle = !p.shuffle }
                    }
                }

                // Loop (kanan)
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    width: 30; height: 30; radius: 15
                    color: loopMa.containsMouse ? Root.Colors.surface1 : "transparent"
                    visible: mediaCard.player?.loopSupported ?? false
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text {
                        anchors.centerIn: parent; font.pixelSize: 14
                        text: (mediaCard.player?.loopState === MprisLoopState.Track)
                              ? "󰑘" : "󰑖"
                        color: (mediaCard.player?.loopState ?? MprisLoopState.None)
                               !== MprisLoopState.None
                               ? Root.Colors.blue : Root.Colors.subtext
                    }
                    MouseArea {
                        id: loopMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const p = mediaCard.player; if (!p) return
                            switch (p.loopState) {
                                case MprisLoopState.None:
                                    p.loopState = MprisLoopState.Playlist; break
                                case MprisLoopState.Playlist:
                                    p.loopState = MprisLoopState.Track; break
                                case MprisLoopState.Track:
                                    p.loopState = MprisLoopState.None; break
                            }
                        }
                    }
                }

                // Play/Pause (tengah)
                Rectangle {
                    anchors.centerIn: parent
                    width: 44; height: 44; radius: 22
                    color: Root.Colors.blue
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text {
                        anchors.centerIn: parent
                        text: (mediaCard.player?.playbackState === MprisPlaybackState.Playing)
                              ? "󰏤" : "󰐊"
                        font.pixelSize: 20; color: Root.Colors.base
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const p = mediaCard.player; if (!p) return
                            p.playbackState === MprisPlaybackState.Playing
                                ? p.pause() : p.play()
                        }
                    }
                }

                // Previous
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.horizontalCenter; anchors.rightMargin: 28
                    width: 36; height: 36; radius: 18
                    color: prevMa.containsMouse ? Root.Colors.surface1 : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text {
                        anchors.centerIn: parent; text: "󰒮"; font.pixelSize: 18
                        color: Root.Colors.text
                        opacity: (mediaCard.player?.canGoPrevious ?? false) ? 1 : 0.3
                    }
                    MouseArea {
                        id: prevMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const p = mediaCard.player; if (p?.canGoPrevious) p.previous()
                        }
                    }
                }

                // Next
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.horizontalCenter; anchors.leftMargin: 28
                    width: 36; height: 36; radius: 18
                    color: nextMa.containsMouse ? Root.Colors.surface1 : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Text {
                        anchors.centerIn: parent; text: "󰒭"; font.pixelSize: 18
                        color: Root.Colors.text
                        opacity: (mediaCard.player?.canGoNext ?? false) ? 1 : 0.3
                    }
                    MouseArea {
                        id: nextMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const p = mediaCard.player; if (p?.canGoNext) p.next()
                        }
                    }
                }
            }

            // Label output aktif
            Item {
                width: parent.width
                height: 18
                visible: mediaCard.hasPlayer

                RowLayout {
                    anchors.fill: parent
                    spacing: 4

                    Text {
                        text: mediaCard.outputIcon
                        font.pixelSize: 10
                        color: Root.Colors.blue
                        Behavior on color { ColorAnimation { duration: 150 } }

                        // Klik ikon untuk toggle mute output aktif
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const s = mediaCard.defaultSink
                                if (s?.audio) mediaCard.setSinkMuted(!s.audio.muted)
                            }
                        }
                    }

                    Text {
                        text: mediaCard.outputKindText
                        font.pixelSize: 10
                        font.bold: true
                        color: Root.Colors.blue
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Item { Layout.preferredWidth: 2 }

                    Text {
                        Layout.fillWidth: true
                        text: mediaCard.outputName
                        font.pixelSize: 10
                        color: Root.Colors.subtext
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }
            }

            // Volume slider — selalu terhubung ke Pipewire (sink aktif)
            Item {
                width: parent.width
                height: 34

                Dash.SliderRow {
                    id: volumeSlider
                    anchors.left: parent.left
                    anchors.right: volumePctLabel.left
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    icon: {
                        const s = mediaCard.defaultSink?.audio
                        if (!s || s.muted || s.volume <= 0) return "󰝟"
                        return s.volume < 0.5 ? "󰕿" : "󰕾"
                    }
                    // Nilai sumber: baca dari sink aktif (reactive ke Pipewire)
                    readonly property real sourceVolume:
                        mediaCard.defaultSink?.audio ? mediaCard.defaultSink.audio.volume : 0

                    value: sourceVolume

                    onMoved: v => mediaCard.setSinkVolume(v)
                }

                Text {
                    id: volumePctLabel
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(volumeSlider.value * 100) + "%"
                    font.pixelSize: 11
                    color: Root.Colors.subtext
                    horizontalAlignment: Text.AlignRight
                    width: 34
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }
        }
    }
}