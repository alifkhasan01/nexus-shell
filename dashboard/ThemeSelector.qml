import QtQuick
import QtQuick.Layouts
import "../" as Root

// Grid 2×2 tombol tema Catppuccin — klik untuk ganti tema aktif.
// Tombol aktif ditandai dengan background aksen + teks terang.
// Selain warna shell, ganti tema juga memicu matugen untuk sinkron ke GTK,
// Qt, foot, hyprland, dan gsettings (lihat Colors.qml).
GridLayout {
    id: root
    columns: 2
    rowSpacing: 8
    columnSpacing: 8
    Layout.fillWidth: true

    readonly property var themes: [
        { id: "catppuccin-latte",     label: "Latte",     dot: "#1e66f5" },
        { id: "catppuccin-frappe",    label: "Frappé",    dot: "#8caaee" },
        { id: "catppuccin-macchiato", label: "Macchiato", dot: "#8aadf4" },
        { id: "catppuccin-mocha",     label: "Mocha",     dot: "#89b4fa" }
    ]

    Repeater {
        model: root.themes

        delegate: Rectangle {
            readonly property bool isActive: Root.Colors.currentTheme === modelData.id

            Layout.fillWidth: true
            implicitHeight: 36
            radius: 10
            color: isActive ? Root.Colors.blue : Root.Colors.surface0

            Behavior on color { ColorAnimation { duration: 160 } }

            // dot warna aksen flavor (kiri)
            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 8
                height: 8
                radius: 4
                color: isActive ? Root.Colors.base : modelData.dot
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
