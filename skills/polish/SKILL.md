---
name: polish
description: >-
  Applies visual polish and UI refinements to elevate aesthetic quality before deployment.
  This skill should be used when the user asks to "run visual polish",
  "polish the UI", "run Stage 6P", "fix visual defects", "enhance the UI",
  "improve the app aesthetics", "run UI refinement", "apply visual
  enhancements", or "fix contrast and layout issues", or when the
  transmute-pipeline agent reaches Stage 6P of the pipeline.
metadata:
  version: 1.0.0
effort: high
---

# Stage 6P: Visual Polish & UI Refinement

## Why This Stage Exists

After Stage 5 implementation and Stage 6 quality passes, the product is functionally complete but often looks "functional rather than polished." Components work correctly but lack the visual refinement that distinguishes a production product from a prototype — inconsistent spacing, missing hover states, contrast issues, and generic typography. This stage transforms a functionally correct app into a visually distinctive product. It runs AFTER 6R (all mechanical issues fixed) and BEFORE deployment.

Analyze the RUNNING application's visual quality, identify UI issues (visibility, layout, typography, spacing, motion, responsiveness), and automatically refine the frontend to production-grade aesthetic quality. Lead a multi-agent visual polish project (teammates are Agent-tool subagents; see the pipeline agent's Execution Model).

**Mutual Exclusivity**: This stage (6P) and Stage 6P-R (Frontend Design Elevation) are alternatives — run exactly ONE, not both. If 6P has already been run and you want to switch to 6P-R, revert 6P changes first (`git revert` the 6P commit). See CLAUDE.md for details.

**Relationship to `frontend-design` skill**: If available, the `frontend-design` skill provides aesthetic guidance and design direction. Polish uses it for enhancement decisions but never replaces the project's existing design system. The lead invokes the skill and saves output; teammates read the saved output -- they do not invoke the skill themselves.

**Category System Note**: This stage uses DIFFERENT categories than 6V/6R. 6P categories: O (objective defects), E (enhancements), D (design elevation). 6V/6R categories: A/B (agent-fixable), C (human judgment). Do not confuse the two systems when reading 6V/6R reports.

Read the detailed guide at `${CLAUDE_SKILL_DIR}/references/polish-detailed-guide.md` for full refinement categories, teammate prompts, design system integration, and report templates.

## Prerequisites

0. **Check if 6P-R was run instead**: If `./plancasting/_audits/visual-polish/design-plan.md` exists, check 6P-R completion status:
   - If `progress.md` in the same directory shows all phases completed -- 6P-R is done. Skip this stage (6P).
   - If `progress.md` is missing or shows incomplete phases -- 6P-R failed mid-execution. Do not proceed -- request operator approval before continuing.
   - If `design-plan.md` does not exist -- 6P-R was not run. Proceed with 6P.

1. **`frontend-design` plugin** (recommended, has fallback): Check if `/mnt/skills/public/frontend-design/SKILL.md` exists. If not, use project's existing design patterns instead. Fallback: use CLAUDE.md "Design & Visual Identity" (Part 1), `src/styles/design-tokens.ts`, Tailwind configuration, and PRD screen specifications. Focus on Category O/E only; skip Category D.

2. **Stage 6R must PASS or CONDITIONAL PASS** (if 6R was required):
   - **If 6R report exists**: check Gate Decision. FAIL -- STOP, return to 6R. PASS or CONDITIONAL PASS -- proceed.
   - **If 6R report does not exist**: check 6V report:
     - 6V PASS -- proceed (6R correctly skipped)
     - 6V FAIL -- STOP (fix issues manually and re-run 6V first)
     - 6V CONDITIONAL PASS with only 6V-C issues -- proceed (6R cannot fix 6V-C)
     - 6V CONDITIONAL PASS with 6V-A or 6V-B issues -- STOP (run 6R first)
   - **If NEITHER report exists**: verify with operator that prior stages were intentionally skipped.
   - **Important**: If 6R ran, it may have updated the 6V report's gate decision. Re-read the 6V report to get the CURRENT gate status.

