#!/usr/bin/env bash
# install-deps.sh — Install dependensi yang dibutuhkan config quickshell ini.
#
# Distro-aware: mendukung Arch (pacman + AUR helper), Debian/Ubuntu (apt),
# Fedora (dnf), openSUSE (zypper), Void (xbps), dan Alpine (apk).
#
# Cara pakai:
#   ./install-deps.sh            # auto-elevate via pkexec, atau
#   sudo ./install-deps.sh       # langsung sebagai root
#   ./install-deps.sh --list     # cuma tampilkan paket yang akan dipasang
#
# Semua paket yang sudah terpasang akan di-skip (idempotent).

set -uo pipefail

# ── Daftar paket per distro ─────────────────────────────────────────────
# format: "distro|pkg1 pkg2 ...|aur_pkg1 aur_pkg2 ..."  (aur hanya Arch)

declare -A ARCH_PKGS=(
  [grimblast]="grimblast-git"
  [bluetoothctl]="bluez-utils"
  [nmcli]="networkmanager"
  [notify-send]="libnotify"
  [brightnessctl]="brightnessctl"
  [cliphist]="cliphist"
  [wl-copy]="wl-clipboard"
  [pactl]="pipewire-utils"
  [wpctl]="wireplumber"
  [playerctl]="playerctl"
  [awww]="awww"
  [hyprsunset]="hyprsunset"
  [zenity]="zenity"
  [powerprofilesctl]="power-profiles-daemon"
  [jq]="jq"
  [ffmpegthumbnailer]="ffmpegthumbnailer"
  [magick]="imagemagick"
  [curl]="curl"
)

declare -A DEB_PKGS=(
  [grimblast]="grim slurp"          # debian nggak punya grimblast, pakai grim+slurp
  [bluetoothctl]="bluez"
  [nmcli]="network-manager"
  [notify-send]="libnotify-bin"
  [brightnessctl]="brightnessctl"
  [cliphist]="cliphist"
  [wl-copy]="wl-clipboard"
  [pactl]="pipewire-utils"
  [wpctl]="libspa-0.2-bluetooth wireplumber"
  [playerctl]="playerctl"
  [awww]="swww"
  [hyprsunset]="hyprsunset"
  [zenity]="zenity"
  [powerprofilesctl]="power-profiles-daemon"
  [jq]="jq"
  [ffmpegthumbnailer]="ffmpegthumbnailer"
  [magick]="imagemagick"
  [curl]="curl"
)

declare -A RPM_PKGS=(
  [grimblast]="grim slurp"
  [bluetoothctl]="bluez"
  [nmcli]="NetworkManager"
  [notify-send]="libnotify"
  [brightnessctl]="brightnessctl"
  [cliphist]="cliphist"
  [wl-copy]="wl-clipboard"
  [pactl]="pipewire-utils"
  [wpctl]="wireplumber"
  [playerctl]="playerctl"
  [awww]="swww"
  [hyprsunset]="hyprsunset"
  [zenity]="zenity"
  [powerprofilesctl]="power-profiles-daemon"
  [jq]="jq"
  [ffmpegthumbnailer]="ffmpegthumbnailer"
  [magick]="imagemagick"
  [curl]="curl"
)

declare -A ZYPP_PKGS=(
  [grimblast]="grim slurp"
  [bluetoothctl]="bluez"
  [nmcli]="NetworkManager"
  [notify-send]="libnotify"
  [brightnessctl]="brightnessctl"
  [cliphist]="cliphist"
  [wl-copy]="wl-clipboard"
  [pactl]="pipewire-utils"
  [wpctl]="wireplumber"
  [playerctl]="playerctl"
  [awww]="swww"
  [zenity]="zenity"
  [powerprofilesctl]="power-profiles-daemon"
  [jq]="jq"
  [ffmpegthumbnailer]="ffmpegthumbnailer"
  [magick]="imagemagick"
  [curl]="curl"
)

declare -A XBPS_PKGS=(
  [grimblast]="grim slurp"
  [bluetoothctl]="bluez"
  [nmcli]="NetworkManager"
  [notify-send]="libnotify"
  [brightnessctl]="brightnessctl"
  [cliphist]="cliphist"
  [wl-copy]="wl-clipboard"
  [pactl]="pipewire-utils"
  [wpctl]="wireplumber"
  [playerctl]="playerctl"
  [awww]="swww"
  [zenity]="zenity"
  [powerprofilesctl]="power-profiles-daemon"
  [jq]="jq"
  [ffmpegthumbnailer]="ffmpegthumbnailer"
  [magick]="imagemagick"
  [curl]="curl"
)

declare -A ALPINE_PKGS=(
  [grimblast]="grim slurp"
  [bluetoothctl]="bluez"
  [nmcli]="networkmanager"
  [notify-send]="libnotify"
  [brightnessctl]="brightnessctl"
  [cliphist]="cliphist"
  [wl-copy]="wl-clipboard"
  [pactl]="pipewire-utils"
  [playerctl]="playerctl"
  [awww]="swww"
  [zenity]="zenity"
  [jq]="jq"
  [ffmpegthumbnailer]="ffmpegthumbnailer"
  [magick]="imagemagick"
  [curl]="curl"
)

