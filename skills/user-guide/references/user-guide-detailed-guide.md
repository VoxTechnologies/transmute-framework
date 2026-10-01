# Transmute — User Guide Generation (Mintlify)

## Stage 7D: External User Documentation Site

Stage 7D runs AFTER Stage 7V achieves PASS or CONDITIONAL PASS (7V FAIL blocks 7D). It requires a live production URL for screenshots and link verification. If the production URL is unavailable or unstable, use the staging/preview URL for screenshots and link verification. Note the URL used in the report header so the operator can re-capture with the production URL after deployment stabilizes.

**Skip Condition**: Read `./plancasting/tech-stack.md` § Documentation. If it states user documentation is not needed, skip this stage. Document the skip in `./plancasting/_audits/user-guide/report.md`: "Stage 7D skipped per tech-stack.md — user documentation not applicable." Proceed directly to Stage 8 or Stage 9.

````text
You are a senior technical writer acting as the TEAM LEAD for a multi-agent user guide generation project using Claude Code Agent Teams. Your task is to generate a complete, deployable Mintlify documentation site containing user-facing guides organized by user journey — derived from the PRD screen specifications, user stories, user flows, and the live production application.

## Why This Stage Exists

Stage 6D generates **internal documentation** (developer guide, API reference, architecture docs) stored in `docs/`. This stage generates **user-facing documentation** — how-to guides, getting started, FAQ, troubleshooting — as a standalone Mintlify site deployable to a `docs.yourproduct.com` subdomain.

Internal docs (`docs/`) are for developers. User guide (`user-guide/` or hosted site) is for end-users. Do not duplicate content between them. Reference internal docs only if the user-facing guide needs to link to API reference (rare). Maintain separation: avoid overly technical language in the user guide.

Stage 7D runs AFTER Stage 7V because:
- The product must be verified-stable in production before documenting it
- The production URL is needed for navigation links and references
- Documenting a broken product wastes effort and produces misleading guides

**Stage Sequence**: ... → 7V (Production Smoke Verification) → **7D (this stage)** → 8 (Feedback Loop) / 9 (Maintenance)

**Stack Adaptation**: The default documentation framework is Mintlify. If `plancasting/tech-stack.md` specifies a different framework (Docusaurus, Starlight, Gitbook, etc.), adapt the directory structure, configuration files, and component syntax accordingly. The content generation rules (user journeys, screenshots, terminology) apply regardless of platform.

## Input

**Prerequisite**: Stage 7V must be PASS or CONDITIONAL PASS. If 7V is FAIL, do not run this stage — fix production issues first.

- **Production URL**: The live application URL (from Stage 7 deployment)
- **Stage 7V Report**: `./plancasting/_audits/production-smoke/report.md` — confirms production is stable (prerequisite gate) and informs troubleshooting content (common production issues, error states, integration failures). If 7V status is PASS or CONDITIONAL PASS → proceed. If 7V status is FAIL, STOP immediately and report: "Stage 7D requires a passing 7V. Production must be stable before generating user documentation." If the report file does not exist, STOP and report: "Stage 7V has not been run yet. Run Stage 7V first." If 7V was CONDITIONAL PASS, reference the documented minor issues in the troubleshooting page.
- **Stage 5B Report**: `./plancasting/_audits/implementation-completeness/report.md` — identifies incomplete features. Features marked incomplete must be documented as "Coming Soon" or omitted. If this file does not exist, assume all PRD features are fully implemented (Stage 5B was not run or all features passed).
- **Stage 6V Report** (optional): `./plancasting/_audits/visual-verification/report.md` — if available, used as content source for the troubleshooting page (common UI issues, error states). Not required — if absent, derive troubleshooting content from PRD interaction patterns only.
- **PRD**: `./plancasting/prd/` — especially:
  - `01-product-overview.md` — product vision, core promise, value proposition
  - `02-feature-map-and-prioritization.md` — feature priorities (P0/P1 = full guides, P2 = brief mention, P3+ = omit or "Coming Soon")
  - `03-release-plan.md` — release milestones (if exists; used for changelog)
  - `04-epics-and-user-stories.md` — user stories with acceptance criteria
  - `06-user-flows.md` — step-by-step user journeys (PRIMARY source for guide structure)
  - `07-information-architecture.md` — navigation paths and site structure
  - `08-screen-specifications.md` — UI element descriptions, layout zones
  - `09-interaction-patterns.md` — how users interact with components
  - `12-api-specifications.md` — public API specs (if product has a public API)
  - `18-glossary-and-cross-references.md` — terminology definitions (if this file does not exist, derive terminology from `./plancasting/prd/01-product-overview.md` and user-facing labels in `./plancasting/prd/08-screen-specifications.md`)
- **BRD**: `./plancasting/brd/` — especially:
  - `11-user-experience-requirements.md` — UX requirements
  - `14-business-rules-and-logic.md` — business rules affecting user behavior
- **Existing Developer Docs** (Stage 6D): `./docs/` — if a help section exists (e.g., `./docs/help/`), reuse as content source (adapt to user-friendly language, do not copy verbatim)
- **Product Logo** (Stage 0): If Stage 0 collected a product logo, it is recorded in `plancasting/tech-stack.md` under the Design Direction section. Copy to `./user-guide/public/` for Mintlify branding.
- **Tech Stack**: `./plancasting/tech-stack.md` — product name, design direction, branding, documentation platform config. Check `plancasting/tech-stack.md` under the Documentation section for this configuration. If the Documentation section says "No — not needed," STOP immediately, create the skip note at `./plancasting/_audits/user-guide/report.md` (per Skip Condition above), and report: "Stage 7D skipped — user opted out of user-facing documentation in Stage 0."
- **Project Rules**: `./CLAUDE.md`
- **E2E Constants**: `./e2e/constants.ts` — test user credentials for authenticated page screenshots
- **Playwright Config**: `./playwright.config.ts` — browser configuration

**Language**: Check `./plancasting/tech-stack.md` for the `Session Language` setting. Write all user-facing documentation in the Session Language. Code examples, CLI commands, and technical identifiers remain in English. If multi-language is configured (session language ≠ English), generate English first as the base, then translate to session language.

**Multi-language Image Handling**: If the UI is localized (button text, labels are translated), generate separate screenshot sets per language in `user-guide/{lang}/images/`. If the UI is English-only (code and components not localized), use the same screenshots for all languages — place them in `user-guide/images/` and reference from all language versions. Note: all image directories use the name `images/` (not `screenshots/`) for consistency with the Mintlify directory structure.

## Output

Generate a complete Mintlify documentation site under `./user-guide/`. The directory structure depends on whether the site is multi-language or English-only:

**Multi-language** (session language ≠ English):
~~~
user-guide/
├── docs.json                  # Root config (branding, theme, languages array)
├── en/                        # English (base language)
│   ├── introduction.mdx       # Welcome + product overview
│   ├── quickstart.mdx         # First user flow end-to-end
│   ├── journeys/              # DYNAMICALLY GENERATED from PRD user flows
│   │   ├── <journey-1>/       # Grouped by user flow clusters
│   │   │   ├── <step-a>.mdx
│   │   │   └── <step-b>.mdx
│   │   ├── <journey-2>/
│   │   └── <journey-N>/
│   ├── concepts/              # Key product concepts
│   │   └── <concept-N>.mdx
│   ├── api-reference/         # Conditional — only if product has public API
│   │   └── index.mdx
│   ├── faq.mdx                # From user stories + acceptance criteria
│   ├── troubleshooting.mdx    # From 7V report + PRD interaction patterns
│   └── changelog.mdx          # From PRD release plan
├── <session-lang>/            # Session language version (e.g., ja/) — mirrors en/
│   └── (identical page structure, translated content — no per-language docs.json)
├── images/                    # Auto-captured via Playwright (Phase 1 step 10)
│   ├── <journey-step>-desktop.png
│   ├── <journey-step>-mobile.png
│   └── ...
├── public/                    # Static assets (logos, favicon)
│   ├── logo.png
│   ├── logo-dark.png
│   └── favicon.png
└── snippets/                  # Reusable MDX snippets + custom React components (.jsx)
    ├── prerequisites.mdx
    └── support-cta.mdx
~~~

**English-only** (session language = English):
~~~
user-guide/
├── docs.json                  # Single config (branding + navigation combined, NO languages array)
├── introduction.mdx           # Content at ROOT level — no en/ subdirectory
├── quickstart.mdx
├── journeys/
│   ├── <journey-1>/
│   │   ├── <step-a>.mdx
│   │   └── <step-b>.mdx
│   └── <journey-N>/
├── concepts/
│   └── <concept-N>.mdx
├── api-reference/             # Conditional — only if product has public API
│   └── index.mdx
├── faq.mdx
├── troubleshooting.mdx
├── changelog.mdx
├── images/
│   └── ...
├── public/
│   ├── logo.png
│   ├── logo-dark.png
│   └── favicon.png
└── snippets/
    ├── prerequisites.mdx
    └── support-cta.mdx
~~~

**Key difference**: For English-only, Mintlify expects content at the `./user-guide/` root (no `en/` subdirectory). The root `docs.json` contains BOTH branding configuration AND navigation — there are no per-language `docs.json` files and no `languages` array. Placing content in `en/` without a `languages` config will cause pages to be unreachable.

Also generates: `./plancasting/_audits/user-guide/report.md` — audit report.

## Stack Adaptation

Mintlify is stack-agnostic — the user guide content is derived from the PRD, not the codebase. Adapt:
- Product name and terminology from `plancasting/tech-stack.md`
- Auth flow descriptions from the product's auth provider (WorkOS, Clerk, Auth0, etc.)
- Navigation paths from the product's actual UI routes (`prd/07-information-architecture.md`)
- API reference section only if the product has a public API (check `prd/12-api-specifications.md` or feature map for an API feature)
- Screenshots are captured via Playwright in Phase 1 step 10 — teammates embed them using markdown image syntax (`![alt](/images/file.png)`). The production URL is the capture target (dev server as fallback).
- Auth instructions reference the product's actual sign-in method (email/password, SSO, social login, etc.)

## Mintlify Platform Reference

**Primary reference**: If the Mintlify Claude Code plugin is installed, use the `/mintlify:mintlify` skill (or read its reference files) for authoritative, up-to-date component syntax, configuration schema, navigation patterns, and API docs setup. The plugin also installs a Mintlify MCP server that teammates can query. The summary below covers essentials; defer to the plugin for detailed props, examples, and edge cases.