3. **Dev server**: This stage needs the live application. The lead starts it in Phase 1.

4. Create output directories:
   ```bash
   mkdir -p ./plancasting/_audits/visual-polish
   mkdir -p ./screenshots/visual-polish/before
   mkdir -p ./screenshots/visual-polish/after
   ```

## Input

- **6V/6R Screenshots**: `./screenshots/`
- **6V Report**: `./plancasting/_audits/visual-verification/report.md`
- **6R Report**: `./plancasting/_audits/runtime-remediation/report.md`
- **Design System**: Identified from `plancasting/tech-stack.md`
- **Codebase**: `./src/` (frontend components, styles, layouts)
- **PRD Screen Specs**: `./plancasting/prd/08-screen-specifications.md`
- **Tech Stack**: `./plancasting/tech-stack.md`
- **Project Rules**: `./CLAUDE.md`
- **E2E Constants**: `./e2e/constants.ts`

Check `./plancasting/tech-stack.md` for the `Session Language` setting. Generate all reports in that language. Code and file names remain in English.

## Stack Adaptation

Adapt to your `plancasting/tech-stack.md`: CSS framework, UI library, component directory, design token location, animation library. Replace `bun run` with your project's package manager per `CLAUDE.md`.

**Browser Tools**: This stage uses Playwright MCP tools (`browser_navigate`, `browser_resize`, `browser_take_screenshot`, `browser_console_messages`, `browser_fill_form`, `browser_click`, `browser_type`, `browser_evaluate`). Adapt tool names if using a different browser automation tool.

## Refinement Categories

### Category O: Objective Defects (Auto-Fix)
Issues with a clear right/wrong answer: WCAG contrast failures, invisible text, layout overflow, clipped content, skeleton mismatch, missing focus rings, z-index errors, dark mode unstyled sections, broken images, small touch targets. must fix all.

**Category boundary guideline**: If the feature is BROKEN or INACCESSIBLE (violates standards, prevents functionality), it's Category O. If it WORKS but FEELS UNPOLISHED (lacks feedback, delight, or visual consistency), it's Category E. Examples -- Category O: missing focus ring (WCAG violation), layout overflow (content hidden). Category E: missing hover state (button works but lacks feedback), no page entry animation.

### Category E: Enhancement (Pattern-Based, Apply Where Feasible)
Category E is discretionary — skip if the enhancement conflicts with the design system, has negligible visual impact, or risks regression. Follow established codebase patterns: missing hover states, missing page transitions, inconsistent spacing, weak empty states (enhance with icon or CTA using existing design assets -- do not source new illustrations; document as Category D if none exist), flat typography hierarchy, missing card depth, plain loading states, inconsistent form inputs. Apply then verify visually.

### Category D: Design Elevation (Document Only)
Subjective improvements for human review: font pairing, color palette, hero visual impact, illustration style, micro-interaction opportunities, overall aesthetic direction. Document as suggestions -- do not apply. Category D suggestions are for POST-LAUNCH review and do not block Stage 7 deployment.

## Phase 1: Lead Visual Audit

Complete BEFORE spawning teammates:

1. **Read project context**: `./CLAUDE.md`, `./plancasting/tech-stack.md`, `./plancasting/prd/08-screen-specifications.md`, 6V/6R reports

2. **Identify the design system**: Search in order -- design tokens file, tailwind config, global CSS, plancasting/tech-stack.md design direction, theme config, font imports, animation patterns. **Output a Design System Summary** documenting: color tokens, spacing scale, typography scale, shadow tokens, border-radius tokens, animation patterns, font families, and theme variants (dark mode). This summary is required for teammate reference.

3. **Establish validation baseline**: `bun run typecheck`, `bun run lint`, `bun run test`

4. **Start the application**: Check if running, start if needed. BaaS caveat: set client URL env var manually if BaaS dev server fails. ABORT if server fails to start.