# ── Urutan pemasangan (mendahulukan yang penting) ───────────────────────
ORDER=(grimblast bluetoothctl nmcli notify-send brightnessctl cliphist
       wl-copy pactl wpctl playerctl awww hyprsunset
       zenity powerprofilesctl jq ffmpegthumbnailer magick curl)

# ── Deteksi distro / package manager ────────────────────────────────────
detect_pm() {
  if   command -v pacman  >/dev/null 2>&1; then echo "pacman"
  elif command -v dnf     >/dev/null 2>&1; then echo "dnf"
  elif command -v apt-get >/dev/null 2>&1; then echo "apt"
  elif command -v zypper  >/dev/null 2>&1; then echo "zypper"
  elif command -v xbps-install >/dev/null 2>&1; then echo "xbps"
  elif command -v apk     >/dev/null 2>&1; then echo "apk"
  else echo "unknown"
  fi
}

# AUR helper untuk Arch
detect_aur() {
  for h in paru yay; do
    if command -v "$h" >/dev/null 2>&1; then echo "$h"; return; fi
  done
  echo ""
}

PM="$(detect_pm)"

case "$PM" in
  pacman) PKGS="ARCH_PKGS"   ;;
  dnf)    PKGS="RPM_PKGS"    ;;
  apt)    PKGS="DEB_PKGS"    ;;
  zypper) PKGS="ZYPP_PKGS"   ;;
  xbps)   PKGS="XBPS_PKGS"   ;;
  apk)    PKGS="ALPINE_PKGS" ;;
  *)
    echo "ERROR: package manager tidak dikenali. Install manual paket-paket ini:"
    echo "  ${ORDER[*]}"
    exit 1
    ;;
esac

# Resolve nama array dinamis
declare -n MAP="$PKGS"

# ── Kompilasi daftar paket yang belum terpasang ─────────────────────────
need_install=()
for bin in "${ORDER[@]}"; do
  if command -v "$bin" >/dev/null 2>&1; then
    echo "[OK]   $bin sudah terpasang"
    continue
  fi
  pkgs="${MAP[$bin]:-}"
  if [ -z "$pkgs" ]; then
    echo "[??]   $bin — tidak ada paket yang cocok untuk distro ini (manual)"
    continue
  fi
  echo "[...]  $bin → $pkgs"
  need_install+=("$pkgs")
done

# Unique, pertahankan urutan
uniq=()
for p in "${need_install[@]}"; do
  skip=0
  for q in "${uniq[@]}"; do [ "$q" = "$p" ] && skip=1 && break; done
  [ "$skip" -eq 0 ] && uniq+=("$p")
done
need_install=("${uniq[@]}")

if [ "${#need_install[@]}" -eq 0 ]; then
  echo
  echo "✔ Semua dependensi sudah terpasang!"
  exit 0
fi

if [ "${1:-}" = "--list" ]; then
  echo
  echo "Paket yang akan dipasang:"
  printf '  %s\n' "${need_install[@]}"
  exit 0
fi

# ── Eksekusi install ─────────────────────────────────────────────────────
echo
echo ">> Akan menginstall ${#need_install[@]} paket..."

if [ "$(id -u)" -ne 0 ]; then
  echo ">> Butuh akses root — menggunakan pkexec..."
  if ! command -v pkexec >/dev/null 2>&1; then
    echo "ERROR: pkexec tidak tersedia. Jalankan ulang sebagai root:"
    echo "  sudo $0"
    exit 1
  fi
  exec pkexec env HOME="$HOME" XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" bash "$0" "$@"
fi

case "$PM" in
  pacman)
    AUR="$(detect_aur)"
    if [ -z "$AUR" ]; then
      # Tanpa AUR helper: buang paket AUR supaya pacman tidak error
      echo ">> Tidak ada AUR helper (paru/yay) — paket AUR dilewati:"
      echo "   grimblast-git, matugen, walker (install manual)"
      need_install=()
      for p in "${uniq[@]}"; do
        case "$p" in
          grimblast-git|matugen|walker) ;;
          *) need_install+=("$p") ;;
        esac
      done
    else
      echo ">> Menggunakan $AUR (untuk paket AUR seperti grimblast-git)"
    fi
    if [ "${#need_install[@]}" -gt 0 ]; then
      "${AUR:-pacman}" -S --needed --noconfirm "${need_install[@]}"
    fi
    ;;
  dnf)
    dnf install -y "${need_install[@]}"
    ;;
  apt)
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y "${need_install[@]}"
    ;;
  zypper)
    zypper --non-interactive install "${need_install[@]}"
    ;;
  xbps)
    xbps-install -Sy "${need_install[@]}"
    ;;
  apk)
    apk add "${need_install[@]}"
    ;;
esac

echo
echo "✔ Selesai. Restart quickshell agar fitur aktif."
exit 0
