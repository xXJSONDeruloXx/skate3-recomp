#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/app"
GAME_DIR="${GAME_DATA_ROOT:-$SCRIPT_DIR/Skate 3 Files}"
USER_DIR="${USER_DATA_ROOT:-$SCRIPT_DIR/user-data}"
CACHE_DIR="${CACHE_ROOT:-$SCRIPT_DIR/cache}"

show_error() {
  local message="$1"
  echo -e "$message"
  if command -v zenity >/dev/null 2>&1; then
    zenity --error --width=520 --text="$message" || true
  fi
}

require_path() {
  local path="$1"
  local label="$2"
  if [ ! -e "$path" ]; then
    show_error "Missing $label:\n$path\n\nPut your Skate 3 dump in:\n$GAME_DIR"
    exit 1
  fi
}

require_path "$APP_DIR/skate3" "launcher binary"
require_path "$APP_DIR/librexruntimerd.so" "runtime library"
require_path "$GAME_DIR/default.xex" "default.xex"
require_path "$GAME_DIR/default.xex_uncrypted.xex" "default.xex_uncrypted.xex"
require_path "$GAME_DIR/data" "data folder"
require_path "$GAME_DIR/nxeart" "nxeart"

mkdir -p "$USER_DIR" "$CACHE_DIR"
chmod +x "$APP_DIR/skate3" || true

export LD_LIBRARY_PATH="$APP_DIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

cd "$APP_DIR"
exec ./skate3 \
  --game-data-root "$GAME_DIR" \
  --user-data-root "$USER_DIR" \
  --cache-root "$CACHE_DIR" \
  "$@"
