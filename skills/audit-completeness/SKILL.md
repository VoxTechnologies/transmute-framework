---
name: audit-completeness
description: >-
  Audits the codebase to verify every PRD feature is fully implemented, not just scaffolded.
  This skill should be used when the user asks to "audit implementation completeness",
  "check for stubs", "detect stub components", "run implementation audit",
  "run Stage 5B", "verify feature completeness", or "find unfinished implementations",
  or when the transmute-pipeline agent reaches Stage 5B of the pipeline.
metadata:
  version: 1.0.0
effort: high
---

# Transmute Audit Completeness — Stage 5B: Implementation Completeness Audit

Lead a multi-agent implementation completeness audit (teammates are Agent-tool subagents; see the pipeline agent's Execution Model). Systematically verify that EVERY feature in the PRD has been FULLY implemented — not just scaffolded — and fix any gaps found.

Read the detailed guide at `${CLAUDE_SKILL_DIR}/references/audit-completeness-detailed-guide.md` for the complete teammate instructions, scan scripts, fix patterns, and coordination protocol.

## Why This Stage Exists

Stage 5 (Feature Implementation) builds all features sequentially. In practice, a recurring pattern emerges: backend implementations are thorough and complete, but many frontend components remain as stubs — scaffold-quality code with placeholder text, unconnected hooks, missing interactive behavior, or components that exist in files but are never rendered. This happens because:
- Over a long feature queue, per-feature attention competes with everything accumulated so far, even though context itself is managed automatically
- Per-feature quality gates become less rigorous as the session progresses
- Frontend teammates produce "looks done" output that passes a late-queue quality gate

This stage runs with a FRESH context window, focused SOLELY on finding and fixing these gaps. It is the hard gate between implementation and QA.

## Category System (Size-Based — Different from 6V/6R)

Issues found during this audit are classified into three SIZE-BASED categories:

- **Category A**: <30 non-blank non-comment lines per affected file — stub text replacement, dead links, missing simple states
- **Category B**: 30–100 lines per file AND <150 lines total across affected files — component body rebuild, form handler wiring, modal content population
- **Category C**: ≥100 lines in any single file OR ≥150 lines total across all affected files OR unbuilt features — escalate to Stage 5 re-run

> This differs from Stage 6V/6R, which classifies by FIXABILITY (A = auto-fixable, B = semi-auto, C = needs human judgment). Size-based categories here determine whether the fix is small enough for a 5B teammate to handle or requires a full Stage 5 re-run.

**Multi-file classification rule**: Category A — all files need <30 lines each. Category B — largest file needs <100 lines AND total across all files <150 lines. Category C — largest file needs ≥100 lines OR total ≥150 lines across all affected files. If ambiguous, default to the higher category. If multiple independent issues happen to be in the same feature, classify each issue separately.

**What Stage 5B Does not Do**: Stage 5B fixes cosmetic/moderate gaps (Category A/B) and documents large gaps (Category C). It does not: (1) create entirely new backend functions or API endpoints — that's Stage 5 re-implementation, (2) build new features from scratch — only completes partially-built features, (3) refactor architecture — that's Stage 6E, (4) add error handling patterns — that's Stage 6G, (5) fix security issues — that's Stage 6A. If a fix requires >100 lines of net-new code in a single file, it's Category C and gets escalated back to Stage 5.

## Prerequisite Checks

1. Verify `./plancasting/prd/` exists with markdown files. If missing: STOP — "Stage 5B requires completed PRD. Run Stages 1-2 first."
2. Verify `./plancasting/_progress.md` exists. If missing: STOP — "Stage 5B requires plancasting/_progress.md from Stage 5. Run Stage 5 first."
3. Verify source code directories exist (check `plancasting/tech-stack.md` for paths). If no source code beyond scaffold: STOP — "Stage 5B requires Stage 5 implementation."
4. Verify `./CLAUDE.md` exists. If missing: WARN — "Proceeding without project-specific conventions."

## Known Failure Patterns (Prioritized)

Based on observed Plan Cast outcomes, these are the most common stub patterns, ordered by frequency:

### Frontend Stubs (PRIMARY — ~80% of issues) (observed across early Plan Casts; percentages are approximate and overlap — duplication co-occurs with frontend stubs, so totals exceed 100%)
1. **Scaffold component bodies**: Components that return a single `<div>` or `<p>` with the feature name and description, no real UI
2. **Unconnected hooks**: Components that import a hook but use `useState("")` or hardcoded mock data instead of the hook's return value
3. **Missing form handlers**: Forms with `onSubmit` that calls `e.preventDefault()` and nothing else
4. **Placeholder navigation**: Links using `href="#"` or `onClick={() => {}}` instead of real routes
5. **Missing state handling**: Components that render the happy-path state but skip loading, error, and empty states entirely
6. **Orphan components**: Component files that exist but are never imported by any page or parent component
7. **Inline page stubs**: Pages that render a heading and a `<p>` tag instead of composing the feature's components
8. **Missing i18n keys**: Components using translation keys that don't exist in the messages file
9. **Stub modals/dialogs**: Modal triggers that exist but the modal component is a placeholder
10. **Missing responsive behavior**: Components that only work at desktop width with no mobile consideration

### Backend Stubs (SECONDARY — ~15% of issues)
1. **Action stubs**: Actions that log "not implemented" instead of calling external APIs
2. **Missing validation**: Functions that accept arguments but don't validate business rules from BRD
3. **Incomplete error handling**: Functions that catch errors but return generic messages instead of your backend error type (e.g., `ConvexError` for Convex) with proper codes

### Duplication Pattern (SECONDARY — ~15% of issues in well-scaffolded projects; overlaps with frontend stubs)

This pattern is DISTINCT from stubs. It occurs when Stage 5's frontend teammate builds UI inline in page files instead of implementing inside existing scaffold component files. The result is:
1. **Orphan components**: Scaffold component files exist in `[components-dir]` but are never imported by any page — because the page rebuilt the same UI inline
2. **Bloated pages**: Page files that contain 200+ lines of inline UI (hooks, state, JSX) that should be decomposed into the scaffold's component files
3. **Duplicate logic**: The same hook is imported in both the orphan component AND the page file, but only the page's version is rendered
4. **Missing component composition**: Pages that should compose 3-5 components instead render everything in a single monolithic return statement

**Root cause**: Stage 5's frontend teammate reads the feature brief and PRD screen spec, then writes fresh code in the page file without first checking what scaffold files already exist. The scaffold manifest (`plancasting/_scaffold-manifest.md`) was not consulted.

**Detection**: Pages with many hook imports but zero component imports from `[components-dir]` are suspicious. Cross-reference with the scaffold manifest if it exists.

### Integration Gaps (~5% of issues)
1. **Cross-feature data flows**: Feature A produces data that Feature B should display, but B uses mock data
2. **Navigation gaps**: Sidebar/navbar links that don't include all implemented features
3. **Dashboard aggregation**: Dashboard widgets that show hardcoded zeros instead of real query results

## Stack Adaptation

Before running any scans, read `plancasting/tech-stack.md` to determine actual directory structure. Replace ALL placeholder paths (`[backend-dir]`, `[pages-dir]`, `[components-dir]`, `[hooks-dir]`) with actual project paths. Replace `npm run` with your package manager.

## Execution Phases

### Phase 1: Lead Analysis (Before Spawning Teammates)

1. **Read project context**:
   - `./CLAUDE.md` — internalize all conventions
   - `./plancasting/tech-stack.md` — understand the stack
   - `./plancasting/_progress.md` — see what Stage 5 marked as "Done"
   - `./plancasting/_implementation-report.md` — see Stage 5's own assessment
   - `./plancasting/_briefs/` — read relevant feature briefs to understand Stage 5's planned implementation scope

2. **Build Feature Inventory from PRD**:
   - Read `plancasting/prd/02-feature-map-and-prioritization.md` — list ALL features
   - Read `plancasting/prd/04-epics-and-user-stories.md` — list ALL user stories with acceptance criteria
   - Read `plancasting/prd/08-screen-specifications.md` — list ALL screens
   - Read `plancasting/prd/12-api-specifications.md` — list ALL API endpoints/functions
   - Create master checklist: Feature -> User Stories -> Expected Screens -> Expected Functions

3. **Run Automated Stub Scan** across the ENTIRE codebase (see detailed guide for full scan scripts):
   - Text-pattern stub detection (grep for placeholder text)
   - Minimal component detection (files under 20 lines)
   - Orphan component detection (files never imported)
   - Dead onClick / href="#" detection
   - Mock data in production components
   - Unconnected hooks (useState with empty/hardcoded values)
   - Missing loading/error states (components using hooks without isLoading check)
   - Empty or near-empty page files
   - Duplication pattern detection (bloated pages with zero component imports)
   - Scaffold manifest cross-reference

4. **Cross-reference PRD against implementation**: For each feature verify routes, backend functions, UI components, hooks, and acceptance criteria coverage.

5. **Classify findings into three categories** (see Category System above and detailed guide for full classification rules):

   **Fixing Priority Within A/B Categories**: (1) Fix P0/P1 critical user flow issues first. (2) Then P2/P3. (3) Within each flow, backend before frontend. (4) Within each layer, integration gaps before stubs.

6. **Generate audit report** at `./plancasting/_audits/implementation-completeness/report.md`

7. **Create fix plan** with teammate assignments.

### Phase 2: Spawn Fix Teammates

Apply the early exit decision table (covers cases where no teammate spawning is needed — if Category A/B count >= 1, proceed to teammate spawning regardless):

| Cat A/B count | Cat C count | Gate Decision | Action |
|---|---|---|---|
| 0 | 0 | PASS | Skip Phase 2-3 -> generate report -> Stage 6 |
| 0 | 1–3 | CONDITIONAL PASS | Skip Phase 2-3, document Cat C -> Stage 6 |
| 0 | 4–5 | FAIL-RETRY | Skip Phase 2-3, document Cat C -> re-run 5B (max 3 runs) |
| 0 | 6+ (or total unfixed >=6) | FAIL-ESCALATE | Skip Phase 2-3, document Cat C -> re-run Stage 5 |
| 1+ | any | *(after fixes)* | Spawn teammates for A/B fixes, document Cat C |
| any (Run 4+) | any | FAIL-ESCALATE | Skip Phase 2 auto-fixes, reclassify all remaining A/B as Cat C |

**Per-feature escalation rule**: If a single feature (same FEAT-ID) reports FAIL-RETRY three consecutive times across 5B re-runs, that feature automatically escalates to FAIL-ESCALATE regardless of overall category counts. Other features' results and intervening PASS/CONDITIONAL PASS outcomes for OTHER features are irrelevant. **Reading previous run state**: At the start of Phase 1, read the previous audit report at `./plancasting/_audits/implementation-completeness/report.md` if it exists — extract the per-feature `5B Runs` column to continue tracking consecutive FAIL-RETRY counts. If no previous report exists, this is Run 1.

When skipping Phase 2-3, the lead must still generate the audit report with gate decision and Category C details. Phase 4 (report) and Phase 5 (rule extraction) always run regardless of early exit.

Spawn Teammates 1 and 2 in parallel. Teammate 3 must wait until both complete.

**Teammate 1: "frontend-stub-fixer"** (PRIMARY — 70% of effort)
- Fix all Category A and B frontend issues
- Replace every stub with FUNCTIONAL implementation
- Connect components to existing backend hooks
- Implement all states (loading, error, empty, data)
- Fix duplication pattern (move inline page UI into scaffold components)
- Decompose bloated pages into component composition
- Run full stub scan, typecheck, lint, and tests after all fixes

**Teammate 2: "backend-stub-fixer"** (if backend issues found)
- Fix all backend stubs with real business logic
- Add missing validation from BRD business rules
- Fix integration gaps (cross-feature data flows)
- Verify all function exports match frontend expectations

**Teammate 3: "e2e-verification"** (always run last, after Teammates 1+2)
- Run full test suite (typecheck, lint, unit, integration, E2E)
- Run final stub scan — must return zero results
- Run orphan component scan
- Spot-check all pages with Category B fixes + additional random pages (coverage by feature count: <10 features = all pages; 10-30 = 50%; >30 = 30%, plus all Category B pages)
- Report results in structured format

### Phase 3: Coordination

**Mandatory file conflict prevention**: Before spawning, assign mutually exclusive file sets to Teammates 1 and 2. If shared files exist, assign them to Teammate 1 exclusively. Teammate 2 must not modify frontend-owned files.

While teammates work:
1. After each teammate completes, review their completion message for Category C escalations — document in `plancasting/_progress.md`
2. If FAIL-ESCALATE gate triggered (6+ Cat C, or 6+ total unfixed, or 3 consecutive FAIL-RETRY), note systemic frontend failure in audit report, recommend FULL Stage 5 re-run rather than targeted fixes. For FAIL-RETRY (4–5 Cat C), recommend re-running 5B with targeted fixes.
3. Resolve conflicts between backend and frontend fixes. If both modify same file, lead reviews and merges.
4. If teammate stuck on fix exceeding Category B scope (>100 lines), reclassify as Category C and move on.

### Phase 4: Audit Report & Gate Decision

After all teammates complete:

1. **Ensure output directory exists**: `mkdir -p ./plancasting/_audits/implementation-completeness/`

2. **Update audit report** at `./plancasting/_audits/implementation-completeness/report.md` with:
   - Summary (total issues by category, fixed counts, Run Number)
   - Fix summary (components fixed, orphans deleted, i18n keys added, backend functions fixed)
   - Verification results (TypeScript, lint, unit tests, E2E, stub scan, orphan scan)
   - Gate decision
   - Category C escalations (if any)
   - Issues by feature (detailed breakdown)

3. **Update `plancasting/_progress.md`**: Mark Category C features as Needs Re-implementation. Add Stage 5B Audit section.

4. **Gate Decision**:
   Gate decision is evaluated in priority order: PASS first, then CONDITIONAL PASS, then FAIL-RETRY, then FAIL-ESCALATE. The first matching outcome applies.
   - **PASS**: All A/B fixed, zero Cat C, all tests pass, zero stubs remain -> Stage 6
   - **CONDITIONAL PASS**: All A/B fixes attempted; 0–2 A/B remain unfixed (each documented with explanation), OR all A/B fixed AND 1–3 Cat C documented. If BOTH unfixed A/B AND Cat C exist, apply CONDITIONAL PASS only if total unfixed (A/B + C) ≤ 3; otherwise FAIL-RETRY -> Stage 6 with known gaps
   - **FAIL-RETRY**: 3+ A/B unfixed, OR test failures from 5B fixes, OR 4–5 Cat C -> re-run 5B (max 3 re-runs; 3 consecutive FAIL-RETRY = auto-escalate). Before re-running, diagnose WHY the fix failed — re-running without diagnosis will loop. If Run 4+, skip Phase 2 and escalate all remaining A/B to Cat C.
   - **FAIL-ESCALATE**: 6+ Cat C issues, OR 6+ total unfixed issues across all categories combined AFTER Phase 2/3 fix attempts (i.e., remaining unfixed A/B that Phase 2 could not resolve + all Category C), OR 3 consecutive FAIL-RETRY outcomes for the same feature -> re-run Stage 5 for affected features (FAIL-RETRY and FAIL-ESCALATE both block Stage 6)

### Phase 5: Rule Extraction (Post-Gate)

After gate decision, extract implementation lessons as path-scoped rules (see CLAUDE.md 'Path-Scoped Rules'):

1. Scan audit findings for repeatable patterns across 2+ features
2. Generate rule candidates with Source Stage, Evidence, Trigger, Rule Text, Target File, Confidence, Affected Features
3. Route by confidence: HIGH (2+ features) -> `.claude/rules/`, MEDIUM/LOW -> `plancasting/_rules-candidates.md`
4. Update CLAUDE.md Part 2 Path-Scoped Rules table if HIGH confidence rules added

> **Limits**: Respect the limits from CLAUDE.md: max 15 rules per file, max 8 rule files total.

### Phase 6: Shutdown

Shut down all teammates. Output final summary: gate decision, issues fixed, escalations, rules extracted (count by confidence level).

## Session Recovery

If interrupted:
1. Check if `./plancasting/_audits/implementation-completeness/report.md` exists.
2. If it exists, check its contents:
   - (a) If it has Fix Summary + Verification Results with test results: Phase 2+3 completed — skip to Phase 4 for gate decision.
   - (b) If it has Fix Summary but no Verification Results: check which teammates finished (if 'Components fixed:' line exists, Teammate 1 completed; if 'Backend functions fixed:' line exists, Teammate 2 completed; missing line = incomplete teammate). Re-spawn incomplete ones, then spawn Teammate 3.
   - (c) If it has Issues Found but no Fix Summary: Phase 1 completed, Phase 2 not started — skip to Phase 2.
   - (d) If no Issues Found section: Phase 1 scan did not complete — restart Phase 1.
3. If report does not exist: restart from Phase 1.
4. Check `plancasting/_progress.md` for features already marked as Needs Re-implementation.
5. Determine Run Number: If existing report has Run Number, increment by 1. If Run 4+ (third re-run), skip Phase 2 auto-fixes — escalate all remaining A/B to Category C. Common causes for reaching Run 4: (a) backend dependencies still missing, (b) teammate repeatedly making identical mistakes.

## Critical Rules

1. never skip the automated stub scan. It is the objective foundation.
2. never mark a stub as "acceptable" — stubs are always bugs at this stage.
3. never delete test files to make the suite pass. Fix the code, not the tests.
4. always read the feature brief and PRD screen spec before fixing a component.
5. always follow CLAUDE.md conventions when writing fix code.
6. always run the full verification suite before declaring complete.
7. Frontend fixes are the PRIMARY focus (70% of effort).
8. If a component fix requires backend changes that don't exist, classify as Category C.
9. The goal is completeness, not perfection. Every feature should be FUNCTIONAL. Polish happens in Stage 6. **5B Quality Standard**: 5B fixes should bring components from 'scaffold' to 'working' — happy path complete, loading/error states present, no obvious bugs. This is not production polish (Stage 6P handles that).
10. Fix, don't redesign. Maintain Stage 5's architectural decisions.

## Output Specification

| Artifact | Path | Description |
|---|---|---|
| Audit report | `plancasting/_audits/implementation-completeness/report.md` | Full findings, fixes, verification, gate decision |
| Progress tracker | `plancasting/_progress.md` (updated) | Cat C features marked for re-implementation |
| Fixed codebase | Source directories | All Category A/B issues resolved |
