import QtQuick
import Quickshell.Io
import "../" as Root

// Tombol di Bar untuk toggle WallpaperPanel.
// Menampilkan thumbnail wallpaper aktif (dari ~/.cache/wallpaper/current)
// sebagai ikon kecil, dengan fallback ke ikon teks.
Item {
    id: root
    width: 34
    height: 26

    property bool panelOpen: false
    signal togglePanel()

    // Baca path wallpaper aktif dari cache
    property string currentWallpaper: ""

    Process {
        id: readCurrentProc
        command: ["sh", "-c", "cat ~/.cache/wallpaper/current 2>/dev/null || echo ''"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim()
                root.currentWallpaper = p.length > 0 ? ("file://" + p) : ""
            }
        }
    }

    // Refresh thumbnail setiap 5 detik untuk menangkap perubahan
    Timer {
        interval: 5000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: readCurrentProc.running = true
    }

    // ── Background hover ──────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: 6
        color: btnArea.containsMouse
             ? Root.Colors.surface1
             : (root.panelOpen ? Root.Colors.surface0 : "transparent")
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    // ── Thumbnail wallpaper aktif (kotak kecil) ───────────────────────────
    Rectangle {
        id: thumbBox
        anchors.centerIn: parent
        width: 22; height: 14
        radius: 3
        color: Root.Colors.surface1
        clip: true
        border.color: root.panelOpen ? Root.Colors.blue : Root.Colors.surface2
        border.width: 1
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Image {
            anchors.fill: parent
            source: root.currentWallpaper
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false                 // jangan cache supaya perubahan langsung terlihat
            sourceSize.width:  44        // decode kecil — hanya 22px yang ditampilkan
            sourceSize.height: 28
            smooth: true
            visible: status === Image.Ready
        }

        // Fallback icon
        Text {
            anchors.centerIn: parent
            visible: root.currentWallpaper === ""
                  || parent.children[0]?.status !== Image.Ready
            text: "󰸉"
            font.pixelSize: 9
            color: root.panelOpen ? Root.Colors.blue : Root.Colors.subtext
            Behavior on color { ColorAnimation { duration: 150 } }
        }
    }

    // ── Tooltip ───────────────────────────────────────────────────────────
    Rectangle {
        visible: btnArea.containsMouse
        z: 10
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.top
        anchors.bottomMargin: 6
        implicitWidth: tipTxt.implicitWidth + 16; height: 22; radius: 6
        color: Root.Colors.surface2
        border.color: Root.Colors.surface1; border.width: 1

        Text {
            id: tipTxt
            anchors.centerIn: parent
            font.pixelSize: 11; color: Root.Colors.text
            text: "Wallpaper"
        }
    }

    MouseArea {
        id: btnArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.togglePanel()
    }
}
