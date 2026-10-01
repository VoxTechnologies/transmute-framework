#!/usr/bin/env bash
# Transmute Framework — conformance check.
#
# Static checks run offline and finish in seconds. They catch the class of
# regression this repository has shipped before (a command namespace that
# matched nothing, a path variable Claude Code never substitutes, a gate hook
# that warned instead of blocking, a stage added in some of its eight places).
#
#   scripts/conformance.sh            # static checks only
#   scripts/conformance.sh --live     # + load the plugin with `claude -p` and
#                                     #   check routing and hook behaviour
#                                     #   (uses your Claude Code session; ~1 min)
#
# Exit code: 0 when every check passes, 1 otherwise. Run before every release
# and after any edit that touches a stage.

set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
FAIL=0
pass() { printf '  ok    %s\n' "$1"; }
fail() { printf '  FAIL  %s\n' "$1"; FAIL=1; }
check() { # check "<label>" <command...>  (passes when the command succeeds)
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then pass "$label"; else fail "$label"; fi
}

STAGES=(tech-stack brd prd validate-specs scaffold implement audit-completeness audit-security audit-a11y optimize docs refactor seed-data harden prelaunch verify remediate polish redesign smoke user-guide feedback maintain)

echo "== Structure =="
if command -v claude >/dev/null 2>&1; then
  check "plugin manifest validates" claude plugin validate .
else
  # CI runners have no Claude Code CLI; fall back to a JSON parse of both manifests.
  check "plugin manifests parse as JSON (claude CLI not installed)" python3 -c "import json;[json.load(open(f)) for f in ('.claude-plugin/plugin.json','.claude-plugin/marketplace.json','hooks/hooks.json')]"
fi
for s in "${STAGES[@]}"; do
  [[ -f "skills/$s/SKILL.md" ]] || fail "skills/$s/SKILL.md missing"
done
pass "23 stage skill directories present (${#STAGES[@]} checked)"

echo "== Every stage lands in every place (the consistency invariant) =="
for s in "${STAGES[@]}"; do
  grep -q "| \`$s\`\|\`$s\` |\| $s |" commands/cast.md || fail "commands/cast.md: no mapping row for $s"
  grep -qE "^\s*$s[|)]|^\s*[a-z0-9|-]*\|$s[|)]" hooks/scripts/check-prerequisites.sh || fail "check-prerequisites.sh: no case arm for $s"
  grep -q "| $s |" agents/transmute-pipeline.md || fail "transmute-pipeline.md: no Stage Skills Map row for $s"
  grep -q "$s" README.md || fail "README.md: $s not mentioned"
done
pass "cast.md mapping, hook case arm, Stage Skills Map row, README mention: all 23 stages"

echo "== Claude Code 2.1 compliance =="
check "no \${CLAUDE_SKILL_ROOT} outside the docs that explain it" bash -c '! rg -q "CLAUDE_SKILL_ROOT" skills agents commands templates hooks'
check "every SKILL.md points at \${CLAUDE_SKILL_DIR}" bash -c '[ "$(rg -l "CLAUDE_SKILL_DIR" skills/*/SKILL.md | wc -l)" -eq 23 ]'
check "commands/cast.md reads the first argument as \$0" bash -c 'rg -q "Examine \`\\\$0\`" commands/cast.md && ! rg -q "Examine \`\\\$1\`" commands/cast.md'
check "no /transmute: namespace outside README changelog, docs history and demo recording" bash -c '! rg -n "/transmute:" --glob "!README.md" --glob "!docs/plugin-architecture.md" --glob "!demo.tape" . | grep -v "transmuter:" | grep -q .'
check "rules templates scope with paths: (not globs:)" bash -c '[ "$(grep -l "^paths: \[" templates/rules-templates/_*-template.md | wc -l)" -eq "$(ls templates/rules-templates/_*-template.md | wc -l)" ] && ! grep -q "^globs:" templates/rules-templates/_*-template.md'
check "hook registered on PreToolUse and UserPromptExpansion" bash -c 'grep -q "\"PreToolUse\"" hooks/hooks.json && grep -q "\"UserPromptExpansion\"" hooks/hooks.json'
check "hook never gates with exit 1" bash -c '! grep -qE "^\s*exit 1\b" hooks/scripts/check-prerequisites.sh'
check "stale .claude-plugin/hooks copy absent" bash -c '[ ! -e .claude-plugin/hooks ]'
check "every skill and agent declares effort:" bash -c '[ "$(grep -l "^effort:" skills/*/SKILL.md agents/*.md | wc -l)" -eq 30 ]'
check "frontmatter parses as YAML (skills, agents, command)" python3 - <<'EOF'
import glob,re,sys,yaml
for p in glob.glob('skills/*/SKILL.md')+glob.glob('agents/*.md')+['commands/cast.md']:
    m=re.match(r'---\n(.*?)\n---\n',open(p).read(),re.S)
    d=yaml.safe_load(m.group(1)); assert isinstance(d,dict) and 'description' in d, p
