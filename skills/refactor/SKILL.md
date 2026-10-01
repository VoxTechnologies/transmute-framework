---
name: refactor
description: >-
  Audits the codebase for code quality issues and refactors without changing external behavior.
  This skill should be used when the user asks to "refactor the codebase",
  "clean up code quality", "eliminate duplication", "improve abstractions",
  "enforce consistency", "remove dead code", or "optimize architecture"
  — or when the transmute-pipeline agent reaches Stage 6E of the pipeline.
metadata:
  version: 1.0.0
effort: medium
---

# Stage 6E: Code Quality and Architecture Refinement

Lead a multi-agent code refactoring project. Audit the COMPLETE codebase for code quality, eliminate duplication, improve abstractions, enforce consistency, and optimize architecture — without changing any external behavior.

**Stage Sequence** (recommended ordering): Stage 5B → 6A/6B/6C (parallel) → **6E (this stage)** → 6F (Seed Data) → 6G (Resilience Hardening) → 6D (Documentation) → 6H (Pre-Launch) → 6V → 6R → 6P/6P-R → 7 (Deploy)

## Cardinal Rule

**NO BEHAVIORAL CHANGES.** Refactoring changes internal structure without altering external behavior. Every test that passed before refactoring must still pass after. If a refactoring would require changes to tests that validate external behavior (API contracts, acceptance criteria), the behavior is changing — stop and reconsider. Tests validating implementation details (private functions, internal state) may be restructured.

**Scope clarification**: 'No behavioral changes' means no changes to external APIs or user-facing behavior. Internal function signatures MAY change if all call sites are updated atomically in the same commit.

## Context: Why This Stage Exists

The Feature Orchestrator builds features one at a time, with each cycle's teammates having limited awareness of other features' implementation details. This produces a working product, but leaves behind:
- Duplicated utility functions and patterns across feature domains
- Missed abstraction opportunities
- Inconsistent naming, patterns, or conventions across features
- Schema and index redundancies from incremental additions
- Overly coupled code where cross-feature integration was added reactively
- Dead code from iterative fixes during quality gate cycles

## Prerequisites

Verify before starting:

1. `./plancasting/_audits/implementation-completeness/report.md` exists with PASS or CONDITIONAL PASS. If missing or FAIL, STOP — Stage 5B must pass first.
2. Read `./CLAUDE.md` and `./plancasting/tech-stack.md` for project conventions.
3. Check that `./plancasting/_audits/security/report.md` (6A), `./plancasting/_audits/accessibility/report.md` (6B), and `./plancasting/_audits/performance/report.md` (6C) exist. If any are missing, WARN and document in the report.
4. **Incomplete features (5B Category C)**: Skip refactoring features marked as incomplete. However, DO refactor shared utilities/hooks that incomplete features use (since other complete features may also depend on them).

Check `./plancasting/tech-stack.md` for the `Session Language` setting. Generate all reports in that language. Code and file names remain in English. Replace all `bun run` commands with the project's package manager from `CLAUDE.md`.

## Stack Adaptation

Source examples use Convex + Next.js. Adapt all paths and patterns to the actual tech stack in `plancasting/tech-stack.md`: `convex/` becomes your backend directory, Convex functions become your backend functions, `src/app/` becomes your frontend pages, etc. Read `CLAUDE.md` Part 2 for actual conventions.

## Phase 1: Lead Analysis and Planning

Complete BEFORE spawning teammates:

1. Read `./CLAUDE.md`, `./plancasting/tech-stack.md`, `./ARCHITECTURE.md` (if exists), and `./plancasting/_audits/implementation-completeness/report.md`.
2. **Run the full test suite and save baseline** to `./plancasting/_audits/refactoring/baseline-test-results.md`:
   ```bash
   bun run typecheck
   bun run test
   bun run test:e2e
   ```
   Verify test counts are non-zero. Check the test runner output for lines like "Tests: X passed", "X test suites". If the output shows 0 tests found, treat as 0 test files. (1) If ALL suites return 0 tests: STOP — do not refactor without tests. Run Stage 5 first. (2) If some suites have tests but others don't: WARN and proceed limited to covered code paths. (3) If all have tests: proceed normally. If baseline tests fail, STOP and resolve failures first.
3. Count total files, functions, components, hooks, and lines of code. Identify largest files (candidates for splitting) and highest-coupling files.
4. Analyze the codebase for refactoring opportunities across seven categories:

   | Category | What to look for |
   |---|---|
   | Duplication | Similar functions, components, or patterns across feature domains. Extract when ANY threshold met: (a) identical function 3+ times, (b) function 2+ times with >90% similarity, (c) extracting reduces lines by >15% |
   | Abstraction | Repeated logic that should be extracted into shared modules |
   | Consistency | Naming, patterns, or conventions that vary across features |
   | Schema | Redundant indexes, tables that could be merged, unused fields |
   | Coupling | Feature code importing another feature's internals. Run `npx madge --circular src/` for cycle detection |
   | Dead code | Unused exports, unreachable branches, commented-out code |
   | File structure | Files exceeding 300 lines, unclear module boundaries |

5. Create `./plancasting/_audits/refactoring/plan.md` with prioritized opportunities, affected files, risk levels, and parallelizable work packages.

Read the detailed guide at `${CLAUDE_SKILL_DIR}/references/refactor-detailed-guide.md` for the complete teammate spawn prompts, coordination protocols, and analysis criteria.

## Phase 2: Spawn Refactoring Teammates

Spawn 4 teammates. Each spawn prompt must include the refactoring plan and the cardinal rule.

