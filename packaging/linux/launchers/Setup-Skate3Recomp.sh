#!/usr/bin/env bash
set -euo pipefail

KNOWN_DECRYPTED_HASH="fc4d26404382cb2c2fc2c0ee3ade9e7b5bf3635cfb6ecd43ca432ebaf3efd080"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
DROP_ROOT="$PROJECT_ROOT/Skate 3 Files"
EXISTING_SOURCE_ROOT="$PROJECT_ROOT/skate3"
ASSETS_ROOT="$PROJECT_ROOT/work/assets"
RUNTIME_ROOT="$PROJECT_ROOT/work/runtime-assets"
USER_ROOT="$PROJECT_ROOT/work/user-data"
CACHE_ROOT="$PROJECT_ROOT/work/cache"
LAUNCHER_PATH="$PROJECT_ROOT/Launch Skate 3 Recomp.sh"

status() {
  echo "$1"
}

show_error() {
  local message="$1"
  echo -e "$message" >&2
  if command -v zenity >/dev/null 2>&1; then
    zenity --error --width=560 --text="$message" || true
  fi
}

show_info() {
  local message="$1"
  echo -e "$message"
  if command -v zenity >/dev/null 2>&1; then
    zenity --info --width=560 --text="$message" || true
  fi
}

compute_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print tolower($1)}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print tolower($1)}'
  else
    return 1
  fi
}

find_source_root() {
  local candidate
  for candidate in "$DROP_ROOT" "$EXISTING_SOURCE_ROOT"; do
    if [[ -d "$candidate/data" && -f "$candidate/default.xex" ]]; then
      if [[ -f "$candidate/default.xex_uncrypted.xex" ]]; then
        printf '%s\n%s\n' "$candidate" "$candidate/default.xex_uncrypted.xex"
        return 0
      fi
      if hash=$(compute_sha256 "$candidate/default.xex" 2>/dev/null); then
        if [[ "$hash" == "$KNOWN_DECRYPTED_HASH" ]]; then
          printf '%s\n%s\n' "$candidate" "$candidate/default.xex"
          return 0
        fi
      fi
    fi
  done
  return 1
}

copy_tree() {
  local src="$1"
  local dst="$2"
  mkdir -p "$dst"
  rm -rf "$dst"
  mkdir -p "$dst"
  cp -a "$src/." "$dst/"
}

prepare_runtime_data_route() {
  local assets_data="$ASSETS_ROOT/data"
  local runtime_data="$RUNTIME_ROOT/data"
  rm -rf "$runtime_data"
  ln -s "$assets_data" "$runtime_data" 2>/dev/null || cp -a "$assets_data" "$runtime_data"
}

run_setup() {
  mkdir -p "$DROP_ROOT"

  local found source_root runtime_xex
  if ! found="$(find_source_root)"; then
    show_error "Put the Skate 3 files in:\n$DROP_ROOT\n\nRequired:\n- default.xex\n- default.xex_uncrypted.xex\n- data\n- nxeart"
    exit 1
  fi

  source_root="$(printf '%s' "$found" | sed -n '1p')"
  runtime_xex="$(printf '%s' "$found" | sed -n '2p')"

  status "Using game files from $source_root"
  status "Copying game files into the working folder..."
  copy_tree "$source_root" "$ASSETS_ROOT"

  status "Preparing runtime files..."
  mkdir -p "$RUNTIME_ROOT" "$USER_ROOT" "$CACHE_ROOT"
  cp -f "$runtime_xex" "$RUNTIME_ROOT/default.xex"
  cp -f "$runtime_xex" "$RUNTIME_ROOT/default.xex_uncrypted.xex"
  if [[ -f "$source_root/nxeart" ]]; then
    cp -f "$source_root/nxeart" "$RUNTIME_ROOT/nxeart"
  fi
  prepare_runtime_data_route

  status "Setup complete."
}

run_setup_with_progress() {
  if command -v zenity >/dev/null 2>&1; then
    (
      run_setup
      echo 100
    ) | zenity --progress --title="Skate 3 Recomp Setup" \
        --text="Preparing Skate 3 Recomp..." --pulsate --auto-close --no-cancel || {
      show_error "Setup failed."
      exit 1
    }
  else
    run_setup
  fi
}

main() {
  if [[ "${1:-}" == "--self-test" ]]; then
    status "Self-test not implemented for Linux setup script."
    exit 0
  fi

  if command -v zenity >/dev/null 2>&1; then
    while true; do
      choice="$(zenity --question \
        --width=560 \
        --title="Skate 3 Recomp Setup" \
        --ok-label="Set Up Game" \
        --cancel-label="Cancel" \
        --extra-button="Open Folder" \
        --text="Put your Skate 3 files in:\n$DROP_ROOT\n\nPress 'Set Up Game' when ready." 2>&1 || true)"
      if [[ "$choice" == "Open Folder" ]]; then
        xdg-open "$DROP_ROOT" >/dev/null 2>&1 || true
        continue
      fi
      if [[ -n "$choice" ]]; then
        exit 0
      fi
      break
    done
  else
    status "Put your Skate 3 files in:"
    status "$DROP_ROOT"
    read -r -p "Press Enter to set up the game, or Ctrl+C to cancel..." _
  fi

  run_setup_with_progress

  if command -v zenity >/dev/null 2>&1; then
    if zenity --question --width=420 --title="Skate 3 Recomp Setup" \
        --ok-label="Launch Game" --cancel-label="Close" \
        --text="Setup complete. Start the game now?"; then
      chmod +x "$LAUNCHER_PATH" || true
      "$LAUNCHER_PATH" &
    fi
  else
    read -r -p "Setup complete. Start the game now? [Y/n] " answer
    answer="${answer:-Y}"
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      chmod +x "$LAUNCHER_PATH" || true
      "$LAUNCHER_PATH"
    fi
  fi
}

main "$@"
