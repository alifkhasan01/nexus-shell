pragma Singleton
import QtQuick

QtObject {
    id: root

    // ── Ukuran & layout ───────────────────────────────────────────────────
    readonly property int   baseSize:     36    // ukuran ikon idle
    readonly property int   dockPadH:     10    // padding kiri-kanan pill
    readonly property int   dockPadV:     6     // padding atas-bawah dalam pill
    readonly property int   itemSpacing:  4     // jarak antar ikon
    readonly property int   bottomMargin: 8     // jarak dari tepi bawah layar

    // ── Launcher button ───────────────────────────────────────────────────
    readonly property bool   showLauncher: false   // nonaktif, pakai walker di MenuButton

    // ── Pinned apps ───────────────────────────────────────────────────────
    readonly property var pinnedApps: [
        { name: "Firefox",   icon: "firefox",                cmd: "firefox",   appId: "firefox"                },
        { name: "Thunar",    icon: "thunar",                 cmd: "thunar",    appId: "thunar"                 },
        { name: "Terminal",  icon: "org.wezfurlong.wezterm", cmd: "wezterm",   appId: "org.wezfurlong.wezterm" },
        { name: "VS Code",   icon: "code",                   cmd: "code",      appId: "code"                   },
        { name: "Obsidian",  icon: "obsidian",               cmd: "obsidian",  appId: "md.obsidian.Obsidian"   },
        { name: "Discord",   icon: "discord",                cmd: "discord",   appId: "discord"                },
        { name: "Spotify",   icon: "spotify",                cmd: "spotify",   appId: "spotify"                }
    ]
}
