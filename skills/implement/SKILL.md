---
name: implement
description: >-
  Orchestrates full-product feature implementation using parallel backend, frontend, and test agents.
  This skill should be used when the user asks to "implement features",
  "build the product", "run feature implementation", "orchestrate implementation",
  "run Stage 5", "start the feature build", or "implement from PRD",
  or when the transmute-pipeline agent reaches Stage 5 of the pipeline.
metadata:
  version: 1.1.0
effort: high
---

# Transmute Implement — Stage 5: Feature Implementation Orchestrator

Orchestrate the implementation of a COMPLETE product with a team of subagents (each "teammate" below is an Agent-tool subagent — `feature-backend`, `feature-frontend`, `feature-tests`, `feature-reviewer` — whose final message is its completion message; Claude Code's experimental Agent Teams can be used instead when `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is set). Read the PRD, identify ALL features, and systematically implement every one — including backend, frontend, and tests — with quality gates between features and a final full-product integration verification.

Read the detailed guide at `${CLAUDE_SKILL_DIR}/references/implementation-detailed-guide.md` for the complete teammate instructions, testing pitfalls, and coordination protocol.

## Critical Framing: Full-Build Approach

Build the COMPLETE product. Every feature in the PRD is implemented in this run. There is no MVP gate, no "good enough for Phase 1" checkpoint. Features are implemented in dependency order (P0 -> P1 -> P2 -> P3), but ALL priority levels are built. P0-P3 determines the build ORDER, not the build SCOPE.

If Stage 5B audit later identifies systemic gaps (6+ Category C issues, OR 6+ total unfixed issues, OR 3 consecutive FAIL-RETRY outcomes triggering a FAIL-ESCALATE gate), the lead must re-run Stage 5 for those specific features — but features are never skipped, only reworked. When you reach the end of the queue, the product is complete.

## Post-Implementation Quality Gate

After this stage completes, Stage 5B (Implementation Completeness Audit) will scan ALL features for:
- Stub components that were never filled with real logic
- Duplicate inline implementations that bypass scaffold components
- Missing test coverage
- Orphan component files

## Prerequisite Checks

Before proceeding, verify ALL of these conditions:

1. Verify `./plancasting/prd/` directory exists with markdown files. If missing: STOP — "Stage 5 requires completed PRD."
2. Verify `./plancasting/brd/` directory exists with markdown files. If missing: STOP — "Stage 5 requires completed BRD."
3. Verify `./plancasting/tech-stack.md` exists. If missing: STOP — "Stage 5 requires plancasting/tech-stack.md."
4. Verify `./CLAUDE.md` exists and Part 2 is populated (no `[PLACEHOLDER]` markers). If not: STOP — "Stage 5 requires Stage 4 CLAUDE.md setup."
5. Verify `./plancasting/_scaffold-manifest.md` exists. If missing: WARN — "Scaffold manifest not found. Proceed with manual directory scanning."
6. Verify credentials: `grep -E 'YOUR_.*_HERE|TODO_.*|CHANGE_ME|PLACEHOLDER|^[A-Z_]+=\s*$' .env.local` must return no matches.
7. Stop any running dev server before starting.

## Stack Adaptation

Replace all `npm run` commands with your project's package manager from `CLAUDE.md` or `plancasting/tech-stack.md`. Adapt all file paths and patterns to your actual stack (Convex paths -> your backend, `src/app/` -> your pages dir, etc.).

## Startup Sequence

1. Read `./CLAUDE.md` — internalize all conventions.
2. Read `./plancasting/tech-stack.md` — understand the stack. Check `Session Language` for output language.
3. Read `./plancasting/prd/02-feature-map-and-prioritization.md` — build the feature queue.
4. Read `./plancasting/_progress.md` — check for resumed sessions. If features have `🔄` status, this is a 5B re-run — filter queue to only those features and read the audit report for specific gaps.
5. Read `./plancasting/_scaffold-manifest.md` — understand the scaffold structure.
6. Read `./plancasting/_codegen-context.md` — understand naming conventions, patterns, and code generation context established during scaffolding. If missing, WARN: "Scaffold context not found. Proceed with manual directory scanning."

## Feature Queue Construction

Build the implementation queue from PRD `02-feature-map-and-prioritization.md`:
- Order by priority: P0 (critical) -> P1 (important) -> P2 (nice-to-have) -> P3 (future)
- Within each priority, order by dependency (features with no dependencies first)
- ALL priorities are included — P0-P3 determines ORDER, not SCOPE

Skip features already marked as Done in `plancasting/_progress.md`. Resume features marked as In Progress. Skip features marked as `⏸ Blocked` (treat like Done for resumption, but retain their blocked status).

**Parallel waves (opt-in)**: `plancasting/tech-stack.md` § Model Specifications "Stage 5 parallel waves" sets how many features may be in flight at once (default 1 = the sequential cycle below). When it is above 1, build waves from the dependency order: a wave holds up to N features that (a) have no unmet dependency, (b) touch no shared UI (navigation, dashboard, shared layout — read the Cross-feature integration points of each brief: features with a `UI reference` or `Workflow` integration level to another feature in the same wave are serialized), and (c) are not sub-features of the same parent. Each feature in a wave runs its Step 1–5 cycle in its own git worktree (`git worktree add ../<project>-FEAT-NNN -b feat/FEAT-NNN`; every teammate prompt names that directory and all file operations stay inside it). When a feature's quality gate passes, merge its branch into the main working tree (`git merge --no-ff feat/FEAT-NNN`), run the full typecheck and test suite on the merged tree, and only then mark it Done; resolve merge conflicts yourself and re-run the suite. A wave ends when all its features are merged. The time saved comes from the waves; the risk is in shared files, which is why rule (b) exists. Keep the default at 1 until a measured run on the project shows the merges stay clean.

**Feature Splitting**: If a feature requires creating or substantially modifying more than ~15 files total, split into sub-features and implement sequentially. Identify logical sub-features from user stories. Each sub-feature should be independently testable. Update `_progress.md` with IDs like `FEAT-003a`, `FEAT-003b`. Parent feature is marked Done only when all sub-features are Done.

## Per-Feature Implementation Cycle

For each feature in the queue, execute these 5 steps sequentially:

### Step 1: Feature Analysis (Lead Only)

Generate a Feature Implementation Brief at `./plancasting/_briefs/<feature-id>.md` containing:
- Feature ID, name, priority
- Related PRD sections (screen specs, user stories, API specs, data model refs)
- Related BRD sections (business rules, security requirements)
- Backend scope: functions to create/modify, schema changes, external API integrations
- Frontend scope: components to create/modify, hooks needed, pages to update
- Cross-feature integration points and integration level:
  - **Data-only**: Feature reads/writes shared data (e.g., dashboard reads task counts)
  - **UI reference**: Feature links to or displays summaries from another feature
  - **Workflow**: Features form a connected multi-step user flow
- Acceptance criteria extracted from user stories
- Testing requirements

### Step 2: Backend Implementation (Teammate: "backend")

Spawn a backend teammate with the Feature Implementation Brief. The teammate must:
- Read CLAUDE.md, plancasting/tech-stack.md, the feature brief, and the scaffold manifest
- Perform SCAFFOLD INVENTORY before writing any code
- Create/update backend functions with real business logic (not stubs)
- Add proper argument validation, auth checks, error handling
- Implement external API integrations with retry logic
- Run backend tests and verify no regressions

### Step 3: Frontend Implementation (Teammate: "frontend")

Blocked by Step 2 completion. Spawn with the brief AND backend teammate's completion message.

The frontend teammate must:
- Read CLAUDE.md, plancasting/tech-stack.md, design tokens, and the brief
- Perform SCAFFOLD INVENTORY (mandatory) — list all existing scaffold files, read the manifest
- Implement business logic INSIDE existing scaffold component files (never rebuild inline in pages)
- Create custom hooks wrapping backend functions
- Implement all component states (default, loading, empty, error, disabled)
- Follow the design direction from plancasting/tech-stack.md with design tokens
- Update cross-feature UI (navigation, dashboard, shared components)
- Wire feature flags where applicable
- Write component tests
- Run stub elimination scan — zero stub patterns remaining
- Run typecheck, lint, and tests

### Step 4: E2E Tests (Teammate: "e2e-tester")

Blocked by Step 3 completion. The teammate must:
- Write Playwright tests covering happy path, alternative paths, error paths
- Write cross-feature E2E tests in `e2e/integration/`
- Test responsive behavior on mobile + desktop viewports
- Run ALL existing E2E tests to verify no regressions
- Clean up test data using `afterEach`/`afterAll` hooks

### Step 5: Quality Gate (Lead Only)

After all teammates complete:

> Items 1-6 are **blocking** (fail = feature not done). Items 8 and 10 are **required for session recovery**. Items 7, 9, 11-12 are **secondary** (fail = documented for Stage 5B).

1. Run full project typecheck, test suite, and E2E suite
2. Fix any regressions (spawn fix teammates if needed)
3. Verify cross-feature integration
4. Run module map sync check (if applicable)
5. Run traceability check (every user story has backend + frontend + test coverage)
6. Run design consistency check (tokens, aesthetic direction, visual consistency)
7. Update scaffold manifest if new files were created
8. Update `plancasting/_progress.md` — mark feature as Done
9. Shutdown teammates
10. Proceed to next feature — do not stop at any priority boundary

## Anti-Stub Quality Gates (Critical)

Before marking ANY feature as Done, verify:

### Per-Feature Grep Patterns

Run this scan on all files created or modified for the feature:

```bash
# Scan for stub patterns (zero matches required)
grep -rn --include="*.tsx" --include="*.ts" --include="*.jsx" --include="*.js" \
  "implementation pending\|pending feature build\|⚠️ STUB\|TODO \[Stage 5\]\|Coming soon\|Not yet implemented\|PLACEHOLDER" \
  <modified-files> | grep -v 'placeholder="\|Placeholder='

# Scan for orphan components (every component must be imported somewhere)
for file in <new-component-files>; do
  component_name=$(basename "$file" .tsx)
  if ! grep -rl "from.*${component_name}\|import.*${component_name}" [frontend-dir] --include="*.tsx" --include="*.ts" | grep -v "$file"; then
    echo "ORPHAN: $file is never imported"
  fi
done
```

If either scan finds issues, the feature must be sent back to the responsible teammate. Do not mark as Done.

### Structural Checks

1. **No placeholder text patterns**: Zero matches from the grep scan above.
2. **Functional component bodies**: Every component imports/uses hooks or receives real props, renders meaningful UI, handles all states, has wired interactive elements.
3. **No orphan components**: Every component file is imported by at least one page.
4. **Page-level data flow**: Real data from hooks, functional form submissions, real route navigation.

## Handling Failures

- **Build errors**: Send to responsible teammate. Spawn "debugger" teammate if unresolvable.
- **Test failures (regression)**: Never skip or delete tests. Diagnose: intentional change (update test) or bug (fix code).
- **Dependency conflicts**: Mark blocked feature as `⏸ Blocked` in `plancasting/_progress.md` with the blocking feature noted in the Notes column. Continue with next non-blocked feature. **After each feature completes**: Scan `plancasting/_progress.md` for any features marked as `⏸ Blocked`. For each, check if its dependency (noted in Notes) is now `✅ Done`. If yes, change status to `🔧 In Progress` and add to the queue.
- **Cross-feature breaks**: Highest priority — fix immediately before proceeding.

## Full-Product Completion Sequence

After ALL features are Done in `plancasting/_progress.md`:

1. **Full Integration Test Suite**: Run typecheck, lint, all tests, all E2E. All must pass.

2. **Cross-Feature Integration Sweep**: Spawn "cross-feature-auditor" to verify cross-feature user flows, data flows, shared UI aggregations, and write additional E2E tests for gaps. Priority order: (1) Flag but do not fix data model inconsistencies. (2) Flag navigation gaps but do not add links. (3) Fix simple integration issues.

3. **Onboarding Flow Verification**: Spawn "onboarding-auditor" (if PRD specifies onboarding) to verify progressive disclosure, first-time experience, and empty states.

4. **Performance Validation**: Spawn "performance-auditor" for lightweight sanity check — bundle size, Lighthouse scores, query performance. Flag critical blockers only (page load >10s on 4G throttle, bundle >100% over budget); optimization happens in Stage 6C. Do not implement optimization fixes in this stage.

5. **Final Implementation Report**: Generate `./plancasting/_implementation-report.md` with completion summary (features, files, functions, components, hooks, tests), PRD coverage (target: 100%), cross-feature integration metrics, quality metrics (zero errors, test pass rates, bundle/lighthouse), assumptions, PRD gaps, known issues, and launch readiness assessment.

6. **Shutdown**: Shut down all remaining teammates.

## Session Recovery

If resuming a previously interrupted implementation:
1. Read `plancasting/_progress.md` for feature status. Perform a **positional scan** (top-to-bottom, not status-prioritized).
2. For In Progress features: check `plancasting/_briefs/` to determine where implementation stopped. Inspect the codebase to establish sub-status: (a) Backend: check if backend functions exist with real logic (not just scaffolds), (b) Frontend: check if components/pages render real UI connected to hooks, (c) Tests: check if test files exist with passing assertions. Resume from the first incomplete layer — do not re-spawn teammates for layers that are already complete.
3. For Needs Re-implementation features (set by Stage 5B): read `./plancasting/_audits/implementation-completeness/report.md` for specific gaps. Focus frontend teammate on replacing stubs. Only re-run backend teammate if audit explicitly flags backend issues. For features with `🔄` status: keep as 🔄 (not 🔧) so next session rebuilds from scratch.
4. For `⏸ Blocked` features: check if blocking dependency is now Done. If yes, unblock and add to queue.
5. Resume from first incomplete step. Do not restart from beginning.

## Critical Rules

1. never skip a feature. Every feature in the PRD must be implemented.
2. never skip the Feature Analysis step. Every feature must have a brief.
3. never spawn frontend until backend confirms completion.
4. never spawn E2E until frontend confirms completion.
5. never proceed to next feature until quality gate passes (including regression tests).
6. never proceed past a cross-feature break. Fix immediately.
7. always read CLAUDE.md at startup. never modify Part 1.
8. always update `plancasting/_progress.md` after each feature cycle.
9. always run FULL test suite at each quality gate.
10. Split features requiring 15+ files into sub-features.
11. always run the Full-Product Completion Sequence before the final report. If `plancasting/_implementation-report.md` exists but lacks a 'Launch Readiness Assessment' section, re-run the Full-Product Completion Sequence.
12. The final report must show 100% PRD coverage. All features must show Done (or Blocked with documented reason).

## Output Specification

| Artifact | Path | Description |
|---|---|---|
| Feature briefs | `plancasting/_briefs/<feature-id>.md` | One per feature with scope and acceptance criteria |
| Implementation report | `plancasting/_implementation-report.md` | Full completion summary and launch readiness |
| Progress tracker | `plancasting/_progress.md` (updated) | All features marked Done |
| Working product | Source code directories | Complete functional codebase |
| Cross-feature E2E tests | `e2e/integration/` | Integration tests spanning features |
