import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Io
import "../" as Root
import "./dashboard" as Dash

// Dashboard ala Caelestia: dropdown panel besar berisi media player,
// quick toggles, slider volume/brightness, dan ringkasan sistem.
// Ditoggle dari Bar (klik Clock) lewat properti `dashboardOpen`.
PanelWindow {
    id: root

    property alias open: content.visible
    signal closeRequested()

    // Anchor full-width supaya bisa dipakai sebagai area transparan buat
    // menutup dashboard saat klik di luar kartu; kartu sendiri lebarnya tetap.
    anchors { top: true; left: true; right: true }
    margins.top: 40
    implicitHeight: content.implicitHeight + 32
    color: "transparent"
    visible: open

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "quickshell-dashboard"
    // Penting: exclusiveZone default di beberapa compositor akan auto-reserve
    // area seluas implicitHeight window ini (karena anchor top+left+right),
    // sehingga window lain (termasuk window tiling) ikut terdorong turun
    // setiap dashboard dibuka. Set 0 supaya dashboard murni jadi popup
    // overlay yang melayang di atas, tanpa mengambil space window lain.
    WlrLayershell.exclusiveZone: 0

    // klik di luar kartu untuk menutup
    MouseArea {
        anchors.fill: parent
        onClicked: root.closeRequested()
    }

    Rectangle {
        id: content
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: 420
        implicitHeight: mainCol.implicitHeight + 32
        height: implicitHeight
        radius: 20
        color: Root.Colors.mantle
        border.color: Root.Colors.surface1
        border.width: 1

        // supaya klik di dalam card tidak ikut nutup dashboard
        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            id: mainCol
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16

            // ---------- Header ----------
            RowLayout {
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: Qt.formatDateTime(new Date(), "dddd, dd MMMM yyyy")
                    color: Root.Colors.text
                    font.pixelSize: 16
                    font.bold: true
                }
                Text {
                    text: Qt.formatDateTime(new Date(), "HH:mm")
                    color: Root.Colors.blue
                    font.pixelSize: 16
                    font.bold: true
                }
            }

            // ---------- Media player ----------
            Dash.MediaCard {}

            // ---------- Quick toggles ----------
            Dash.QuickToggles {}

            // ---------- Sliders ----------
            ColumnLayout {
                id: audioCol
                Layout.fillWidth: true
                spacing: 8

                property var sink: Pipewire.defaultAudioSink

                PwObjectTracker { objects: [audioCol.sink] }

                Dash.SliderRow {
                    Layout.fillWidth: true
                    icon: "󰕾"
                    value: audioCol.sink?.audio ? audioCol.sink.audio.volume : 0
                    onMoved: v => { if (audioCol.sink?.audio) audioCol.sink.audio.volume = v }
                }

                Dash.SliderRow {
                    id: brightnessSlider
                    Layout.fillWidth: true
                    icon: "󰃞"

                    Process {
                        id: setBrightness
                    }
                    onMoved: v => {
                        setBrightness.command = ["brightnessctl", "set", Math.round(v * 100) + "%"]
                        setBrightness.running = true
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Root.Colors.surface0 }

            // ---------- System stats ----------
            Dash.SystemStats {
                Layout.fillWidth: true
            }
        }
    }
}
