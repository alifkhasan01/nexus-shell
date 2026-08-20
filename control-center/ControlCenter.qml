pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland._FocusGrab
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import "components"

// Control Center panel — toggle via ShellState (global shortcut / bar button).
PanelWindow {
    id: root

    // Sumber kebenaran dari shell.qml (ShellState.controlCenterOpen).
    property var shellState: null
    property bool panelVisible: shellState ? shellState.controlCenterOpen : false

    onPanelVisibleChanged: {
        if (shellState && shellState.controlCenterOpen !== panelVisible)
            shellState.controlCenterOpen = panelVisible
    }

    visible: panelVisible
    implicitWidth: 340
    implicitHeight: content.implicitHeight + 32

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "nexus-control-center"
    WlrLayershell.keyboardFocus: panelVisible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    anchors {
        top: true
        right: true
    }

    margins {
        top: 8
        right: 8
    }

    color: "transparent"

    // klik di luar panel buat nutup
    HyprlandFocusGrab {
        id: grab
        windows: [root]
        active: root.panelVisible
        onCleared: root.panelVisible = false
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    Rectangle {
        anchors.fill: parent
        radius: 20
        color: "#1e1e2e"
        border.width: 1
        border.color: "#313244"

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: "#00000080"
            shadowBlur: 0.6
            shadowVerticalOffset: 4
        }

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: 16
            spacing: 14

            // ---------- Header ----------
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    radius: 20
                    color: "#89b4fa"

                    Text {
                        anchors.centerIn: parent
                        text: "󰀄"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 20
                        color: "#1e1e2e"
                    }
                }

                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true

                    Text {
                        text: Quickshell.env("USER") || "youtta"
                        font.family: "JetBrainsMono Nerd Font"
                        font.bold: true
                        font.pixelSize: 15
                        color: "#cdd6f4"
                    }

                    Text {
                        text: UPower.displayDevice.isLaptopBattery
                            ? Math.round(UPower.displayDevice.percentage * 100) + "% "
                              + (UPower.displayDevice.state === UPowerDeviceState.Charging ? "󰂄 charging" : "battery")
                            : "desktop"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        color: "#a6adc8"
                    }
                }

                // Power buttons
                Row {
                    spacing: 6

                    Repeater {
                        model: [
                            { icon: "󰌾", cmd: ["hyprlock"] },
                            { icon: "󰗼", cmd: ["wlogout"] }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            width: 32; height: 32; radius: 10
                            color: powerMa.containsMouse ? "#45475a" : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 15
                                color: "#f38ba8"
                            }

                            MouseArea {
                                id: powerMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    powerProc.command = modelData.cmd
                                    powerProc.running = true
                                    root.panelVisible = false
                                }
                            }
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#313244" }

            // ---------- Quick toggles ----------
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 8
                columnSpacing: 8

                Toggle {
                    Layout.fillWidth: true
                    icon: "󰤨"
                    label: "Wi-Fi"
                    sublabel: QuickSettingsService.wifiEnabled ? "Nyala" : "Mati"
                    active: QuickSettingsService.wifiEnabled
                    loading: QuickSettingsService.wifiBusy
                    onToggled: QuickSettingsService.toggleWifi()
                }

                Toggle {
                    Layout.fillWidth: true
                    icon: "󰂯"
                    label: "Bluetooth"
                    sublabel: QuickSettingsService.bluetoothEnabled ? "Nyala" : "Mati"
                    active: QuickSettingsService.bluetoothEnabled
                    loading: QuickSettingsService.bluetoothBusy
                    onToggled: QuickSettingsService.toggleBluetooth()
                }

                Toggle {
                    Layout.fillWidth: true
                    icon: "󰤭"
                    label: "Do Not Disturb"
                    active: QuickSettingsService.dndEnabled
                    onToggled: QuickSettingsService.toggleDnd()
                }

                Toggle {
                    Layout.fillWidth: true
                    icon: "󰛨"
                    label: "Night Light"
                    active: QuickSettingsService.nightLightEnabled
                    onToggled: QuickSettingsService.toggleNightLight()
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#313244" }

            // ---------- Sliders ----------
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                SliderRow {
                    Layout.fillWidth: true
                    icon: {
                        const sink = Pipewire.defaultAudioSink
                        if (!sink || sink.audio.muted) return "󰝟"
                        const v = sink.audio.volume
                        return v > 0.5 ? "󰕾" : v > 0 ? "󰖀" : "󰕿"
                    }
                    value: Pipewire.defaultAudioSink?.audio.volume ?? 0
                    onMoved: (v) => {
                        if (Pipewire.defaultAudioSink) Pipewire.defaultAudioSink.audio.volume = v
                    }
                    onIconClicked: {
                        const sink = Pipewire.defaultAudioSink
                        if (sink) sink.audio.muted = !sink.audio.muted
                    }
                }

                SliderRow {
                    Layout.fillWidth: true
                    icon: value > 0.5 ? "󰃠" : "󰃞"
                    value: BrightnessService.brightness
                    onMoved: (v) => BrightnessService.setBrightness(v)
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#313244" }

            // ---------- Media player ----------
            MediaWidget {
                Layout.fillWidth: true
            }
        }
    }

    Process {
        id: powerProc
    }
}
