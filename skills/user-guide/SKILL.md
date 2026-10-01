---
name: user-guide
description: >-
  Generates a user-facing documentation site from the PRD, user stories, user flows, BRD business rules, and the production application.
  This skill should be used when the user asks to "generate user documentation",
  "create the user guide", "build the Mintlify docs site", "generate user-facing docs",
  "create documentation for users", "run stage 7D", "generate the docs site",
  or "create getting started guides",
  or when the transmute-pipeline agent reaches Stage 7D of the pipeline.
metadata:
  version: 1.1.0
effort: medium
---

# User Guide Generation (Mintlify) — Stage 7D

Read the detailed guide at `${CLAUDE_SKILL_DIR}/references/user-guide-detailed-guide.md` for the full agent team architecture, Mintlify platform reference, content generation rules, report template, and known failure patterns.

## Prerequisites

1. Read `./plancasting/_audits/production-smoke/report.md` (Stage 7V report). If 7V status is FAIL, stop: "Stage 7D requires 7V PASS or CONDITIONAL PASS. Production must be stable before generating user documentation." If the report does not exist, stop: "Stage 7V has not been run yet. Run Stage 7V first."
2. Check `plancasting/tech-stack.md` under the Documentation section. If it says "No -- not needed," stop: "Stage 7D skipped -- user opted out of user-facing documentation in Stage 0."
3. Read `CLAUDE.md`, `plancasting/tech-stack.md` (product name, design direction, session language, documentation config).
4. Check `plancasting/tech-stack.md` for the `Session Language` setting. Generate all content in the session language. If multi-language (session language differs from English), generate English first, then translate.

## Inputs

- **Production URL**: The live application URL
- **7V Report**: `./plancasting/_audits/production-smoke/report.md`
- **5B Report** (if exists): `./plancasting/_audits/implementation-completeness/report.md` -- identifies incomplete features for "Coming Soon" treatment
- **6V Report** (optional): `./plancasting/_audits/visual-verification/report.md` -- content source for troubleshooting
- **PRD files**: `./plancasting/prd/01-product-overview.md`, `02-feature-map-and-prioritization.md`, `03-release-plan.md`, `04-epics-and-user-stories.md`, `06-user-flows.md`, `07-information-architecture.md`, `08-screen-specifications.md`, `09-interaction-patterns.md`, `12-api-specifications.md`, `18-glossary-and-cross-references.md`
- **BRD files**: `./plancasting/brd/11-user-experience-requirements.md`, `14-business-rules-and-logic.md`
- **Developer Docs** (if exists): `./docs/` -- adapt (not copy) help content
- **E2E Constants**: `./e2e/constants.ts`, `./playwright.config.ts`

## Output

Generate a complete Mintlify documentation site under `./user-guide/`. Also generate `./plancasting/_audits/user-guide/report.md`.

**Multi-language** (session language differs from English): Root `docs.json` with `navigation.languages` array containing per-language groups + `en/` and `<session-lang>/` subdirectories. Per-language `docs.json` files may still be used for navigation overrides.

**English-only**: Root `docs.json` with both branding and navigation. Content at root level (no `en/` subdirectory).

Target 15-30 pages per language (excluding API reference).

## Execution Flow

### Phase 1: Lead Analysis and Planning

Perform pre-generation cleanup if `./user-guide/` already exists (check `git status`/`git diff` for uncommitted changes first -- stop if found).