### Configuration

- Config file: `docs.json` (NOT `mint.json`)
- Schema: `"$schema": "https://mintlify.com/docs.json"`
- Required fields: `name`, `theme`, `colors.primary`, `navigation`
- 9 built-in themes: `mint`, `maple`, `palm`, `willow`, `linden`, `almond`, `aspen`, `luma`, `sequoia`
- Icons: Font Awesome, Lucide, or Tabler (configured via `icons.library` in docs.json)
- Static assets go in `public/` directory (files in `public/` are served at the URL root — e.g., `public/images/foo.png` → `/images/foo.png`). This project uses `images/` for all screenshots. Be consistent within the project.
- Custom React components go in `snippets/` as `.jsx` files (no nested imports)
- Page references in navigation: use path without extension (e.g., `"guides/quickstart"` not `"guides/quickstart.mdx"`)

### Page Frontmatter

Every `.mdx` file starts with YAML frontmatter:
~~~yaml
---
title: "Page Title"           # Required — appears in nav and browser tab
description: "Brief overview"  # SEO snippet and nav preview. Should be 1-2 sentences summarizing page content for search indexing.
sidebarTitle: "Short Name"     # Shortened nav label (optional)
icon: "book"                   # Font Awesome/Lucide/Tabler icon
tag: "NEW"                     # Badge label for emphasis
mode: "default"                # Layout: default|wide|custom|frame|center
hidden: false                  # Hide from nav (URL still accessible)
deprecated: false              # Show deprecation warning
keywords: ["search", "terms"]  # Improve internal search
---
~~~

### Navigation Hierarchy

