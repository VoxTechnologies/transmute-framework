#!/usr/bin/env bash
# Transmute Framework — Gate Enforcement Hook
# Validates that prerequisites from prior stages exist before allowing
# the next stage to proceed.
#
# Registered for two events (see hooks/hooks.json):
#   - PreToolUse (matcher: Skill)        — fires when Claude invokes a stage skill
#   - UserPromptExpansion (stage names)  — fires when the user types /transmuter:<stage>
#     directly, which bypasses PreToolUse entirely.
#
# Blocking contract (Claude Code hooks reference): exit code 2 blocks the
# tool call / expansion and sends stderr to Claude. Exit code 1 is a
# NON-blocking error — the stage would still run — so never use it to gate.

set -euo pipefail

# Read the hook input from stdin
INPUT=$(cat)

# Extract the stage name. The key differs by event:
#   PreToolUse/Skill       -> tool_input.skill (older builds: tool_input.skill_name)
#   UserPromptExpansion    -> command_name
# macOS-compatible (sed, no grep -P).
extract() {
  echo "$INPUT" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -1
}
SKILL_NAME=$(extract skill_name)
[[ -z "$SKILL_NAME" ]] && SKILL_NAME=$(extract skill)
[[ -z "$SKILL_NAME" ]] && SKILL_NAME=$(extract command_name)
# Strip a plugin namespace prefix (e.g. "transmuter:brd" -> "brd")
SKILL_NAME="${SKILL_NAME##*:}"

# If we can't extract the skill name, pass through
if [[ -z "$SKILL_NAME" ]]; then
  exit 0
fi

# Block: message to stderr (delivered to Claude), exit 2 (blocking)
block() {
  echo "BLOCK: $1" >&2
  exit 2
}

# Stage 1 stop condition (agents/transmute-pipeline.md § Stage 1 Gate). A plan whose BRD is
# >= 30% assumptions fails Stage 2B unless the operator has reviewed them, so block Stage 2
# up front instead of spending a PRD run on it. The marker is matched loosely because the
# review log writes it as a bold list item ("- **Operator reviewed**: YES").
assumption_gate() {
  local log="./plancasting/brd/_review-log.md" pct
  [[ -f "$log" ]] || return 0
  pct=$(sed -n 's/.*Assumption volume[*]*:[*[:space:]]*\([0-9][0-9]*\)\(\.[0-9]*\)\{0,1\}%.*/\1/p' "$log" | head -1)
  [[ -n "$pct" && "$pct" -ge 30 ]] || return 0
  grep -qiE 'Operator reviewed[*]*:[*[:space:]]*YES' "$log" && return 0
  block "$1 is stopped by the Stage 1 gate: the BRD is ${pct}% assumptions and $log does not say 'Operator reviewed: YES'. Revise the business plan and re-run Stage 1, or review the assumptions and set the marker."
}

