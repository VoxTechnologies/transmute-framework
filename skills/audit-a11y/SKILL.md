---
name: audit-a11y
description: >-
  Performs a multi-agent WCAG accessibility audit of the frontend codebase.
  This skill should be used when the user asks to "audit accessibility",
  "check WCAG compliance", "run an accessibility review", "a11y audit",
  "check screen reader support", "fix accessibility issues",
  or "verify keyboard navigation",
  or when the transmute-pipeline agent reaches Stage 6B of the pipeline.
metadata:
  version: 1.0.0
effort: medium
---

# Accessibility Audit — Stage 6B

Read the detailed guide at `${CLAUDE_SKILL_DIR}/references/audit-a11y-detailed-guide.md` for the complete audit procedures, teammate spawn prompts, WCAG checklist patterns, and report templates.

Lead a multi-agent accessibility audit of the complete frontend codebase against BRD/PRD WCAG requirements. Identify violations and fix them.

**Stage Sequence** (recommended ordering): Stage 5B → (6A ‖ **6B (this stage)** ‖ 6C) → 6E → 6F → 6G → 6D → 6H → 6V → 6R → 6P/6P-R → 7 (Deploy). Note: 6A, 6B, and 6C run **in parallel** (each in a separate session). If running in parallel, commit 6A changes as soon as 6A completes to avoid config file conflicts — see CLAUDE.md § "Stage 6 ordering".

## Prerequisite Checks

Before any audit work, verify:

1. Check that `./plancasting/_audits/implementation-completeness/report.md` exists and shows PASS or CONDITIONAL PASS. If missing, STOP: "Stage 5B report not found — run Stage 5B before starting Stage 6 audits." (Override: if the operator explicitly confirms 5B was intentionally skipped, proceed with a WARN in the report noting unverified implementation completeness.)
2. If 5B shows FAIL, STOP — the codebase has unresolved implementation gaps that must be fixed before accessibility auditing. If CONDITIONAL PASS, read documented Category C issues and skip accessibility auditing for those incomplete features.
3. If `./plancasting/_audits/security/report.md` (6A) exists, read it to understand security changes that should not be undone during accessibility fixes (e.g., CSP headers, CORS configuration).
4. If `./plancasting/_audits/performance/report.md` (6C) exists, read it to understand performance optimizations (e.g., font loading, animation patterns, lazy loading) that should not be regressed.
5. Read `./CLAUDE.md` and `./plancasting/tech-stack.md` for project conventions.
6. Read relevant PRD sections for implementation context.

## Inputs

- **Codebase**: `./src/` (adapt paths per tech stack)
- **Tech Stack**: `./plancasting/tech-stack.md`
- **BRD Accessibility Requirements**: `./plancasting/brd/08-non-functional-requirements.md` (WCAG section). If not found, search: `grep -rlE "WCAG|accessibility" ./plancasting/brd/`
- **BRD UX Requirements**: `./plancasting/brd/11-user-experience-requirements.md`
- **PRD Screen Specs**: `./plancasting/prd/08-screen-specifications.md` (accessibility annotations)
- **PRD Interaction Patterns**: `./plancasting/prd/09-interaction-patterns.md`
- **Project Rules**: `./CLAUDE.md`
- **Implementation Completeness**: `./plancasting/_audits/implementation-completeness/report.md`

Check `./plancasting/tech-stack.md` for the `Session Language` setting. Generate reports in that language. Keep code and file names in English.

## Stack Adaptation

Adapt references to your actual stack:
- `src/app/` becomes your pages/routes directory
- `src/components/` becomes your component directory
- React Aria patterns become your accessibility library's patterns
- `bun run` becomes your package manager command

**Component Library Rule**: If using a component library with built-in accessibility (React Aria, HeadlessUI, Radix, shadcn/ui, Untitled UI), do not add redundant ARIA attributes that conflict with the library's built-in handling — this can actually break accessibility. Check the library's documentation before adding ARIA attributes to library-provided components.

## Known Failure Patterns

1. **Redundant ARIA on library components**: Do not add `aria-label`, `role`, or `aria-expanded` to components that already handle these via their accessibility library. Always check library handling first.
2. **`aria-hidden="true"` to suppress violations**: Never hide elements from the accessibility tree instead of fixing the issue. Only use for genuinely decorative elements.
3. **`role="button"` on div**: Always prefer semantic HTML (`<button>`) over ARIA roles.
4. **Inconsistent focus styles**: Always use the project's established focus ring pattern from CLAUDE.md. Verify the focus ring token resolves correctly in your Tailwind version (Tailwind v4 uses CSS-first configuration).
5. **Layout breaks from semantic changes**: Verify visual appearance after changing `<div>` to `<section>` or `<nav>`.
6. **Missing `lang` attribute**: Always check `<html lang="...">` (WCAG 3.1.1 Level A).

