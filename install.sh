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
    echo "ERROR: directory '$1' does not exist."
    exit 1
}

echo "=== Operational AI Workflows — Install ==="
echo "Framework: $FRAMEWORK_DIR"
echo "Target:    $TARGET_DIR"
echo ""

# Check python dependency
if ! command -v python3 &>/dev/null && ! command -v python &>/dev/null; then
    echo "WARNING: python is not installed. The implementation-health hook requires Python 3."
    echo "Install with:"
    echo "  - Windows:       winget install Python.Python.3  (or download from https://www.python.org)"
    echo "  - Debian/Ubuntu: sudo apt-get install python3"
    echo "  - macOS:         brew install python3"
    echo ""
fi

# Run sync
"$FRAMEWORK_DIR/bin/sync.sh" "$TARGET_DIR"

echo ""
echo "=== Installation complete ==="
echo ""
echo "Future updates are applied automatically at the start of each Claude Code session."
echo "(SessionStart hook checks GitHub hourly and syncs if a new version is available)"
echo ""
echo "Next steps:"
echo "  Open Claude Code in $TARGET_DIR and run:"
echo "    /init-project    — to generate the CLAUDE.md (Common + Project layers)"
echo "    /bootstrap-intelligence  — to pre-fill with project patterns"
echo ""
