import QtQuick
import QtQuick.Layouts
import "../" as Root

// Toggle Light / Dark — klik untuk ganti tema aktif.
RowLayout {
    id: root
    spacing: 8
    Layout.fillWidth: true

    // ── Tombol Light ──────────────────────────────────────────────────────
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 36
        radius: 12
        color: Root.Colors.currentTheme === "light" ? Root.Colors.blue : Root.Colors.surface0
        border.color: Qt.rgba(Root.Colors.surface1.r, Root.Colors.surface1.g, Root.Colors.surface1.b, 0.3)
        border.width: 1
        Behavior on color { ColorAnimation {
            duration: Root.Appearance.animation.elementMoveFast.duration
            easing.type: Root.Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
        }}
        Behavior on border.color { ColorAnimation {
            duration: Root.Appearance.animation.elementMoveFast.duration
            easing.type: Root.Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
        }}

        Row {
            anchors.centerIn: parent
            spacing: 6
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰖨"
                font.pixelSize: 14
                color: Root.Colors.currentTheme === "light" ? Root.Colors.base : Root.Colors.subtext
                Behavior on color { ColorAnimation {
            duration: Root.Appearance.animation.elementMoveFast.duration
            easing.type: Root.Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
        }}
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Ayu Light"
                font.pixelSize: 12
                font.bold: Root.Colors.currentTheme === "light"
                color: Root.Colors.currentTheme === "light" ? Root.Colors.base : Root.Colors.subtext
                Behavior on color { ColorAnimation {
            duration: Root.Appearance.animation.elementMoveFast.duration
            easing.type: Root.Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
        }}
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Root.Colors.currentTheme = "light"
        }
    }

    // ── Tombol Dark ───────────────────────────────────────────────────────
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 36
        radius: 12
        color: Root.Colors.currentTheme === "dark" ? Root.Colors.blue : Root.Colors.surface0
        border.color: Qt.rgba(Root.Colors.surface1.r, Root.Colors.surface1.g, Root.Colors.surface1.b, 0.3)
        border.width: 1
        Behavior on color { ColorAnimation {
            duration: Root.Appearance.animation.elementMoveFast.duration
            easing.type: Root.Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
        }}
        Behavior on border.color { ColorAnimation {
            duration: Root.Appearance.animation.elementMoveFast.duration
            easing.type: Root.Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
        }}

        Row {
            anchors.centerIn: parent
            spacing: 6
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰖔"
                font.pixelSize: 14
                color: Root.Colors.currentTheme === "dark" ? Root.Colors.base : Root.Colors.subtext
                Behavior on color { ColorAnimation {
            duration: Root.Appearance.animation.elementMoveFast.duration
            easing.type: Root.Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
        }}
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Ayu Dark"
                font.pixelSize: 12
                font.bold: Root.Colors.currentTheme === "dark"
                color: Root.Colors.currentTheme === "dark" ? Root.Colors.base : Root.Colors.subtext
                Behavior on color { ColorAnimation {
            duration: Root.Appearance.animation.elementMoveFast.duration
            easing.type: Root.Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
        }}
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Root.Colors.currentTheme = "dark"
        }
    }
}