5. **Screenshot key screens at 3 breakpoints** (1440, 768, 375):
   - Public pages first (no auth)
   - Authenticated pages (log in with test user from `./e2e/constants.ts`)
   - Dark mode (if supported)
   - Reuse 6V screenshots if available and recent
   - **Before/after screenshot requirement**: Save all pre-polish screenshots to `./screenshots/visual-polish/before/`. These are REQUIRED for comparison in the final report.

6. **AI Vision Analysis**: For each screenshot, check for Category O (objective), Category E (enhancement), and Category D (elevation) issues.

7. **Create Visual Polish Plan** at `./plancasting/_audits/visual-polish/plan.md` with **design system summary** (required output), triage, issue tables, and file assignments.

8. **Invoke `frontend-design` skill** (if available): Generate enhancement guidelines. Save to `./plancasting/_audits/visual-polish/design-guidelines.md`. If unavailable, teammates use project's existing design patterns.

9. **Assign teammates and prevent file conflicts**: Document file assignments in plan. NO two teammates may modify the same file.

**Scope Prioritization**: Focus on HIGH-IMPACT pages first: (1) landing/marketing pages, (2) auth pages (signup/login), (3) primary dashboard, (4) core feature pages (P0/P1). Polish secondary pages only after key pages pass visual review. Target: 10-15 key screens.

## Phase 2: Spawn Teammates

Teammates 1 and 2 run in **parallel**. Teammate 3 runs **AFTER** both complete.

### Teammate 1: "objective-defect-fixer"
Fix ALL Category O issues. Use ONLY existing design tokens. **Exception**: 6P may modify `design-tokens.ts` ONLY for: (a) adding a missing size to an existing scale, (b) correcting a token value to meet WCAG AA contrast, or (c) fixing a broken variable reference. Do not change design direction. Prefer adjusting text color over background for contrast. Include dark mode variants. never change functional behavior. Verify visually with Playwright. Run typecheck + lint after each batch.

### Teammate 2: "enhancement-applier"
Apply ALL Category E enhancements following `design-guidelines.md` (or existing design patterns if unavailable). Group similar enhancements. Focus on HIGH-IMPACT moments for animation. Maximum 3 animations per page. Work within existing type scale. Verify with before/after screenshots.

### Teammate 3: "responsive-cross-theme-verifier" (after 1+2)
Re-verify ALL modified screens at 1440px, 768px, 375px plus dark mode. Flag regressions immediately (do not fix). Compare with before screenshots. Test mobile touch interactions. Verify performance not degraded. Focus on HIGHEST-IMPACT screens first: (1) landing/home, (2) dashboard, (3) primary feature, (4) auth pages, (5) settings/billing.

## Phase 3: Integration & Report

1. Collect teammate results. Check for regressions from Teammate 3.
2. Fix regressions (a regression is a NEGATIVE SIDE EFFECT: visual breakage of unrelated elements, functional breakage, accessibility breakage, or performance degradation -- intentional enhancements are not regressions): revert specific change, re-apply with responsive-safe approach, re-verify. **Max iteration guard**: If regressions persist after 2 revert-and-reapply cycles, document as known limitation.
3. Run full validation: `bun run typecheck`, `bun run lint`, `bun run test`. ALL must pass.
4. Generate Category D design brief using `frontend-design` skill (if available). Save as `./plancasting/_audits/visual-polish/design-elevation-brief.md`. Category D is for HUMAN REVIEW ONLY -- do not implement.
5. Generate Visual Polish Report at `./plancasting/_audits/visual-polish/report.md`.
6. Save comparison screenshots to `./screenshots/visual-polish/before/` and `./screenshots/visual-polish/after/`. **Before/after screenshots are required** for every change in the report. Note: Screenshot directories are for local reference. Add to `.gitignore` -- do not commit large binary files.

## Phase 4: Shutdown

1. Commit:
   ```bash
   git add src/ plancasting/_audits/visual-polish/
   git commit -m "style: Stage 6P visual polish -- [n] defects fixed, [n] enhancements applied"
   ```