1. Read 7V report -- confirm PASS or CONDITIONAL PASS.
2. Read Stage 5B report -- identify incomplete features for "Coming Soon" treatment.
3. Read PRD -- extract all user flows (UF-*), screen specs (SC-*), user stories (US-*), feature map, product overview.
4. Read Stage 6D help docs (`docs/help/`, if exists) -- extract adaptable content.
5. Read `plancasting/tech-stack.md` -- extract product name, design direction, session language, documentation platform config.
6. Derive journey categories from PRD:
   - Read user flows from `plancasting/prd/06-user-flows.md`. Fall back to `plancasting/prd/02-feature-map-and-prioritization.md` if no UF-* entries exist.
   - Cluster flows by user goal (shared entry point, sequential chain, same domain entity, standalone).
   - Name journeys using user-facing language (the user's goal, not feature names).
   - Order by natural user progression (onboarding -> core value -> advanced -> admin).
   - Map each UF-* to a page within its journey directory.
   - Determine concept pages from product overview and glossary.
   - Determine public API status (yes/no, OpenAPI spec path).
7. Build content map -- create `./_guide-context.md` with product info, journey groups, concept pages, writing style guidelines, branding, language config, incomplete features list, API reference decision, screenshot mode, and feature priority mapping.
8. Capture screenshots via Playwright MCP browser tools. Generate a screenshot manifest, capture public pages first (no auth required — must succeed), then authenticated pages (best-effort). Hide UI overlays (Next.js dev badge, cookie consent banners) before each capture by injecting CSS via `browser_evaluate`. Capture viewport-only screenshots (NOT full-page). Verify each screenshot shows actual content before committing. Save to `./user-guide/images/`. If the project's `.gitignore` contains `screenshots/`, add `!user-guide/images/` exception. Budget: max 30 screenshots total. Screenshot modes: `images` (all captured), `images-partial` (public captured, some auth skipped), or `text-only` (only if nothing loads at all). Do not default to `text-only` — public page screenshots should always succeed regardless of auth status. Tiered failure handling: Tier 1 (public pages) must succeed — failure is a blocker. Tier 2 (authenticated pages) attempt production first; if login fails, try dev server; if dev server shows "Session expired" this is a dev-mode auth race condition — switch back to production. Tier 3 (mode decision) — public success = `images` regardless of auth; some auth skipped = `images-partial`; only `text-only` if both production and dev are completely inaccessible. If `./e2e/doc-recordings/` exists, optionally capture animated recordings (MP4) for interactive flows — recordings replace static screenshots for the same page. Update `_guide-context.md` with final screenshot mode before spawning teammates.
9. Create task list for teammates.

### Phase 2: Spawn Documentation Teammates

Spawn 3 teammates in parallel for content creation. Teammate 3's validation step waits for Teammates 1 and 2 to complete.

**Teammate 1 -- "journey-writer"**: Write all journey guide pages, introduction.mdx, and quickstart.mdx. For each page, read source UF-*, SC-*, US-*, BR-* (or BRL-*) specs. Write using `<Steps>`/`<Step>` components. For hero visuals, check the manifest `Recordings` section first — if an MP4 recording exists, embed with `<video autoPlay muted loop playsInline className="w-full aspect-video rounded-xl" src="/images/<name>.mp4"></video>` INSTEAD of a static screenshot. If no recording exists, embed screenshots using markdown `![alt](/images/file.png)` syntax — do not use `<Frame><img>` (causes CDN 403 errors). Add callouts (`<Note>`, `<Warning>`, `<Tip>`, `<Info>`), and include "Next steps" sections. never start the MDX body with a `# Title` heading — Mintlify auto-renders the frontmatter `title` as h1. always escape dollar signs before numbers (`\$69`, not `$69`) — MDX interprets `$...$` as LaTeX.

**Teammate 2 -- "concepts-and-reference-writer"**: Write concept pages, FAQ (as `<AccordionGroup>`), troubleshooting (problem -> cause -> solution), changelog (using `<Update>` components), and API reference (conditional -- only if product has public API without OpenAPI spec). For visual embedding, check recordings first (use `<video>` tag), then screenshots (use markdown `![alt](/images/file.png)` syntax). always escape dollar signs before numbers. never start the MDX body with a `# Title` heading.

**Teammate 3 -- "config-and-structure"**: Create root `docs.json` (branding, theme, colors from `plancasting/tech-stack.md`) using the validated template from the detailed guide. For multi-language, use `navigation.languages` pattern in root `docs.json`. Per-language `docs.json` may still be used for navigation overrides. Static assets in `public/`, snippets (`prerequisites.mdx`, `support-cta.mdx`). Do not add: `colors.anchors`, top-level `anchors` array, top-level `languages` array, or `navigation` as a bare array. After Teammates 1 and 2 complete, run validation: `mint validate`, `mint broken-links`, `mint a11y`, jargon scan (two categories: always-flag technical identifiers vs flag-with-context common words), verify `![](/images/...)` references point to actual files in `user-guide/images/`, frontmatter description check, translation parity check.

### Phase 3: Coordination

Monitor progress, coordinate content consistency, ensure cross-page links are consistent. When Teammates 1 and 2 complete, notify Teammate 3 to proceed with validation.

### Phase 4: Review and Audit

1. Review Teammate 3's validation results. Run CLI checks if needed.
2. Verify no PRD/BRD jargon in user-facing content.
3. Verify incomplete features marked "Coming Soon" or omitted.
4. Spot-check media references: verify 3-5 random `![](/images/...)` references in MDX files point to actual files in `user-guide/images/`.
5. Verify translation parity if multi-language.
6. Generate `./plancasting/_audits/user-guide/report.md` with: summary, structure validation, content coverage, screenshot coverage (including animated recordings fields, broken media references, total media size), jargon scan, link integrity, translation parity, CLI check results, and gate decision.

### Phase 5: Shutdown

1. Verify all teammates completed.
2. If PASS or WARN: delete `_guide-context.md`. If FAIL: retain it for re-run.
3. Output summary.

## Content Generation Rules

For each guide page, follow this transformation pipeline:
1. **Identify the user flow** from `plancasting/prd/06-user-flows.md` -- extract happy path steps.
2. **Enrich with screen specs** from `plancasting/prd/08-screen-specifications.md` -- use visible labels, not component names.
3. **Add acceptance criteria** from `plancasting/prd/04-epics-and-user-stories.md` -- transform Given/When/Then into "What you should see" callouts.
4. **Apply business rules** from `plancasting/brd/14-business-rules-and-logic.md` -- plan-tier restrictions as `<Info>`, validation rules as `<Warning>`.
5. **Embed visuals** from the manifest in `_guide-context.md` -- first check the `Recordings` section for an MP4 recording (embed with `<video>` tag INSTEAD of a screenshot). If no recording, check the screenshot manifest and embed with `![alt](/images/file.png)` markdown syntax. Place the hero visual after the opening paragraph. If no visual exists, use `<Note>` callouts.
6. **Rewrite for the audience** -- replace ALL technical terms, use product terminology, second person, present tense, imperative mood.

## Gate Decision

- **PASS**: All P0/P1 features documented, zero jargon leakage, zero broken links, all docs.json files valid, all navigation entries resolve, translation parity (if multi-language), CLI checks pass (or N/A if CLI unavailable)
- **WARN**: P0/P1 fully covered but: P2 coverage gaps, minor style inconsistencies, 1-2 jargon instances in non-critical pages, orphan pages (MDX files not in any navigation), minor `mint a11y` issues, or Mintlify CLI checks not tested (CLI unavailable). Deploy with known issues documented.
- **FAIL**: Any of: missing P0/P1 feature coverage, broken navigation (pages in nav but no file), invalid docs.json, >=3 jargon instances, translation structure mismatch, broken media references (image/video references pointing to non-existent files). Fix before deploying.

## Critical Rules

1. never copy PRD text verbatim -- rewrite for non-technical users.
2. never organize by feature ID -- organize by user journey.
3. never use numbered markdown lists for procedures -- always use `<Steps>`/`<Step>`.
4. never use markdown blockquotes for callouts -- always use `<Note>`/`<Warning>`/`<Tip>`/`<Info>`/`<Check>`/`<Danger>`.
5. Limit group nesting to ONE level deep in docs.json.
6. never reference pages with file extensions in docs.json navigation.
7. always validate docs.json as valid JSON.
7a. always include `"theme"` in docs.json -- it is a REQUIRED field. Valid values: `mint`, `maple`, `palm`, `willow`, `linden`, `almond`, `aspen`, `luma`, `sequoia`.
7b. always structure `navigation` in docs.json as an OBJECT, not an array. For multi-language: `{ "languages": [{ "language": "en", "groups": [...] }, ...] }`. For single-language: `{ "groups": [...] }`. A bare array WILL fail.
7c. never use `colors.anchors` or top-level `anchors` in docs.json -- these are deprecated. Use only `colors.primary`, `colors.light`, `colors.dark`.
8. always include meaningful `description` in every page's frontmatter.
9. always cross-reference Stage 5B to avoid documenting incomplete features.
10. always extract branding from `plancasting/tech-stack.md` -- never use placeholders.
11. If multi-language: generate English first, then translate. Verify identical structure.
12. always include "Next steps" at the bottom of each journey page.
13. never include technical identifiers in user-facing content (no FEAT-*, US-*, SC-*, FR-*, BR-*, UF-*).
14. never reference a screenshot that doesn't exist in the manifest.
15. always wait for page content to fully load before capturing screenshots.
16. always include meaningful `alt` text on screenshot images.
17. Maximum 30 screenshots total, maximum 3 per journey page.
18. always use standard markdown image syntax `![Alt text](/images/file.png)` for screenshots. Do not use `<Frame><img>` wrapping -- it can cause CDN 403 errors on Mintlify's hosting.
19. If screenshot mode is `text-only`, ALL teammates use `<Note>` callouts instead of images.
20. Use `<Accordion>` for optional/advanced content that most users can skip.
21. Use `<Tabs>` when the same task has different instructions for different contexts (desktop/mobile, plan tiers).
22. If screenshot mode is `text-only` or `images-partial` with <50% manifest success, do not mix screenshot and text-only approaches within the same guide -- use `<Note>` callouts consistently.
23. always hide UI overlays (Next.js dev badge, cookie consent banners) before capturing screenshots or recordings.
24. When an animated recording (MP4) exists for a page, embed it with `<video>` INSTEAD of the static screenshot -- NOT alongside it. The video replaces the screenshot.
25. always use PRODUCTION URL for authenticated page captures (screenshots and recordings). Dev servers have known race conditions with real-time auth providers where the initial token fetch gets aborted during navigation, causing permanent "Session expired" error boundaries.
26. For animated recordings, always trim the login/navigation portion from auth recordings during conversion (use `ffmpeg -ss <seconds>`). The video should start on the feature page with content visible.
27. always verify captured screenshots/recordings show actual content before embedding. Check for: loading spinners, "Session expired" screens, error boundaries, blank pages, cookie banners, dev badges. Retry with longer wait times or overlay hiding if needed.
