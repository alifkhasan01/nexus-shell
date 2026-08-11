#!/usr/bin/env bash
# Wrapper untuk menjalankan Quickshell dengan setting aman
# Mencegah crash dari GTK theme parsing error

export QT_QUICK_CONTROLS_STYLE=Basic
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1

exec quickshell "$@"
