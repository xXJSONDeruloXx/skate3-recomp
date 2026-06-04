#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/app"
APP_EXE="$APP_DIR/skate3"
GAME_ROOT="$SCRIPT_DIR/work/runtime-assets"
USER_ROOT="$SCRIPT_DIR/work/user-data"
CACHE_ROOT="$SCRIPT_DIR/work/cache"

show_error() {
  local message="$1"
  echo -e "$message"
  if command -v zenity >/dev/null 2>&1; then
    zenity --error --width=520 --text="$message" || true
  fi
}

if [[ "${1:-}" == "--dry-run" ]]; then
  echo "Skate 3 Recomp launcher"
  echo "App: $APP_EXE"
  echo "Game data: $GAME_ROOT"
  echo "User data: $USER_ROOT"
  echo "Cache: $CACHE_ROOT"
  echo "Display: 1920x1080 120Hz fullscreen"
  echo "Physics timing: target_16_7ms"
  echo "PC settings: shown before game start"
  echo "Controls: MnK enabled, Start=P"
  exit 0
fi

if [[ ! -f "$APP_EXE" ]]; then
  show_error "Missing Skate 3 Recomp executable:\n$APP_EXE"
  exit 1
fi

if [[ ! -f "$GAME_ROOT/default.xex" ]]; then
  show_error "Missing Skate 3 runtime files.\n\nRun 'Setup Skate 3 Recomp.sh' first."
  exit 1
fi

mkdir -p "$USER_ROOT" "$CACHE_ROOT"
chmod +x "$APP_EXE" || true

export LD_LIBRARY_PATH="$APP_DIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

cd "$APP_DIR"
exec "$APP_EXE" \
  --game-data-root "$GAME_ROOT" \
  --user-data-root "$USER_ROOT" \
  --cache-root "$CACHE_ROOT" \
  --resolution 1080p \
  --video-mode-width 1920 \
  --video-mode-height 1080 \
  --video-mode-refresh-rate 120 \
  --window-width 1920 \
  --window-height 1080 \
  --fullscreen \
  --skate3-physics-timing 1 \
  --mnk-mode \
  --keybind-start P \
  "$@"