EOF
check "no current-generation model ID carries a date suffix" bash -c '! rg -q "claude-(opus|sonnet|fable)-5[-0-9]*-20[0-9]{6}" --glob "*.md" skills templates agents'
check "hook script syntax" bash -n hooks/scripts/check-prerequisites.sh
check "cast.md knows the attended mode and the early-verify (5V) alias" bash -c 'grep -q "attended" commands/cast.md && grep -q "early-verify" commands/cast.md'
check "progress template carries Duration and Usage columns and the 5V row" bash -c 'grep -q "| Duration | Usage |" templates/progress.md && grep -q "^| 5V |" templates/progress.md'
check "pipeline agent defines the Stage 1 and 5V gates" bash -c 'grep -q "### Stage 1 Gate" agents/transmute-pipeline.md && grep -q "### 5V Gate" agents/transmute-pipeline.md'

echo "== Gate hook behaviour (fixtures) =="
HOOK="$ROOT/hooks/scripts/check-prerequisites.sh"
T="$(mktemp -d)"; pushd "$T" >/dev/null
run_hook() { echo "$1" | bash "$HOOK" >/dev/null 2>&1; echo $?; }
[[ "$(run_hook '{"tool_name":"Skill","tool_input":{"skill":"brd"}}')" == 2 ]] && pass "brd blocked without business plan (PreToolUse, skill key)" || fail "brd should block (exit 2)"
[[ "$(run_hook '{"tool_name":"Skill","tool_input":{"skill_name":"prd"}}')" == 2 ]] && pass "prd blocked without BRD (skill_name key)" || fail "prd should block (exit 2)"
[[ "$(run_hook '{"command_name":"transmuter:scaffold","command_type":"skill"}')" == 2 ]] && pass "scaffold blocked via UserPromptExpansion with namespace prefix" || fail "scaffold should block (exit 2)"
[[ "$(run_hook '{"command_name":"cast","command_type":"command"}')" == 0 ]] && pass "cast passes through" || fail "cast should pass (exit 0)"
[[ "$(run_hook '{"tool_name":"Skill","tool_input":{"skill":"feedback"}}')" == 0 ]] && pass "feedback (no prerequisites) passes" || fail "feedback should pass"
mkdir -p plancasting/businessplan plancasting/_audits/spec-validation && touch plancasting/businessplan/plan.md plancasting/_audits/spec-validation/report.md plancasting/tech-stack.md
[[ "$(run_hook '{"tool_name":"Skill","tool_input":{"skill":"brd"}}')" == 0 ]] && pass "brd passes with business plan + tech-stack.md" || fail "brd should pass once prerequisites exist"
printf 'TRANSMUTER_ANTHROPIC_API_KEY=YOUR_KEY_HERE\nRESEND_API_KEY=CHANGE_ME\n' > .env.local
[[ "$(run_hook '{"tool_name":"Skill","tool_input":{"skill":"scaffold"}}')" == 2 ]] && pass "scaffold blocked on placeholder pipeline-infrastructure credential (red tier)" || fail "scaffold should block on red-tier placeholder"
printf 'TRANSMUTER_ANTHROPIC_API_KEY=sk-ant-real\nRESEND_API_KEY=CHANGE_ME\n' > .env.local
[[ "$(run_hook '{"tool_name":"Skill","tool_input":{"skill":"scaffold"}}')" == 0 ]] && pass "scaffold passes with only a service-tier placeholder (yellow tier is a Stage 5 gate)" || fail "scaffold should pass with yellow-tier placeholder"
mkdir -p plancasting && touch plancasting/_scaffold-manifest.md
[[ "$(run_hook '{"tool_name":"Skill","tool_input":{"skill":"implement"}}')" == 2 ]] && pass "implement blocked on any remaining placeholder" || fail "implement should block on placeholder"
printf 'TRANSMUTER_ANTHROPIC_API_KEY=sk-ant-real\nRESEND_API_KEY=re_real\n' > .env.local
printf '# CLAUDE.md\n## Part 2\n- Project: [PROJECT_NAME]\n' > CLAUDE.md
[[ "$(run_hook '{"tool_name":"Skill","tool_input":{"skill":"implement"}}')" == 2 ]] && pass "implement blocked while CLAUDE.md Part 2 has [PLACEHOLDER]s (Stage 4 check)" || fail "implement should block on CLAUDE.md placeholders"
printf '# CLAUDE.md\n## Part 2\n- Project: TaskLoop\n' > CLAUDE.md
[[ "$(run_hook '{"tool_name":"Skill","tool_input":{"skill":"implement"}}')" == 0 ]] && pass "implement passes with real credentials and populated CLAUDE.md" || fail "implement should pass"
[[ "$(run_hook '{"tool_name":"Skill","tool_input":{"skill":"verify","args":"MODE: critical"}}')" == 2 ]] && pass "5V (verify, MODE: critical) blocked without the 5B report" || fail "5V should block without 5B report"
mkdir -p plancasting/_audits/implementation-completeness && touch plancasting/_audits/implementation-completeness/report.md
mkdir -p plancasting/transmute-framework && touch plancasting/transmute-framework/feature_scenario_generation.md
[[ "$(run_hook '{"tool_name":"Skill","tool_input":{"skill":"verify","args":"MODE: critical"}}')" == 0 ]] && pass "5V passes with the 5B report and no 6H report" || fail "5V should pass with 5B report"
[[ "$(run_hook '{"tool_name":"Skill","tool_input":{"skill":"verify"}}')" == 2 ]] && pass "6V (full) still requires the 6H readiness report" || fail "6V should block without 6H report"
popd >/dev/null; rm -rf "$T"

