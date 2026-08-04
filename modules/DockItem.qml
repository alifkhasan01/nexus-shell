import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../" as Root

// Satu ikon di dock — tanpa magnifikasi hover macOS (dihapus per permintaan).
// Fitur: running dot, bounce launch, tooltip, klik buka/fokus app.

Item {
    id: root

    property string appName:    ""
    property string appIcon:    ""
    property string appCmd:     ""
    property string appId:      ""
    property bool   isLauncher: false

    readonly property int iconSize: Root.DockConfig.baseSize

    implicitWidth:  iconSize
    implicitHeight: iconSize

    // ── Running state ─────────────────────────────────────────────────────
    readonly property bool isRunning: {
        const tls = Hyprland.toplevels.values
        const mid = (appId !== "" ? appId : appIcon).toLowerCase()
        for (let i = 0; i < tls.length; i++) {
            const tl = tls[i]
            if (!tl) continue
            const wid = (tl.wayland && tl.wayland.appId) ? tl.wayland.appId.toLowerCase() : ""
            const cls = tl.lastIpcObject
                        ? ((tl.lastIpcObject.initialClass || tl.lastIpcObject.class) || "").toLowerCase()
                        : ""
            if (wid === mid || cls === mid) return true
        }
        return false
    }

    // ── Bounce ────────────────────────────────────────────────────────────
    property bool bouncing: false
    property real bounceY:  0

    onBouncingChanged: { if (!bouncing) bounceY = 0 }

    Timer {
        id: bounceTimer
        interval: 1400
        repeat:   false
        onTriggered: root.bouncing = false
    }

    SequentialAnimation {
        running: root.bouncing
        loops:   Animation.Infinite
        NumberAnimation { target: root; property: "bounceY"; to: -(root.iconSize * 0.4); duration: 180; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "bounceY"; to: 0;                      duration: 180; easing.type: Easing.InQuad  }
        NumberAnimation { target: root; property: "bounceY"; to: -(root.iconSize * 0.2); duration: 130; easing.type: Easing.OutQuad }
        NumberAnimation { target: root; property: "bounceY"; to: 0;                      duration: 130; easing.type: Easing.InQuad  }
    }

    // ── Launch ────────────────────────────────────────────────────────────
    Process {
        id: launchProc
    }

    function launch() {
        if (isLauncher) {
            launchProc.command = ["sh", "-c", "walker"]
            launchProc.running = true
            return
        }
        if (isRunning) {
            const tls = Hyprland.toplevels.values
            const mid = (appId !== "" ? appId : appIcon).toLowerCase()
            for (let i = 0; i < tls.length; i++) {
                const tl = tls[i]
                if (!tl) continue
                const wid = (tl.wayland && tl.wayland.appId) ? tl.wayland.appId.toLowerCase() : ""
                const cls = tl.lastIpcObject
                            ? ((tl.lastIpcObject.initialClass || tl.lastIpcObject.class) || "").toLowerCase()
                            : ""
                if (wid === mid || cls === mid) {
                    Hyprland.dispatch("focuswindow address:" + tl.address)
                    return
                }
            }
        }
        // Launch baru — jalankan via sh -c agar bisa pakai PATH penuh
        launchProc.command = ["sh", "-c", appCmd]
        launchProc.running = true
        root.bouncing = true
        bounceTimer.start()
    }

    // ── Visual ────────────────────────────────────────────────────────────
    Item {
        anchors.centerIn: parent
        width:  root.iconSize
        height: root.iconSize
        transform: Translate { y: root.bounceY }

        Image {
            id: appImg
            anchors.fill:    parent
            anchors.margins: 2
            source:          Quickshell.iconPath(root.appIcon)
            smooth:          true
            mipmap:          true
            fillMode:        Image.PreserveAspectFit

            // Fallback teks jika ikon tidak ditemukan
            visible: status === Image.Ready
        }

        // Fallback: kotak berwarna + inisial
        Rectangle {
            anchors.fill:  parent
            anchors.margins: 2
            visible:       appImg.status !== Image.Ready
            radius:        8
            color:         Root.Colors.surface1
            border.color:  Root.Colors.surface2
            border.width:  1

            Text {
                anchors.centerIn: parent
                text:             root.appName.charAt(0).toUpperCase()
                font.pixelSize:   root.iconSize * 0.45
                color:            Root.Colors.text
                font.bold:        true
            }
        }
    }

    // ── Running dot ───────────────────────────────────────────────────────
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom:           parent.bottom
        anchors.bottomMargin:     -6

        width:  root.isRunning ? 4 : 0
        height: width
        radius: 2
        color:  Root.Colors.blue

        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
    }

    // ── Tooltip ───────────────────────────────────────────────────────────
    Rectangle {
        anchors.bottom:           parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin:     6

        visible:  tipMouse.containsMouse
        opacity:  tipMouse.containsMouse ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 120 } }

        implicitWidth:  tipText.implicitWidth + 16
        implicitHeight: 22
        radius:         6
        color:          Root.Colors.surface0
        border.color:   Root.Colors.surface2
        border.width:   1

        Text {
            id: tipText
            anchors.centerIn: parent
            text:             root.appName
            font.pixelSize:   11
            color:            Root.Colors.subtext
        }
    }

    // ── Click area ────────────────────────────────────────────────────────
    MouseArea {
        id: tipMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape:  Qt.PointingHandCursor
        onClicked:    root.launch()
    }
}
