#!/usr/bin/env bash
# Fetch lyrics dari LRCLIB untuk track yang sedang diputar.
# Usage: fetch_lyrics.sh "Track Title" "Artist Name" "Album Name"
# Output: lirik (prefer synced/LRC), kosong jika tidak ditemukan / instrumental.

title="${1:-}"
artist="${2:-}"
album="${3:-}"

args=(--data-urlencode "track_name=$title" --data-urlencode "artist_name=$artist")
if [ -n "$album" ]; then args+=(--data-urlencode "album_name=$album"); fi

extract() {
    jq -r '.syncedLyrics // .plainLyrics // empty' 2>/dev/null <<<"$1"
}

# 1) Kecocokan persis via /api/get
resp=$(curl -s --max-time 8 -G "https://lrclib.net/api/get" "${args[@]}")
lyrics=$(extract "$resp")
if [ -n "$lyrics" ]; then
    printf '%s' "$lyrics"
    exit 0
fi

# 2) Fallback: hasil pencarian teratas
list=$(curl -s --max-time 8 -G "https://lrclib.net/api/search" --data-urlencode "q=$title" "${args[@]}")
lyrics=$(jq -r '.[0].syncedLyrics // .[0].plainLyrics // empty' 2>/dev/null <<<"$list")
printf '%s' "$lyrics"