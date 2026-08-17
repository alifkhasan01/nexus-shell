import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import "../../" as Root

// Widget judul window aktif — tampil di tengah bar.
// Quickshell v0.3.0+: Hyprland.activeToplevel langsung bertipe HyprlandToplevel.
// Menggunakan icon dari .desktop file system (fallback ke nerd font icon)
Item {
    id: root

    implicitWidth:  visible ? (row.implicitWidth + 24) : 0
    implicitHeight: 30

    property int maxWidth: 280

    // Window aktif diambil dari workspace yang sedang dipakai (focusedWorkspace),
    // bukan hanya global activeToplevel, sehingga selalu sinkron dengan
    // workspace aktif saat berpindah workspace/fokus. Fallback ke activeToplevel.
    readonly property var _tl: {
        const ws = Hyprland.focusedWorkspace
        if (ws) {
            const tls = (ws.toplevels && ws.toplevels.values) || []
            for (let i = 0; i < tls.length; i++) {
                const t = tls[i]
                if (t && t.activated) return t
            }
        }
        return Hyprland.activeToplevel
    }

    readonly property string _title: _tl ? (_tl.title ?? "") : ""

    // class ada di lastIpcObject
    readonly property string _class: {
        if (!_tl) return ""
        const obj = _tl.lastIpcObject
        return obj ? (obj["class"] || "") : ""
    }

    // Cari desktop entry yang cocok dengan class window
    readonly property var _desktopEntry: {
        if (!_class) return null
        
        const apps = DesktopEntries.applications.values
        const className = _class.toLowerCase()
        
        // Cari exact match dulu
        for (let i = 0; i < apps.length; i++) {
            const app = apps[i]
            if (!app) continue
            
            const appClass = (app.id || "").toLowerCase().replace(".desktop", "")
            if (appClass === className) return app
            
            // Cek juga dari exec/name
            const appName = (app.name || "").toLowerCase()
            if (appName === className) return app
        }
        
        // Kalau gak ada exact match, cari partial match
        for (let i = 0; i < apps.length; i++) {
            const app = apps[i]
            if (!app) continue
            
            const appClass = (app.id || "").toLowerCase()
            const appName = (app.name || "").toLowerCase()
            
            if (appClass.includes(className) || className.includes(appClass.replace(".desktop", "")))
                return app
            if (appName.includes(className) || className.includes(appName))
                return app
        }
        
        return null
    }

    // Icon path dari desktop entry atau fallback ke nerd font
    readonly property string _iconPath: {
        if (_desktopEntry && _desktopEntry.icon) {
            return Quickshell.iconPath(_desktopEntry.icon, true)
        }
        return ""
    }

    // Fallback nerd font icon
    function _fallbackIcon(cls) {
        const c = (cls || "").toLowerCase()
        if (c.includes("firefox"))                                   return "󰈹"
        if (c.includes("chrome") || c.includes("chromium"))          return ""
        if (c.includes("code") || c.includes("vscodium") ||
            c.includes("kiro"))                                      return "󰨞"
        if (c.includes("kitty") || c.includes("alacritty") ||
            c.includes("wezterm") || c.includes("foot"))             return ""
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
        if (c.includes("nvim") || c.includes("vim"))                 return ""
        return "󰖲"
    }

    visible: _title !== ""

    // Pill background
    Rectangle {
        anchors.fill: parent
        radius: 8
        color: Root.Colors.surface0
        Behavior on color { ColorAnimation {
            duration: Root.Appearance.animation.elementMoveFast.duration
            easing.type: Root.Appearance.animation.elementMoveFast.type
            easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
        }}
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6

        // App icon - gunakan IconImage dari system atau fallback ke text icon
        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16

            // System icon dari .desktop file
            IconImage {
                anchors.centerIn: parent
                width: 16
                height: 16
                visible: root._iconPath !== ""
                source: root._iconPath
                asynchronous: true
            }

            // Fallback: Nerd font icon
            Text {
                anchors.centerIn: parent
                visible: root._iconPath === ""
                text: root._fallbackIcon(root._class)
                font.family: "CaskaydiaCove Nerd Font"
                font.pixelSize: 13
                color: Root.Colors.blue
                Behavior on color { ColorAnimation {
                    duration: Root.Appearance.animation.elementMoveFast.duration
                    easing.type: Root.Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
                }}
            }
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
            Behavior on color { ColorAnimation {
                duration: Root.Appearance.animation.elementMoveFast.duration
                easing.type: Root.Appearance.animation.elementMoveFast.type
                easing.bezierCurve: Root.Appearance.animation.elementMoveFast.bezierCurve
            }}
        }
    }
}