# Define prerequisite checks for each stage
case "$SKILL_NAME" in
  tech-stack)
    # Stage 0: Requires business plan
    if [[ ! -d "./plancasting/businessplan" ]]; then
      block "Stage 0 (Tech Stack) requires a Business Plan at ./plancasting/businessplan/. Place your business plan files there first."
    fi
    ;;

  brd)
    # Stage 1: Requires business plan and plancasting/tech-stack.md
    if [[ ! -d "./plancasting/businessplan" ]]; then
      block "Stage 1 (BRD) requires a Business Plan at ./plancasting/businessplan/. Place your business plan files there first."
    fi
    if [[ ! -f "./plancasting/tech-stack.md" ]]; then
      block "Stage 1 (BRD) requires plancasting/tech-stack.md from Stage 0. Run '/transmuter:cast tech-stack' first."
    fi
    ;;

  prd)
    # Stage 2: Requires BRD
    if [[ ! -d "./plancasting/brd" ]]; then
      block "Stage 2 (PRD) requires ./plancasting/brd/ from Stage 1. Run '/transmuter:cast brd' first."
    fi
    assumption_gate "Stage 2 (PRD)"
    ;;

  validate-specs)
    # Stage 2B: Requires BRD + PRD
    if [[ ! -d "./plancasting/brd" ]] || [[ ! -d "./plancasting/prd" ]]; then
      block "Stage 2B (Spec Validation) requires both ./plancasting/brd/ and ./plancasting/prd/. Run Stages 1 and 2 first."
    fi
    assumption_gate "Stage 2B (Spec Validation)"
    ;;

  scaffold)
    # Stage 3: Requires spec validation report + credentials
    if [[ ! -f "./plancasting/_audits/spec-validation/report.md" ]]; then
      block "Stage 3 (Scaffold) requires spec validation report. Run '/transmuter:cast validate' first."
    fi
    # Credential tiers: Stage 3 gates only the red tier (pipeline infrastructure).
    # Service credentials (yellow tier) are gated at Stage 5, where tests first need them.
    if [[ -f ".env.local" ]]; then
      if grep -E '^(TRANSMUTER_ANTHROPIC_API_KEY|E2B_API_KEY|SANDBOX_AUTH_TOKEN)=' .env.local 2>/dev/null \
         | grep -qE 'YOUR_.*_HERE|TODO_.*|CHANGE_ME|PLACEHOLDER|=\s*$'; then
        block "Stage 3 requires the pipeline-infrastructure credentials (TRANSMUTER_ANTHROPIC_API_KEY, E2B_API_KEY, SANDBOX_AUTH_TOKEN) in .env.local to be real values when present. Service credentials may stay as placeholders until Stage 5."
      fi
      if grep -qE 'YOUR_.*_HERE|TODO_.*|CHANGE_ME|PLACEHOLDER|^[A-Z_]+=\s*$' .env.local 2>/dev/null; then
        echo "INFO: .env.local still has placeholder values. They are fine for Stage 3 (scaffold) but Stage 5 (implement) will not start until every value is real."
      fi
    fi
    ;;

  implement)
    # Stage 5: Requires scaffold, a populated CLAUDE.md (the former manual Stage 4), and real credentials
    if [[ ! -f "./plancasting/_scaffold-manifest.md" ]] && [[ ! -f "./ARCHITECTURE.md" ]]; then
      block "Stage 5 (Implementation) requires scaffold from Stage 3. Run '/transmuter:cast scaffold' first."
    fi
    if [[ ! -f "./CLAUDE.md" ]]; then
      block "Stage 5 (Implementation) requires ./CLAUDE.md (installed and populated by Stage 3). Run '/transmuter:cast scaffold' first."
    fi
    # Stage 4 check: no [BRACKETED] placeholders may remain in Part 2
    if sed -n '/^## Part 2/,$p' ./CLAUDE.md | grep -qE '\[[A-Z][A-Z0-9_ -]*\]'; then
      block "Stage 4 check failed: CLAUDE.md Part 2 still contains [BRACKETED] placeholders. Fill them (re-run Stage 3's CLAUDE.md step) before Stage 5."
    fi
    if [[ -f ".env.local" ]] && grep -qE 'YOUR_.*_HERE|TODO_.*|CHANGE_ME|PLACEHOLDER|^[A-Z_]+=\s*$' .env.local 2>/dev/null; then
      block "Stage 5 (Implementation) requires every credential in .env.local to be a real value — tests and integrations run against them from here on. Fix the placeholders first."
    fi
    ;;

  audit-completeness)
    # Stage 5B: Requires implementation
    if [[ ! -f "./plancasting/_progress.md" ]]; then
      block "Stage 5B (Audit) requires plancasting/_progress.md from Stage 5. Run '/transmuter:cast implement' first."
    fi
    ;;

  audit-security|audit-a11y|optimize)
    # Stage 6A/6B/6C: Requires 5B report
    if [[ ! -f "./plancasting/_audits/implementation-completeness/report.md" ]]; then
      block "This stage requires the implementation completeness audit. Run '/transmuter:cast audit' first."
    fi
    ;;

  refactor)
    # Stage 6E: Requires 6A-6C complete
    if [[ ! -f "./plancasting/_audits/implementation-completeness/report.md" ]]; then
      block "Stage 6E (Refactor) requires the implementation completeness audit. Run '/transmuter:cast audit' first."
    fi
    if [[ ! -f "./plancasting/_audits/security/report.md" ]]; then
      block "Stage 6E (Refactor) requires the security audit. Run '/transmuter:cast security' first."
    fi
    if [[ ! -f "./plancasting/_audits/accessibility/report.md" ]]; then
      block "Stage 6E (Refactor) requires the accessibility audit. Run '/transmuter:cast a11y' first."
    fi
    if [[ ! -f "./plancasting/_audits/performance/report.md" ]]; then
      block "Stage 6E (Refactor) requires the performance audit. Run '/transmuter:cast optimize' first."
    fi
    ;;

  seed-data|harden)
    # Stage 6F/6G: Requires 6E
    if [[ ! -f "./plancasting/_audits/refactoring/report.md" ]]; then
      block "This stage requires the refactoring audit (Stage 6E). Run '/transmuter:cast refactor' first."
    fi
    ;;

  docs)
    # Stage 6D: Requires 5B, optimally after 6G (all code changes finalized)
    if [[ ! -f "./plancasting/_audits/implementation-completeness/report.md" ]]; then
      block "Stage 6D (Documentation) requires the implementation completeness audit. Run '/transmuter:cast audit' first."
    fi
    # Warn if running before 6G (code may still change)
    if [[ ! -f "./plancasting/_audits/resilience/report.md" ]]; then
      echo "INFO: Stage 6D is optimal after Stage 6G (resilience hardening). If code changes after 6D, re-run 6D to update docs."
    fi
    ;;

  prelaunch)
    # Stage 6H: Requires 6A-6G complete
    for report in security accessibility performance refactoring resilience; do
      if [[ ! -f "./plancasting/_audits/$report/report.md" ]]; then
        block "Stage 6H (Pre-Launch) requires all Stage 6 audits. Missing: plancasting/_audits/$report/report.md"
      fi
    done
    ;;

  verify)
    # Stage 6V: Requires 6H + feature scenario generation template.
    # Stage 5V (early runtime check) is the same skill in "MODE: critical" invoked right after 5B;
    # it needs the 5B report instead of the 6H readiness report.
    if echo "$INPUT" | grep -qiE 'MODE: *critical|early-verify|pre-audit|5V'; then
      if [[ ! -f "./plancasting/_audits/implementation-completeness/report.md" ]]; then
        block "Stage 5V (Early Runtime Check) requires the Stage 5B report. Run '/transmuter:cast audit' first."
      fi
    elif [[ ! -f "./plancasting/_launch/readiness-report.md" ]]; then
      block "Stage 6V (Verification) requires pre-launch report. Run '/transmuter:cast prelaunch' first (or run the early check as '/transmuter:cast early-verify')."
    fi
    if [[ ! -f "./plancasting/transmute-framework/feature_scenario_generation.md" ]]; then
      block "Stage 6V (Verification) requires plancasting/transmute-framework/feature_scenario_generation.md. Copy it from the plugin's templates directory."
    fi
    ;;

  remediate)
    # Stage 6R: Requires 6V report
    if [[ ! -f "./plancasting/_audits/visual-verification/report.md" ]]; then
      block "Stage 6R (Remediation) requires visual verification report. Run '/transmuter:cast verify' first."
    fi
    ;;

  polish)
    # Stage 6P: Requires 6V report (6R may have been skipped)
    if [[ ! -f "./plancasting/_audits/visual-verification/report.md" ]]; then
      block "Stage 6P (Visual Polish) requires visual verification report. Run '/transmuter:cast verify' first."
    fi
    ;;

  redesign)
    # Stage 6P-R: Same prerequisites as 6P — requires 6V report (6R may have been skipped)
    if [[ ! -f "./plancasting/_audits/visual-verification/report.md" ]]; then
      block "Stage 6P-R (Frontend Design Elevation) requires visual verification report. Run '/transmuter:cast verify' first."
    fi
    ;;

  smoke)
    # Stage 7V: Requires 6V report + 6H readiness report + deployment
    if [[ ! -f "./plancasting/_audits/visual-verification/report.md" ]]; then
      block "Stage 7V (Production Smoke) requires visual verification report (6V). Run '/transmuter:cast verify' first."
    fi
    if [[ ! -f "./plancasting/_launch/readiness-report.md" ]]; then
      block "Stage 7V (Production Smoke) requires pre-launch readiness report (6H). Run '/transmuter:cast prelaunch' first."
    fi
    echo "INFO: Stage 7V (Production Smoke) — ensure the app is deployed before running."
    ;;

  user-guide)
    # Stage 7D: Requires 7V PASS
    if [[ ! -f "./plancasting/_audits/production-smoke/report.md" ]]; then
      block "Stage 7D (User Guide) requires production smoke test. Run '/transmuter:cast smoke' first."
    fi
    ;;

  feedback|maintain)
    # Stage 8/9: Post-launch, no hard file prerequisites
    ;;

  *)
    # Non-transmute skill — pass through
    ;;
esac

exit 0
