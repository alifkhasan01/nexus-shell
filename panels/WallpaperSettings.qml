import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import "../" as Root

// ─────────────────────────────────────────────────────────────────────────────
// WallpaperSettings  —  popup overlay settings untuk WallpaperPanel
//
// Semua warna dari Root.Colors (Ayu palette, reaktif terhadap perubahan tema).
// Semua animasi dari Root.Appearance.animation.elementMoveFast.
// Font icon dari Root.Appearance.font.family.iconNerd.
// ─────────────────────────────────────────────────────────────────────────────
Item {
    id: settingsRoot

    // ── API ──────────────────────────────────────────────────────────────────
    property bool   open:               false
    property string wallpaperDir:       ""
    property string transitionType:     "wipe"
    property real   transitionDuration: 1.0
    property int    transitionFps:      60
    property bool   slideshowEnabled:   false
    property int    slideshowMinutes:   5
    property string wallpaperMode:      "fill"

    signal saveRequested()
    signal scanRequested()
    signal pickFolderRequested()

    // tidak dipakai lagi, dibiarkan agar tidak break binding lama
    property bool pickingDir: false

    // ── Shorthand animasi (ikut tema) ────────────────────────────────────────
    readonly property int   _dur:  Root.Appearance.animation.elementMoveFast.duration
    readonly property int   _ease: Root.Appearance.animation.elementMoveFast.type
    readonly property var   _bez:  Root.Appearance.animation.elementMoveFast.bezierCurve
    readonly property string _nf:  Root.Appearance.font.family.iconNerd

    // ── Tidak ikut layout parent saat tidak visible ──────────────────────────
    visible: _backdropOpacity > 0
    anchors.fill: parent

    // ── Animasi state ────────────────────────────────────────────────────────
    property real _backdropOpacity: 0
    property real _popupScale:      0.94

    onOpenChanged: {
        if (open) { _backdropOpacity = 1; _popupScale = 1.0 }
        else       { _backdropOpacity = 0; _popupScale = 0.94 }
    }

    Behavior on _backdropOpacity {
        NumberAnimation {
            duration: Root.Appearance.animation.elementMoveSmall.duration
            easing.type: Root.Appearance.animation.elementMoveSmall.type
            easing.bezierCurve: Root.Appearance.animation.elementMoveSmall.bezierCurve
        }
    }
    Behavior on _popupScale {
        NumberAnimation {
            duration: Root.Appearance.animation.elementMoveSmall.duration
            easing.type: Root.Appearance.animation.elementMoveSmall.type
            easing.bezierCurve: Root.Appearance.animation.elementMoveSmall.bezierCurve
        }
    }

    // ── Backdrop ─────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.48 * settingsRoot._backdropOpacity)
        radius: parent instanceof Rectangle ? parent.radius : 0

        MouseArea { anchors.fill: parent; onClicked: settingsRoot.open = false }
    }

    // ── Popup card ───────────────────────────────────────────────────────────
    Rectangle {
        id: popup
        anchors.centerIn: parent
        width:  Math.min(500, settingsRoot.width - 48)
        height: contentCol.implicitHeight + 48
        radius: Root.Appearance.rounding.large
        color:  Root.Colors.mantle
        border.color: Root.Colors.surface1
        border.width: 1

        opacity: settingsRoot._backdropOpacity
        scale:   settingsRoot._popupScale

        Behavior on color        { ColorAnimation { duration: settingsRoot._dur; easing.type: settingsRoot._ease; easing.bezierCurve: settingsRoot._bez } }
        Behavior on border.color { ColorAnimation { duration: settingsRoot._dur; easing.type: settingsRoot._ease; easing.bezierCurve: settingsRoot._bez } }

        MouseArea { anchors.fill: parent; onClicked: {} }

        ColumnLayout {
            id: contentCol
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 20 }
            spacing: 18

            // ── Header popup ─────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 8

                Text {
                    text: "  Pengaturan Wallpaper"
                    font.pixelSize: 14; font.bold: true
                    font.family: settingsRoot._nf
                    color: Root.Colors.text
                    Behavior on color { ColorAnimation { duration: settingsRoot._dur; easing.type: settingsRoot._ease; easing.bezierCurve: settingsRoot._bez } }
                }
                Item { Layout.fillWidth: true }

                // Tombol tutup
                Rectangle {
                    width: 28; height: 28; radius: Root.Appearance.rounding.verysmall
                    color: closeMa.containsMouse ? Root.Colors.surface1 : "transparent"
                    Behavior on color { ColorAnimation { duration: settingsRoot._dur; easing.type: settingsRoot._ease; easing.bezierCurve: settingsRoot._bez } }
                    Text {
                        anchors.centerIn: parent
                        text: "󱎘"; font.pixelSize: 13; font.family: settingsRoot._nf
                        color: Root.Colors.subtext
                        Behavior on color { ColorAnimation { duration: settingsRoot._dur; easing.type: settingsRoot._ease; easing.bezierCurve: settingsRoot._bez } }
                    }
                    MouseArea {
                        id: closeMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: settingsRoot.open = false
                    }
                }
            }

            // Divider
            Rectangle { Layout.fillWidth: true; height: 1; color: Root.Colors.surface1; Behavior on color { ColorAnimation { duration: settingsRoot._dur } } }

            // ── SECTION: Folder ──────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                // Section header — semua section pakai pola yang sama: ikon + label + garis
                RowLayout {
                    Layout.fillWidth: true; spacing: 6
                    Text { text: "󰉋"; font.pixelSize: 12; font.family: settingsRoot._nf; color: Root.Colors.subtext; Behavior on color { ColorAnimation { duration: settingsRoot._dur } } }
                    Text { text: "FOLDER"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.2; color: Root.Colors.subtext; Behavior on color { ColorAnimation { duration: settingsRoot._dur } } }
                    Rectangle { Layout.fillWidth: true; height: 1; color: Root.Colors.surface1; Behavior on color { ColorAnimation { duration: settingsRoot._dur } } }
                }

                // Tombol picker folder
                Rectangle {
                    Layout.fillWidth: true; height: 36
                    radius: Root.Appearance.rounding.verysmall
                    color: dirMa.containsMouse ? Root.Colors.surface1 : Root.Colors.surface0
                    Behavior on color { ColorAnimation { duration: settingsRoot._dur; easing.type: settingsRoot._ease; easing.bezierCurve: settingsRoot._bez } }

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 8
                        Text {
                            text: "󰉋"; font.pixelSize: 13; font.family: settingsRoot._nf
                            color: Root.Colors.blue
                            Behavior on color { ColorAnimation { duration: settingsRoot._dur } }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: settingsRoot.wallpaperDir.length > 0 ? settingsRoot.wallpaperDir : "Belum dipilih…"
                            font.pixelSize: 12
                            color: settingsRoot.wallpaperDir.length > 0 ? Root.Colors.text : Root.Colors.subtext
                            elide: Text.ElideLeft
                            Behavior on color { ColorAnimation { duration: settingsRoot._dur } }
                        }
                        Text {
                            text: ""; font.pixelSize: 11; font.family: settingsRoot._nf
                            color: Root.Colors.subtext
                        }
                    }
                    MouseArea {
                        id: dirMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: settingsRoot.pickFolderRequested()
                    }
                }
            }

            // ── SECTION: Posisi & Tampilan ───────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true; spacing: 6
                    Text { text: "󰹙"; font.pixelSize: 12; font.family: settingsRoot._nf; color: Root.Colors.subtext; Behavior on color { ColorAnimation { duration: settingsRoot._dur } } }
                    Text { text: "POSISI & TAMPILAN"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.2; color: Root.Colors.subtext; Behavior on color { ColorAnimation { duration: settingsRoot._dur } } }
                    Rectangle { Layout.fillWidth: true; height: 1; color: Root.Colors.surface1; Behavior on color { ColorAnimation { duration: settingsRoot._dur } } }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 5; columnSpacing: 6; rowSpacing: 0

                    Repeater {
                        model: [
                            { id: "fill",    icon: "󰹙", label: "Fill"    },
                            { id: "fit",     icon: "󰹚", label: "Fit"     },
                            { id: "stretch", icon: "󰢅", label: "Stretch" },
                            { id: "center",  icon: "󰘞", label: "Center"  },
                            { id: "tile",    icon: "󰙀", label: "Tile"    }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            height: 56; radius: Root.Appearance.rounding.verysmall

                            readonly property bool isActive: settingsRoot.wallpaperMode === modelData.id

                            color: isActive
                                   ? Root.Colors.surface1
                                   : (modeMa.containsMouse ? Root.Colors.surface0 : "transparent")
                            border.color: isActive ? Root.Colors.blue : Root.Colors.surface1
                            border.width: isActive ? 2 : 1
                            Behavior on color        { ColorAnimation { duration: settingsRoot._dur; easing.type: settingsRoot._ease; easing.bezierCurve: settingsRoot._bez } }
                            Behavior on border.color { ColorAnimation { duration: settingsRoot._dur; easing.type: settingsRoot._ease; easing.bezierCurve: settingsRoot._bez } }

                            ColumnLayout {
                                anchors.centerIn: parent; spacing: 4
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.icon; font.pixelSize: 20
                                    font.family: settingsRoot._nf
                                    color: parent.parent.isActive ? Root.Colors.blue : Root.Colors.subtext
                                    Behavior on color { ColorAnimation { duration: settingsRoot._dur; easing.type: settingsRoot._ease; easing.bezierCurve: settingsRoot._bez } }
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.label; font.pixelSize: 10
                                    color: parent.parent.isActive ? Root.Colors.text : Root.Colors.subtext
                                    Behavior on color { ColorAnimation { duration: settingsRoot._dur; easing.type: settingsRoot._ease; easing.bezierCurve: settingsRoot._bez } }
                                }
                            }
                            MouseArea {
                                id: modeMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { settingsRoot.wallpaperMode = modelData.id; settingsRoot.saveRequested() }
                            }
                        }
                    }
                }
            }

            // ── SECTION: Transisi ────────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true; spacing: 6
                    Text { text: ""; font.pixelSize: 12; font.family: settingsRoot._nf; color: Root.Colors.subtext; Behavior on color { ColorAnimation { duration: settingsRoot._dur } } }
                    Text { text: "TRANSISI"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.2; color: Root.Colors.subtext; Behavior on color { ColorAnimation { duration: settingsRoot._dur } } }
                    Rectangle { Layout.fillWidth: true; height: 1; color: Root.Colors.surface1; Behavior on color { ColorAnimation { duration: settingsRoot._dur } } }
                }

                // Chips jenis transisi — aktif = blue bg + base text, nonaktif = surface0 + text
                Flow {
                    Layout.fillWidth: true; spacing: 5

                    Repeater {
                        model: ["simple","fade","wipe","wave","grow","center","outer","random"]
                        delegate: Rectangle {
                            required property string modelData
                            readonly property bool isActive: settingsRoot.transitionType === modelData
                            height: 26; width: chipLbl.implicitWidth + 18
                            radius: Root.Appearance.rounding.verysmall
                            color: isActive
                                   ? Root.Colors.blue
                                   : (chipMa.containsMouse ? Root.Colors.surface1 : Root.Colors.surface0)
                            Behavior on color { ColorAnimation { duration: settingsRoot._dur; easing.type: settingsRoot._ease; easing.bezierCurve: settingsRoot._bez } }

                            Text {
                                id: chipLbl; anchors.centerIn: parent
                                text: modelData; font.pixelSize: 11
                                color: parent.isActive ? Root.Colors.base : Root.Colors.text
                                Behavior on color { ColorAnimation { duration: settingsRoot._dur; easing.type: settingsRoot._ease; easing.bezierCurve: settingsRoot._bez } }
                            }
                            MouseArea {
                                id: chipMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { settingsRoot.transitionType = modelData; settingsRoot.saveRequested() }
                            }
                        }
                    }
                }

                // Durasi + FPS dengan slider
                RowLayout {
                    Layout.fillWidth: true; spacing: 20

                    // Durasi
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4

                        RowLayout {
                            Text { text: "Durasi"; font.pixelSize: 11; color: Root.Colors.subtext; Behavior on color { ColorAnimation { duration: settingsRoot._dur } } }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                height: 22; width: 52; radius: Root.Appearance.rounding.verysmall
                                color: Root.Colors.surface0
                                border.color: durInput.activeFocus ? Root.Colors.blue : "transparent"
                                border.width: 1
                                Behavior on color        { ColorAnimation { duration: settingsRoot._dur } }
                                Behavior on border.color { ColorAnimation { duration: 120 } }
                                TextInput {
                                    id: durInput
                                    anchors.centerIn: parent; width: parent.width - 10
                                    text: settingsRoot.transitionDuration.toFixed(1)
                                    font.pixelSize: 11; color: Root.Colors.text
                                    horizontalAlignment: TextInput.AlignHCenter
                                    validator: DoubleValidator { bottom: 0.1; top: 5.0; decimals: 1 }
                                    onEditingFinished: {
                                        settingsRoot.transitionDuration = parseFloat(text) || 1.0
                                        durSlider.value = settingsRoot.transitionDuration
                                        settingsRoot.saveRequested()
                                    }
                                }
                            }
                            Text { text: "dtk"; font.pixelSize: 11; color: Root.Colors.subtext }
                        }

                        Slider {
                            id: durSlider
                            Layout.fillWidth: true
                            from: 0.1; to: 5.0; stepSize: 0.1
                            value: settingsRoot.transitionDuration
                            onMoved: {
                                settingsRoot.transitionDuration = Math.round(value * 10) / 10
                                durInput.text = settingsRoot.transitionDuration.toFixed(1)
                                settingsRoot.saveRequested()
                            }
                            background: Rectangle {
                                x: durSlider.leftPadding
                                y: durSlider.topPadding + durSlider.availableHeight / 2 - height / 2
                                width: durSlider.availableWidth; height: 4; radius: 2
                                color: Root.Colors.surface1
                                Behavior on color { ColorAnimation { duration: settingsRoot._dur } }
                                Rectangle {
                                    width: durSlider.visualPosition * parent.width
                                    height: parent.height; radius: 2
                                    color: Root.Colors.blue
                                    Behavior on color { ColorAnimation { duration: settingsRoot._dur } }
                                }
                            }
                            handle: Rectangle {
                                x: durSlider.leftPadding + durSlider.visualPosition * (durSlider.availableWidth - width)
                                y: durSlider.topPadding + durSlider.availableHeight / 2 - height / 2
                                width: 14; height: 14; radius: 7
                                color: durSlider.pressed ? Root.Colors.blue : Root.Colors.surface2
                                border.color: Root.Colors.blue; border.width: 2
                                Behavior on color { ColorAnimation { duration: settingsRoot._dur } }
                            }
                        }
                    }

                    // FPS
                    ColumnLayout {
                        Layout.preferredWidth: 130; spacing: 4

                        RowLayout {
                            Text { text: "FPS"; font.pixelSize: 11; color: Root.Colors.subtext; Behavior on color { ColorAnimation { duration: settingsRoot._dur } } }
                            Item { Layout.fillWidth: true }
                            Rectangle {
                                height: 22; width: 46; radius: Root.Appearance.rounding.verysmall
                                color: Root.Colors.surface0
                                border.color: fpsInput.activeFocus ? Root.Colors.blue : "transparent"
                                border.width: 1
                                Behavior on color        { ColorAnimation { duration: settingsRoot._dur } }
                                Behavior on border.color { ColorAnimation { duration: 120 } }
                                TextInput {
                                    id: fpsInput
                                    anchors.centerIn: parent; width: parent.width - 10
                                    text: settingsRoot.transitionFps
                                    font.pixelSize: 11; color: Root.Colors.text
                                    horizontalAlignment: TextInput.AlignHCenter
                                    validator: IntValidator { bottom: 24; top: 144 }
                                    onEditingFinished: {
                                        settingsRoot.transitionFps = parseInt(text) || 60
                                        fpsSlider.value = settingsRoot.transitionFps
                                        settingsRoot.saveRequested()
                                    }
                                }
                            }
                        }

                        Slider {
                            id: fpsSlider
                            Layout.fillWidth: true
                            from: 24; to: 144; stepSize: 1
                            value: settingsRoot.transitionFps
                            onMoved: {
                                settingsRoot.transitionFps = Math.round(value)
                                fpsInput.text = settingsRoot.transitionFps
                                settingsRoot.saveRequested()
                            }
                            background: Rectangle {
                                x: fpsSlider.leftPadding
                                y: fpsSlider.topPadding + fpsSlider.availableHeight / 2 - height / 2
                                width: fpsSlider.availableWidth; height: 4; radius: 2
                                color: Root.Colors.surface1
                                Behavior on color { ColorAnimation { duration: settingsRoot._dur } }
                                Rectangle {
                                    width: fpsSlider.visualPosition * parent.width
                                    height: parent.height; radius: 2
                                    color: Root.Colors.blue
                                    Behavior on color { ColorAnimation { duration: settingsRoot._dur } }
                                }
                            }
                            handle: Rectangle {
                                x: fpsSlider.leftPadding + fpsSlider.visualPosition * (fpsSlider.availableWidth - width)
                                y: fpsSlider.topPadding + fpsSlider.availableHeight / 2 - height / 2
                                width: 14; height: 14; radius: 7
                                color: fpsSlider.pressed ? Root.Colors.blue : Root.Colors.surface2
                                border.color: Root.Colors.blue; border.width: 2
                                Behavior on color { ColorAnimation { duration: settingsRoot._dur } }
                            }
                        }
                    }
                }
            }

            // ── SECTION: Slideshow ───────────────────────────────────────────
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true; spacing: 6
                    Text { text: "󰔟"; font.pixelSize: 12; font.family: settingsRoot._nf; color: Root.Colors.subtext; Behavior on color { ColorAnimation { duration: settingsRoot._dur } } }
                    Text { text: "SLIDESHOW"; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.2; color: Root.Colors.subtext; Behavior on color { ColorAnimation { duration: settingsRoot._dur } } }
                    Rectangle { Layout.fillWidth: true; height: 1; color: Root.Colors.surface1; Behavior on color { ColorAnimation { duration: settingsRoot._dur } } }
                }

                RowLayout {
                    Layout.fillWidth: true; spacing: 12

                    // Toggle pill — aktif = blue (pola dari QuickToggle)
                    Rectangle {
                        width: 52; height: 28; radius: 14
                        color: settingsRoot.slideshowEnabled ? Root.Colors.blue : Root.Colors.surface1
                        Behavior on color { ColorAnimation { duration: 220; easing.type: settingsRoot._ease; easing.bezierCurve: settingsRoot._bez } }

                        Rectangle {
                            width: 20; height: 20; radius: 10
                            color: settingsRoot.slideshowEnabled ? Root.Colors.base : Root.Colors.surface2
                            anchors.verticalCenter: parent.verticalCenter
                            x: settingsRoot.slideshowEnabled ? parent.width - width - 4 : 4
                            Behavior on x     { NumberAnimation { duration: 220; easing.type: Easing.InOutQuad } }
                            Behavior on color { ColorAnimation { duration: settingsRoot._dur } }
                        }

                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                settingsRoot.slideshowEnabled = !settingsRoot.slideshowEnabled
                                settingsRoot.saveRequested()
                            }
                        }
                    }

                    Text {
                        text: settingsRoot.slideshowEnabled ? "Aktif" : "Nonaktif"
                        font.pixelSize: 12
                        color: settingsRoot.slideshowEnabled ? Root.Colors.text : Root.Colors.subtext
                        Behavior on color { ColorAnimation { duration: settingsRoot._dur } }
                    }

                    Item { Layout.fillWidth: true }

                    Text { text: "ganti tiap"; font.pixelSize: 11; color: Root.Colors.subtext; Behavior on color { ColorAnimation { duration: settingsRoot._dur } } }

                    Rectangle {
                        height: 26; width: 52; radius: Root.Appearance.rounding.verysmall
                        color: Root.Colors.surface0
                        border.color: slideInput.activeFocus ? Root.Colors.blue : "transparent"
                        border.width: 1
                        Behavior on color        { ColorAnimation { duration: settingsRoot._dur } }
                        Behavior on border.color { ColorAnimation { duration: 120 } }
                        TextInput {
                            id: slideInput
                            anchors.centerIn: parent; width: parent.width - 10
                            text: settingsRoot.slideshowMinutes
                            font.pixelSize: 12; color: Root.Colors.text
                            horizontalAlignment: TextInput.AlignHCenter
                            validator: IntValidator { bottom: 1; top: 120 }
                            onEditingFinished: {
                                settingsRoot.slideshowMinutes = parseInt(text) || 5
                                settingsRoot.saveRequested()
                            }
                        }
                    }

                    Text { text: "menit"; font.pixelSize: 11; color: Root.Colors.subtext; Behavior on color { ColorAnimation { duration: settingsRoot._dur } } }
                }
            }

            // bottom spacer
            Item { Layout.preferredHeight: 4 }
        }
    }
}
