#!/usr/bin/env bash
# gen-thumbs.sh — Generate disk thumbnail cache untuk wallpaper picker.
#
# Penggunaan:
#   gen-thumbs.sh <file1> [file2 ...]
#   echo -e "file1\nfile2" | gen-thumbs.sh
#
# Output per baris: "<thumb_path>|<orig_path>"
# Thumbnail disimpan di ~/.cache/quickshell/thumbs/<md5(path)>.jpg
# Skip jika thumbnail sudah ada DAN lebih baru dari sumber.
#
# Dependensi (salah satu): ffmpegthumbnailer, convert (ImageMagick), atau magick (IM7)

THUMB_DIR="${HOME}/.cache/quickshell/thumbs"
THUMB_SIZE="${THUMB_SIZE:-320}"  # lebar px; tinggi proporsional

mkdir -p "$THUMB_DIR"

# ── Pilih engine ──────────────────────────────────────────────────────────────
if   command -v ffmpegthumbnailer >/dev/null 2>&1; then  ENGINE="ffmpegthumbnailer"
elif command -v convert            >/dev/null 2>&1; then  ENGINE="convert"
elif command -v magick             >/dev/null 2>&1; then  ENGINE="magick"
else
    echo "ERROR: Tidak ada tool thumbnail (ffmpegthumbnailer / convert / magick)" >&2
    exit 1
fi

# ── Fungsi generate satu thumbnail ───────────────────────────────────────────
make_thumb() {
    local src="$1"
    [[ -f "$src" ]] || return 1

    # Hash dari path → nama unik tanpa konflik meski nama file sama
    local hash
    hash=$(printf '%s' "$src" | md5sum | cut -c1-32)
    local thumb="${THUMB_DIR}/${hash}.jpg"

    # Skip jika thumb ada DAN lebih baru dari sumber
    if [[ -f "$thumb" ]] && [[ "$thumb" -nt "$src" ]]; then
        printf '%s|%s\n' "$thumb" "$src"
        return 0
    fi

    # Generate
    local ok=0
    case "$ENGINE" in
        ffmpegthumbnailer)
            ffmpegthumbnailer -i "$src" -o "$thumb" \
                -s "$THUMB_SIZE" -q 6 -f >/dev/null 2>&1 && ok=1
            ;;
        convert)
            convert "$src[0]" \
                -thumbnail "${THUMB_SIZE}x" \
                -quality 82 \
                "$thumb" >/dev/null 2>&1 && ok=1
            ;;
        magick)
            magick "$src[0]" \
                -thumbnail "${THUMB_SIZE}x" \
                -quality 82 \
                "$thumb" >/dev/null 2>&1 && ok=1
            ;;
    esac

    if (( ok )); then
        printf '%s|%s\n' "$thumb" "$src"
    else
        # Gagal generate — output kosong untuk path ini (QML pakai asli)
        printf '|%s\n' "$src"
    fi
}

export -f make_thumb
export THUMB_DIR ENGINE THUMB_SIZE

# ── Baca input: args atau stdin ───────────────────────────────────────────────
if [[ $# -gt 0 ]]; then
    for f in "$@"; do make_thumb "$f"; done
else
    while IFS= read -r line; do
        [[ -n "$line" ]] && make_thumb "$line"
    done
fi
