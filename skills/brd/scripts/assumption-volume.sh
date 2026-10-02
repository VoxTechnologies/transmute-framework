#!/usr/bin/env bash
# Stage 1 assumption volume, counted the same way every run.
#
#   bash ${CLAUDE_SKILL_DIR}/scripts/assumption-volume.sh [brd-dir]   (default ./plancasting/brd)
#
# Prints the line Stage 1 copies into _review-log.md § Assumption Review Status:
#   - **Assumption volume**: 53.1% (182 assumptions / 343 requirement IDs)
# Numerator: `> ⚠️ ASSUMPTION:` blockquotes (each counts once, however long).
# Denominator: unique requirement IDs (BR, FR, NFR, CR, SR, BRL, DR, IR) anywhere in the BRD.
# The lead counted by hand until v3.2.1 and reported 60.1% for a BRD that measures 53.1%;
# the Stage 1 gate turns on this number, so it is computed, not estimated.
set -euo pipefail
DIR="${1:-./plancasting/brd}"
[[ -d "$DIR" ]] || { echo "no BRD directory: $DIR" >&2; exit 2; }
a=$(cat "$DIR"/*.md | grep -cE '^[[:space:]]*>[[:space:]]*⚠️[[:space:]]*ASSUMPTION:' || true)
r=$(cat "$DIR"/*.md | grep -oE '\b(BRL|BR|FR|NFR|CR|SR|DR|IR)-[0-9]{2,}\b' | LC_ALL=C sort -u | wc -l | tr -d ' ')
[[ "$r" -gt 0 ]] || { echo "no requirement IDs found in $DIR" >&2; exit 2; }
pct=$(awk -v a="$a" -v r="$r" 'BEGIN{printf "%.1f", 100*a/r}')
flag=$(awk -v p="$pct" 'BEGIN{print (p>=30)?"YES":"NO"}')
echo "- **Assumption volume**: ${pct}% (${a} assumptions / ${r} requirement IDs)"
echo "- **Flagged as CRITICAL**: ${flag}"
