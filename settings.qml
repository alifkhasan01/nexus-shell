//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=8000
//@ pragma UseQApplication

import Quickshell
import QtQuick
import "./modules/settings"

// Standalone settings app — dijalankan sebagai proses terpisah via:
//   quickshell -p settings.qml
// Tidak menggunakan ShellRoot agar tidak terikat ke bar/panel loop.
FloatingWindow {
    id: root

    implicitWidth: 860
    implicitHeight: 600
    title: "Pengaturan"

    SettingsApp {}
}
