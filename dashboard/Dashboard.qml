import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Io
import "../" as Root
import "./" as Dash

// ═══════════════════════════════════════════════════════════════════════
// Control Center — Dashboard tabbed.
// Penggabungan panel lama (Calendar, Connect, Clipboard, Notif, Volume,
// Battery) menjadi satu window dengan tab:
//   0 Overview | 1 Media | 2 Network | 3 Clipboard | 4 Notif | 5 Kalender | 6 Info
// Rel panel kiri memilih tab; content memakai lebar/tinggi per-tab.
// ═══════════════════════════════════════════════════════════════════════
PanelWindow {
    id: root

    property bool open: false
    signal closeRequested()
    signal screenshotRequested()
    signal grimRequested()
    signal recorderToggleRequested()
    signal recorderMicToggleRequested()
    signal setFaceRequested()
    signal notifyRequested(string icon, string summary, string body)
    signal dndToggleRequested()
    signal tabSelectionChanged(int index)

    // State DND yang bisa dibaca QuickToggles tanpa perlu poll swaync
    property bool dndActive: false

    // Tab yang diminta bar/shortcut (di-set sebelum open)
    property int requestedTab: 0
    property int requestedConnectTab: 0   // 0 = Wi-Fi, 1 = Bluetooth

    // Tab aktif
    property int activeTab: 0

    onRequestedTabChanged: if (open) activeTab = requestedTab

    anchors { top: true; left: true; right: true }
    margins.top: 5
    color: "transparent"
    visible: showPanel
    implicitHeight: card.height + 8

    property bool showPanel: false
    onOpenChanged: {
        if (open) {
            showPanel = true
            activeTab = requestedTab
        }
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "quickshell-dashboard"
    WlrLayershell.exclusiveZone: 0

    MouseArea {
        anchors.fill: parent
        hoverEnabled: false
        onClicked: root.closeRequested()
    }

    // ── Spesifikasi tab ─────────────────────────────────────────────────────
    QtObject {
        id: tabSpecs
        readonly property var titles: ["Overview", "Media", "Volume", "Battery", "Network", "Clipboard", "Notifikasi", "Kalender", "Info"]
        readonly property var icons:  ["󰀄", "󰝚", "󰕾", "󰁹", "󰖩", "󰅍", "󰂞", "󰸗", "󰋊"]
        readonly property var widths: [420, 400, 420, 320, 420, 420, 400, 720, 420]
        readonly property var heights: [470, 520, 580, 520, 620, 580, 560, 670, 560]
    }

    readonly property int _railW: 52
    readonly property int _pad:   12
    readonly property int _headerH: 44
    readonly property int _contentW: tabSpecs.widths[root.activeTab]
    readonly property int _contentH: tabSpecs.heights[root.activeTab]
    readonly property int _cardW: root._pad + root._railW + 1 + root._pad + root._contentW + root._pad
    readonly property int _cardH: root._headerH + root._contentH + root._pad * 2

    // ── Kartu utama ─────────────────────────────────────────────────────────
    Rectangle {
        id: card
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width:  root._cardW
        height: root._cardH
        radius: 20
        color:  Root.Colors.mantle
        border.color: Root.Colors.surface2
        border.width: 2
        clip: true

        // ── Animasi slide dari atas + fade + scale ──────────────────────
        opacity: 0
        scale: 0.96
        transform: Translate { id: cardSlide; y: -40 }

        states: State {
            name: "open"
            when: root.open
            PropertyChanges { target: card;      opacity: 1; scale: 1 }
            PropertyChanges { target: cardSlide; y: 0 }
        }

        transitions: [
            Transition {
                from: ""; to: "open"
                ParallelAnimation {
                    NumberAnimation { target: cardSlide; property: "y";     duration: 400; easing.type: Easing.OutCubic }
                    NumberAnimation { target: card;      property: "scale"; duration: 400; easing.type: Easing.OutCubic }
                    NumberAnimation { target: card;      property: "opacity"; duration: 350; easing.type: Easing.OutQuad }
                }
            },
            Transition {
                from: "open"; to: ""
                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation { target: cardSlide; property: "y";     duration: 350; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: card;      property: "scale"; duration: 350; easing.type: Easing.InOutQuad }
                        NumberAnimation { target: card;      property: "opacity"; duration: 300; easing.type: Easing.InQuad }
                    }
                    PauseAnimation { duration: 50 }
                    ScriptAction { script: root.showPanel = false }
                }
            }
        ]

        Behavior on color        { ColorAnimation { duration: 200 } }
        Behavior on border.color { ColorAnimation { duration: 200 } }

        MouseArea { anchors.fill: parent; hoverEnabled: false; onClicked: {} }

        // ── Rail tab kiri ────────────────────────────────────────────────
        Item {
            id: rail
            x: root._pad
            y: root._pad
            width: root._railW
            height: card.height - root._pad * 2

            Column {
                anchors.fill: parent
                spacing: 6

                // Avatar kecil
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 34; height: 34

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Root.Colors.surface0
                        border.color: Root.Colors.lavender
                        border.width: 2
                    }

                    Image {
                        id: railFaceImg
                        anchors.fill: parent
                        anchors.margins: 2
                        source: "file:///home/xans/.face"
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        visible: status === Image.Ready
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: ShaderEffectSource {
                                sourceItem: Rectangle {
                                    width: parent.width; height: parent.height
                                    radius: width / 2; color: "white"; visible: false
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: railFaceImg.status !== Image.Ready
                        text: "󰀄"
                        font.family: "CaskaydiaCove Nerd Font"
                        font.pixelSize: 16
                        color: Root.Colors.subtext
                    }
                }

                Rectangle {
                    width: parent.width - 10
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 1
                    color: Root.Colors.surface1
                }

                // Tombol tab
                Repeater {
                    model: tabSpecs.icons

                    delegate: Rectangle {
                        required property string modelData
                        required property int index

                        width: rail.width
                        height: 38
                        radius: 10
                        color: {
                            if (root.activeTab === index)
                                return Qt.rgba(Root.Colors.blue.r, Root.Colors.blue.g, Root.Colors.blue.b, 0.22)
                            if (tabMa.containsMouse)
                                return Root.Colors.surface0
                            return "transparent"
                        }
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: 18
                            color: root.activeTab === index ? Root.Colors.blue : Root.Colors.subtext
                            Behavior on color { ColorAnimation { duration: 120 } }
                        }

                        // Tooltip nama tab
                        Rectangle {
                            visible: tabMa.containsMouse && root.activeTab !== index
                            anchors {
                                left: parent.right; leftMargin: 6
                                verticalCenter: parent.verticalCenter
                            }
                            width: tipTxt.implicitWidth + 12
                            height: 22
                            radius: 6
                            color: Root.Colors.surface1
                            z: 50
                            Text {
                                id: tipTxt
                                anchors.centerIn: parent
                                text: tabSpecs.titles[index]
                                font.pixelSize: 10
                                color: Root.Colors.text
                            }
                        }

                        MouseArea {
                            id: tabMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.activeTab = index
                                root.tabSelectionChanged(index)
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true; height: 1; width: 1 }

                // Jam bawah rail
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    id: railClock
                    text: Qt.formatDateTime(new Date(), "HH:mm")
                    font.pixelSize: 13
                    font.bold: true
                    color: Root.Colors.subtext
                    Timer {
                        interval: 10000; running: true; repeat: true
                        onTriggered: railClock.text = Qt.formatDateTime(new Date(), "HH:mm")
                    }
                }
            }
        }

        // ── Separator rail ───────────────────────────────────────────────
        Rectangle {
            x: root._pad + root._railW
            y: root._pad
            width: 1
            height: card.height - root._pad * 2
            color: Root.Colors.surface1
        }

        // ── Header ───────────────────────────────────────────────────────
        Item {
            id: header
            x: root._pad + root._railW + root._pad
            y: root._pad
            width: root._contentW
            height: root._headerH

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                text: tabSpecs.icons[root.activeTab] + "  " + tabSpecs.titles[root.activeTab]
                font.pixelSize: 15
                font.bold: true
                color: Root.Colors.text
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            Text {
                id: headerDate
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: closeBtn.left
                anchors.rightMargin: 10
                text: Qt.formatDateTime(new Date(), "dd MMM yyyy · HH:mm")
                font.pixelSize: 11
                color: Root.Colors.subtext
                Timer {
                    interval: 30000; running: true; repeat: true
                    onTriggered: headerDate.text = Qt.formatDateTime(new Date(), "dd MMM yyyy · HH:mm")
                }
            }

            // Tombol tutup
            Rectangle {
                id: closeBtn
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                width: 26; height: 26; radius: 8
                color: closeMa.containsMouse ? Root.Colors.surface1 : Root.Colors.surface0
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    font.pixelSize: 11
                    color: Root.Colors.subtext
                }

                MouseArea {
                    id: closeMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeRequested()
                }
            }
        }

        // ── Konten tab ───────────────────────────────────────────────────
        Item {
            id: contentArea
            x: root._pad + root._railW + root._pad
            y: root._pad + root._headerH
            width: root._contentW
            height: root._contentH

            // ═══ TAB 0: OVERVIEW ═══════════════════════════════════════
            Dash.OverviewTab {
                anchors.fill: parent
                dndActive: root.dndActive
                opacity: root.activeTab === 0 ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 180 } }
                onScreenshotRequested:      root.screenshotRequested()
                onGrimRequested:            root.grimRequested()
                onRecorderToggleRequested:  root.recorderToggleRequested()
                onRecorderMicToggleRequested: root.recorderMicToggleRequested()
                onNotifyRequested: (i, s, b) => root.notifyRequested(i, s, b)
                onDndToggleRequested:       root.dndToggleRequested()
                onCloseRequested:           root.closeRequested()
            }

            // ═══ TAB 1: MEDIA ═══════════════════════════════════════════
            Dash.MediaTab {
                anchors.fill: parent
                opacity: root.activeTab === 1 ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 180 } }
            }

            // ═══ TAB 2: VOLUME ══════════════════════════════════════════
            Dash.VolumeTab {
                anchors.fill: parent
                opacity: root.activeTab === 2 ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 180 } }
            }

            // ═══ TAB 3: BATTERY ═════════════════════════════════════════
            Dash.BatteryTab {
                anchors.fill: parent
                active: root.activeTab === 3
                opacity: root.activeTab === 3 ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 180 } }
            }

            // ═══ TAB 4: NETWORK (Wi-Fi + Bluetooth) ══════════════════════
            Dash.NetworkTab {
                anchors.fill: parent
                active: root.activeTab === 4
                requestedTab: root.requestedConnectTab
                opacity: root.activeTab === 4 ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 180 } }
            }

            // ═══ TAB 5: CLIPBOARD ═══════════════════════════════════════
            Dash.ClipboardTab {
                anchors.fill: parent
                active: root.activeTab === 5
                opacity: root.activeTab === 5 ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 180 } }
                onCloseRequested: root.closeRequested()
            }

            // ═══ TAB 6: NOTIFIKASI ═══════════════════════════════════════
            Dash.NotifTab {
                anchors.fill: parent
                opacity: root.activeTab === 6 ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 180 } }
            }

            // ═══ TAB 7: KALENDER ═════════════════════════════════════════
            Dash.CalendarTab {
                anchors.fill: parent
                active: root.activeTab === 7
                opacity: root.activeTab === 7 ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 180 } }
            }

            // ═══ TAB 8: INFO ════════════════════════════════════════════
            Dash.InfoTab {
                anchors.fill: parent
                opacity: root.activeTab === 8 ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 180 } }
                onSetFaceRequested: root.setFaceRequested()
            }
        }
    }
}