import QtQuick
import Quickshell.Hyprland
import "../../" as Root

// Widget judul window aktif — tampil di tengah bar.
// Quickshell v0.3.0+: Hyprland.activeToplevel langsung bertipe HyprlandToplevel.
Item {
    id: root

    implicitWidth:  visible ? (row.implicitWidth + 24) : 0
    implicitHeight: 30

    property int maxWidth: 280

    // Langsung akses HyprlandToplevel — tidak perlu resolve via attached object
    readonly property var _tl: Hyprland.activeToplevel

    readonly property string _title: _tl ? (_tl.title ?? "") : ""

    // class ada di lastIpcObject (tidak ada dedicated .className di v0.3.0)
    readonly property string _class: {
        if (!_tl) return ""
        const obj = _tl.lastIpcObject
        return (obj && obj["class"]) ? obj["class"] : ""
    }

    function _iconFor(cls) {
        const c = (cls || "").toLowerCase()
        if (c.includes("firefox"))                                   return "󰈹"
        if (c.includes("chrome") || c.includes("chromium"))         return ""
        if (c.includes("code") || c.includes("vscodium") ||
            c.includes("kiro"))                                      return "󰨞"
        if (c.includes("kitty") || c.includes("alacritty") ||
            c.includes("wezterm") || c.includes("foot"))            return ""
        if (c.includes("thunar") || c.includes("nautilus") ||
            c.includes("dolphin"))                                   return "󰉋"
        if (c.includes("spotify"))                                   return "󰓇"
        if (c.includes("discord"))                                   return "󰙯"
        if (c.includes("telegram"))                                  return "󰔁"
        if (c.includes("mpv"))                                       return "󰐈"
        if (c.includes("vlc"))                                       return "󰐽"
        if (c.includes("gimp"))                                      return "󰽉"
        if (c.includes("obs"))                                       return "󱜠"
        if (c.includes("steam"))                                     return "󰓓"
        if (c.includes("libreoffice"))                               return "󰏫"
        if (c.includes("nvim") || c.includes("vim"))                return ""
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
        id: row
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
