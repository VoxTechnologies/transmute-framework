---
name: redesign
description: >-
  Performs a comprehensive frontend design elevation with interactive design discovery.
  This skill should be used when the user asks to "redesign the frontend",
  "run a design overhaul", "rebrand the UI", "run Stage 6P-R",
  "new visual identity", "elevate the frontend design",
  "run frontend redesign", "design elevation",
  or "replace the generic AI look",
  or when the transmute-pipeline agent reaches Stage 6P-R of the pipeline.
metadata:
  version: 1.1.0
effort: high
---

# Stage 6P-R: Frontend Design Elevation (Interactive Redesign)

Unlike the standard Stage 6P (visual polish — which fixes defects within an existing design system), this stage performs a FULL design elevation: collecting project context interactively, studying reference products, extracting Figma design tokens, making deliberate design decisions with the user, and implementing a cohesive visual overhaul.

Read the detailed guide at `${CLAUDE_SKILL_DIR}/references/redesign-detailed-guide.md` for full phases, anti-slop patterns, component matrices, review procedures, and report templates.

## When to Use This vs. Standard 6P

| Scenario | Use |
|---|---|
| App looks functional but needs contrast fixes, hover states, spacing consistency | Standard 6P (polish skill) |
| App looks like generic AI-generated SaaS and needs a distinctive visual identity | **This skill** (redesign) |
| Rebranding or major design direction change | **This skill** |
| First-time design system establishment | **This skill** |
| Post-launch design refresh based on user feedback | **This skill** |

## Pipeline Position

**Stage 6P-R** occupies the same pipeline slot as 6P (after all Stage 6 quality passes, before Stage 7 deployment). It is an ALTERNATIVE to standard 6P, not an addition. Run one or the other, not both. If 6P has already been run and you want to switch to 6P-R, revert 6P changes first (`git revert` the 6P commit).

**Mutual Exclusion with 6P**: 6P and 6P-R are mutually exclusive. To switch from 6P to 6P-R: (1) commit all current work including 6P changes, (2) revert the 6P commit with `git revert <6P-commit-hash>`, (3) Start a new session and run 6P-R.

**Stage Sequence**: ... → 6V → [6R — only if 6V found 6V-A/B issues] → **6P-R** → 7 (Deploy) → 7V → 7D → 8 / 9

## Prerequisites

1. **Application must be fully built and functional.** Stage 5 complete, Stage 5B audit passed. This stage changes ONLY visual presentation — never functional behavior.

2. **Stage 6V/6R should be complete** (if applicable):
   - If 6R report exists: must show PASS or CONDITIONAL PASS
   - If only 6V report exists: must show PASS or CONDITIONAL PASS with only 6V-C issues (6R correctly skipped — 6R cannot fix human-judgment issues)
   - If 6V shows CONDITIONAL PASS with 6V-A/6V-B issues: STOP — run 6R first
   - If neither exists: verify with operator that prior stages were intentionally skipped

3. **Browser automation tools available**: Playwright MCP tools required (browser_navigate, browser_resize, browser_take_screenshot, browser_fill_form, browser_click, browser_console_messages, browser_snapshot, browser_evaluate).

4. **`frontend-design` skill recommended**: Check if `/mnt/skills/public/frontend-design/SKILL.md` exists. If available, use it for design decisions. If not, use the anti-AI-slop patterns in the detailed guide as the design authority.

5. **Output directories**:
   ```bash
   mkdir -p ./plancasting/_audits/visual-polish
   mkdir -p ./screenshots/visual-polish/before
   mkdir -p ./screenshots/visual-polish/after
   mkdir -p ./screenshots/visual-polish/references
   ```

## Known Failure Patterns

1. **Replacing UI library components wholesale** — breaks accessibility; use library's component API instead
2. **CSS specificity wars** — use library's theming API, not raw overrides
3. **Breaking existing dark mode** — always add both light and dark variants
4. **Animation performance regression** — only animate `transform` and `opacity`
5. **Font loading FOUT/FOIT** — use `next/font` with `display: swap`
6. **Font not available on Google Fonts** — verify availability before configuring; Fontshare fonts need `next/font/local`
7. **Overzealous scope** — focus on 10-15 high-impact pages, not 50+ components
8. **Silent design deviation** — approved plan is a contract; deviations require user approval
9. **Credentials in committed files** — reference source, never write raw values
10. **Old token remnants** — grep for hardcoded hex values after updating tokens
11. **Hybrid theme `setTheme()` persists to localStorage** — use CSS `prefers-color-scheme` instead
12. **Hybrid theme stale localStorage** — include migration step for returning users
13. **Docs screenshots saved to wrong path** — grep docs for actual image path before capturing
14. **Docs config colors not updated** — update docs config in SAME commit as accent change

## Recovery & Resume

**Progress tracking**: After each major step, update `./plancasting/_audits/visual-polish/progress.md` with checkbox entries for all phases and steps.