## Phase 1: Analysis and Planning

Complete before spawning teammates:

1. Read `./CLAUDE.md`, `./plancasting/tech-stack.md`, and BRD/PRD accessibility requirements. Check BOTH `./plancasting/brd/08-non-functional-requirements.md` (or grep fallback) AND `prd/15-non-functional-specifications.md` for WCAG version and conformance level. If they conflict, PRD takes precedence. Determine:
   - **WCAG version**: 2.2 (preferred, released Oct 2023), 2.1, or 2.0. If not specified, default to WCAG 2.2.
   - **Conformance level**: A, AA, or AAA. If not specified, default to AA.
   If targeting 2.1, still audit 2.2 criteria (e.g., 2.5.8 Target Size Minimum) as forward-looking best practices.
2. Build an **Accessibility Checklist** organized by WCAG principle (Perceivable, Operable, Understandable, Robust).
3. Write `./plancasting/_audits/accessibility/checklist.md` with the full checklist.
4. Create a task list for all teammates with dependency tracking.

## Phase 2: Spawn Audit Teammates

Spawn 3 parallel teammates. Each prompt must include the accessibility checklist and target WCAG level. Replace directory paths with your project's actual paths per Stack Adaptation.

### Teammate 1: semantic-structure-auditor

Scope: Semantic HTML, headings, landmarks, document structure.

- **Heading hierarchy**: Scan every page. Verify one h1 per page (or `aria-label` on main landmark). Verify sequential heading levels (h1 to h2 to h3). Sibling sections may restart hierarchy. Verify headings use semantic elements, not styled divs.
- **Landmarks**: Verify every page has exactly one `<main>`, `<nav>` with `aria-label` for each navigation region, `<header>` and `<footer>` where appropriate, and no significant content outside landmarks.
- **Semantic HTML**: Flag `<div>`/`<span>` where semantic elements should be used (`<button>`, `<a>`, `<nav>`, `<article>`, `<section>`, `<form>`, `<table>`, `<ul>`/`<ol>`/`<li>`). Verify lists, tables, links, and buttons use correct elements.
- Fix each violation found.

### Teammate 2: interactive-elements-auditor

Scope: Keyboard navigation, focus management, interactive components.

- **Keyboard navigation**: Verify all interactive elements are Tab-reachable (and Shift+Tab for reverse). Verify custom components follow correct keyboard patterns (dropdowns: arrow keys + Enter/Space/Escape; modals: focus trap + Escape + focus return; tabs: arrow keys between tabs, Tab to content). Flag onClick without onKeyDown. Flag tabIndex > 0.
- **Focus management**: Verify visible focus on all interactive elements (no `outline: none` without replacement). Verify logical focus movement after dynamic content changes (modal open, toast appear, route change). Verify skip-to-main-content link exists.
- **ARIA on interactives**: Verify buttons have accessible names. Verify icon-only buttons have `aria-label`. Verify toggle buttons use `aria-pressed`/`aria-expanded`. Verify form inputs have associated labels (`<label htmlFor>` or `aria-label`). Verify error states use `aria-live`/`aria-describedby`. Verify loading states use `aria-live="polite"`/`role="status"`.
- Fix each issue found.

### Teammate 3: content-and-media-auditor

Scope: Text alternatives, color contrast, responsive accessibility.

- **Text alternatives**: Verify all `<img>` have meaningful alt text (or `alt=""` for decorative). Verify SVG icons have `aria-hidden="true"` or accessible labels. Verify video/audio have captions/transcripts.
- **Color and contrast**: Extract actual hex/RGB values from design tokens or CSS variable definitions — static Tailwind class analysis alone is insufficient for computed colors. Use automated contrast checking tools (axe-core, wcag-contrast-verifier) as the primary method. Manual calculation when needed: relative luminance L = 0.2126R + 0.7152G + 0.0722B (after sRGB linearization); contrast ratio = (L1 + 0.05) / (L2 + 0.05). Target: >= 4.5:1 normal text, >= 3:1 large text (WCAG AA). If dark mode exists, verify both themes pass. Verify information is not conveyed by color alone.
- **Responsive accessibility**: Verify readability at 200% zoom without horizontal scrolling. Verify touch target minimum sizes (WCAG 2.2 AA: 24x24px; WCAG 2.1 AAA: 44x44px; mobile-first: 44x44px recommended). Verify no content hidden at different breakpoints.
- **Empty and error states**: Verify empty states have descriptive text. Verify error messages use `aria-describedby`. Verify form validation errors are announced.
- **Motion sensitivity** (WCAG 2.3.1 Level A, 2.3.3 Level AAA): Check all animation types (CSS transitions, CSS animations, JS-driven, animated SVGs). Verify `@media (prefers-reduced-motion: reduce)` is used. For JS animations verify `matchMedia` check. Verify no auto-playing animations without control. Verify parallax effects respect `prefers-reduced-motion`. Verify `scroll-behavior: smooth` is wrapped in a `prefers-reduced-motion: no-preference` media query.
- **Language** (WCAG 3.1.1, 3.1.2): Verify `<html lang="...">` is set correctly. Verify `dir` attribute for RTL if applicable.
- Fix each issue found.

