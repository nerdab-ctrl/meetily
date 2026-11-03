#!/usr/bin/env bash
# grab-photos.sh: copy photos off a dying Android phone, newest first, and resume after every crash.
#
# Usage:   ./grab-photos.sh [destination-folder]
# Default: ~/Desktop/phone-photos
#
# Start this BEFORE powering the phone on. It waits, copies whenever the phone is
# reachable, and picks up where it stopped after each reboot or bootloop.
# Needs: adb (brew install android-platform-tools), and USB debugging enabled on the phone.
# Safe: it only READS from the phone. It never deletes, wipes or writes anything on it.
#
# Compatible with the stock macOS bash 3.2.

set -u

DEST="${1:-$HOME/Desktop/phone-photos}"
POLL_SECONDS="${POLL_SECONDS:-2}"

# Folders in priority order. Camera first, then WhatsApp, then everything else.
SOURCES=(
  "/sdcard/DCIM/Camera"
  "/sdcard/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Images"
  "/sdcard/WhatsApp/Media/WhatsApp Images"
  "/sdcard/DCIM"
  "/sdcard/Pictures"
  "/sdcard/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Video"
  "/sdcard/WhatsApp/Media/WhatsApp Video"
  "/sdcard/Movies"
)

# Pass 1 = photos only (small, fast, most value per second of uptime).
# Pass 2 = videos (large; a crash mid-file wastes the window).
VIDEO_RE='\.(mp4|mov|3gp|mkv|avi|webm)$'

LOG="$DEST/.grab-log.txt"
LIST="$DEST/.remote-list.txt"

say() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*" | tee -a "$LOG"; }

if ! command -v adb >/dev/null 2>&1; then
  echo "adb not found. Install it first:"
  echo "  brew install android-platform-tools"
  exit 1
fi

mkdir -p "$DEST" || { echo "Cannot create $DEST"; exit 1; }
: >>"$LOG"

trap 'echo; say "Stopped by user. Run the script again to resume. Nothing is lost."; exit 130' INT

local_size() { # portable on macOS and Linux
  if [ -f "$1" ]; then wc -c <"$1" | tr -d ' '; else echo -1; fi
}

# Block until the phone is reachable over adb. Explain every other state in plain words.
wait_for_phone() {
  local last="" state msg
  while true; do
    state="$(adb get-state 2>&1 | tr -d '\r')"
    case "$state" in
      device) say "Phone connected. Copying..."; return 0 ;;
      *unauthorized*) msg="Phone found but not authorised: unlock it and tap ALLOW on the 'Allow USB debugging?' prompt (tick 'Always allow')." ;;
      recovery) msg="Phone is in RECOVERY mode: photos cannot be read there. Reboot normally." ;;
      sideload|bootloader) msg="Phone is in $state mode: photos cannot be read there. Reboot normally." ;;
      *offline*) msg="Phone is booting (offline). Waiting..." ;;
      *) msg="Waiting for phone... (plug in, boot normally, USB debugging must be ON)" ;;
    esac
    if [ "$msg" != "$last" ]; then say "$msg"; last="$msg"; fi
    sleep "$POLL_SECONDS"
  done
}

# Write "mtime|size|path" for every file in the source folders, in priority order, newest first per folder.
build_list() {
  : >"$LIST.tmp"
  local src
  for src in "${SOURCES[@]}"; do
    adb shell "find '$src' -type f -exec stat -c '%Y|%s|%n' {} + 2>/dev/null" 2>/dev/null \
      | tr -d '\r' | grep '|' | sort -t'|' -k1,1nr >>"$LIST.tmp"
    [ "$(adb get-state 2>/dev/null | tr -d '\r')" = "device" ] || return 1
  done
  # Drop duplicates (e.g. /sdcard/DCIM/Camera also appears under /sdcard/DCIM), keeping the first (priority) occurrence.
  awk -F'|' '!seen[$3]++' "$LIST.tmp" >"$LIST" && rm -f "$LIST.tmp"
}

# Copy every pending file matching the pass filter. Return 1 if the phone dropped mid-way.
copy_pass() {
  local pass="$1" mtime size path rel target tmp have
  while IFS='|' read -r mtime size path; do
    [ -n "$path" ] || continue
    if [ "$pass" = "photos" ]; then
      echo "$path" | grep -qiE "$VIDEO_RE" && continue
    else
      echo "$path" | grep -qiE "$VIDEO_RE" || continue
    fi
    rel="${path#/sdcard/}"
    target="$DEST/$rel"
    have="$(local_size "$target")"
    [ "$have" = "$size" ] && continue          # already copied in full
    mkdir -p "$(dirname "$target")"
    tmp="$target.partial"
    if adb pull -a "$path" "$tmp" </dev/null >/dev/null 2>&1 &&[ "$(local_size "$tmp")" = "$size" ]; then
      mv -f "$tmp" "$target"
      COPIED=$((COPIED + 1))
      [ $((COPIED % 25)) -eq 0 ] && say "Copied $COPIED files this session (latest: $rel)"
    else
      rm -f "$tmp"
      say "Connection lost while copying: $rel"
      return 1
    fi
  done <"$LIST"
  return 0
}

count_pending() {
  local n=0 mtime size path
  while IFS='|' read -r mtime size path; do
    [ -n "$path" ] || continue
    [ "$(local_size "$DEST/${path#/sdcard/}")" = "$size" ] || n=$((n + 1))
  done <"$LIST"
  echo "$n"
}

COPIED=0
say "Saving to: $DEST"
while true; do
  wait_for_phone
  if ! build_list; then say "Phone dropped while listing files. Waiting for it to come back..."; continue; fi
  total="$(grep -c '|' "$LIST" || true)"
  say "Found $total files on phone; $(count_pending) still to copy. Photos first, then videos."
  copy_pass photos || continue
  say "All photos copied. Now copying videos..."
  copy_pass videos || continue
  pending="$(count_pending)"
  if [ "$pending" = "0" ]; then
    say "DONE. All $total files are safe in $DEST ($COPIED copied this session)."
    exit 0
  fi
  say "$pending files still pending; retrying..."
done