**Recovery hierarchy** (check in order, stop at first match):
1. If `progress.md` shows all phases complete → stage is done, skip to shutdown
2. If `progress.md` shows incomplete phase X: X ≤ 2 → re-run interactive phases; X ≥ 3 → continue from next incomplete step
3. If `progress.md` missing but `context.md` exists → assume Phase 1 completed, continue from Phase 2
4. If neither exists → restart from Phase 0

## Input

- **Frontend code**: `./src/`
- **Tech stack**: `./plancasting/tech-stack.md`
- **Screen specs**: `./plancasting/prd/08-screen-specifications.md`
- **Project rules**: `./CLAUDE.md`
- **Test credentials**: `./e2e/constants.ts`
- **6V/6R reports**: `./plancasting/_audits/visual-verification/report.md`, `./plancasting/_audits/runtime-remediation/report.md`

Check `./plancasting/tech-stack.md` for the `Session Language` setting. Generate all reports in that language. Code and file names remain in English.

## Stack Adaptation

This skill is framework-agnostic and design-library-agnostic. Adapt to your `plancasting/tech-stack.md`: CSS framework, UI library, component directory, design token location, animation library, font loading strategy. Replace `bun run` with your project's package manager per `CLAUDE.md`.

## Phase 0: Interactive Project Context Collection (User Input Required)

Collect ALL context BEFORE any design work. Ask each question ONE AT A TIME.

**Fast-path option**: After presenting scan results, offer batch mode for experienced users.

1. **Step 0.1 — Automated Project Scan**: Read CLAUDE.md and tech-stack.md, scan framework, CSS, component library, fonts, theme support, page inventory, design tokens, existing design direction. Present results.
2. **Step 0.2 — Primary Brand Color**: Ask for hex code or direction
3. **Step 0.3 — Current App Screenshots**: Capture or receive current state
4. **Step 0.4 — Reference Product URLs**: Study 1-3 admired products visually
5. **Step 0.5 — Reference Product Credentials**: If needed for authenticated views
6. **Step 0.6 — Figma Design**: Extract tokens via Figma MCP (optional)
7. **Step 0.7 — Product Logo SVG**: Collect logo, dark variant, icon mark, theme strategy, placements, sizing
8. **Step 0.8 — Design Framework/Library**: Confirm detected UI library
9. **Step 0.9 — Production URL**: Get app URL for visual review
10. **Step 0.10 — User Account Credentials**: Get test credentials (never commit raw values)
11. **Step 0.11 — Context Summary**: Save to `./plancasting/_audits/visual-polish/context.md`

## Phase 1: Design Decisions (Interactive Menu — 6-8 Decisions)

Present each as a numbered menu. Wait for user selection. Reference Phase 0 context for informed choices.

1. **Color Theme Mode** (Light Warm / Light Cool / Dark Rich / Dark Vibrant / Hybrid)
2. **Accent Color** (Coral / Emerald / Amber / Violet / Electric Blue / Rose / Custom)
3. **Design Style** (Refined Minimal / Editorial / Polished Product / Developer Tool-first / Warm Playful)
4. **Typography Pairing** (6 curated pairs + custom)
5. **Border Radius** (Sharp / Moderate / Rounded / Pill)
6. **Animation Level** (Subtle / Moderate / Expressive)
7. **Hero Section Style** — skip if no public pages (Product Screenshot / Abstract / Illustration / Split / Video / Minimal Text-only)
8. **Dashboard Layout** — skip if no authenticated pages (Sidebar+Content / Top Nav / Collapsible Sidebar / Keep current)

## Phase 2: Design Plan Confirmation (User Approval Required)

Derive concrete token values from decisions (color palette, typography scale, spacing, shadows, motion). Compile complete design plan including pages to modify (prioritized HIGH/MEDIUM/LOW). Save to `./plancasting/_audits/visual-polish/design-plan.md`.

Present to user. **Do not proceed to Phase 3 until explicitly approved.**

Phase 2 Outcomes: APPROVED → Phase 3 | REVISE (max 2 rounds) → update plan | REJECT → abandon branch, fall back to standard 6P.

## Phase 3: Implementation (Token-First Cascade — Autonomous)

Implement in this specific order. Each step cascades into the next:

1. **Step 3.1 — Design Tokens**: Update all token sources (highest leverage — cascades ~80%)
2. **Step 3.2 — Font Setup**: Install and configure approved font pairing
3. **CHECKPOINT**: Run typecheck + lint after Steps 3.1-3.2. Fix failures before continuing.
4. **Step 3.3 — Theme Provider Defaults**: Update theme config (never use `setTheme()` for Hybrid themes)
5. **Step 3.4 — Shared UI Component Audit**: Scan for hardcoded values bypassing tokens
6. **Step 3.5 — Anti-Slop Pre-Scan**: Document existing AI-slop patterns in `slop-inventory.md`
7. **Step 3.6 — Layout Components**: Update sidebar, header, footer, nav, logo placement
8. **Step 3.7 — Public Pages**: Landing/hero, auth pages, pricing (by user impact)
9. **Step 3.8 — Authenticated Pages**: Dashboard, list views, detail views, settings
10. **Step 3.9 — Feature Components Batch Audit**: Final scan for inconsistencies
11. **Step 3.10 — Motion & Animation**: Apply approved animation level (max 3 per page, `prefers-reduced-motion` required)
12. **Step 3.11 — Light/Dark Mode Verification**: Final pass on both modes