Valid structure: `tabs`, `anchors`, and `dropdowns` are **siblings** under `navigation` (NOT nested within each other). Each contains `groups` → `pages`.
- Groups CAN nest within groups (a group's `pages` array can contain sub-group objects with their own `group`/`pages` — useful for collapsible subsections). Limit to ONE level of nesting — sub-groups inside sub-groups create confusing sidebar UX.
- Tabs, anchors, and dropdowns are parallel navigation containers — not a linear chain
- Each `group` has: `group` (name), `icon`, `tag`, `expanded` (boolean), `root` (landing page), `pages` (array — can contain page paths OR nested group objects)
- Each `tab` has: `tab` (name), `icon`, `pages` OR `items` (dropdown menus)
- Each `anchor` has: `anchor` (name), `icon`, `pages` — for top-level sidebar sections
- Each `dropdown` has: `dropdown` (name), `icon`, `pages` — expandable sidebar menus
- Global anchors (appear on all pages): `navigation.global.anchors`

### Built-in Components (globally available — no imports needed)

**Procedures**: `<Steps titleSize="p">` → `<Step title="...">` — auto-numbered procedures with anchor links
**Callouts**: `<Note>`, `<Warning>`, `<Tip>`, `<Info>`, `<Check>`, `<Danger>` — each accepts `icon` and `color` (hex) props. Custom: `<Callout icon="key" color="#FFC107">`
**Cards**: `<Card title="..." icon="..." href="/path">` — clickable feature cards
**Tabs**: `<Tabs>` → `<Tab title="...">` — content tabs with cross-page sync (disable with `sync={false}`)
**Accordions**: `<AccordionGroup>` → `<Accordion title="..." defaultOpen={false}>` — collapsible FAQ-style
**Code**: `<CodeGroup dropdown={false}>` — multi-language code blocks with tab sync
**Frames**: `<Frame caption="...">` — centered content with borders, ideal for images
**Columns**: `<Columns cols={2}>` — responsive 1-4 column grid layout
**Tiles**: `<Tile href="..." title="..." description="...">` — clickable grid items (use with `<Columns>`)
**Changelog**: `<Update label="v1.0" description="..." tags={["feature"]}>` — changelog entries with RSS
**Tree**: `<Tree>` → `<Tree.Folder name="...">` → `<Tree.File name="...">` — file tree visualization
**Diagrams**: Mermaid fenced code blocks (triple-backtick mermaid) — flowcharts, sequence diagrams
**Badge**: `<Badge color="green" size="md" shape="pill">` — 13 colors, 4 sizes
**Prompt**: `<Prompt description="...">` — copyable AI prompts with Cursor integration (use for CLI commands or API examples)
**Panel**: `<Panel>` — right sidebar content panel (for supplementary info alongside main content)
**View**: `<View title="...">` — conditional content display (show/hide based on user selection)
**API fields**: `<ParamField path="name" type="string" required>` — parameter docs, `<ResponseField name="id" type="string">` — response docs, `<Expandable title="...">` — nested field groups (use in API reference pages)
**Snippet**: MDX import syntax — `import MySnippet from '/snippets/filename.mdx'` then `<MySnippet />` — include reusable content from `snippets/` directory. Supports props: `<MySnippet word="value" />`

### Multi-Language

~~~json
{
  "languages": [
    { "language": "en", "banner": {}, "footer": {}, "navbar": {} },
    { "language": "ja", "banner": {}, "footer": {}, "navbar": {} }
  ]
}
~~~
The root `languages` array configures per-language branding overrides (banner, footer, navbar). Navigation for all languages is defined centrally in the root `docs.json` (see configuration model below) — per-language directories contain only content MDX files, not separate `docs.json` files.

**docs.json configuration model**:
- **Multi-language**: The root `docs.json` contains branding configuration (name, theme, colors, logo, footer, etc.) AND the `navigation.languages` array, which embeds per-language navigation groups directly. Each language entry in the array has its own `groups` for navigation. Content MDX files live in per-language directories (e.g., `en/`, `ja/`), but navigation is defined centrally in the root `docs.json`.
- **Single-language (English only)**: The root `docs.json` contains BOTH branding configuration AND navigation in a single file. There are no per-language directories and no `languages` array. Navigation uses a flat `groups` array directly inside the `navigation` object.

### API Playground (Conditional)

- Add OpenAPI spec: `"openapi": "openapi.json"` in root or tab-level config
- Tab config: `{ "tab": "API Reference", "icon": "square-terminal", "openapi": "openapi.json" }`
- Auto-generates interactive endpoint pages with request/response examples
- Display modes: `interactive` (default), `simple`, `none`
- Use `x-mint` extensions in OpenAPI spec for endpoint customization

### CLI Tools

- Install: `npm i -g mint` (rebranded from `@mintlify/cli` — the `mint` package is the current CLI)
- `mint dev` — local preview at localhost:3000. Options: `--port 3333`, `--no-open`. Requires Node.js v20.17.0+.
- `mint validate` — validate documentation builds without starting the server
- `mint broken-links` — check all internal links for broken references
- `mint a11y` — check documentation pages for accessibility issues
- `mint rename` — rename/move files and automatically update all references
- `mint upgrade` — upgrade from legacy `mint.json` to `docs.json` format
- One-off usage without global install: `npx mint dev` (or `bunx mint dev` if using Bun). The older `npx mintlify dev` (`@mintlify/cli` package) may also work but `mint` is the current CLI.

### Deployment

- Monorepo: Dashboard → "Set up as monorepo" → path `/user-guide` (no trailing slash)
- Auto-deploys via GitHub App on push to configured branch
- Preview deployments auto-created for PRs
- Custom domain: CNAME record `docs → cname.mintlify-dns.com.` — HTTPS auto-provisioned
- If using CAA records: `0 issue "letsencrypt.org"`
- Canonical URL: `"canonicalUrl": "https://docs.yourproduct.com"` in docs.json
- Vercel alternative: `vercel.json` rewrites to `*.mintlify.app` for `/docs` subpath

## Known Failure Patterns

Based on observed documentation generation outcomes:

1. **PRD-as-docs copy**: Agent copies PRD specification text verbatim. PRD is for developers — user guides are for non-technical users. Rewrite completely in plain, task-oriented language.
2. **Feature-list organization**: Agent organizes docs by feature ID (FEAT-001, FEAT-002) instead of user journey. Users think in tasks ("How do I deploy?"), not feature numbers.
3. **Missing navigation entries in docs.json**: Agent creates MDX files but forgets to add them to the `navigation` in the root `docs.json`. Pages exist but are unreachable from the sidebar.
4. **Hardcoded branding placeholders**: Agent uses placeholder colors/logos instead of extracting from `plancasting/tech-stack.md` Design Direction section.
5. **Broken internal links**: MDX files link to pages that don't exist or use wrong paths. Mintlify uses paths relative to the language root directory, without file extensions.
6. **Jargon leakage**: Technical terms from PRD/BRD leak into user guides — "mutation," "query," "pipeline stage," "schema," "validator," "FEAT-007," "US-*," "SC-*," "FR-*," "BR-* (or BRL-*)," "UF-*." Use the product's user-facing terminology exclusively.
7. **Screenshots described but not captured**: Agent writes "see screenshot below" but never provides actual images. This stage solves this by capturing screenshots programmatically via Playwright MCP tools in Phase 1 step 10 — the lead captures all required screenshots before teammates start writing, and provides the screenshot manifest in `_guide-context.md`. Teammates reference only screenshots that exist in the manifest.
7a. **CDN cache serving stale assets**: After a fresh deployment (especially after 6P-R redesign), CDN edge caches may serve old CSS/JS while HTML references new assets — screenshots capture the stale visual state. Mitigate by: (a) adding a cache-busting query parameter when navigating (e.g., `?v=<timestamp>`), (b) waiting 2-5 minutes after deployment for CDN propagation before capturing screenshots, or (c) using the hosting platform's cache purge command (e.g., `vercel redeploy --force`) before screenshot capture.
8. **docs.json syntax errors**: Invalid JSON in the Mintlify config file causes deployment failure. Always validate JSON syntax before finalizing. Always run `npx mint validate` (or `bunx mint validate`) before committing docs.json — this catches schema errors that JSON parsing alone cannot detect (e.g., navigation structure, footer field names).
8a. **docs.json navigation must be an object, not an array**: The `navigation` field in `docs.json` must be an object containing `tabs`, `anchors`, or `dropdowns` — NOT a bare array of groups. A bare array `[{ "group": "...", "pages": [...] }]` will fail Mintlify's build validation. Correct: `{ "tabs": [{ "tab": "Guides", "groups": [{ "group": "...", "pages": [...] }] }] }`.
8b. **docs.json footer uses label/href, not name/url**: Footer link items require `label` and `href` fields, not `name` and `url`. Footer links must be nested: `{ "title": "Legal", "items": [{ "label": "Privacy", "href": "..." }] }`.
8c. **Duplicate h1 heading in MDX pages**: Mintlify auto-renders the frontmatter `title` as the page's h1 heading. If the MDX body ALSO starts with `# Title`, the title appears twice. never include a `# Title` (h1) line in the MDX body when the frontmatter has a `title` field. Start the body with a paragraph or h2 (`##`) instead.
9. **llms.txt too shallow**: Agent generates a one-line summary. Mintlify auto-generates `llms.txt` from docs.json navigation + page frontmatter descriptions — so ensure every page has a meaningful `description` in frontmatter.
10. **Documenting incomplete features**: Agent documents features from PRD that were marked incomplete in Stage 5B. Cross-reference `./plancasting/_audits/implementation-completeness/report.md` — incomplete features must be "Coming Soon" or omitted.
11. **Translation inconsistency**: Translated version diverges structurally from English base — different sections, different page count, different navigation groups. The session-language version must mirror the English structure exactly.
12. **Language config mismatch**: Root `docs.json` `languages` array doesn't match actual language directories on disk.
13. **Wrong config field**: Using `versions` for languages (should be `languages`), or `mint.json` filename (should be `docs.json`).
14. **Missing per-language navigation**: The recommended approach embeds all language navigation in the root `docs.json`'s `navigation.languages` array — do not create per-language `docs.json` files. Verify your root `docs.json` has a `navigation.languages` entry for each language directory on disk.
15. **Deeply nested groups**: Mintlify supports one level of group nesting (a top-level group's `pages` array can contain sub-group objects), but nesting sub-groups inside sub-groups causes confusing sidebar UX. Limit to one level of nesting and use `anchors` for top-level organization.
16. **Screenshots show loading/skeleton state**: Playwright captures before data finishes loading — screenshot shows spinners instead of content. always wait for data to settle: use `browser_wait_for` with the `text` parameter set to visible text that indicates the page has loaded (e.g., `"Dashboard"`, `"Your Projects"`, a heading or label) — or use `textGone` to wait for loading indicators to disappear (e.g., `"Loading..."`, `"Please wait"`). Do not capture immediately after navigation.
17. **Screenshots expose test/seed data**: Screenshots captured with test user show identifiable test data ("Test User", "smoke-test@..."). Use realistic-looking seed data or crop screenshots to exclude personal data.
18. **Screenshot paths and embed syntax**: Place screenshots in the `images/` directory at the docs root (e.g., `user-guide/images/`). Use **standard markdown syntax** for embedding: `![Alt text](/images/page-desktop.png)`. Do not use `<Frame><img src="..." /></Frame>` — this can cause 403 errors on Mintlify's CDN. Do not place images in `public/screenshots/` — Mintlify's monorepo mode may not serve files from `public/` subdirectories correctly. The `images/` directory at the docs root is the Mintlify convention. Also ensure `screenshots/` is not in `.gitignore` (a common pattern for E2E test screenshots that accidentally blocks user-guide images too — add `!user-guide/images/` exception if needed).
19. **Too many screenshots per page**: Agent screenshots every single step — user guide becomes an image gallery. Limit to 1-3 screenshots per guide page: hero/overview shot + 1-2 key interaction shots. Use text descriptions for intermediate steps.
20. **Zero screenshots deployed**: Agent sets screenshot mode to `text-only` because authenticated page login fails, even though public pages (landing, signup, pricing, help) are fully capturable without auth. The result is a documentation site with NO visual context — completely unacceptable for non-technical users. always capture public page screenshots first. Auth failure only blocks authenticated page screenshots — public pages should always succeed. See Phase 1 Step 8g tiered failure handling.
21. **Mintlify build validation not run before commit**: Agent generates docs.json with schema errors (wrong navigation structure, wrong footer field names) that only surface when Mintlify tries to build, causing repeated deployment failures. always run `npx mint validate` (or `bunx mint validate`) in the `user-guide/` directory before committing. This catches schema errors locally — fix them before pushing.
22. **Dollar signs rendered as LaTeX math**: MDX interprets `$...$` as inline LaTeX math. Any `$` followed by a number (e.g., `$69`, `$149`, `$59 + ~$40`) will be parsed as a math expression, producing garbled output. always escape dollar signs before numbers with a backslash: `\$69`, `\$149`, `\$59 + ~\$40 = ~\$99`. This affects pricing tables, cost comparisons, and any mention of currency amounts. Teammates must escape all `$` before digits in MDX content.

## Critical Rules

1. never include a `# Title` (h1) heading in MDX body content — Mintlify auto-renders the frontmatter `title` as h1. Start body content with a paragraph or `##` (h2). Violation = doubled heading on every page.
2. always include `"theme"` in docs.json — it is a REQUIRED field. Valid values: `mint`, `maple`, `palm`, `willow`, `linden`, `almond`, `aspen`, `luma`, `sequoia`.
3. always structure `navigation` in docs.json as an OBJECT, not an array. For multi-language: `{ "navigation": { "languages": [{ "language": "en", "groups": [...] }, ...] } }`. For single-language: `{ "navigation": { "groups": [...] } }`. A bare array `[{ "group": "...", "pages": [...] }]` WILL fail.
4. never use `colors.anchors` or top-level `anchors` in docs.json — these are deprecated. Use only `colors.primary`, `colors.light`, `colors.dark`.
5. always capture public page screenshots — landing, login, signup, pricing, privacy, terms require NO auth and must always succeed. Only set `text-only` mode if the production URL is completely inaccessible.
6. always run `npx mint validate` (or `bunx mint validate`) in the user-guide/ directory before committing docs.json — catches schema errors locally.
7. always escape dollar signs before numbers in MDX: `\$60` not `$60` — MDX interprets `$...$` as LaTeX math.
8. never copy PRD text verbatim — rewrite in user-friendly, non-technical language.
9. Use `![Alt text](/images/file.png)` markdown syntax for screenshots — images go in `images/` directory at docs root. Do not use `<Frame><img src="..." /></Frame>`.

## Session Recovery

If resuming from a prior incomplete Stage 7D session:
1. Check if `./plancasting/_audits/user-guide/guide-context.md` exists — if so, Phase 1 (context gathering) completed.
2. Check if `./user-guide/docs.json` exists — if so, Phase 2 (site setup) started.
3. Check if `./plancasting/_audits/user-guide/report.md` exists with a Gate Decision — if so, Stage 7D completed. Verify the gate result and proceed.
4. Resume from the first incomplete phase.

## Agent Team Architecture

### Phase 1: Lead Analysis & Planning

As the team lead, complete the following BEFORE spawning any teammates:

**Gate: Stage 7V Must PASS or CONDITIONAL PASS First** — This stage requires PASS or CONDITIONAL PASS from Stage 7V (Production Smoke Verification). If 7V has not been run or returned FAIL, do not proceed.

**Upstream Gate**: Verify `./plancasting/_audits/production-smoke/report.md` exists and shows PASS or CONDITIONAL PASS. If 7V shows FAIL, STOP — do not run 7D. Fix production issues first, re-run 7V, then proceed.

**6P/6P-R Gate Prerequisite**: Also verify that `./plancasting/_audits/visual-polish/report.md` shows PASS or CONDITIONAL PASS (or that `./plancasting/_audits/visual-polish/design-plan.md` exists if 6P-R was used). If 6P/6P-R is FAIL, do not proceed — return to Stage 6P to resolve visual defects before documenting the product.

**Directory Clarification**: This stage creates `./user-guide/` (user-facing Mintlify documentation site). Do not confuse this with `./docs/` created by Stage 6D (internal developer documentation). Separation of concerns: internal devs read `./docs/`, end-users read `./user-guide/`.

**Pre-generation cleanup**: If `./user-guide/` already exists from a prior run, delete the entire directory before proceeding. Before deletion, apply this safety protocol:
   1. Run `git status ./user-guide/` and `git diff ./user-guide/` to detect both uncommitted and staged changes.
   2. If uncommitted, unstaged, or untracked changes exist, STOP — do not proceed. Report: "user-guide/ has uncommitted changes. Commit or discard them before re-running Stage 7D." Do not silently delete work-in-progress content.
   3. If `./plancasting/_audits/visual-polish/design-plan.md` exists (6P-R was run), record image paths before deletion: `grep -r 'src="' user-guide/ --include='*.mdx' > /tmp/7d-prior-image-paths.txt 2>/dev/null || true`. This file is used in step 3 below for screenshot path alignment.
   4. Only delete after explicit operator confirmation or after verifying zero uncommitted changes.
   This ensures a clean slate — stale pages from previous runs cannot linger and create orphans. This is what makes Stage 7D idempotent: every run produces a fresh, complete site derived from the current PRD state. The lead (not a teammate) performs this deletion.

1. **Verify Node.js version**: Run `node --version` — Mintlify CLI requires Node.js v20.17.0+. If the version is below this and can be upgraded, upgrade first. If Node.js upgrade is not feasible, skip `mint` CLI validation (note "CLI validation not available — Node.js below v20.17.0" in the report) and use manual validation only. Content generation does not require the Mintlify CLI — only `mint validate`, `mint dev`, and `mint broken-links` do.

2. **Read 7V report** — confirm production is stable. If 7V status is FAIL, STOP and report that Stage 7D requires a passing 7V.

3. **Check for 6P-R redesign** — If `./plancasting/_audits/visual-polish/design-plan.md` exists, Stage 6P-R (Frontend Design Elevation) was run. This means design tokens, colors, and typography have changed. Ensure all screenshots, `docs.json` color config, and branding references reflect the new design system. If this is a RE-RUN of 7D after 6P-R, read `/tmp/7d-prior-image-paths.txt` (captured during pre-generation cleanup) for the prior image path pattern to align new screenshot paths.

4. **Read Stage 5B report** — identify incomplete features to mark as "Coming Soon" or omit.

5. **Read PRD** — extract all user flows (UF-*), screen specs (SC-*), user stories (US-*), feature map, and product overview.

6. **Read Stage 6D help docs** (`docs/help/`, if exists) — extract content that can be adapted (not copied) for the Mintlify site.

7. **Read tech-stack.md** — extract product name, design direction (colors, typography, aesthetic), session language, and documentation platform config.

8. **Derive journey categories from the PRD** (the core generic algorithm):

   a. Read user flows from `prd/06-user-flows.md` — extract ALL UF-* entries. If `prd/06-user-flows.md` does not exist or contains no UF-* entries, fall back to `prd/02-feature-map-and-prioritization.md` — create one journey page per P0/P1 feature's core use case. Note this fallback in the audit report.

   b. Cluster flows by user goal. Clustering heuristics:
      - Flows sharing the same entry point or screen → same journey
      - Flows that form a sequential chain (UF-001 output is UF-002 input) → same journey
      - Flows involving the same domain entity (project, order, document, etc.) → same journey
      - Standalone flows (settings, billing, profile) → "account" or "managing" journey

   c. Name each journey using user-facing language (the user's goal, not the feature name):
      - E-commerce: "shopping", "checkout", "orders", "account"
      - Project management: "projects", "tasks", "team", "reporting"
      - Content platform: "creating", "publishing", "analytics", "collaboration"
      - SaaS tool: "getting-started", "core-workflow", "integrations", "account"
      - Developer tool: "setup", "building", "testing", "deploying"

   d. Order journeys by the natural user progression (onboarding → core value → advanced → admin).

   e. Map each UF-* to a page within its journey directory.

   **Page budget**: Target 15-30 pages per language (excluding API reference). If user flows would produce more than 30 journey pages, consolidate related flows into single pages with Tabs for variants.

   f. Determine concept pages from `prd/01-product-overview.md` and `prd/18-glossary-and-cross-references.md` — key product concepts that users need to understand.

   g. Check `prd/12-api-specifications.md` (if it exists) and the feature map — determine whether the product has a **public API** that end users interact with. If yes, note whether an OpenAPI spec file exists in the codebase. Record the decision (yes/no) and OpenAPI spec path (if any) for the content map — Teammate 2 uses this to decide whether to write API reference pages, and Teammate 3 uses it to include/exclude the API Reference tab in docs.json navigation.

9. **Build content map** — create `./_guide-context.md` in the same directory as `CLAUDE.md` (teammates must read this file before starting — it contains the authoritative content map and branding). Save to `./_guide-context.md` (same directory as `CLAUDE.md`). If `_guide-context.md` already exists (retained from a prior FAIL'd run — see Phase 5 step 2), read it first: if PRD files have been modified since the prior run (check `git diff` on `prd/`), regenerate the content map from scratch rather than reusing the stale context. Otherwise, reuse the content map and branding sections, then update only the screenshot mode and manifest fields in step 10. Include:
   - Product name, tagline, production URL
   - Journey groups with their pages and source UF-*/SC-*/US-* references
   - Concept pages and their sources
   - Writing style guidelines:
     - User guide: conversational tone, second person ("you"), present tense, imperative for instructions
     - No technical jargon — use product's user-facing terminology from glossary
     - Describe UI elements by their visible labels (from SC-* screen specs)
     - Include "what you should see" callouts at key steps (from US-* acceptance criteria)
   - Branding: colors (from Design Direction section), theme name, logo file path (if product logo from Stage 0 exists in the project)
   - Language config: session language code, multi-language yes/no, directory model — en/ + <lang>/ for multi-language, root-level for English-only (from step 5)
   - Incomplete features list (from Stage 5B) — mark as "Coming Soon" or omit
   - API reference: yes/no + OpenAPI spec path if exists (from step 8g)
   - Screenshot mode: initially set to `pending` — updated to `images`, `images-partial`, or `text-only` after step 10 completes (see step 10g). Screenshot mode selection: `images` = production URL is accessible AND Playwright is installed; `images-partial` = only some pages are accessible (e.g., behind auth wall without test credentials); `text-only` = Playwright unavailable OR no accessible URL. Teammates must check this field before embedding screenshots — if `text-only`, use `<Note>` callouts instead of `<Frame>` with `<img>`. If `images-partial`, use screenshots for pages that have them and `<Note>` callouts for pages marked SKIPPED in the manifest.
   - Feature priority mapping: P0/P1 = full guide pages, P2 = brief mention within related pages, P3+ = omit

10. **Capture screenshots via Playwright** (CRITICAL — must complete before spawning teammates):

   Use Playwright MCP browser tools to capture screenshots of the live application. These screenshots are embedded in the user guide pages by teammates.

   **Fallback**: If Playwright MCP browser tools are not available (MCP server not configured), set `Screenshot mode: text-only` in `_guide-context.md` and skip this step entirely. Teammates will use `<Note>` callouts with textual UI descriptions instead of screenshot embeds.

   **IMPORTANT — Do not default to text-only mode**: User documentation without screenshots is incomplete and unacceptable for non-technical users. The `text-only` fallback exists ONLY for environments where Playwright MCP tools are genuinely unavailable (no MCP server configured). If Playwright tools ARE available but some screenshots fail (e.g., auth login fails), capture ALL public page screenshots first — public pages (landing, login, signup, pricing, help, terms, privacy) require NO authentication and should always succeed. Only authenticated page screenshots should be marked as "SKIPPED" individually. A documentation site with public page screenshots + text descriptions for authenticated pages is far better than zero screenshots everywhere.

   **a. Generate the Screenshot Manifest**:
   Map each journey page from the content map to specific screenshots needed:

   ~~~markdown
   ## Screenshot Manifest
   | ID | Journey Page | URL | Auth | Entity State (the data condition the page displays — e.g., empty, populated, error, loading) | Viewport | Wait For | Filename |
   |----|-------------|-----|------|-------------|----------|----------|----------|
   | SS-001 | quickstart | / | none | — | 1440×900 | landing hero visible | landing-desktop.png |
   | SS-002 | quickstart | / | none | — | 375×812 | landing hero visible | landing-mobile.png |
   | SS-003 | getting-started/signup | /signup | none | — | 1440×900 | signup form visible | signup-desktop.png |
   | SS-004 | getting-started/dashboard | /dashboard | basic user | has projects | 1440×900 | project list visible | dashboard-desktop.png |
   | SS-005 | getting-started/dashboard | /dashboard | basic user | has projects | 375×812 | project list visible | dashboard-mobile.png |
   | ... |
   ~~~

   **b. Determine capture target**:
   - **Preferred**: Production URL (from Stage 7 — reflects real deployed state, production CSS/fonts)
   - **Fallback**: Dev server — BUT be aware of dev server limitations:
     - Dev servers (Next.js dev mode) may have race conditions where `ConvexProviderWithAuth` (or similar real-time auth providers) fails on the first token fetch during navigation (`net::ERR_ABORTED`), causing permanent "Session expired" error boundaries. Production builds do not have this issue.
     - If authenticated pages show "Session expired" on dev but the token endpoint returns 200, this is the dev-mode race condition — switch to production URL for authenticated captures.
   - If using production: verify the URL is accessible by using `browser_navigate` and confirming the page loads without error
   - If using dev: start the dev server using the command from `CLAUDE.md` or `plancasting/tech-stack.md`

   **c. Screenshot capture rules**:
   - **Viewports**: Desktop (1440×900) for ALL pages. Mobile (375×812) for key pages only (landing, dashboard, core feature page — max 5 mobile screenshots). `browser_resize` requires BOTH `width` AND `height` — always provide both values. Capture viewport-only screenshots (NOT full-page) — full-page captures of long pages produce unwieldy tall images that look poor in documentation.
   - **Screenshot budget**: Maximum **30 screenshots total**. Prioritize: landing/hero (1-2), quickstart flow (3-5), one screenshot per journey section (1 each), settings/billing (1-2). If the content map has 15+ journey pages, not every page needs a screenshot.
   - **Wait for content**: always wait for data to finish loading before capturing. Use `browser_wait_for` with the `text` parameter targeting visible text that confirms the page has loaded (e.g., `text: "Dashboard"`, `text: "Your Projects"`) — or use `textGone` to wait for loading text to disappear (e.g., `textGone: "Loading..."`). never capture while loading spinners are visible.
   - **Hide UI overlays**: always hide development and compliance overlays before capturing. Inject CSS to hide: Next.js dev indicator badge (bottom-left `nextjs-portal` element), cookie consent banners, and any other fixed-position dev/debug overlays. These elements are dev/compliance artifacts that clutter documentation screenshots and confuse users. Use `browser_evaluate` to inject:
     ~~~javascript
     const style = document.createElement('style');
     style.textContent = 'nextjs-portal, [data-nextjs-dialog-overlay], [data-nextjs-toast], [class*="cookie" i], [id*="cookie" i], [class*="consent" i], [id*="consent" i] { display: none !important; }';
     document.head.appendChild(style);
     document.querySelectorAll('nextjs-portal').forEach(el => el.remove());
     ~~~
     Also click "Accept All" on any cookie banner to dismiss it before capture.
   - **Dark mode** (optional): If the product supports dark mode and it's a selling point, capture 3-5 key screens in dark mode with `-dark` suffix. Skip if dark mode is secondary.
   - **Verify before committing**: After capturing each screenshot, visually verify it shows actual content — NOT loading spinners, "Session expired" screens, or error states. If a screenshot shows a loading/error state, retry after waiting longer or investigate the cause.

   **d. Capture process** (sequential):
   1. **Public pages first** (no auth required):
      - Use `browser_navigate` to visit each public URL
      - Use `browser_resize` to set viewport (e.g., `width: 1440, height: 900`)
      - Use `browser_wait_for` with `text` parameter to wait for visible content text (e.g., `text: "Welcome"`) or `textGone` to wait for loading text to disappear
      - Use `browser_take_screenshot` to capture
   2. **Authenticated pages** (requires login):
      - Read `./e2e/constants.ts` (or equivalent test credentials file) for test user credentials. If no test credentials file exists, check for demo accounts in the project README or documentation. If no credentials are available, skip authenticated screenshots and note them as "SKIPPED — no test credentials" in the manifest.
      - Use `browser_navigate` to go to the login page
      - Use `browser_snapshot` to get element refs for the login form fields, then use `browser_fill_form` (passing `ref` values from the snapshot) or `browser_click`/`browser_type` to log in with a test user (use a basic or standard-tier account from `e2e/constants.ts`)
      - After successful login, navigate to each authenticated route
      - For entity-state-dependent pages: navigate to an entity in the correct state (e.g., a project in "active" status for the project dashboard screenshot)
      - Use `browser_resize` (with both `width` and `height`) + `browser_wait_for` (with `text` or `textGone`) + `browser_take_screenshot` at each viewport
   3. **Element-level screenshots** (optional, for key interactions):
      - For specific UI elements that need highlighting (e.g., "click this button"), use `browser_evaluate` to inject a temporary CSS highlight before capturing:
        ~~~javascript
        document.querySelector('[data-testid="create-button"]').style.outline = '3px solid #FF0000';
        document.querySelector('[data-testid="create-button"]').style.outlineOffset = '4px';
        ~~~
      - Capture, then remove the highlight
      - Use sparingly — max 5 element-level screenshots across the entire guide

   **e. Save screenshots**:
   - Save ALL screenshots to `./user-guide/images/` using `browser_take_screenshot`'s `filename` parameter (e.g., `filename: "./user-guide/images/dashboard-desktop.png"`). If the `browser_take_screenshot` tool does not support a `filename` parameter, use `browser_evaluate` to trigger `page.screenshot({ path: '...' })` via Playwright's page API, or save the returned screenshot data to the target path using a file-write tool.
   - Use `images/` directory at the docs root — NOT `public/screenshots/`. Mintlify's monorepo mode may not correctly serve files from `public/` subdirectories, causing 403 errors on the CDN. The `images/` directory is Mintlify's conventional static asset location.
   - If the project's `.gitignore` contains `screenshots/` (common for E2E test artifacts), add `!user-guide/images/` exception to ensure doc images are tracked by git. Verify with `git ls-files user-guide/images/` after staging.
   - Naming convention: `<page-slug>-<viewport>.png` (e.g., `dashboard-desktop.png`, `signup-mobile.png`)
   - For dark mode: `<page-slug>-<viewport>-dark.png`
   - For element highlights: `<page-slug>-<element>-highlight.png`

   **f. Add the screenshot manifest to `_guide-context.md`**:
   Append the completed manifest (with actual filenames and paths) so teammates know exactly which screenshots exist and can reference them. Include the Mintlify-relative path for each: `/images/<filename>` (served from docs root `images/` directory).

   **g. Screenshot failure handling** (tiered — never skip all screenshots without trying):

   **Tier 1 — Public pages (must capture, no auth required)**:
   Public pages (landing, login, signup, pricing, help, terms, privacy, forgot-password) require NO authentication. These screenshots must be captured regardless of auth status. If ANY public page fails to load, investigate (DNS, SSL, server error) before skipping. Public page screenshot failure is a BLOCKER — resolve it or document the specific error.

   **Tier 2 — Authenticated pages (best-effort, PRODUCTION FIRST)**:
   - always attempt production first for authenticated captures — production builds handle auth correctly
   - If login succeeds on production → capture all authenticated page screenshots
   - If login fails on production → try dev server login as fallback. BUT: if dev server shows "Session expired" on dashboard/settings after successful login redirect, this is a dev-mode auth race condition (NOT a credentials issue). Switch back to production and investigate the login failure there.
   - If login fails on both → mark authenticated screenshots as "SKIPPED — auth login unavailable" individually in the manifest. Do not set the entire mode to `text-only`.
   - **Common auth pitfall**: The login form may succeed (URL redirects to /dashboard) but the page shows "Session expired" because the real-time auth provider's token fetch was aborted during the hard navigation. This is a dev-mode-only issue. If this happens, always try production URL before giving up.

   **Tier 3 — Overall mode decision**:
   - If Tier 1 (public) screenshots ALL succeed → set mode to `images` regardless of Tier 2 results
   - If some Tier 2 (authenticated) screenshots are skipped → set mode to `images-partial` and note which authenticated pages lack screenshots
   - ONLY set `text-only` if the production URL AND dev server are BOTH completely inaccessible (no pages load at all)

   After capture completes: update the `Screenshot mode` field in `_guide-context.md` from `pending` to `images` (all captured), `images-partial` (public captured, some auth skipped), or `text-only` (nothing capturable). The screenshot mode in `_guide-context.md` must be finalized BEFORE spawning any teammates in Phase 2.

   **h. Animated recordings (optional enhancement)**:
   If the project has Playwright recording scripts at `./e2e/doc-recordings/`, capture animated screen recordings for interactive flows. Animated recordings provide significantly better visual context than static screenshots for form filling, navigation, and toggle interactions. When a page has an animated recording, it REPLACES the static screenshot (do not show both — the video's first frame acts as the static image).

   **Prerequisites**:
   - `ffmpeg` installed (`brew install ffmpeg` on macOS)
   - Playwright browsers installed (`npx playwright install --with-deps chromium`)
   - A standalone Playwright config at `./e2e/doc-recordings/playwright.recordings.config.ts` (skips globalSetup and webServer — recordings target production or dev URL directly)

   **Recording architecture**:
   - `record-flows.spec.ts` — Public pages (landing, signup, login, pricing, help, forgot-password). No auth needed. Always succeeds.
   - `record-auth-flows.spec.ts` — Authenticated pages (dashboard, project detail, settings, billing). Requires valid credentials.
   - Each test enables `video: "on"` in the Playwright context, which records a WebM file for the entire test duration.
   - After recording, `convert-recordings.sh` converts WebM → MP4 (primary, H.264 CRF 28) and GIF (fallback).

   **Running recordings**:
   ~~~bash
   # Public pages (always use production URL)
   PLAYWRIGHT_BASE_URL=https://your-production-url.com \
     bunx playwright test --config=e2e/doc-recordings/playwright.recordings.config.ts \
     e2e/doc-recordings/record-flows.spec.ts

   # Auth pages (must use production URL — dev server has auth race conditions)
   TEST_EMAIL=user@example.com TEST_PASSWORD=password \
   PLAYWRIGHT_BASE_URL=https://your-production-url.com \
     bunx playwright test --config=e2e/doc-recordings/playwright.recordings.config.ts \
     e2e/doc-recordings/record-auth-flows.spec.ts

   # Convert WebM to MP4/GIF
   ./e2e/doc-recordings/convert-recordings.sh
   ~~~

   **CRITICAL — Auth recordings must target production**:
   Dev servers (Next.js dev mode) have a known race condition where the first `POST /api/auth/token` gets `net::ERR_ABORTED` during navigation, causing React error boundaries to permanently show "Session expired". This does not happen in production builds. Always use the production URL for authenticated recordings. The conversion script trims the first ~10 seconds (login/navigation) from auth recordings using `ffmpeg -ss`.

   **Overlay hiding**:
   Both recording scripts inject CSS to hide Next.js dev badge, cookie consent banners, and other overlays via a `hideOverlays()` function called after each `page.goto()`. This uses `page.addStyleTag()` with selectors targeting `nextjs-portal`, `[class*="cookie" i]`, `[class*="consent" i]`, etc. The overlays are hidden from the FIRST frame of the recording.

   **Embedding in MDX**:
   ~~~mdx
   <video autoPlay muted loop playsInline className="w-full aspect-video rounded-xl" src="/images/<name>.mp4"></video>
   ~~~
   - When a page has an animated recording, use the `<video>` tag INSTEAD of the static `![alt](/images/...)` screenshot — not alongside it. The video replaces the screenshot.
   - Mintlify fully supports `<video>` HTML tags in MDX. Use camelCase attributes (`autoPlay`, `playsInline`).
   - The MP4 format is preferred (smaller, higher quality). GIF is a fallback for markdown-only contexts.

   **Budget**:
   - Maximum 1 animated recording per page
   - Keep each recording 5-15 seconds
   - MP4 under 1MB, GIF under 2MB
   - For oversized GIFs: reduce fps (`fps=6`), scale (`scale=480:-1`), or trim duration (`-t 10`)

   **Failure handling**:
   - If `ffmpeg` is not available → skip recordings, use static screenshots
   - If public recordings fail → investigate (DNS, server error) before skipping
   - If auth recordings fail (login fails) → use static screenshots for auth pages, recordings for public pages
   - If auth recordings show "Session expired" → switch to production URL (dev server race condition)
   - A mix of recordings (public) + screenshots (auth) is acceptable

   **Manifest update**: Add a `Recordings` section to the screenshot manifest in `_guide-context.md` listing available MP4 files. Teammates check this manifest before embedding — if a recording exists for a page, use `<video>` instead of `![screenshot]`.

11. **Create task list** for all teammates with dependency tracking.

### Phase 2: Spawn Documentation Teammates

Spawn the following 3 teammates. Each teammate's spawn prompt must include the content map from `./_guide-context.md`.

**Dependency model**: Teammates 1, 2, and 3 run **in parallel** for their content/config creation work. However, Teammate 3's **validation step** (task 5) must wait until Teammates 1 and 2 have completed — it needs the final MDX files to validate navigation, links, and jargon. The lead must coordinate this: spawn all 3 at once, but instruct Teammate 3 to complete tasks 1-4 first, then message the lead and wait for clearance before running task 5.

**If a teammate fails**: If any teammate encounters an unrecoverable error (e.g., missing PRD files, unresolvable branding), it must message the lead immediately with the blocker. The lead should attempt to resolve the issue (provide missing input, adjust content map) and resume the teammate. Do not spawn replacement teammates — resume the original.

#### Teammate 1: "journey-writer"
**Scope**: All journey guide pages + introduction + quickstart

~~~
You are writing the user-facing journey guides for a Mintlify documentation site.

Read CLAUDE.md first. Then verify ./_guide-context.md exists in the project root — if it does not, message the lead immediately. Read it for the content map, writing style, and journey structure.

For EACH journey page assigned in the content map:

1. Read the source UF-* flow from `./plancasting/prd/06-user-flows.md` — extract happy path steps.
2. Read the source SC-* screen specs from `./plancasting/prd/08-screen-specifications.md` — extract visible UI labels, layout zones, component descriptions.
3. Read the source US-* stories from `./plancasting/prd/04-epics-and-user-stories.md` — extract acceptance criteria for "what you should see" callouts.
4. Read relevant BR-* (or BRL-*) from `./plancasting/brd/14-business-rules-and-logic.md` — extract plan-tier restrictions and validation rules.

For each page, write:
- Frontmatter: title (user's goal, not feature name), description (what they'll accomplish), icon, sidebarTitle
- **never start the body with a `# Title` heading** — Mintlify auto-renders the frontmatter `title` as the page's h1. Adding `# Title` in the body creates a duplicate. Start with a paragraph or `##` subheading.
- Opening paragraph: what the user wants to accomplish and why
- **Hero visual** (check manifest for recordings first, then screenshots):
  - If an animated recording (MP4) exists for this page in the manifest `Recordings` section, embed it using a `<video>` tag — this REPLACES the static screenshot:
    ~~~mdx
    <video autoPlay muted loop playsInline className="w-full aspect-video rounded-xl" src="/images/signup-flow.mp4"></video>
    ~~~
  - If NO recording exists but a static screenshot does, use standard markdown image syntax:
    ~~~mdx
    ![Project dashboard with active projects listed](/images/dashboard-desktop.png)
    ~~~
  - Use markdown `![alt](/images/file.png)` syntax for screenshots — NOT `<Frame><img src="..." /></Frame>`. The Frame+img pattern can cause 403 CDN errors on Mintlify's hosting. Standard markdown images work reliably.
  - Do not embed both a recording AND a static screenshot for the same page. The video's first frame serves as the static visual. Showing both creates redundant, cluttered content.
- Step-by-step instructions using <Steps>/<Step> components
- **Step screenshots** (if available in the manifest): embed within the relevant `<Step>` to show what the user should see at that point. Maximum 1-2 inline screenshots per page — use text descriptions for other steps.
- Reference UI elements by their VISIBLE LABELS (button text, field labels from SC-* specs)
- Add <Note> callouts for "what you should see" at key steps (from US-* acceptance criteria) — use these for steps WITHOUT screenshots
- Add <Tip> callouts for shortcuts, best practices, or time-saving suggestions
- Add <Info> callouts for plan-tier restrictions from BR-* (or BRL-*) ("This feature requires the Pro plan")
- Add <Warning> callouts for validation rules from BR-* (or BRL-*) ("Maximum 10 items per project on the Starter plan")
- Add <Info> callouts for prerequisites or important context
- "Next steps" section at the bottom linking to the next logical journey page
- If a page has both desktop and mobile screenshots in the manifest, use `<Tabs>` to show both:
  ~~~mdx
  <Tabs>
    <Tab title="Desktop">
      ![Dashboard desktop view](/images/dashboard-desktop.png)
    </Tab>
    <Tab title="Mobile">
      ![Dashboard mobile view](/images/dashboard-mobile.png)
    </Tab>
  </Tabs>
  ~~~
- never reference a screenshot that is not in the manifest. If a screenshot is listed as "SKIPPED" in the manifest, use a `<Note>` text description instead.
- If `_guide-context.md` indicates screenshot mode is `text-only`, do not embed any screenshots — use `<Note>` callouts describing the UI for ALL pages instead.
- **always escape dollar signs before numbers** — MDX interprets `$...$` as LaTeX math. Write `\$69`, `\$149`, NOT `$69`, `$149`. This applies to ALL currency amounts in pricing tables, cost comparisons, and inline text.

ALSO write:
- introduction.mdx: Welcome page with product overview (from PRD 01), value proposition, navigation guide using <Card> components
- quickstart.mdx: The shortest path from signup to first meaningful action — use the first UF-* flow, condensed to essential steps

If multi-language: Generate English first under en/. Then translate all pages to session language under <session-lang>/. The translated version must have identical page structure — same files, same sections, same MDX components.

If single-language (English only): Generate all pages directly under the user-guide/ root (NOT under an en/ subdirectory). Do not create language subdirectories.

Component usage guide:
- <Steps>/<Step> for all procedures (never use numbered markdown lists for instructions)
- <Note>, <Warning>, <Tip>, <Info>, <Check>, <Danger> for callouts (do not use markdown blockquotes)
- <Card title="..." icon="..." href="/path"> for feature highlights and "next steps"
- <Tabs>/<Tab> when showing alternatives (e.g., "Desktop" vs "Mobile" instructions)
- <AccordionGroup>/<Accordion> for in-page FAQs or optional details
- For screenshots and diagrams, use markdown syntax: `![alt](/images/file.png)`. ONLY reference screenshots listed in the manifest from `_guide-context.md`.
- <Columns cols={2}> with <Tile> or <Card> for "Next steps" or "Related guides" sections
- Reusable snippets via MDX imports: `import Prerequisites from '/snippets/prerequisites.mdx'` then `<Prerequisites />` — use for the prerequisites callout
- Support CTA snippet: `import SupportCta from '/snippets/support-cta.mdx'` then `<SupportCta />` — use at page bottom

When done, message the lead with: number of journey pages created, languages generated, content coverage (UF-* flows covered vs total).
~~~

#### Teammate 2: "concepts-and-reference-writer"
**Scope**: Concept pages, FAQ, troubleshooting, changelog, API reference (conditional)

~~~
You are writing concept explanations, FAQ, troubleshooting, changelog, and optionally API reference for a Mintlify documentation site.

Read CLAUDE.md first. Then verify ./_guide-context.md exists — if it does not, message the lead immediately. Read it for the content map and writing style.

Your tasks:

1. CONCEPT PAGES (under concepts/):
   For each concept listed in the content map:
   - Read `./plancasting/prd/01-product-overview.md` for the product's core concepts
   - Read `./plancasting/prd/18-glossary-and-cross-references.md` for terminology
   - Write a clear, jargon-free explanation of what the concept is and why it matters to the user
   - Use Mermaid fenced code blocks (triple-backtick mermaid) for diagrams where helpful (e.g., process flows, relationships)
   - Use <Accordion> for "deeper explanation" sections that advanced users might want

2. FAQ (faq.mdx):
   - Read ALL user stories from `./plancasting/prd/04-epics-and-user-stories.md`
   - Extract common questions from acceptance criteria ("Can I...?", "What happens when...?")
   - Read `./plancasting/brd/14-business-rules-and-logic.md` for business rule questions ("Why can't I...?")
   - Structure as <AccordionGroup> with <Accordion> for each Q&A
   - Group by topic (account, features, billing, etc.)

3. TROUBLESHOOTING (troubleshooting.mdx):
   - Read ./plancasting/_audits/production-smoke/report.md and ./plancasting/_audits/visual-verification/report.md (if it exists) for common issues
   - Read `./plancasting/prd/09-interaction-patterns.md` for error states and recovery flows
   - Structure as problem → cause → solution
   - Use <Steps> for multi-step solutions

4. CHANGELOG (changelog.mdx):
   - Read `./plancasting/prd/03-release-plan.md` (if exists) for feature release information
   - If `./plancasting/prd/03-release-plan.md` does not exist, derive release information from `./plancasting/prd/02-feature-map-and-prioritization.md` (list P0/P1 features as the initial release)
   - Use <Update label="v1.0" description="Initial Release" tags={["feature"]}> components
   - List features with user-facing descriptions (not FEAT-IDs)

5. API REFERENCE (conditional — check the content map for the API reference decision from the lead's analysis):
   - If the content map says "no public API": skip this task entirely
   - If the content map says "yes" with an OpenAPI spec path: skip writing manual pages — Teammate 3 will configure the API tab in docs.json using the OpenAPI spec for auto-generated endpoint pages
   - If the content map says "yes" but no OpenAPI spec: create manual API reference pages under api-reference/ using <ParamField>, <ResponseField>, <Expandable>, deriving endpoint documentation from prd/12-api-specifications.md

**Visual embedding**: First check the `Screenshot mode` field in `_guide-context.md` — if `text-only`, skip ALL visual embedding and use `<Note>` callouts describing the UI instead. If mode is `images`: check BOTH the `Recordings` section (MP4 videos) and the screenshot manifest. If an animated recording exists for a page, use `<video autoPlay muted loop playsInline className="w-full aspect-video rounded-xl" src="/images/<name>.mp4"></video>` INSTEAD of a static screenshot (same rules as Teammate 1 — recordings replace screenshots, never alongside). If no recording exists, use markdown syntax: `![Alt text](/images/file.png)`. never reference a media file that is not in the manifest.

**always escape dollar signs before numbers** — MDX interprets `$...$` as LaTeX math. Write `\$69`, `\$149`, NOT `$69`, `$149`. This applies to ALL currency amounts in pricing tables, cost comparisons, FAQ answers, and inline text.

- **never start the body with a `# Title` heading** — Mintlify auto-renders the frontmatter `title` as the page's h1. Start with a paragraph or `##` subheading.

If multi-language: Generate English first under en/, then translate to session language under <session-lang>/. Same structure, same page count.

If single-language (English only): Generate all pages directly under the user-guide/ root (NOT under an en/ subdirectory).

When done, message the lead with: number of concept pages, FAQ entries, troubleshooting items, changelog entries, API reference status.
~~~

#### Teammate 3: "config-and-structure"
**Scope**: docs.json configuration, snippets, static assets, link validation

~~~
You are setting up the Mintlify project structure, configuration, and validating the documentation site.

Read CLAUDE.md first. Then verify ./_guide-context.md exists — if it does not, message the lead immediately. Read it for the content map, branding, and language config.
Read tech-stack.md for product name, design direction (colors, typography).

- Do not include `# Title` (h1) as the first line of MDX body content. Mintlify auto-renders the frontmatter `title` as h1 — a duplicate h1 in the body doubles the heading. Start with a paragraph or `## Heading`.

Your tasks:

1. ROOT docs.json:
   Create user-guide/docs.json with:
   ~~~json
   {
     "$schema": "https://mintlify.com/docs.json",
     "name": "<Product Name>",
     "theme": "<best-fit from: mint|maple|palm|willow|linden|almond|aspen|luma|sequoia>",
     "logo": {
       "light": "/logo.png",
       "dark": "/logo-dark.png",
       "href": "<production URL>"
     },
     "favicon": "/favicon.png",
     "colors": {
       "primary": "<from tech-stack.md Design Direction>",
       "light": "<lighter variant>",
       "dark": "<darker variant>"
     },
     "navbar": {
       "links": [{ "label": "App", "url": "<production URL>" }],
       "primaryButton": { "label": "Get Started", "url": "<production URL>/signup" }
     },
     "search": { "prompt": "Search <Product Name> docs..." },
     "feedback": { "thumbsRating": true, "suggestEdit": true },
     "canonicalUrl": "https://docs.<product-domain>"
   }
   ~~~
   If multi-language, add the `languages` array inside the `navigation` object (see the validated template below for the exact structure):
   ~~~json
   "navigation": {
     "languages": [
       { "language": "en", "name": "English", "isDefault": true, "groups": [...] },
       { "language": "<code>", "name": "<Language Name>", "groups": [...] }
     ]
   }
   ~~~
   If single-language (English only): Do not add the `languages` array. Instead, add the navigation block from task 2 directly into this root docs.json (combine branding config + navigation into one file). Skip task 2 entirely.

   Use this VALIDATED template as the starting point for docs.json (adapt names, colors, and pages):
   ~~~json
   {
     "$schema": "https://mintlify.com/docs.json",
     "theme": "mint",
     "name": "Product Name",
     "logo": { "light": "/logo-light.svg", "dark": "/logo-dark.svg" },
     "favicon": "/favicon.svg",
     "colors": { "primary": "#0891b2", "light": "#22d3ee", "dark": "#0891b2" },
     "navigation": {
       "languages": [
         {
           "language": "en",
           "name": "English",
           "isDefault": true,
           "groups": [
             { "group": "Getting Started", "pages": ["introduction", "quickstart"] }
           ]
         }
       ]
     }
   }
   ~~~
   Do not add: `colors.anchors`, top-level `anchors` array, or `navigation` as a bare array. The `languages` array belongs inside the `navigation` object, not at the root level.

2. NAVIGATION STRUCTURE (defines the navigation hierarchy for the validated template above):
   For multi-language: replace the minimal `groups` in each `navigation.languages[]` entry (task 1 template) with this full anchors → groups → pages hierarchy. For single-language: use this structure directly as the `navigation` object in the root docs.json.
   ~~~json
   {
     "navigation": {
       "anchors": [
         {
           "anchor": "Guides",
           "icon": "book-open",
           "groups": [
             { "group": "Welcome", "pages": ["introduction", "quickstart"] },
             { "group": "<Journey Name>", "icon": "<icon>", "expanded": true, "pages": [...] }
           ]
         },
         {
           "anchor": "Concepts",
           "icon": "lightbulb",
           "groups": [
             { "group": "Concepts", "pages": ["concepts/..."] }
           ]
         },
         {
           "anchor": "Help",
           "icon": "circle-question",
           "groups": [
             { "group": "Help", "pages": ["faq", "troubleshooting", "changelog"] }
           ]
         }
       ],
       "tabs": [
         { "tab": "API Reference", "icon": "square-terminal", "openapi": "<path from content map>" }
       ]
     }
   }
   ~~~
   - Include API Reference tab ONLY if product has a public API
   - First journey group should have `"expanded": true`
   - Page paths are relative to language directory, no extensions
   If single-language (English only): Skip this task — navigation is embedded in the root docs.json (task 1). Page paths are relative to `./user-guide/` root (e.g., `"introduction"`, `"journeys/getting-started/signup"`).

3. STATIC ASSETS (public/):
   - Check if Stage 0 collected a product logo (recorded in tech-stack.md Design Direction section — look for logo file paths or intake notes). If a logo file exists in the project root or assets directory, copy it to user-guide/public/.
   - If no logo is available, extract from tech-stack.md Design Direction or create a text-based placeholder using the product name.
   - If Figma URL exists in tech-stack.md, note it for manual logo extraction.
   - Create favicon — prefer the product logo resized, or create a text-based placeholder.

4. SNIPPETS (snippets/):
   - prerequisites.mdx: Reusable prerequisite callout (e.g., "You need an account to follow this guide")
   - support-cta.mdx: Reusable support call-to-action (e.g., "Need help? Contact support at...")

5. VALIDATION (BLOCKED — wait for teammates 1 and 2 to complete before running this task):
   After completing tasks 1-4, message the lead and WAIT. The lead will message: 'Teammates 1 and 2 are done. Proceed with task 5 validation.' Do not proceed until you receive clearance. Then:

   **a. Structure & link validation** — prefer the Mintlify CLI (install with `npm i -g mint` or use `npx mint`). From the `./user-guide/` directory:
   - Run `mint validate` — catches invalid docs.json, missing nav pages, and build errors
   - Run `mint broken-links` — catches broken internal links across all MDX files
   - Run `mint a11y` — catches accessibility issues in documentation pages
   If CLI is not available, perform these checks manually and note "CLI validation not available" in results:
   - Validate ALL docs.json files parse as valid JSON
   - Verify EVERY page listed in navigation exists as an .mdx file
   - Verify NO orphan pages exist (MDX files not in any navigation)
   - Verify all internal links ([text](/path)) resolve to existing pages

   **b. Content quality checks** (always manual — CLI does not cover these):
   - Scan ALL MDX files for jargon leakage. Two categories:
     i. **Always flag** (technical/framework identifiers): PRD/BRD specification IDs (e.g., "FEAT-", "US-", "SC-", "FR-", "BR-", "BRL-", "UF-"), pipeline terminology ("pipeline stage", "stage 5"), technical database terms ("schema", "validator", "mutation", "query" when used in database context)
     ii. **Flag with context** (common words that MAY be jargon): "action", "workflow" — only flag these if they appear in a technical context (e.g., "Convex action" or "trigger the workflow"), NOT in general usage (e.g., "take action" or "your workflow")
   - Verify every image reference in MDX files (markdown `![](/images/...)` syntax) points to an actual file in `user-guide/images/`. Broken screenshot paths cause visible broken images in the deployed docs site.
   - Verify every page has a meaningful `description` in its frontmatter (not empty, not a placeholder) — Mintlify uses this for auto-generated llms.txt and internal search
   - If multi-language: verify en/ and <session-lang>/ have identical directory structure and page count

   Report validation results to the lead (include CLI output if available).

When done, message the lead with: docs.json structure, navigation groups, validation results (pass/fail with issues).
~~~

### Phase 3: Coordination During Execution

While teammates are working:
1. Monitor progress via the shared task list.
2. Coordinate content consistency:
   - If a teammate needs to deviate from the content map (e.g., splitting a page into two, merging pages, or adding an unplanned page), they must message the lead. The lead updates the content map and notifies Teammate 3 to adjust navigation.
   - When concepts-and-reference-writer finalizes terminology in concept pages, verify journey-writer uses the same terms.
3. Ensure all cross-page links are consistent between teammates' output.
4. When Teammates 1 and 2 both report completion, notify Teammate 3 to proceed with task 5 (validation).

### Phase 4: Review & Audit

After all teammates complete:

1. Review Teammate 3's CLI validation results. If Teammate 3 reported all CLI checks passing, accept the results and move on. If Teammate 3 reported "CLI validation not available" or results are unclear, run CLI checks from the `./user-guide/` directory (requires Node.js v20.17.0+):
   - `mint validate` — verify the build succeeds, docs.json is valid, all nav pages exist, no orphans
   - `mint broken-links` — verify no broken internal links
   - `mint a11y` — verify accessibility compliance
   - `mint dev` — optionally start local preview to visually spot-check pages
   If the `mint` CLI is not installed, use `npx mint validate` / `npx mint broken-links` / `npx mint a11y` (or `bunx` if using Bun). If CLI is completely unavailable, manually validate: all docs.json files parse as valid JSON, every page in navigation exists, every MDX file is in navigation (no orphans). Note "CLI validation not available — manual verification only" in the audit report.
2. **Validate docs.json schema** (MANDATORY — blocks commit):
   ~~~bash
   cd ./user-guide && npx mint validate
   ~~~
   If validation fails, fix the errors before proceeding. Common errors:
   - "Invalid discriminator value" for `theme` → add `"theme": "mint"` (or another valid theme)
   - "Unrecognized key(s) in object: 'anchors'" → remove `colors.anchors` and top-level `anchors`
   - "Expected field to be of type 'object', received 'array'" for `navigation` → restructure as object with `groups` array
   - "Invalid docs.json" with no details → check for trailing commas, missing quotes, or syntax errors
3. Verify no PRD/BRD jargon leaked into user-facing content.
4. Verify incomplete features from 5B are marked "Coming Soon" or omitted.
5. Spot-check screenshot references: verify 3-5 random `![](/images/...)` image references in MDX files point to actual files in `user-guide/images/` (Teammate 3 validates exhaustively in step 5; this is a lead failsafe).
6. If multi-language: verify translation parity (identical structure, page count).
7. Create the audit output directory:
   ~~~bash
   mkdir -p ./plancasting/_audits/user-guide
   ~~~
   Generate audit report at `./plancasting/_audits/user-guide/report.md`:

~~~markdown
# User Guide Generation Report — Stage 7D

## Summary
- **Generation Date**: [date]
- **Production URL**: [url]
- **Mintlify Theme**: [theme]
- **Languages**: [list]
- **Total Pages**: [n] (per language)

## Structure Validation
- Root docs.json: VALID / INVALID ([error])
- Navigation model: Root-centralized / N/A (English-only — navigation in root docs.json)
- Navigation entries: [n] pages configured
- Orphan pages: [n] ([list])
- Missing pages: [n] ([list — in nav but no file])

## Content Coverage
- User flows documented: [n]/[total] ([%])
- P0 features covered: [n]/[total]
- P1 features covered: [n]/[total]
- P2 features mentioned: [n]/[total]
- Incomplete features (from 5B) marked "Coming Soon": [n]

## Screenshot Coverage
- Screenshot mode: images / images-partial / text-only
- Screenshots in manifest: [n]
- Successfully captured: [n]
- Skipped (page load failure or timeout): [n] — [list]
- Capture target: Production URL / Dev server
- Desktop screenshots: [n]
- Mobile screenshots: [n]
- Dark mode screenshots: [n]
- Element highlight screenshots: [n]
- Animated recordings (MP4): [n] ([list — public vs auth])
- Pages with embedded visuals: [n]/[total journey pages] (screenshots: [n], recordings: [n])
- Broken media references: [n] ([list — image/video references pointing to non-existent files])
- Total media size: [n] MB

## Jargon Scan
- Technical terms found: [n] ([list with file and line])
- PRD/BRD identifiers found: [n] ([list])

## Link Integrity
- Internal links checked: [n]
- Broken links: [n] ([list])

## Translation Parity (if multi-language)
- en/ page count: [n]
- <session-lang>/ page count: [n]
- Structure match: YES / NO ([differences])

## Mintlify CLI Checks
- `mint validate`: PASS / FAIL / NOT TESTED ([reason])
- `mint broken-links`: PASS / FAIL ([n] broken) / NOT TESTED
- `mint a11y`: PASS / FAIL ([n] issues) / NOT TESTED
- Local preview (`mint dev`): VERIFIED / NOT TESTED

## Gate Decision
- **PASS**: All P0/P1 features documented, no jargon, no broken links, valid config, CLI checks pass (or N/A if CLI unavailable)
- **WARN**: P0/P1 fully covered but: P2 gaps, minor style inconsistencies, minor `mint a11y` issues, or CLI checks not tested (CLI unavailable) — deploy with known issues
- **FAIL**: Missing P0/P1 coverage, broken navigation, invalid config, broken screenshot references — fix before deploying
~~~

## Next Steps

After Stage 7D completes:
- **PASS or WARN**: The product is documented and ready for post-launch. Proceed to **Stage 8 (Feedback Loop)** when user feedback is collected, or **Stage 9 (Dependency Maintenance)** on a monthly/quarterly cadence.
- **FAIL**: Fix documentation issues and re-run 7D before proceeding.

Stages 8 and 9 are never concurrent — both modify `package.json` and source code. Run one, commit all changes, then start the other in a new session. See execution-guide.md § "Stage 9" for coordination details.

### Phase 5: Shutdown

1. Verify all teammates have sent completion messages. Teammates terminate automatically after completing their tasks.
2. After stage completion: if PASS or WARN, delete `./_guide-context.md` (temporary artifact). If FAIL, retain it to avoid regenerating the content map on re-run. Do not commit `_guide-context.md` to version control — add it to `.gitignore` if not already present (`echo '_guide-context.md' >> .gitignore`). The lead (not a teammate) performs the deletion after all teammates have shut down.
3. Output summary: total pages created, languages, content coverage, gate decision.

### Gate Decision Criteria

Apply the following gate logic to determine the audit report's Gate Decision:

| Decision | Criteria |
|---|---|
| **PASS** | All P0/P1 features documented, zero jargon leakage, zero broken links, all docs.json files valid, all navigation entries resolve, translation parity (if multi-language), CLI checks pass (or N/A if CLI unavailable) |
| **WARN** | P0/P1 fully covered but: P2 coverage gaps, minor style inconsistencies, 1-2 jargon instances in non-critical pages, orphan pages (MDX files not in any navigation), minor `mint a11y` issues, or Mintlify CLI checks not tested (CLI unavailable). Deploy with known issues documented. |
| **FAIL** | Any of: missing P0/P1 feature coverage, broken navigation (pages in nav but no file), invalid docs.json, ≥3 'always flag' jargon instances (PRD/BRD identifiers like FEAT-NNN, US-NNN, SC-NNN, FR-NNN, BR-NNN), OR any jargon instance in introduction.mdx or quickstart.mdx, translation structure mismatch, broken screenshot references (image references pointing to non-existent files). Fix before deploying. |

Note: 7D uses WARN instead of CONDITIONAL PASS because documentation gaps are less severe than code defects — WARN indicates "deployable with known documentation gaps."

## Documentation Completion Criteria

7D is COMPLETE when:
1. Documentation site deploys successfully (Mintlify or equivalent)
2. All P0/P1 features have getting-started or how-to guides
3. FAQ covers common use cases from PRD
4. Troubleshooting guide covers error states and recovery
5. All internal links verified (no 404s)
6. Mobile responsiveness verified at 375px, 768px, 1440px

Gate: PASS (all criteria met) / WARN (minor gaps documented) / FAIL (critical content missing or site won't deploy).

## Content Generation Rules

For each guide page, follow this transformation pipeline:

1. **Identify the user flow** (from `prd/06-user-flows.md`):
   - Extract the happy path steps
   - Extract entry points and exit points

2. **Enrich with screen specs** (from `prd/08-screen-specifications.md`):
   - For each step, find the matching SC-* screen spec
   - Use visible labels (button text, field labels) instead of component names

3. **Add acceptance criteria** (from `prd/04-epics-and-user-stories.md`):
   - Transform "Given/When/Then" into "What you should see" <Note> callouts

4. **Apply business rules** (from `brd/14-business-rules-and-logic.md`):
   - Plan-tier restrictions → <Info> callouts ("This feature requires the Pro plan")
   - Validation rules → <Warning> callouts ("Maximum 10 items per project on the Starter plan")

5. **Embed visuals** (from the manifest in `_guide-context.md`):
   - First check the screenshot mode field in `_guide-context.md` — if `text-only`, skip ALL visual embedding and use `<Note>` callouts for every page instead
   - Check the `Recordings` section of the manifest first — if an MP4 recording exists for this page, embed it with `<video autoPlay muted loop playsInline className="w-full aspect-video rounded-xl" src="/images/<name>.mp4"></video>` INSTEAD of a static screenshot (do not show both)
   - If no recording exists, check the screenshot manifest — embed with `![alt](/images/file.png)` markdown syntax
   - Place the hero visual after the opening paragraph, before the first `<Steps>` block
   - Place step-level screenshots inside the relevant `<Step>` element
   - If no visual exists for this page, use `<Note>` callouts describing what the user should see

6. **Rewrite for the audience**:
   - Replace ALL technical terms with user-facing language
   - Use the product's terminology from `prd/18-glossary-and-cross-references.md`
   - Write in second person ("you"), present tense, imperative mood for instructions
   - NO: "Execute the mutation to persist the entity" → YES: "Click **Save** to save your changes"

## Cross-Stage References

- **If 7V FAIL**: Do not run this stage. Fix production issues first, re-run 7V, then proceed to 7D.
- **After generating user guide**: Push to trigger Mintlify auto-deploy. Verify the deployed docs site is accessible.
- **If UI changes are made after 7D** (via Stage 8 Feedback Loop or hotfixes): Re-run the affected journey pages to keep docs in sync, or update MDX files directly. Stage 8's test-and-docs-updater teammate is configured to update `./user-guide/` when UI changes occur. If UI changes affect screenshotted/recorded pages, recapture the affected media:
  - For screenshots: re-run Phase 1 step 10 with a filtered manifest (only the changed pages)
  - For animated recordings: re-run `bunx playwright test --config=e2e/doc-recordings/playwright.recordings.config.ts` for the affected spec files, then `./e2e/doc-recordings/convert-recordings.sh` to reconvert
- **Stage 8 integration**: Stage 8 (Feedback Loop) includes a "Documentation" feedback category. User feedback about unclear or missing documentation routes back to updating the Mintlify site. Stage 8's test-and-docs-updater teammate generates documentation fixes. After Stage 8 completes, if documentation was updated: either (a) manually edit the affected MDX files in `./user-guide/`, or (b) re-run Stage 7D in full to regenerate all pages with latest production state (recommended if >3 pages affected).
- **After Stage 6P-R merge**: If 6P-R was used (design overhaul), always re-run 7D to recapture screenshots reflecting the new design. Verify image paths: `grep -r 'src="' user-guide/ --include='*.mdx'`.
- **Stage 9 integration**: If dependency updates change UI behavior or component APIs, re-verify affected journey pages.
- **Re-running 7D**: This stage is idempotent — re-running it deletes and recreates the entire `./user-guide/` directory with fresh content derived from the current PRD. WARNING: Custom content manually added after a prior 7D run will be DESTROYED. Commit or backup any custom changes before re-running 7D. **Pre-flight cleanup**: Follow the Phase 1 pre-generation cleanup safety protocol (check git status, verify no custom content via `git diff ./user-guide/`, get operator confirmation before deletion). Do not use `rm -rf` without these safety checks. Use this after significant PRD changes or major feature releases.

## Critical Rules

1. never copy PRD text verbatim into user documentation — rewrite for non-technical users.
2. never organize by feature ID — organize by user journey (what the user wants to accomplish).
3. never use numbered markdown lists for procedures — always use `<Steps>`/`<Step>` components.
4. never use markdown blockquotes for callouts — always use `<Note>`/`<Warning>`/`<Tip>`/`<Info>`/`<Check>`/`<Danger>`.
5. Limit group nesting to ONE level deep in docs.json (a top-level group containing a sub-group is fine; a sub-group inside a sub-group is too deep). Use anchors for top-level organization.
6. never reference pages with file extensions in docs.json navigation — use paths without `.mdx`.
7. always validate docs.json as valid JSON before finalizing.
8. always include meaningful `description` in every page's frontmatter (Mintlify uses this for llms.txt auto-generation and search).
9. always cross-reference Stage 5B to avoid documenting incomplete features as available.
10. always extract branding (colors, product name, logo) from tech-stack.md — never use placeholders.
11. If multi-language: always generate English first, then translate — never generate languages independently from PRD.
12. If multi-language: always verify translated version has identical structure to English version.
13. always include a "Next steps" section at the bottom of each journey page linking to the next logical page.
14. never include technical identifiers in user-facing content — no FEAT-*, US-*, SC-*, FR-*, BR-* (or BRL-*), UF-*, FS-*, AS-*, ES-*, RS-*, NS-*, SS-*.
15. Use `<Accordion>` for optional/advanced content that most users can skip.
16. Use `<Tabs>` when the same task has different instructions for different contexts (desktop/mobile, plan tiers, etc.).
17. never reference a screenshot that doesn't exist in the manifest — teammates must check `_guide-context.md` for the screenshot manifest before embedding any image references.
18. always wait for page content to fully load before capturing screenshots — loading spinners and skeleton screens in documentation screenshots look unprofessional and confuse users.
19. always include meaningful `alt` text on screenshot images — describe what the screenshot shows for accessibility and for users with images disabled.
20. Maximum 30 screenshots total across the entire user guide (for products with 15+ screens, this limit may need adjustment — use judgment but keep the guide concise). Maximum 3 screenshots per journey page (1 hero + 2 key steps). Prioritize quality over quantity — a well-described text step is better than a redundant screenshot.
21. always use standard markdown image syntax `![Alt text](/images/file.png)` for screenshots. Do not use `<Frame><img>` wrapping — it can cause CDN 403 errors.
22. If screenshot capture is in text-only fallback mode (see Phase 1 step 10g), ALL teammates must use `<Note>` callouts describing the UI instead of `<Frame>` with images. Do not mix screenshot and text-only approaches within the same guide.
23. always hide UI overlays (Next.js dev badge, cookie consent banners) before capturing screenshots or recordings. These development/compliance artifacts should never appear in user-facing documentation.
24. When an animated recording (MP4) exists for a page, embed it with `<video>` INSTEAD of the static screenshot — NOT alongside it. Showing both is redundant. The video replaces the screenshot.
25. always use PRODUCTION URL for authenticated page captures (screenshots and recordings). Dev servers have known race conditions with real-time auth providers (Convex, Firebase, Supabase) where the initial token fetch gets aborted during navigation, causing permanent "Session expired" error boundaries. Production builds do not have this issue.
26. For animated recordings, always trim the login/navigation portion from auth recordings during conversion (use `ffmpeg -ss <seconds>`). The video should start on the feature page with content visible — NOT on the login form.
27. always verify captured screenshots/recordings show actual content before embedding. Check for: loading spinners, "Session expired" screens, error boundaries, blank pages, cookie banners, dev badges. If any of these appear, retry with longer wait times, overlay hiding, or switch capture targets.
````
