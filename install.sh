#!/usr/bin/env bash
# install.sh — Instala las skills del equipo MultiAtlas en ~/.claude/skills/
# Uso: ./install.sh

set -euo pipefail

REPO_SKILLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/skills"
TARGET_SKILLS_DIR="$HOME/.claude/skills"

echo ""
echo "===== Instalador skills MultiAtlas ====="
echo ""
echo "Origen : $REPO_SKILLS_DIR"
echo "Destino: $TARGET_SKILLS_DIR"
echo ""

mkdir -p "$TARGET_SKILLS_DIR"

if [ ! -d "$REPO_SKILLS_DIR" ]; then
    echo "ERROR: no encuentro la carpeta skills/ en el repo."
    echo "Ejecuta este script desde la raiz del repo claude-skills-team."
    exit 1
fi

installed=0
for skill_dir in "$REPO_SKILLS_DIR"/*/; do
    skill_name=$(basename "$skill_dir")
    dest_path="$TARGET_SKILLS_DIR/$skill_name"

    echo "Instalando: $skill_name"

    rm -rf "$dest_path"
    cp -r "$skill_dir" "$dest_path"
    installed=$((installed + 1))
done

echo ""
echo "OK: $installed skills instaladas en $TARGET_SKILLS_DIR"
echo ""
echo "Reinicia VS Code para que Claude Code detecte las skills nuevas."
echo ""
