#!/bin/bash
# install.sh — Install Operational AI Workflows framework into a target project.
#
# Usage:
#   ./install.sh /path/to/target/project
#   ./install.sh  (installs to current directory)
#
# What it installs:
#   - .claude/hooks/context-watchdog.sh (context degradation alerts)
#   - .claude/hooks/implementation-health.sh (file churn, retry loops, test regression detection)
#   - .claude/hooks/session-review-hook.sh (automatic session review)
#   - .claude/skills/session-review/SKILL.md (session review skill)
#   - .claude/skills/recovery/SKILL.md (recovery protocol skill)
#   - .claude/commands/context-check.md (on-demand context assessment)
#   - .claude/settings.json (hook configuration — merged if exists)
#
# What it does NOT install (use /init-project from Claude Code for these):
#   - CLAUDE.md (needs project-specific detection + common+project layer composition)
#   - Project-specific configuration

set -e

FRAMEWORK_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="${1:-.}"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

echo "=== Operational AI Workflows — Install ==="
echo "Framework: $FRAMEWORK_DIR"
echo "Target:    $TARGET_DIR"
echo ""

# Verify framework directory
if [ ! -f "$FRAMEWORK_DIR/templates/common-layer.md" ]; then
    echo "ERROR: No se encuentra el framework en $FRAMEWORK_DIR"
    exit 1
fi

# Create directories
echo "[1/6] Creando directorios..."
mkdir -p "$TARGET_DIR/.claude/hooks"
mkdir -p "$TARGET_DIR/.claude/skills/session-review"
mkdir -p "$TARGET_DIR/.claude/skills/recovery"
mkdir -p "$TARGET_DIR/.claude/commands"

# Install hooks
echo "[2/6] Instalando hooks..."
cp "$FRAMEWORK_DIR/templates/hooks/context-watchdog.sh" "$TARGET_DIR/.claude/hooks/context-watchdog.sh"
cp "$FRAMEWORK_DIR/templates/hooks/implementation-health.sh" "$TARGET_DIR/.claude/hooks/implementation-health.sh"
cp "$FRAMEWORK_DIR/templates/hooks/session-review-hook.sh" "$TARGET_DIR/.claude/hooks/session-review-hook.sh"
chmod +x "$TARGET_DIR/.claude/hooks/context-watchdog.sh"
chmod +x "$TARGET_DIR/.claude/hooks/implementation-health.sh"
chmod +x "$TARGET_DIR/.claude/hooks/session-review-hook.sh"

# Install skills
echo "[3/6] Instalando skills..."
cp "$FRAMEWORK_DIR/.claude/skills/session-review/SKILL.md" "$TARGET_DIR/.claude/skills/session-review/SKILL.md"
cp "$FRAMEWORK_DIR/.claude/skills/recovery/SKILL.md" "$TARGET_DIR/.claude/skills/recovery/SKILL.md"

# Install commands
echo "[4/6] Instalando commands..."
cp "$FRAMEWORK_DIR/.claude/commands/context-check.md" "$TARGET_DIR/.claude/commands/context-check.md"

# Install/merge settings.json
echo "[5/6] Configurando hooks..."
if [ -f "$TARGET_DIR/.claude/settings.json" ]; then
    echo "  AVISO: .claude/settings.json ya existe en el target."
    echo "  No se sobrescribe. Merge manual necesario."
    echo "  Template disponible en: $FRAMEWORK_DIR/templates/hooks/settings.json.template"
    echo ""
    echo "  Hooks a añadir manualmente:"
    echo "    PostToolUse: bash .claude/hooks/context-watchdog.sh"
    echo "    PostToolUse: bash .claude/hooks/implementation-health.sh"
    echo "    Stop: bash .claude/hooks/session-review-hook.sh"
else
    cp "$FRAMEWORK_DIR/templates/hooks/settings.json.template" "$TARGET_DIR/.claude/settings.json"
fi

echo ""
echo "=== Instalación completa ==="
echo ""
# Check jq dependency
echo "[6/6] Verificando dependencias..."
if ! command -v jq &>/dev/null; then
    echo "  AVISO: jq no está instalado. El hook implementation-health requiere jq para funcionar."
    echo "  Instala con: sudo apt-get install jq (Debian/Ubuntu) o brew install jq (macOS)"
    echo ""
fi

echo "Archivos instalados:"
echo "  .claude/hooks/context-watchdog.sh       — alertas de degradación de contexto"
echo "  .claude/hooks/implementation-health.sh  — detección de file churn, retry loops, test regression"
echo "  .claude/hooks/session-review-hook.sh    — revisión automática al final de sesión"
echo "  .claude/skills/session-review/          — skill de revisión de sesión"
echo "  .claude/skills/recovery/                — skill de diagnóstico y recuperación"
echo "  .claude/commands/context-check.md       — comando /context-check"
echo "  .claude/settings.json                   — configuración de hooks"
echo ""
echo "Siguiente paso:"
echo "  Abre Claude Code en $TARGET_DIR y ejecuta:"
echo "    /init-project    — para generar el CLAUDE.md (Common + Project layers)"
echo "    /bootstrap-intelligence  — para pre-rellenar con patrones del proyecto"
echo ""
