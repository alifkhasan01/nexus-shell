import QtQuick
import QtQuick.Layouts
import "../" as Root

// Baris 2 tombol tema (Catppuccin Dark/Light) — klik untuk ganti tema aktif.
// Tombol aktif ditandai dengan background biru + teks terang.
// Selain warna shell, ganti tema juga memicu matugen untuk sinkron ke GTK,
// Qt, foot, hyprland, dan gsettings (lihat Colors.qml).
RowLayout {
    id: root
    spacing: 8
    Layout.fillWidth: true

    readonly property var themes: [
        { id: "catppuccin-mocha", label: "Dark"  },
        { id: "catppuccin-latte", label: "Light" }
    ]

    Repeater {
        model: root.themes

        delegate: Rectangle {
            readonly property bool isActive: Root.Colors.currentTheme === modelData.id
            readonly property color accentDot: Root.Colors.themeAccents[modelData.id] ?? Root.Colors.blue

            Layout.fillWidth: true
            implicitHeight: 36
            radius: 10
            color: isActive ? Root.Colors.blue : Root.Colors.surface0

            Behavior on color { ColorAnimation { duration: 160 } }

            // dot warna aksen tema (kiri)
            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 8
                height: 8
                radius: 4
                color: isActive ? Root.Colors.base : parent.accentDot
                Behavior on color { ColorAnimation { duration: 160 } }
            }

            Text {
                anchors.centerIn: parent
                text: modelData.label
                font.pixelSize: 12
                font.bold: isActive
                color: isActive ? Root.Colors.base : Root.Colors.subtext
                Behavior on color { ColorAnimation { duration: 160 } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Root.Colors.currentTheme = modelData.id
            }
        }
    }
}