## Phase 4: Playwright Visual Review (MANDATORY)

Start dev server. Capture ALL pages at 3 breakpoints (1440, 768, 375). Capture dark mode. Evaluate quality against reference product screenshots. Document issues in `review-issues.md`.

## Phase 5: Anti-AI-Slop Refinement

Cross-reference slop inventory from Step 3.5 with visual review. Fix surviving patterns and newly introduced ones. See detailed guide for NEVER patterns (remove) and ALWAYS patterns (apply).

## Phase 6: Fix & Re-Review Cycle

Fix each issue → re-capture → confirm visually. Max 3 full cycles. Run final validation (typecheck + lint + test).

## Phase 7: Documentation & Downstream Updates

Update design tokens docs, tech-stack.md design direction, and docs site config colors. Prepare for Stage 7D re-run.

## Phase 8: Final Report

Generate `./plancasting/_audits/visual-polish/report.md` with design decisions, implementation summary, visual review results, anti-slop audit, responsive verification, files modified, validation results, and gate decision.

## Phase 9: Shutdown

1. Commit on `redesign/frontend-elevation` branch:
   ```bash
   git add src/ plancasting/_audits/visual-polish/ plancasting/tech-stack.md
   git commit -m "style(design): Stage 6P-R frontend redesign — [design style] with [font pair]"
   ```
2. Save commit hash to `./plancasting/_audits/visual-polish/last-polished-commit.txt`
3. Stop dev server if started by this stage
4. Instruct operator: merge `redesign/frontend-elevation` to main, then re-run Stage 7D to recapture screenshots

## Gate Decision

Gate uses **Critical/Major/Minor severity** classification (distinct from 6P's O/E/D categories):

- **Critical**: Visual issues that break usability — invisible text, broken layout, inaccessible contrast, non-functional dark mode
- **Major**: Noticeable inconsistencies — mixed font usage, token remnants, missing hover states across multiple pages
- **Minor**: Subtle polish items — single-page spacing, minor alignment, optional animation refinement

Outcomes:
- **PASS**: All design decisions implemented, zero Critical issues, visual review passed, validation clean → proceed to Stage 7
- **CONDITIONAL PASS**: Zero Critical issues, Minor visual issues remain but documented → proceed to Stage 7
- **FAIL**: Any Critical visual issues, validation failures, or broken dark mode → fix before proceeding
- **Phase 2 rejected**: User rejects design plan → abandon branch, fall back to standard 6P

## Critical Rules

1. never change functional behavior — only visual presentation.
2. never replace design system components with custom implementations.
3. always get explicit user approval on the design plan (Phase 2).
4. always use the `frontend-design` skill if available.
5. always take before/after screenshots.
6. always run validation (typecheck + lint + test) after implementation.
7. always verify at all 3 breakpoints (1440, 768, 375).
8. always verify dark mode if supported.
9. never introduce new dependencies without checking package.json.
10. always apply anti-AI-slop patterns from Phase 5.
11. Maximum 3 animation additions per page.
12. always preserve accessibility (focus rings, ARIA, keyboard nav).
13. Token-first implementation — start with design tokens.
14. always check console errors during Playwright screenshots.
15. never write credentials to committed files.
16. always verify font availability before configuring.
17. Treat contrast ratios as non-negotiable (WCAG AA minimum).
18. ALL animations must respect `prefers-reduced-motion`.
19. Maximum 3 fix-and-review cycles.

## Output Specification

| Artifact | Path |
|----------|------|
| Context Summary | `./plancasting/_audits/visual-polish/context.md` |
| Design Plan | `./plancasting/_audits/visual-polish/design-plan.md` |
| Slop Inventory | `./plancasting/_audits/visual-polish/slop-inventory.md` |
| Progress Tracking | `./plancasting/_audits/visual-polish/progress.md` |
| Visual Review Issues | `./plancasting/_audits/visual-polish/review-issues.md` |
| Redesign Report | `./plancasting/_audits/visual-polish/report.md` |
| Last Polished Commit | `./plancasting/_audits/visual-polish/last-polished-commit.txt` |
| Before Screenshots | `./screenshots/visual-polish/before/` |
| After Screenshots | `./screenshots/visual-polish/after/` |
| Reference Screenshots | `./screenshots/visual-polish/references/` |