**Teammate 1 — "backend-refactorer"**: Backend functions, schema, server-side code. Tasks: function deduplication, schema optimization (index cleanup with verification — BEFORE removing any index: search all backend files, check schema comments, verify production usage if accessible; if any uncertainty, KEEP with comment), consistency enforcement (error handling, auth, validation patterns), dead code removal (with string-reference search including dynamic imports and bracket notation), file splitting for 300+ line files, post-refactor cleanup (remove unused libraries, verify no `any` types or `@ts-ignore` introduced).

**Teammate 2 — "frontend-component-refactorer"**: React components and pages. Tasks: component deduplication into shared directory, pattern extraction (forms, lists, modals, state components), prop interface cleanup (no `any`, consistent naming), file splitting for 300+ line components, design token compliance (flag hardcoded colors/fonts/spacing, consolidate icon imports via barrel file). Do not create hooks — send hook requirements to Teammate 3.

**Teammate 3 — "hooks-and-logic-refactorer"**: Custom hooks, utilities, types, shared logic. Tasks: hook deduplication (generic parameterized hooks), utility consolidation, type consolidation into shared files, import cleanup (unused imports, path aliases, ordering), dead code removal.

**Teammate 4 — "test-and-structure-refactorer"**: Test quality, E2E tests, project structure. Tasks: test deduplication (shared fixtures), test quality (clear descriptions, single-assertion, Given-When-Then), E2E optimization (journey consolidation, page objects), project structure (naming, no circular deps via `dpdm`, `madge`, or similar), traceability audit. **Test count must be >= baseline after refactoring.**

Each teammate runs verification (`bun run typecheck && bun run test`) after ALL changes and reverts any change that causes test failures.

## Phase 3: Coordination

Monitor progress and facilitate cross-team dependencies:
- Backend extractions affect hook call patterns — notify Teammate 3.
- Frontend component extractions affect hook return types — notify Teammate 3.
- Utility moves affect imports everywhere — notify Teammates 2 and 4.
- For shared-file conflicts: assign priority to the more structural change; other teammate waits.
- After each teammate completes, run `bun run typecheck && bun run test` immediately. If tests fail, notify responsible teammate before others proceed.
- If refactoring moves or renames files, check if any `.claude/rules/` file references the old path in its `paths` frontmatter and update accordingly.

## Phase 4: Integration Verification

After all teammates complete:

1. Run COMPLETE test suite and compare to baseline. Pass count must be >= baseline. Zero regressions. Fix any lint errors introduced by refactoring.
   ```bash
   bun run typecheck
   bun run lint
   bun run build
   bun run test
   bun run test:e2e
   ```
2. If E2E tests lack coverage for critical pages, start dev server and manually verify.
3. Update `ARCHITECTURE.md` if refactoring changed module boundaries. If it doesn't exist, document major changes in the report instead.
4. Generate `./plancasting/_audits/refactoring/report.md` with:
   - **Metrics Before vs After**: Total files / lines, duplicated code eliminated, shared modules created, dead code removed, largest file before vs after, unused indexes removed
   - Changes by category (Duplication, Abstraction, Consistency, Schema, Coupling, Dead code, File structure)
   - Test results (baseline vs post-refactoring, zero regressions required)
   - Remaining technical debt with rationale
   - Recommendations to prevent re-accumulation

> **Stage 6F Handoff**: If schema changes were made, document them in the report under 'Schema Changes'. Stage 6F reads this to regenerate affected seed scripts.

> **Stage 6G Handoff**: If error handling patterns were extracted (e.g., shared `withRetry()`, `handleApiError()`), document them under **'Extracted Error Handling Patterns for Stage 6G'** with file locations and usage. Stage 6G reads this to reuse existing patterns.

## Gate Decision

Include in the report under a `## Gate Decision` heading (6H parses this heading):

- **PASS**: All tests pass, zero regressions, lint errors resolved, code quality metrics improved.
- **CONDITIONAL PASS**: All tests pass, minor refactoring opportunities remain documented.
- **FAIL**: Test regressions introduced, or behavioral changes detected.

### Unfixable Violation Protocol

If a refactoring improvement requires architectural changes beyond scope (e.g., fundamental data model restructuring, major framework migration):
1. Document in `./plancasting/_audits/refactoring/unfixable-violations.md` with severity, description, rationale, estimated effort, and recommended approach.
2. Reference in the main report under 'Deferred Architectural Improvements'.
3. Continue with remaining tasks.

## Phase 5: Shutdown

Request shutdown for all teammates. Verify all modifications are saved and committed.

## Critical Rules

1. never refactor and add features in the same change — refactoring must preserve behavior.
2. never delete a public export without verifying zero external consumers.
3. never refactor code without test coverage — add tests first, then refactor.
4. never remove database indexes without verifying all query patterns including production logs.
5. always commit after each logical refactoring unit for granular rollback.
6. always run the full test suite after every refactoring step, not just at the end.
7. If refactoring reduces test count, it is a regression — investigate.
8. Adding new tests during refactoring is acceptable. Removing tests that validate user-facing behavior is not. Tests validating implementation details may be restructured.
9. Reference Stage 5B output to avoid refactoring incomplete features.
10. If refactoring changes module boundaries, public APIs, or directory structure, update `ARCHITECTURE.md` (if exists).
11. If a refactoring opportunity would require architectural changes beyond scope, document in the report under "Deferred Architectural Improvements" — do not attempt it.

## Cross-Stage References

- Runs AFTER 6A-6C. Do not refactor patterns intentionally introduced by those audits.
- If re-running after a prior 6V pass, run a targeted 6V subset to verify no regressions.
- If deploying refactored code to production, run Stage 7V afterward.