## Unfixable Violation Protocol

When a violation cannot be fixed without architectural changes:

1. Document the full conflict with evidence.
2. Mark as **REQUIRES HUMAN DECISION**.
3. Include recommended approach and estimated effort.
4. **If WCAG Level A**: mark CRITICAL and flag as potential launch blocker — Level A is the minimum legal compliance level in most jurisdictions.
5. Record unfixable Level A violations in `./plancasting/_audits/accessibility/unfixable-violations.md` AND summarize in report.md under "Blocking Issues".
6. Continue with remaining fixable violations.

## Phase 3: Coordination

- If semantic-structure-auditor changes a div to a button, notify interactive-elements-auditor for keyboard handler review.
- If content-and-media-auditor finds contrast issues, notify semantic-structure-auditor for landmark styling adjustments.
- Resolve conflicts when multiple teammates modify the same component.

## Phase 4: Automated Testing and Report

1. Install and run axe-core automated tests AFTER all teammates complete manual audits — axe tests serve as final verification, not the primary audit. Install the appropriate package for your E2E framework (`@axe-core/playwright`, `cypress-axe`, or `@axe-core/webdriverio`). Check `plancasting/tech-stack.md` and `CLAUDE.md` for the project's E2E framework. If installation fails, proceed with manual review and document the limitation.
2. Check for an existing accessibility test file before creating one. If none exists, create `e2e/accessibility.spec.ts`. Run axe on every page and report violations.
3. Run accessibility tests: `bun run test:e2e -- e2e/accessibility.spec.ts`
4. Run the full test suite: `bun run typecheck`, `bun run lint`, `bun run build`, `bun run test`, `bun run test:e2e`
5. Generate `./plancasting/_audits/accessibility/report.md` containing:
   - WCAG conformance level achieved
   - Violations by principle (Perceivable/Operable/Understandable/Robust) and severity
   - Fixes applied with code references
   - Automated test results (axe-core)
   - Remaining issues requiring manual testing (screen reader, cognitive review)
   - **Scope note**: Screen reader testing (with NVDA, JAWS, or VoiceOver) is not in scope for 6B — it is a runtime verification done in Stage 6V. Stage 6B focuses on code-level accessibility.
   - BRD NFR accessibility compliance matrix
6. Include a **Gate Decision** under a `## Gate Decision` heading (6H parses this heading):
   - **PASS**: No Level A violations; all Level AA violations fixed or verified as false positives
   - **CONDITIONAL PASS**: All Level A violations fixed; remaining Level AA issues documented as requiring manual verification (e.g., screen reader testing)
   - **FAIL**: Level A violations remain unresolved; document in `./plancasting/_audits/accessibility/unfixable-violations.md` and escalate to Stage 6H as a launch blocker
7. Output summary: total violations found, total fixed, automated test pass rate.

## Phase 5: Shutdown

1. Request shutdown for all teammates.
2. Verify all file modifications are saved and committed.

## Critical Rules

1. always prefer semantic HTML over ARIA roles (`<button>` over `<div role="button">`).
2. never add `aria-hidden="true"` to suppress axe violations — fix the underlying issue.
3. never add ARIA attributes that conflict with your component library's built-in accessibility.
4. always use the project's focus ring convention from CLAUDE.md. If unspecified, define one and document it.
5. always verify visual layout is preserved after semantic HTML changes.
6. always check `<html lang="...">` matches the session language.
7. always verify `prefers-reduced-motion` is respected for animations.
8. always run the full test suite after changes.
9. Use commands from CLAUDE.md for testing.
10. Reference Stage 5B output to identify incomplete features — skip auditing them entirely. Calculate compliance percentages based on audited features only (e.g., "Audited 12/15 features; 3 skipped as incomplete per Stage 5B").
