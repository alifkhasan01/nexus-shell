import QtQuick
import QtQuick.Layouts

// Sesuaikan command kalau tooling kamu beda (mis. iwd, blueman, mako vs dunst,
// wlsunset vs hyprsunset).
RowLayout {
    spacing: 10

    QuickToggle {
        label: "WiFi"
        icon: "󰤨"
        checkCommand: "nmcli radio wifi"
        checkMatch: "enabled"
        onCommand: "nmcli radio wifi on"
        offCommand: "nmcli radio wifi off"
    }

    QuickToggle {
        label: "Bluetooth"
        icon: "󰂯"
        checkCommand: "bluetoothctl show | grep -q 'Powered: yes' && echo yes || echo no"
        checkMatch: "yes"
        onCommand: "bluetoothctl power on"
        offCommand: "bluetoothctl power off"
    }

    QuickToggle {
        label: "DND"
        icon: "󰂛"
        checkCommand: "swaync-client -I"
        checkMatch: "true"
        onCommand: "swaync-client -dn"
        offCommand: "swaync-client -df"
    }

    QuickToggle {
        label: "Night Light"
        icon: "󰌵"
        checkCommand: "pgrep -x hyprsunset > /dev/null && echo yes || echo no"
        checkMatch: "yes"
        onCommand: "hyprsunset -t 4000 & disown"
        offCommand: "killall hyprsunset"
    }
}
