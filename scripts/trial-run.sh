#!/usr/bin/env bash
# Transmute Framework — end-to-end trial runner.
#
# Runs a sequence of pipeline stages non-interactively in a project directory
# with `claude -p`, records wall-clock duration and token usage per stage, and
# stops at the first stage whose expected output is missing. It is how the
# values in tech-stack.md § Model Specifications (session limits, effort levels)
# and the Duration/Usage columns of _progress.md get measured instead of guessed.
#
#   scripts/trial-run.sh <project-dir> <stage> [<stage> ...]
#
#   PLUGIN_DIR   plugin to load (default: this repository)
#   MODEL        session model (default: claude-opus-5-5)
#   MAX_TURNS    per stage (default: 300)
#   EXTRA_PROMPT text appended to every stage invocation (operator answers,
#                dry-run instructions, etc.)
#
# Output: <project-dir>/plancasting/_trial/<stage>.json (full result),
#         <project-dir>/plancasting/_trial/usage.tsv (one row per stage).
# Stage 0 is interactive; pass its answers through EXTRA_PROMPT (see
# examples/sample-plan/README.md for the answer block used in testing).

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="${1:?project dir}"; shift
[[ $# -gt 0 ]] || { echo "no stages given" >&2; exit 2; }
PLUGIN_DIR="${PLUGIN_DIR:-$ROOT}"
MODEL="${MODEL:-claude-opus-5-5}"
MAX_TURNS="${MAX_TURNS:-300}"
EXTRA_PROMPT="${EXTRA_PROMPT:-}"
export PATH="$HOME/.local/bin:$PATH"

cd "$PROJECT" || exit 2
mkdir -p plancasting/_trial
TSV=plancasting/_trial/usage.tsv
[[ -f "$TSV" ]] || printf 'stage\tstarted\tduration_min\tturns\tinput\toutput\tcache_read\tcache_create\tresult\n' > "$TSV"

# expected primary output per stage (mirrors agents/transmute-pipeline.md Stage Skills Map)
expected() {
  case "$1" in
    tech-stack) echo plancasting/tech-stack.md ;;
    brd) echo plancasting/brd ;;
    prd) echo plancasting/prd ;;
    validate-specs) echo plancasting/_audits/spec-validation/report.md ;;
    scaffold) echo plancasting/_scaffold-manifest.md ;;
    implement) echo plancasting/_implementation-report.md ;;
    audit-completeness) echo plancasting/_audits/implementation-completeness/report.md ;;
    early-verify|verify) echo plancasting/_audits/visual-verification/report.md ;;
    audit-security) echo plancasting/_audits/security/report.md ;;
    audit-a11y) echo plancasting/_audits/accessibility/report.md ;;
    optimize) echo plancasting/_audits/performance/report.md ;;
    refactor) echo plancasting/_audits/refactoring/report.md ;;
    harden) echo plancasting/_audits/resilience/report.md ;;
    prelaunch) echo plancasting/_launch/readiness-report.md ;;
    *) echo "" ;;
  esac
}

for stage in "$@"; do
  started="$(date '+%Y-%m-%d %H:%M')"
  t0=$(date +%s)
  echo "== $stage  ($started) =="
  claude -p --plugin-dir "$PLUGIN_DIR" --model "$MODEL" --permission-mode bypassPermissions \
    --max-turns "$MAX_TURNS" --output-format json \
    "/transmuter:cast $stage

$EXTRA_PROMPT" > "plancasting/_trial/$stage.json" 2> "plancasting/_trial/$stage.err"
  rc=$?
  t1=$(date +%s)
  dur=$(python3 -c "print(round(($t1-$t0)/60,1))")
  read -r turns inp out cr cc <<<"$(python3 - "plancasting/_trial/$stage.json" <<'EOF'
import json,sys
try:
    d=json.load(open(sys.argv[1])); u=d.get('usage',{})
    print(d.get('num_turns','?'), u.get('input_tokens',0), u.get('output_tokens',0), u.get('cache_read_input_tokens',0), u.get('cache_creation_input_tokens',0))
except Exception:
    print('? 0 0 0 0')
EOF
)"
  exp="$(expected "$stage")"
  if [[ $rc -ne 0 ]]; then result="claude-exit-$rc"
  elif [[ -n "$exp" && ! -e "$exp" ]]; then result="missing:$exp"
  else result="ok"; fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$stage" "$started" "$dur" "$turns" "$inp" "$out" "$cr" "$cc" "$result" >> "$TSV"
  echo "   $result  ${dur} min  turns=$turns  out=$out  cache_read=$cr"
  [[ "$result" == "ok" ]] || { echo "stopping at $stage ($result); see plancasting/_trial/$stage.err" >&2; exit 1; }
done
echo "trial complete"; column -t -s $'\t' "$TSV"
