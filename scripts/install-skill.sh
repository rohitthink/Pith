#!/bin/bash
# install-skill.sh — install the Pith skill for Claude Code.
#
#   scripts/install-skill.sh            # → ~/.claude/skills/pith (personal)
#   scripts/install-skill.sh <dir>      # → <dir>/pith (e.g. a project's .claude/skills)
#
# Copies SKILL.md plus the templates and scripts it uses, the main docs, and the
# files those docs link to (README, LICENSE, docs/OUTLINE.md, the case study),
# keeping their relative paths so the links resolve. Re-running updates it in place.
set -eu
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST_PARENT="${1:-$HOME/.claude/skills}"
DEST="$DEST_PARENT/pith"

[ -f "$ROOT/skill/pith/SKILL.md" ] || { echo "skill/pith/SKILL.md not found under $ROOT" >&2; exit 1; }
mkdir -p "$DEST/templates" "$DEST/scripts" "$DEST/docs" "$DEST/case-studies"
cp "$ROOT/skill/pith/SKILL.md" "$DEST/SKILL.md"
cp "$ROOT"/templates/* "$DEST/templates/"
cp "$ROOT/scripts/re-inventory.sh" "$ROOT/scripts/re-static.sh" "$DEST/scripts/"
cp "$ROOT/GUARDRAILS.md" "$ROOT/METHOD.md" "$ROOT/AGENT-PLAYBOOK.md" "$ROOT/LESSONS.md" "$DEST/"
cp "$ROOT/README.md" "$ROOT/LICENSE" "$DEST/"
cp "$ROOT/docs/OUTLINE.md" "$DEST/docs/"
cp "$ROOT/case-studies/zest.md" "$DEST/case-studies/"
chmod +x "$DEST"/scripts/*.sh
echo "Installed the Pith skill at $DEST"
echo "In Claude Code, ask to reverse engineer an app you own, or type /pith."
