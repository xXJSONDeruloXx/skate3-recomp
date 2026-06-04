#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SETUP_SCRIPT="$SCRIPT_DIR/launchers/Setup-Skate3Recomp.sh"

if [[ "${1:-}" == "--dry-run" ]]; then
  echo "Skate 3 Recomp setup"
  echo "Setup script: $SETUP_SCRIPT"
  echo "Game files folder: $SCRIPT_DIR/Skate 3 Files"
  echo "Working copy: $SCRIPT_DIR/work/assets"
  echo "Runtime copy: $SCRIPT_DIR/work/runtime-assets"
  exit 0
fi

if [[ ! -f "$SETUP_SCRIPT" ]]; then
  echo "Missing setup script:"
  echo "$SETUP_SCRIPT"
  exit 1
fi

chmod +x "$SETUP_SCRIPT" || true
exec "$SETUP_SCRIPT" "$@"
