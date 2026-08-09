import QtQuick
import Quickshell.Hyprland
import "../../" as Root

// Widget judul window aktif — tampil di antara Clock dan workspace
// Update otomatis lewat Hyprland.focusedClient
Item {
    id: root

    implicitWidth: titleText.implicitWidth + 20
    implicitHeight: 30

    // Judul dipotong kalau terlalu panjang
    property int maxWidth: 280

    readonly property string _title: {
        const c = Hyprland.focusedClient
        if (!c) return ""
        // Lebih prefer initialTitle kalau ada, fallback ke title
        return c.title ?? ""
    }

    readonly property string _class: {
        const c = Hyprland.focusedClient
        if (!c) return ""
        return c.className ?? ""
    }

    // Ikon per app class — fallback ke generic window icon
    function _iconFor(cls) {
        const c = (cls || "").toLowerCase()
        if (c.includes("firefox"))              return "󰈹"
        if (c.includes("chrome") || c.includes("chromium")) return ""
        if (c.includes("code") || c.includes("vscodium"))   return "󰨞"
        if (c.includes("kitty") || c.includes("alacritty") || c.includes("wezterm") || c.includes("foot")) return ""
        if (c.includes("thunar") || c.includes("nautilus") || c.includes("dolphin")) return "󰉋"
        if (c.includes("spotify"))              return "󰓇"
        if (c.includes("discord"))              return "󰙯"
        if (c.includes("telegram"))             return "󰔁"
        if (c.includes("mpv"))                  return "󰐈"
        if (c.includes("vlc"))                  return "󰐽"
        if (c.includes("gimp"))                 return "󰽉"
        if (c.includes("obs"))                  return "󱜠"
        if (c.includes("steam"))                return "󰓓"
        if (c.includes("libreoffice"))          return "󰏫"
        if (c.includes("nvim") || c.includes("vim")) return ""
        return "󰖲"
    }

    visible: _title !== ""

    // Pill background
    Rectangle {
        anchors.fill: parent
        radius: 8
        color: Root.Colors.surface0
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    Row {
        anchors.centerIn: parent
        spacing: 6

        // App icon
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root._iconFor(root._class)
            font.family: "CaskaydiaCove Nerd Font"
            font.pixelSize: 13
            color: Root.Colors.blue
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        // Title text
        Text {
            id: titleText
            anchors.verticalCenter: parent.verticalCenter
            text: root._title
            color: Root.Colors.text
            font.pixelSize: 12
            elide: Text.ElideRight
            width: Math.min(implicitWidth, root.maxWidth)
            Behavior on color { ColorAnimation { duration: 200 } }
        }
    }
}