if [[ "${1:-}" == "--live" ]]; then
  echo "== Live: load the plugin with claude -p (routing + hooks) =="
  export PATH="$HOME/.local/bin:$PATH"
  L="$(mktemp -d)"; pushd "$L" >/dev/null
  out="$(claude -p --plugin-dir "$ROOT" --max-turns 2 "/transmuter:prd" 2>&1 || true)"
  grep -q "UserPromptExpansion operation blocked" <<<"$out" && grep -q "Stage 2 (PRD) requires" <<<"$out" && pass "/transmuter:prd typed directly is blocked by the hook" || fail "/transmuter:prd should be blocked (got: $(head -c 200 <<<"$out"))"
  out="$(claude -p --plugin-dir "$ROOT" --max-turns 2 "/transmuter:cast help" 2>&1 || true)"
  grep -q "tech-stack (0)" <<<"$out" && pass "/transmuter:cast help prints the stage list (\$0 routing)" || fail "/transmuter:cast help should print the help block"
  out="$(claude -p --plugin-dir "$ROOT" --max-turns 3 "/transmuter:cast prd" 2>&1 || true)"
  grep -qi "brd" <<<"$out" && pass "/transmuter:cast prd routes the first argument and reports the missing BRD" || fail "/transmuter:cast prd should mention the missing BRD"
  popd >/dev/null; rm -rf "$L"
fi

echo
if [[ $FAIL -eq 0 ]]; then echo "CONFORMANCE: PASS"; else echo "CONFORMANCE: FAIL"; fi
exit $FAIL
