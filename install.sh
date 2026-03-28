#!/bin/bash
# install.sh — Install Operational AI Workflows framework into a target project.
#
# Usage:
#   ./install.sh /path/to/target/project
#   ./install.sh  (installs to current directory)
#
# This is a wrapper around bin/sync.sh that adds first-time setup messages.
# Subsequent updates happen automatically via the SessionStart auto-update hook.

set -e

FRAMEWORK_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="${1:-.}"
TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd)" || {
    echo "ERROR: directorio '$1' no existe."
    exit 1
}

echo "=== Operational AI Workflows — Install ==="
echo "Framework: $FRAMEWORK_DIR"
echo "Target:    $TARGET_DIR"
echo ""

# Check python3 dependency
if ! command -v python3 &>/dev/null; then
    echo "AVISO: python3 no está instalado. El hook implementation-health requiere python3."
    echo "Instala con: sudo apt-get install python3 (Debian/Ubuntu) o brew install python3 (macOS)"
    echo ""
fi

# Run sync
"$FRAMEWORK_DIR/bin/sync.sh" "$TARGET_DIR"

echo ""
echo "=== Instalación completa ==="
echo ""
echo "Las actualizaciones futuras se aplican automáticamente al iniciar sesión de Claude Code."
echo "(hook SessionStart comprueba GitHub cada hora, sincroniza si hay nueva versión)"
echo ""
echo "Siguiente paso:"
echo "  Abre Claude Code en $TARGET_DIR y ejecuta:"
echo "    /init-project    — para generar el CLAUDE.md (Common + Project layers)"
echo "    /bootstrap-intelligence  — para pre-rellenar con patrones del proyecto"
echo ""
