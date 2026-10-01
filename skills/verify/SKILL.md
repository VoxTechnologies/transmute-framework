---
name: verify
description: >-
  Verifies the running application against PRD screen specs and acceptance criteria in a browser.
  This skill should be used when the user asks to "run visual verification",
  "verify the app against the PRD", "run Stage 6V", "check the running app",
  "verify screens match specs", "run live app verification", "test the running
  application", or "verify acceptance criteria in the browser", or when the
  transmute-pipeline agent reaches Stage 6V of the pipeline.
metadata:
  version: 1.0.0
effort: high
---

# Stage 6V: Visual & Functional Verification

Verify the RUNNING application against every screen specification and acceptance criterion in the PRD by navigating the app in a browser. Lead a multi-agent verification project (teammates are Agent-tool subagents; see the pipeline agent's Execution Model).

Read the detailed guide at `${CLAUDE_SKILL_DIR}/references/verification-detailed-guide.md` for full teammate prompts, failure patterns, and report templates.

Read the scenario generation guide at `${CLAUDE_SKILL_DIR}/references/feature-scenario-generation.md` for the algorithm to build the Feature Scenario Matrix.

## Prerequisites

1. Verify `./plancasting/_launch/readiness-report.md` exists and shows READY. If NOT READY or file missing, STOP -- run Stage 6H first. **Exception — Stage 5V (early runtime check)**: when invoked with `MODE: critical` directly after 5B (alias `/transmuter:cast early-verify`), require `./plancasting/_audits/implementation-completeness/report.md` (PASS or CONDITIONAL PASS) instead of the 6H report, run only the `critical` scope, and title the report "Stage 5V — Early Runtime Check (6V critical scope)". The full 6V run after 6H overwrites it.
2. Create output directories:
   ```bash
   mkdir -p ./plancasting/_audits/visual-verification
   mkdir -p ./screenshots/automated
   mkdir -p ./screenshots/criteria
   mkdir -p ./screenshots/vision
   mkdir -p ./screenshots/visual-verification/baseline
   mkdir -p ./e2e/verification
   ```
3. Verify Playwright browsers are installed:
   ```bash
   bunx playwright install --with-deps chromium
   ```

## Scope Modes

- **`full`** (default) -- All screens in `plancasting/prd/08-screen-specifications.md`. ~30-60 min.
- **`critical`** -- P0/P1 features only. ~15-30 min.
- **`diff`** -- Only screens related to files changed since last verification. ~10-20 min. **Note**: `last-verified-commit.txt` is created at the END of a 6V run, so `diff` mode only works on the second or subsequent run. If the file does not exist, automatically falls back to `full`. **Warning**: diff mode requires a previous 6V report to diff against — do not use for the first 6V run.

**How to specify scope**: Append `MODE: full`, `MODE: critical`, or `MODE: diff` on a new line after pasting the prompt, or as a separate follow-up message. Default is `full`.

**Important**: This stage uses the **FULL** generation mode (all priorities) of the Feature Scenario Matrix. Do not use `critical` or `diff` scope unless explicitly requested by the user.

## Input

- **Running Application**: Dev server (use the dev command from `plancasting/tech-stack.md`)
- **Scenario Generation Guide**: `${CLAUDE_SKILL_DIR}/references/feature-scenario-generation.md`
- **PRD**: `./plancasting/prd/` -- ALL files, especially `02-feature-map-and-prioritization.md`, `04-epics-and-user-stories.md`, `06-user-flows.md`, `07-information-architecture.md`, `08-screen-specifications.md`
- **Tech Stack**: `./plancasting/tech-stack.md`
- **Project Rules**: `./CLAUDE.md`
- **E2E Config**: `./playwright.config.ts`, `./e2e/helpers/`, `./e2e/constants.ts`

Check `./plancasting/tech-stack.md` for the `Session Language` setting. Generate all reports in that language. Code and file names remain in English.

## Stack Adaptation

The examples use Playwright + Next.js + Convex. Adapt to your `plancasting/tech-stack.md`: test directory, test runner, dev server command, data fetching patterns. Replace `npm run` with your project's package manager per `CLAUDE.md`.

## Phase 1: Lead Analysis & Planning

Complete BEFORE spawning teammates:

1. **Read project context**: `./CLAUDE.md`, `./plancasting/tech-stack.md`, `${CLAUDE_SKILL_DIR}/references/feature-scenario-generation.md`, `./playwright.config.ts`, `./e2e/constants.ts`, `./e2e/helpers/`

2. **Generate the Feature Scenario Matrix** following the algorithm in the scenario generation guide:
   - Read ALL PRD sources and extract structured data
   - Read codebase sources (route constants, page files, middleware, auth helpers, schema, layouts)
   - Build the Feature Dependency Graph
   - Generate ALL scenario types: FS-NNN (Feature), AS-NNN (Auth Context), ES-NNN (Entity State), RS-NNN (Role Permission), NS-NNN (Negative)
   - Apply scope filter (full/critical/diff)
   - Cross-reference for coverage gaps -- every screen and route should appear in at least one scenario
   - Save to `./plancasting/_audits/visual-verification/feature-scenario-matrix.md` and gap-fill matrix to `./plancasting/_audits/visual-verification/verification-matrix.md`

3. **Start the application**:
   - Kill any existing process on the dev port: `lsof -ti:3000 | xargs kill 2>/dev/null || true` (Adapt port to your framework's default: Next.js: 3000, Vite/SvelteKit: 5173, Remix: 3000, Astro: 4321)
   - Run the dev server. If BaaS dev server fails non-interactively, set the BaaS URL env var in `.env.local` and run only the frontend dev server.
   - Wait up to 60 seconds. If the server fails to start, ABORT.

4. **Unauthenticated route verification** (BEFORE logging in):
   - Identify all public routes from middleware and PRD
   - Open a fresh browser context (no cookies/localStorage/session)
   - Navigate to EVERY public route -- verify HTTP 200 with correct content
   - Test protected routes without auth -- verify redirect to `/login`
   - Flag ANY public route that incorrectly redirects to login as CRITICAL

5. **Verify test users exist**: Attempt login with credentials from `./e2e/constants.ts`. If login fails, try seed endpoint, auth provider CLI, or UI signup. If all fail, ABORT.

6. **Build Navigation Inventory**: Read route constants, shared layout components, middleware. Compile a Navigation Checklist appended to the verification matrix.

7. **Plan teammate assignments**: Assign separate test user accounts to each teammate to prevent state conflicts.

## Phase 2: Spawn Verification Teammates

Spawn 4 teammates. Teammates 1, 2, and 4 run in parallel. Teammate 3 runs AFTER Teammate 1 completes.

### Teammate 1: "automated-page-verifier"
Systematic page-by-page verification. Tasks: unauthenticated route checks (first), navigation/load verification, component presence, state verification, link integrity crawl, sub-navigation completeness, accessibility quick check, generate Playwright test files.

### Teammate 2: "acceptance-criteria-verifier"
Execute Feature Scenarios and acceptance criteria. Tasks: parse and execute Given/When/Then criteria, generate Playwright tests, cross-feature flow verification, dead route detection, auth redirect verification.

### Teammate 3: "visual-ai-reviewer" (after Teammate 1)
AI Vision review of screenshots at 3 breakpoints (1440px, 768px, 375px). Tasks: collect/take screenshots, visual spec compliance review (layout, component, content, responsive, design consistency), dark mode review.

### Teammate 4: "responsive-and-interaction-verifier"
Interactive behavior and keyboard navigation. Tasks: form/modal/dropdown/tab testing, systematic button action verification, keyboard navigation, responsive functional testing at mobile breakpoints, cross-browser quick check (Chromium, Firefox, WebKit).

## Phase 3: Coordination

- If Teammate 1 finds pages that don't load (HTTP 500, blank), flag as CRITICAL
- Aggregate findings across teammates
- If auth fails for ALL test users, ABORT

## Phase 4: Verification Report

1. Typecheck generated test files: `bun run typecheck`
2. Run generated Playwright tests: `bunx playwright test e2e/verification/ --grep "@verification" --retries=2`
3. Generate report at `./plancasting/_audits/visual-verification/report.md` -- include all result sections (scenario results, page-level results, unauthenticated access, acceptance criteria, visual compliance, navigation/link integrity, button actions, sub-navigation, responsive/interaction, gate decision, failure categorization for 6R routing)
4. Commit generated test files if any
5. Save commit hash: `git rev-parse HEAD > ./plancasting/_audits/visual-verification/last-verified-commit.txt`

## Gate Decision (Dual System)

The gate uses TWO systems -- the final gate is the WORSE of the two:

**Percentage-based system**:
- **PASS**: >90% acceptance criteria pass, all pages load
- **CONDITIONAL PASS**: 80-90% criteria pass
- **FAIL**: <80% criteria pass

**Fixability-based category system** (uses `6V-` prefix to distinguish from 5B):
- **6V-A** (auto-fixable): broken links, dead code, incorrect imports -- 6R fixes automatically
- **6V-B** (semi-auto): stub components, missing loading states -- 6R fixes with effort. Fixable by: adding component logic + local state, wiring existing hooks to components, adding inline handlers. NOT fixable (escalate to C) if it requires: restructuring state management, creating new hooks, changing API contracts, or modifying database schema.
- **6V-C** (human judgment): architectural issues, design decisions -- 6R cannot fix

**Dual-system decision matrix**:

| Percentage | Categories Present | Final Gate | Next Stage |
|---|---|---|---|
| PASS (>90%) | None (zero actionable issues) | PASS | -> 6P/6P-R |
| PASS (>90%) | A/B only | CONDITIONAL PASS | -> 6R -> 6P/6P-R |
| PASS (>90%) | C only | PASS | -> 6P/6P-R (document C for human) |
| PASS (>90%) | Mixed A/B + C | CONDITIONAL PASS | -> 6R -> 6P/6P-R (document remaining C) |
| CONDITIONAL (80-90%) | A/B present | CONDITIONAL PASS | -> 6R -> 6P/6P-R |
| CONDITIONAL (80-90%) | C only | CONDITIONAL PASS | -> 6P/6P-R (document C for human) |
| FAIL (<80%) | Any | FAIL | Manual fix + re-run 6V |

## Flaky Scenario Handling

A **flaky scenario** is a test that fails on the first run but passes on a subsequent re-run without code changes, typically caused by timing issues or external service latency. Retest a failing scenario once. If it passes on retest: mark as "FLAKY -- cause TBD" in the Issues table. In 6V, flaky scenarios are informational (do not count toward gate failure). In 7V (production), flaky scenarios count as FAIL.

## Next Steps

- PASS: skip 6R -> proceed to Stage 6P or 6P-R (Visual Polish or Redesign) -> Deploy -> 7V -> 7D
- CONDITIONAL PASS with 6V-A/B issues: proceed to Stage 6R (Runtime Remediation)
- CONDITIONAL PASS with ONLY 6V-C issues: skip 6R -> proceed to Stage 6P or 6P-R
- FAIL: fix critical issues manually, then re-run Stage 6V

## Phase 5: Shutdown

1. Request shutdown for all teammates
2. Verify all files saved and committed
3. Leave the dev server running for 6R or 6P/6P-R

## Critical Rules

1. always start the dev server and verify accessibility before spawning teammates. ABORT if it fails within 60 seconds.
2. never skip the AI vision review (Teammate 3).
3. never mark a page as PASS if it has console ERRORS. Console WARNINGS from third-party libraries do not constitute FAIL.
4. always test with seeded data.
5. always take screenshots on failure.
6. always map findings to PRD identifiers (SC-NNN, US-NNN, FEAT-NNN).
7. always generate Playwright test files even when using direct browser interaction.
8. This stage FINDS issues -- it does not fix them. Fixes happen in Stage 6R.
9. never let one teammate's actions corrupt state for another.
10. For eventually-consistent backends, use `expect.poll()` or retry assertions (up to 10s timeout).
11. always verify test user seeding BEFORE spawning teammates.
12. always crawl links from shared layouts (sidebar, header, footer, mobile nav).
13. always test navigation at BOTH desktop and mobile viewports.
14. always click buttons and verify their action -- not just DOM presence.
15. always test auth middleware redirects for ALL public routes.
16. always test public routes from a FRESH unauthenticated browser context BEFORE logging in.

## Output Specification

| Artifact | Path |
|----------|------|
| Feature Scenario Matrix | `./plancasting/_audits/visual-verification/feature-scenario-matrix.md` |
| Verification Matrix (gap-fill) | `./plancasting/_audits/visual-verification/verification-matrix.md` |
| Verification Report | `./plancasting/_audits/visual-verification/report.md` |
| Last Verified Commit | `./plancasting/_audits/visual-verification/last-verified-commit.txt` |
| Baseline Screenshots | `./screenshots/visual-verification/baseline/` |
| Playwright Test Files | `e2e/verification/*.spec.ts` |
| Screenshots | `./screenshots/automated/`, `./screenshots/criteria/`, `./screenshots/vision/` |
