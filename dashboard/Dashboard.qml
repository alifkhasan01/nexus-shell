import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Io
import "../" as Root
import "./" as Dash

PanelWindow {
    id: root

    property alias open: card.visible
    signal closeRequested()
    signal screenshotRequested()
    signal grimRequested()
    signal recorderToggleRequested()
    signal recorderMicToggleRequested()
    signal setFaceRequested()
    signal notifyRequested(string icon, string summary, string body)
    signal dndToggleRequested()

    // State DND yang bisa dibaca QuickToggles tanpa perlu poll swaync
    property bool dndActive: false

    anchors { top: true; left: true; right: true }
    margins.top: 5
    color: "transparent"
    visible: open
    implicitHeight: card.height + 16

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "quickshell-dashboard"
    WlrLayershell.exclusiveZone: 0

    MouseArea {
        anchors.fill: parent
        hoverEnabled: false
        onClicked: root.closeRequested()
    }

    // ── Konstanta layout ──────────────────────────────────────────────────
    readonly property int _pad: 14
    readonly property int _gap: 12
    readonly property int _lw:  420                 // kolom kiri: overview + settings
    readonly property int _rw:  400                 // kolom tengah: media (ukuran tetap)
    readonly property int _iw:  420                 // kolom kanan: system info — sama lebar dengan _lw
    readonly property int _cw:  _pad + _lw + _gap + _rw + _gap + _iw + _pad  // = 14+420+12+400+12+420+14 = 1292

    // ── Kartu utama ───────────────────────────────────────────────────────
    Rectangle {
        id: card
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width:  root._cw
        // Tinggi ikut kolom kiri (yang punya ukuran tetap) + padding
        height: leftCol.height + root._pad * 2
        radius: 20
        color:  Root.Colors.mantle
        border.color: Root.Colors.surface2
        border.width: 2
        clip: true

        Behavior on color        { ColorAnimation { duration: 200 } }
        Behavior on border.color { ColorAnimation { duration: 200 } }

        MouseArea { anchors.fill: parent; hoverEnabled: false; onClicked: {} }

        // ── Kolom kiri — Overview + Settings ─────────────────────────
        Column {
            id: leftCol
            x: root._pad
            y: root._pad
            width: root._lw
            spacing: 10

            // Jam & tanggal + profile picture
            Rectangle {
                width: parent.width; height: 76
                radius: 14; color: Root.Colors.base
                Behavior on color { ColorAnimation { duration: 200 } }

                Item {
                    anchors.fill: parent; anchors.margins: 12

                    // ── Foto profil (kiri) ─────────────────────────────
                    Item {
                        id: dashFaceItem
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        width: 48; height: 48

                        // Border ring
                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: "transparent"
                            border.color: Root.Colors.lavender
                            border.width: 2
                            Behavior on border.color { ColorAnimation { duration: 200 } }
                        }

                        // Background fallback
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 3
                            radius: width / 2
                            color: Root.Colors.surface1
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }

                        // Gambar bulat via layer + MultiEffect mask
                        Image {
                            id: dashFaceImg
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
                                        width: dashFaceImg.width
                                        height: dashFaceImg.height
                                        radius: width / 2
                                        color: "white"
                                        visible: false
                                    }
                                }
                            }
                        }

                        // Fallback icon
                        Text {
                            anchors.centerIn: parent
                            visible: dashFaceImg.status !== Image.Ready
                            text: "󰀄"
                            font.family: "CaskaydiaCove Nerd Font"
                            font.pixelSize: 22
                            color: Root.Colors.subtext
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }

                    // ── Tanggal (tengah, anchored ke kiri foto) ────────
                    Column {
                        id: dateCol
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: dashFaceItem.right
                        anchors.leftMargin: 10
                        spacing: 3
                        Text {
                            text: Qt.formatDateTime(new Date(), "dddd")
                            color: Root.Colors.subtext; font.pixelSize: 12
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                        Text {
                            text: Qt.formatDateTime(new Date(), "dd MMMM yyyy")
                            color: Root.Colors.text; font.pixelSize: 14; font.bold: true
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }

                    // ── Jam (kanan) ────────────────────────────────────
                    Text {
                        id: clockText
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        text: Qt.formatDateTime(new Date(), "HH:mm")
                        color: Root.Colors.blue; font.pixelSize: 30; font.bold: true
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Timer {
                            interval: 1000; running: true; repeat: true
                            onTriggered: clockText.text = Qt.formatDateTime(new Date(), "HH:mm")
                        }
                    }
                }
            }

            // Quick toggles
            Dash.QuickToggles {
                width: parent.width
                dashboardRoot: root
            }

            // System stats
            Rectangle {
                width: parent.width; height: 36
                radius: 10; color: Root.Colors.base
                Behavior on color { ColorAnimation { duration: 200 } }
                Dash.SystemStats {
                    anchors.fill: parent
                    anchors.leftMargin: 12; anchors.rightMargin: 12
                }
            }

            // Settings
            Rectangle {
                width: parent.width
                height: settingsContent.implicitHeight + 20
                radius: 14; color: Root.Colors.base
                Behavior on color { ColorAnimation { duration: 200 } }

                Dash.SettingsTab {
                    id: settingsContent
                    anchors.top:    parent.top
                    anchors.left:   parent.left
                    anchors.right:  parent.right
                    anchors.margins: 10
                }
            }
        }

        // ── Kolom kanan — Media full height ──────────────────────────────
        Item {
            id: rightCol
            x: root._pad + root._lw + root._gap
            y: root._pad
            width:  root._rw
            height: leftCol.height

            // Media card — full height kolom kanan
            Rectangle {
                id: mediaCard
                anchors.fill: parent
                radius: 14; color: Root.Colors.base
                Behavior on color { ColorAnimation { duration: 200 } }

                property var player: {
                    const list = Mpris.players.values
                    for (let i = 0; i < list.length; i++)
                        if (list[i]?.isPlaying) return list[i]
                    for (let i = 0; i < list.length; i++)
                        if (list[i]?.trackTitle) return list[i]
                    return list.length > 0 ? list[0] : null
                }
                property bool hasPlayer: player !== null

                Timer {
                    interval: 1000
                    running: mediaCard.hasPlayer &&
                             mediaCard.player?.playbackState === MprisPlaybackState.Playing
                    repeat: true
                    onTriggered: mediaCard.player?.positionChanged()
                }

                // ── Tidak ada player ──────────────────────────────────────
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

                // ── Ada player ────────────────────────────────────────────
                Column {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8
                    visible: mediaCard.hasPlayer

                    // CavaRing — mengambil sisa tinggi setelah info + kontrol
                    Dash.CavaRingDank {
                        anchors.horizontalCenter: parent.horizontalCenter
                        property int _avail: mediaCard.height - 52 - 14 - 44 - 24 - 40
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

                    // Seek bar
                    Item {
                        width: parent.width; height: 14

                        Rectangle {
                            id: seekBar
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width; height: 4; radius: 2
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
                }
            }
        }

        // ── Kolom ketiga — System Info ────────────────────────────────────
        Item {
            id: infoCol
            x: root._pad + root._lw + root._gap + root._rw + root._gap
            y: root._pad
            width:  root._iw
            height: leftCol.height

            Dash.SystemInfo {
                anchors.fill: parent
                onSetFaceRequested: root.setFaceRequested()
            }
        }
    }
}
