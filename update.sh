#!/usr/bin/env bash
# update.sh — Actualiza las skills del equipo MultiAtlas
# Uso: ./update.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "===== Actualizador skills MultiAtlas ====="
echo ""

echo "[1/2] git pull..."
cd "$SCRIPT_DIR"
git pull origin master

echo ""
echo "[2/2] Reinstalando skills..."
"$SCRIPT_DIR/install.sh"
