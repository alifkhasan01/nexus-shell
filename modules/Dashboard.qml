import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Io
import "../" as Root
import "./dashboard" as Dash

PanelWindow {
    id: root

    property alias open: card.visible
    signal closeRequested()
    signal screenshotRequested()
    signal grimRequested()
    signal recorderToggleRequested()
    signal recorderMicToggleRequested()

    anchors { top: true; left: true; right: true }
    margins.top: 5
    implicitHeight: card.height + 16
    color: "transparent"
    visible: open

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "quickshell-dashboard"
    WlrLayershell.exclusiveZone: 0

    MouseArea {
        anchors.fill: parent
        hoverEnabled: false
        onClicked: root.closeRequested()
    }

    property int currentTab: 0

    readonly property var tabs: [
        { icon: "󰕮",  label: "Overview" },
        { icon: "󰝚",  label: "Media"    },
        { icon: "󱠇",  label: "Settings" }
    ]

    // ── Kartu utama ───────────────────────────────────────────────────────
    Rectangle {
        id: card
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: 520
        radius: 20
        color: Root.Colors.mantle
        border.color: Root.Colors.surface2
        border.width: 2
        clip: true

        // Lebar efektif konten = card.width dikurangi margin cardCol kiri+kanan (14×2)
        readonly property real innerWidth: width - 28
        // cardCol margins atas (14) + tab bar (42) + bottomMargin tab bar (12)
        // + konten + cardCol margins bawah (14) + card padding (24) = +106
        readonly property real contentHeight: {
            switch (root.currentTab) {
                case 0: return overviewTab.implicitHeight
                case 1: return mediaTab.implicitHeight
                case 2: return settingsTabItem.implicitHeight
                default: return 0
            }
        }
        height: contentHeight + 106
        Behavior on height { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

        Behavior on color       { ColorAnimation { duration: 200 } }
        Behavior on border.color{ ColorAnimation { duration: 200 } }

        MouseArea { anchors.fill: parent; hoverEnabled: false; onClicked: {} }

        ColumnLayout {
            id: cardCol
            anchors.left:   parent.left
            anchors.right:  parent.right
            anchors.top:    parent.top
            anchors.margins: 14
            spacing: 0

            // ── Tab bar ───────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 42
                radius: 12
                color: Root.Colors.base
                Layout.bottomMargin: 12
                Behavior on color { ColorAnimation { duration: 200 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 4
                    Repeater {
                        model: root.tabs
                        delegate: Rectangle {
                            readonly property bool active: root.currentTab === index
                            Layout.fillWidth: true
                            height: 34
                            radius: 9
                            color: active ? Root.Colors.surface2
                                          : (tabMa.containsMouse ? Root.Colors.surface0 : "transparent")
                            Behavior on color { ColorAnimation { duration: 140 } }
                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 5
                                Text {
                                    text: modelData.icon; font.pixelSize: 14
                                    color: active ? Root.Colors.blue : Root.Colors.subtext
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                }
                                Text {
                                    text: modelData.label; font.pixelSize: 12; font.bold: active
                                    color: active ? Root.Colors.text : Root.Colors.subtext
                                    Behavior on color { ColorAnimation { duration: 140 } }
                                }
                            }
                            MouseArea {
                                id: tabMa; anchors.fill: parent
                                hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: root.currentTab = index
                            }
                        }
                    }
                }
            }

            // ── Viewport konten — hanya area yang terlihat ─────────────────
            // Tinggi viewport = tinggi konten tab aktif (animasi dihandle card.height).
            // Flickable geser row horizontal ke tab yang aktif.
            Item {
                id: viewport
                Layout.fillWidth: true
                height: card.contentHeight   // ikut tinggi konten, smooth karena card.height sudah animate

                Flickable {
                    id: tabFlickable
                    anchors.fill: parent
                    clip: true
                    interactive: false
                    flickableDirection: Flickable.HorizontalFlick
                    contentWidth:  tabRow.width
                    contentHeight: parent.height

                    contentX: root.currentTab * card.innerWidth
                    Behavior on contentX {
                        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                    }

                    // Semua tab dirender berjajar secara horizontal
                    Row {
                        id: tabRow
                        spacing: 0

                        // ── TAB 0 — Overview ──────────────────────────────
                        Item {
                            id: overviewTab
                            width: card.innerWidth
                            implicitHeight: overviewCol.implicitHeight

                            ColumnLayout {
                                id: overviewCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                spacing: 12

                            Rectangle {
                                Layout.fillWidth: true
                                height: 80; radius: 14
                                color: Root.Colors.base
                                Behavior on color { ColorAnimation { duration: 200 } }
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 16; spacing: 0
                                    ColumnLayout {
                                        spacing: 2
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
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        id: bigClock
                                        text: Qt.formatDateTime(new Date(), "HH:mm")
                                        color: Root.Colors.blue; font.pixelSize: 32; font.bold: true
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                        Timer {
                                            interval: 1000; running: true; repeat: true
                                            onTriggered: bigClock.text = Qt.formatDateTime(new Date(), "HH:mm")
                                        }
                                    }
                                }
                            }

                            Dash.QuickToggles {
                                Layout.fillWidth: true
                                dashboardRoot: root
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 36; radius: 10
                                color: Root.Colors.base
                                Behavior on color { ColorAnimation { duration: 200 } }
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 10; spacing: 16
                                    Dash.SystemStats { Layout.fillWidth: true }
                                }
                            }

                            Item { height: 2 }
                            }  // ColumnLayout overviewCol
                        }  // Item overviewTab

                        // ── TAB 1 — Media ─────────────────────────────────
                        Item {
                            id: mediaTab
                            width: card.innerWidth
                            implicitHeight: mediaCol.implicitHeight

                            property var player: {
                                const players = Mpris.players.values
                                for (let i = 0; i < players.length; i++) {
                                    const p = players[i]
                                    if (p && p.isPlaying) return p
                                }
                                for (let i = 0; i < players.length; i++) {
                                    const p = players[i]
                                    if (p && p.trackTitle) return p
                                }
                                return players.length > 0 ? players[0] : null
                            }
                            property bool hasPlayer: player !== null

                            Timer {
                                interval: 1000
                                running: mediaTab.hasPlayer && mediaTab.player?.playbackState === MprisPlaybackState.Playing
                                repeat: true
                                onTriggered: { if (mediaTab.player) mediaTab.player.positionChanged() }
                            }

                            ColumnLayout {
                                id: mediaCol
                                anchors.left: parent.left; anchors.right: parent.right
                                spacing: 12

                                Rectangle {
                                    Layout.fillWidth: true; height: 150; radius: 12
                                    color: Root.Colors.base
                                    visible: !mediaTab.hasPlayer
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                    ColumnLayout {
                                        anchors.centerIn: parent; spacing: 8
                                        Text { Layout.alignment: Qt.AlignHCenter; text: "󰝚"; font.pixelSize: 40; color: Root.Colors.subtext }
                                        Text { Layout.alignment: Qt.AlignHCenter; text: "Tidak ada media yang sedang diputar"; font.pixelSize: 12; color: Root.Colors.subtext }
                                    }
                                }

                                Item {
                                    Layout.fillWidth: true; height: 266
                                    visible: mediaTab.hasPlayer
                                    Dash.CavaRingDank {
                                        anchors.centerIn: parent; size: 260
                                        coverSource: mediaTab.player?.trackArtUrl ?? ""
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 3
                                    visible: mediaTab.hasPlayer
                                    Text {
                                        Layout.fillWidth: true
                                        text: mediaTab.player?.trackTitle ?? "Tidak ada media"
                                        color: Root.Colors.text; font.pixelSize: 16; font.bold: true
                                        horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: mediaTab.player?.trackArtist ?? ""
                                        color: Root.Colors.subtext; font.pixelSize: 13
                                        horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: mediaTab.player?.trackAlbum ?? ""
                                        color: Root.Colors.subtext; font.pixelSize: 11; opacity: 0.7
                                        horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: mediaTab.player?.identity ?? ""
                                        color: Root.Colors.blue; font.pixelSize: 10; opacity: 0.8
                                        horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                                        visible: text !== ""
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true; spacing: 4
                                    visible: mediaTab.hasPlayer
                                    Item {
                                        Layout.fillWidth: true; height: 20
                                        Rectangle {
                                            id: seekTrack
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left; anchors.right: parent.right
                                            height: 5; radius: 3
                                            color: Root.Colors.surface1
                                            Behavior on color { ColorAnimation { duration: 200 } }
                                            readonly property real dur: mediaTab.player?.length ?? 0
                                            readonly property real pos: mediaTab.player?.position ?? 0
                                            Rectangle {
                                                width: seekTrack.dur > 0 ? parent.width * (seekTrack.pos / seekTrack.dur) : 0
                                                height: parent.height; radius: parent.radius
                                                color: Root.Colors.blue
                                                Behavior on width { NumberAnimation { duration: 900; easing.type: Easing.Linear } }
                                            }
                                            MouseArea {
                                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                                onClicked: mouse => {
                                                    const p = mediaTab.player
                                                    if (p && p.canSeek && seekTrack.dur > 0)
                                                        p.position = (mouse.x / seekTrack.width) * seekTrack.dur
                                                }
                                            }
                                        }
                                    }
                                    RowLayout {
                                        Layout.fillWidth: true
                                        function fmt(s) {
                                            const m = Math.floor(s / 60), sec = Math.floor(s % 60)
                                            return m + ":" + (sec < 10 ? "0" : "") + sec
                                        }
                                        Text { text: parent.fmt(mediaTab.player?.position ?? 0); font.pixelSize: 11; color: Root.Colors.subtext }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            text: { const d = mediaTab.player?.length ?? 0; return d > 0 ? parent.fmt(d) : "--:--" }
                                            font.pixelSize: 11; color: Root.Colors.subtext
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true; Layout.bottomMargin: 4
                                    spacing: 0
                                    visible: mediaTab.hasPlayer
                                    Item { Layout.fillWidth: true }
                                    Rectangle {
                                        width: 36; height: 36; radius: 18
                                        color: shufMa.containsMouse ? Root.Colors.surface0 : "transparent"
                                        Behavior on color { ColorAnimation { duration: 100 } }
                                        visible: mediaTab.player?.shuffleSupported ?? false
                                        Text { anchors.centerIn: parent; text: "󰒝"; font.pixelSize: 16
                                            color: (mediaTab.player?.shuffle ?? false) ? Root.Colors.blue : Root.Colors.subtext }
                                        MouseArea { id: shufMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: { const p = mediaTab.player; if (p) p.shuffle = !p.shuffle } }
                                    }
                                    Rectangle {
                                        width: 42; height: 42; radius: 21
                                        color: prevMa.containsMouse ? Root.Colors.surface0 : "transparent"
                                        Behavior on color { ColorAnimation { duration: 100 } }
                                        Text { anchors.centerIn: parent; text: "󰒮"; font.pixelSize: 22
                                            color: Root.Colors.text; opacity: (mediaTab.player?.canGoPrevious ?? false) ? 1 : 0.35 }
                                        MouseArea { id: prevMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: { const p = mediaTab.player; if (p?.canGoPrevious) p.previous() } }
                                    }
                                    Rectangle {
                                        width: 52; height: 52; radius: 26
                                        color: Root.Colors.blue
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        Text { anchors.centerIn: parent
                                            text: (mediaTab.player?.playbackState === MprisPlaybackState.Playing) ? "󰏤" : "󰐊"
                                            font.pixelSize: 24; color: Root.Colors.base }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                const p = mediaTab.player; if (!p) return
                                                p.playbackState === MprisPlaybackState.Playing ? p.pause() : p.play()
                                            }
                                        }
                                    }
                                    Rectangle {
                                        width: 42; height: 42; radius: 21
                                        color: nextMa.containsMouse ? Root.Colors.surface0 : "transparent"
                                        Behavior on color { ColorAnimation { duration: 100 } }
                                        Text { anchors.centerIn: parent; text: "󰒭"; font.pixelSize: 22
                                            color: Root.Colors.text; opacity: (mediaTab.player?.canGoNext ?? false) ? 1 : 0.35 }
                                        MouseArea { id: nextMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: { const p = mediaTab.player; if (p?.canGoNext) p.next() } }
                                    }
                                    Rectangle {
                                        width: 36; height: 36; radius: 18
                                        color: loopMa.containsMouse ? Root.Colors.surface0 : "transparent"
                                        Behavior on color { ColorAnimation { duration: 100 } }
                                        visible: mediaTab.player?.loopSupported ?? false
                                        Text {
                                            anchors.centerIn: parent; font.pixelSize: 16
                                            text: (mediaTab.player?.loopState === MprisLoopState.Track) ? "󰑘" : "󰑖"
                                            color: (mediaTab.player?.loopState ?? MprisLoopState.None) !== MprisLoopState.None
                                                   ? Root.Colors.blue : Root.Colors.subtext
                                        }
                                        MouseArea { id: loopMa; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                const p = mediaTab.player; if (!p) return
                                                switch (p.loopState) {
                                                    case MprisLoopState.None:     p.loopState = MprisLoopState.Playlist; break
                                                    case MprisLoopState.Playlist: p.loopState = MprisLoopState.Track;    break
                                                    case MprisLoopState.Track:    p.loopState = MprisLoopState.None;     break
                                                }
                                            }
                                        }
                                    }
                                    Item { Layout.fillWidth: true }
                                }

                                Item { height: 2 }
                            }
                        }

                        // ── TAB 2 — Settings ──────────────────────────────
                        Item {
                            id: settingsTabItem
                            width: card.innerWidth
                            implicitHeight: settingsInner.implicitHeight
                            Dash.SettingsTab {
                                id: settingsInner
                                anchors.left:  parent.left
                                anchors.right: parent.right
                            }
                        }
                    }
                }
            }
        }
    }
}