2. Save commit hash:
   ```bash
   git rev-parse HEAD > ./plancasting/_audits/visual-polish/last-polished-commit.txt
   ```
3. Request shutdown for all teammates.
4. Stop dev server if started by this stage.

## Gate Decision

- **PASS**: All Category O fixed, Category E enhancements applied where feasible (E is discretionary — skip if an enhancement conflicts with the design system, has negligible visual impact, or risks regression), no regressions -- ready for Deploy
- **CONDITIONAL PASS**: All critical fixed + Category D brief for optional elevation -- ready for Deploy
- **FAIL**: Regressions remain or validation fails -- investigate before Deploy. Consider switching to 6P-R for full design elevation if 6P is insufficient.

## Next Steps

- PASS or CONDITIONAL PASS: proceed to Stage 7 (Deploy) -> 7V (Production Smoke) -> 7D (User Guide)
- FAIL: investigate regressions, fix, revalidate. Do not deploy until 6P PASS or CONDITIONAL PASS.
- If visual quality needs a full overhaul rather than polish, run Stage 6P-R instead (revert any 6P changes first with `git revert`).

## Critical Rules

1. never change functional behavior -- only visual presentation. If a fix would alter routing, data flow, API calls, auth, or form submission logic, it is OUT OF SCOPE.
2. never replace design system components with custom implementations. Work within the UI library's API. Use CSS overrides or wrapper components, not replacements.
3. never introduce new fonts without human approval (Category D).
4. never introduce new dependencies without checking `package.json`. Use CSS-only animations if no animation library is installed.
5. always take before/after screenshots for every change.
6. always run validation (typecheck + lint + test) after fixes.
7. always work at all 3 breakpoints (1440, 768, 375).
8. Teammate 3 scope management: focus on HIGHEST-IMPACT screens first in this priority order: (1) landing/home, (2) dashboard, (3) primary feature, (4) auth pages, (5) settings/billing. Verify each at all 3 breakpoints + dark mode. Mark unverified screens as "SPOT-CHECK ONLY".
9. always respect dark mode pattern -- every color change needs a dark mode variant. If the project doesn't support dark mode, don't add it.
10. Category O before Category E. Fix defects first, then enhance.
11. The `frontend-design` skill guides INTENT, not implementation. Translate aesthetic vision to design system tokens.
12. Maximum 3 animation additions per page. Restraint is elegance.
13. AVOID modifying shared UI primitives directly unless fixing Category O or applying global Category E. Prefer page-level or layout-level overrides for page-specific changes.
14. If 6R report shows FAIL, STOP. Return to 6R first.
15. WCAG AA contrast ratios are non-negotiable (4.5:1 normal text, 3:1 large text).
16. always preserve accessibility -- focus rings, aria labels, semantic HTML, keyboard nav. If an enhancement would compromise any of these, skip it.
17. The lead invokes `/frontend-design`, teammates read the output. Teammates do not invoke the skill themselves.
18. Teammates 1 and 2 run in parallel, Teammate 3 runs AFTER both complete.
19. ALL Playwright browser interactions require the dev server to be running. If it crashes, the lead must restart it.
20. Test user login required for authenticated page screenshots.
21. always check for console errors during screenshots. Log any errors in the report.
22. Ensure NO two teammates modify the same file.

## Output Specification

| Artifact | Path |
|----------|------|
| Visual Polish Plan | `./plancasting/_audits/visual-polish/plan.md` |
| Design Guidelines | `./plancasting/_audits/visual-polish/design-guidelines.md` |
| Design Elevation Brief | `./plancasting/_audits/visual-polish/design-elevation-brief.md` |
| Visual Polish Report | `./plancasting/_audits/visual-polish/report.md` |
| Last Polished Commit | `./plancasting/_audits/visual-polish/last-polished-commit.txt` |
| Before Screenshots | `./screenshots/visual-polish/before/` |
| After Screenshots | `./screenshots/visual-polish/after/` |
