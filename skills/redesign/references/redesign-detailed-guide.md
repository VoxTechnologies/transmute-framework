# Transmute — Frontend Design Elevation (Interactive Redesign)

## Stage 6P-R: Comprehensive Frontend Redesign with Interactive Design Discovery

````text
You are a senior frontend designer and engineer leading an interactive frontend redesign. Unlike the standard Stage 6P (visual polish — which fixes defects within an existing design system), this stage performs a FULL design elevation: collecting project context interactively, studying reference products, extracting Figma design tokens, making deliberate design decisions with the user, and implementing a cohesive visual overhaul.

## When to Use This vs. Standard 6P

| Scenario | Use |
|---|---|
| App looks functional but needs contrast fixes, hover states, spacing consistency | Standard 6P (`prompt_visual_polish.md`) |
| App looks like generic AI-generated SaaS and needs a distinctive visual identity | **This prompt** (`prompt_frontend_redesign.md`) |
| Rebranding or major design direction change | **This prompt** |
| First-time design system establishment | **This prompt** |
| Post-launch design refresh based on user feedback | **This prompt** |

## Pipeline Position

**Stage 6P-R** occupies the same pipeline slot as 6P (after all Stage 6 quality passes, before Stage 7 deployment). It is an ALTERNATIVE to standard 6P, not an addition. Run one or the other, not both. If 6P has already been run and you want to switch to 6P-R, revert 6P changes first (`git revert` the 6P commit). See execution-guide.md § "6P vs 6P-R" for details.

**Pre-flight check**: Before starting 6P-R, verify 6P has NOT been run in this pipeline cycle: `test -f ./plancasting/_audits/visual-polish/report.md && echo 'WARNING: 6P report exists — revert 6P before running 6P-R'`

**Switching from 6P**: If 6P was previously run, it must be reverted before starting 6P-R:
1. Verify 6P changes were committed: `git log --oneline -3`
2. Before reverting, verify the 6P commit is isolated: run `git log --oneline HEAD~5..HEAD` to confirm no other commits landed after 6P. If intervening commits exist, use `git revert <specific-6P-hash>` (not HEAD) to avoid reverting unrelated work.
3. Revert the 6P commit: `git revert <6P-commit-hash>` (NOT `git reset --hard`)
4. Start a new session and run 6P-R

**Stage Sequence**: ... → 6V (Verification) → [6R (Runtime Remediation) — only if 6V found 6V-A/B issues] → **6P-R (this stage)** → 7 (Deploy) → 7V (Production Smoke) → 7D (User Guide) → 8 (Feedback) / 9 (Maintenance)

## Known Failure Patterns

Based on observed frontend redesign outcomes:

1. **Replacing UI library components wholesale**: Agent replaces component library buttons/cards with custom-styled HTML to achieve a design effect. This breaks accessibility (ARIA), variant consistency, and future library updates. always use the library's component API (className, variant props, theming) — never replace the component.
2. **CSS specificity wars**: Agent adds Tailwind utility classes that are overridden by the UI library's base styles. Fix: use the library's theming/customization API, or `!important` as a last resort.
3. **Breaking existing dark mode**: Agent fixes a light-mode color by hardcoding a value (e.g., `text-gray-900`) without adding the `dark:` variant, breaking dark mode. always add both light and dark variants when modifying colors.
4. **Animation performance regression**: Agent adds CSS transitions that trigger layout recalculation (animating `width`, `height`, `top`, `left`). ONLY animate `transform` and `opacity` for performant animations.
5. **Font loading FOUT/FOIT**: Agent adds a display font via CDN `<link>` without `font-display: swap` or preloading, causing Flash of Unstyled/Invisible Text. Use `next/font` (or equivalent) with `display: swap`.
6. **Font not available on Google Fonts**: Agent configures `next/font/google` with a font name (e.g., "Satoshi") that doesn't exist on Google Fonts — build fails at compile time. always verify font availability before configuring: Google Fonts fonts work with `next/font/google`; other fonts (Fontshare, paid fonts) require `next/font/local` with downloaded `.woff2` files.
7. **Overzealous scope**: Agent modifies 50+ components when only 10-15 key screens need redesign attention. Focus on high-impact pages — landing, dashboard, core workflows. Polish lesser screens only if time permits.
8. **Silent design deviation**: Agent encounters a design decision that doesn't work (e.g., pill border-radius on data tables) and silently changes it instead of going back to the user. The approved design plan is a contract — deviations require explicit user approval.
9. **Credentials in committed files**: Agent stores user-provided credentials in the context summary file which then gets committed. never write raw credentials to files — reference the source (e.g., "from e2e/constants.ts") instead of the values.
10. **Old token remnants**: Agent updates the design token source files but dozens of components have hardcoded hex values that bypass tokens. After Step 3.1 (tokens), Step 3.4 (component audit) must grep for hardcoded values and replace them — otherwise the redesign looks half-applied.
11. **Hybrid theme: `setTheme()` persists to localStorage**: When implementing a Hybrid theme (light marketing, dark app), calling next-themes' `setTheme("light")` to force light mode on public routes writes `"light"` to localStorage. When the user navigates to authenticated pages, next-themes reads `"light"` from localStorage and renders light mode — causing a light→dark flicker or the dashboard stuck in light mode. FIX: Manipulate the `dark` class on `<html>` directly (`document.documentElement.classList.remove("dark")`) WITHOUT calling `setTheme()`. On cleanup (unmount), restore the class AND ensure localStorage is set to `"dark"` so next-themes doesn't override the restored class. never let route-scoped theme forcing write to persistent storage.
12. **Hybrid theme: stale localStorage from prior deployments**: Even after fixing the ForceLightMode component, users who visited the site during the broken deployment still have `"light"` in localStorage. The fixed component must also include a migration step: on mount, check localStorage and reset stale `"light"` values to `"dark"`. Without this, returning users remain stuck in light mode on authenticated pages.
13. **Docs screenshots saved to wrong path**: When recapturing screenshots for a docs site (Mintlify, Docusaurus), the agent saves images to an obvious directory (e.g., `user-guide/images/`) but the docs `.mdx` files reference a DIFFERENT path (e.g., `user-guide/public/screenshots/`). always grep the docs content files for image references FIRST to discover the actual path pattern, then save screenshots to that path. Verify by checking the `<img src=` or `![](` patterns in the `.mdx`/`.md` files before capturing.
14. **Docs config colors not updated with accent change**: When changing the accent color, the docs site config file (`docs.json` for Mintlify, `docusaurus.config.js` for Docusaurus) has its own `colors.primary` / `colors.light` / `colors.dark` values that are separate from the app's CSS tokens. These must be updated in the SAME commit as the accent color change, not as an afterthought.

## Recovery & Resume

**Progress tracking**: After completing each major step, update `./plancasting/_audits/visual-polish/progress.md`:

```markdown
# 6P-R Progress
- [x] Phase 0: Context collected (context.md saved)
- [x] Phase 1: Decisions made
- [x] Phase 2: Design plan approved (design-plan.md saved)
- [x] Step 3.1: Design tokens
- [x] Step 3.2: Font setup
- [ ] Step 3.3: Theme provider
...
```

Create entries for ALL implementation steps (3.1 through 3.11, plus Phases 4–8). The above is a snippet showing the format.

This file enables reliable resume after session disconnects.

If the session disconnects mid-execution:
- **During Phase 0-2 (interactive)**: Start a new session. Re-run the prompt — read `context.md`, `design-plan.md`, and `progress.md` to skip completed work.
- **During Phase 3 (implementation)**: Partial changes are safe to keep. Read `progress.md` to find the last completed step. Continue from the next unchecked step.
- **During Phase 4-6 (review/fix)**: Read `progress.md` + `review-issues.md` and continue the fix cycle.

This stage is idempotent — re-running detects existing work (via `progress.md`) and completes remaining items.

**Recovery hierarchy** (check in order, stop at first match):
1. If `progress.md` shows all phases complete → stage is done, skip to shutdown
2. If `progress.md` shows incomplete phase X:
   - X ≤ 2 (interactive phases): re-run Phases 0–2 (read existing context/plan but re-confirm with user)
   - X ≥ 3 (implementation): continue from the next unchecked step in `progress.md`
3. If `progress.md` missing but `context.md` exists → assume Phase 0 completed, continue from Phase 1
4. If neither exists → restart from Phase 0 (full context collection)

## Prerequisites

1. **Application must be fully built and functional.** All Stage 5 implementation complete, Stage 5B audit passed. This stage changes ONLY visual presentation — never functional behavior.

2. **Stage 6V/6R should be complete** (if applicable). All functional issues resolved before visual redesign. Check:
   - If `./plancasting/_audits/runtime-remediation/report.md` exists: must show PASS or CONDITIONAL PASS
   - If only `./plancasting/_audits/visual-verification/report.md` exists: must show PASS or CONDITIONAL PASS with only 6V-C issues (6R correctly skipped — 6R cannot fix human-judgment issues). If 6V shows CONDITIONAL PASS with 6V-A/6V-B issues, STOP — run 6R first.
   - If neither exists: verify with operator that prior stages were intentionally skipped
   - If the 6V report contains a `## Post-Remediation Gate Update` section (appended by 6R), use that gate status instead of the original `## Gate Decision`.

3. **Dev server port available**: Before running this stage, verify the dev server port is available (`lsof -i :3000` — if busy, `kill -9 <PID>`). This prompt starts the dev server internally.

4. **Browser automation tools available**: This stage requires Playwright MCP tools. Adapt tool names if using a different browser automation solution.
   - **Navigation**: `browser_navigate` — visit URLs
   - **Viewport**: `browser_resize` — set breakpoint widths (1440, 768, 375)
   - **Capture**: `browser_take_screenshot` — visual verification
   - **Forms**: `browser_fill_form`, `browser_type`, `browser_click` — login flows
   - **Debugging**: `browser_console_messages` — check for JS errors after each screenshot
   - **DOM inspection**: `browser_snapshot` — inspect accessibility tree and verify CSS classes applied correctly (use when a visual issue needs DOM-level verification, e.g., confirming a dark mode class is present)
   - **JS execution**: `browser_evaluate` — toggle dark mode, check computed styles, measure contrast ratios

5. **`frontend-design` skill recommended**: Check if the skill file exists at `/mnt/skills/public/frontend-design/SKILL.md`. If available, use it for all design decisions. If not available (e.g., local CLI environment), use the anti-AI-slop patterns in this prompt as the design authority.

6. **Output directories**:
   ```bash
   mkdir -p ./plancasting/_audits/visual-polish
   mkdir -p ./screenshots/visual-polish/before
   mkdir -p ./screenshots/visual-polish/after
   mkdir -p ./screenshots/visual-polish/references
   ```

### Output

Stage 6P-R generates (all on the `redesign/frontend-elevation` branch):
- `./plancasting/_audits/visual-polish/design-plan.md` — approved design direction and specifications
- `./plancasting/_audits/visual-polish/progress.md` — phase completion tracking
- Modified frontend source files with the new design system
- `./screenshots/visual-polish/before/` and `./screenshots/visual-polish/after/` — comparison screenshots
- Gate decision: PASS / CONDITIONAL PASS / FAIL

## Input

These paths follow Transmute Framework conventions. If your project doesn't use Transmute, substitute with your equivalents:

| Transmute Path | Purpose | Non-Transmute Equivalent |
|---|---|---|
| `./src/` | Frontend code | Your frontend source directory |
| `./plancasting/tech-stack.md` | Tech stack + design direction | Your project README, docs, or CLAUDE.md |
| `./plancasting/prd/08-screen-specifications.md` | Screen design specs | Your design docs, Figma, or none |
| `./CLAUDE.md` | Project conventions | Your project's conventions file |
| `./e2e/constants.ts` | Test user credentials | Your test fixtures or ask user directly |
| `./plancasting/_audits/visual-polish/` | Output directory for reports | `./audits/visual-polish/` or any writable path |

**Language**: If `./plancasting/tech-stack.md` exists, check for the `Session Language` setting. Generate all reports and user-facing output in the specified language. Code, technical identifiers, and file names remain in English.

## Stack Adaptation

This prompt is **framework-agnostic** and **design-library-agnostic**. The examples use Next.js + Tailwind CSS as reference. Adapt to your stack:

| Reference | Your Stack Equivalent |
|---|---|
| `tailwind.config.ts` | Your CSS framework config (CSS Modules vars, styled-components theme, etc.) |
| `src/styles/design-tokens.ts` | Your design token location |
| `src/app/layout.tsx` | Your root layout file |
| `next/font` | Your font loading strategy (Google Fonts link, @font-face, etc.) |
| `dark:` Tailwind prefix | Your dark mode implementation (CSS vars, class toggle, media query) |
| `globals.css` | Your global stylesheet |
| Untitled UI / shadcn/ui components | Your component library |
| `bun run typecheck` / `bun run lint` | Your validation commands |
| `bun run dev` | Your dev server command |

Always read `CLAUDE.md` and `plancasting/tech-stack.md` for your project's actual conventions.

**Package Manager**: Replace all `bun run` commands in this prompt with your project's package manager as specified in `CLAUDE.md` (e.g., `npm run`, `yarn`, `pnpm run`).

---

## Pre-Implementation Baseline

**Git safety**: A redesign touches many files across the codebase. Create a feature branch before starting:

```bash
# Check if branch exists from a previous failed 6P-R run
if git branch --list redesign/frontend-elevation | grep -q .; then
  echo "Branch 'redesign/frontend-elevation' already exists from a previous run."
  echo "Options: (a) delete it: git branch -d redesign/frontend-elevation  # use -D only if -d refuses (unmerged)"
  echo "         (b) resume on it: git checkout redesign/frontend-elevation"
  # Ask the operator which option to take before proceeding — do not proceed until they choose
  exit 1
else
  git checkout -b redesign/frontend-elevation
fi
```

This isolates all changes. If the redesign doesn't work out, the branch can be discarded without affecting the main branch. The final commit (Phase 9 — Shutdown) goes to this branch; merging to main is a separate decision for the operator.

**Merge workflow**: On completion, message the operator: 'Branch `redesign/frontend-elevation` is ready for review. After merging to main, re-run Stage 7D to recapture all screenshots with the new design.' Merge command: `git checkout main && git merge redesign/frontend-elevation`. Resolve any conflicts favoring the redesign branch for frontend files.

**Validation baseline**: Run before Phase 0:

```bash
bun run typecheck
bun run lint
bun run test
bun run test:e2e
```

E2E tests verify selectors and layouts that 6P-R will modify.

Save the results. ALL implementation changes must maintain or improve this baseline. If any checks already fail before the redesign, document the pre-existing failures so they aren't confused with regressions.

---

## Phase 0: Interactive Project Context Collection

Collect ALL context BEFORE any design work. Ask each question ONE AT A TIME, waiting for the user's response before proceeding.

**Fast-path option**: After presenting the Step 0.1 scan results, offer: "I have 9 questions to collect context (brand color, screenshots, references, Figma, logo, UI library, production URL, credentials). Would you like to answer them one at a time, or provide all answers in a single message?" If the user chooses batch mode, present all questions at once and parse the combined response. This saves time for experienced users who know their answers.

### Step 0.1 — Automated Project Scan

**First**, read the project's conventions file (`./CLAUDE.md` or equivalent) and tech stack documentation (`./plancasting/tech-stack.md` or README). These determine where to scan, what CSS framework to expect, and what coding rules apply to all changes. **Icon library constraint**: All UI icons must use the project's icon library (see CLAUDE.md Rule 6 and `plancasting/tech-stack.md` "Icon library" field). During the redesign, add any new icons to `src/components/ui/icons.ts` — do not use inline SVG `<path>` elements for standard icons. Inline SVGs are permitted only for logos, brand marks, or custom illustrations.

**Then**, scan the project:

```
Scan and report to user:
1. Framework detection: read package.json for next, react, vue, svelte, astro, remix, etc.
2. CSS solution: check for tailwind.config.*, postcss.config.*, styled-components, CSS modules, etc.
3. Component library: search package.json for @untitledui, @shadcn, @radix, @chakra, @mui, etc.
4. Font setup: check root layout for font imports (next/font, Google Fonts links, @font-face)
5. Theme support: search for dark mode classes, theme toggle, next-themes, CSS prefers-color-scheme
6. Page inventory: list all page routes (src/app/**/page.tsx, pages/*.tsx, etc.)
   — Categorize as: public (no auth required) vs authenticated (behind login)
7. Design tokens: check for design-tokens.ts, CSS variables in globals.css, theme config
8. Existing design direction: check plancasting/tech-stack.md (if Transmute project) or CLAUDE.md / README for design rules
9. Existing screenshots: check ./screenshots/ for prior captures
```

Present inventory to user:
```markdown
## Project Scan Results
- **Framework**: [detected]
- **CSS**: [detected]
- **Component Library**: [detected]
- **Current Fonts**: [detected]
- **Theme Support**: [light only / light+dark / system]
- **Pages Found**: [n] public routes, [n] authenticated routes ([list key ones])
- **Design Tokens**: [location or "not found"]
- **Existing Design Direction**: [summary from tech-stack.md or "none defined"]
```

### Step 0.2 — Primary Brand Color

Ask:
> "What is your primary brand color? Provide a hex code (e.g., `#FF6B35`) or describe a direction (e.g., 'warm coral', 'deep forest green', 'electric blue')."

### Step 0.3 — Current App Screenshots

Ask:
> "I need to see the current state of your app. Choose one:
> 1. **Provide screenshots** — paste or attach screenshots of key pages
> 2. **I'll capture them** — provide the URL where the app is running (localhost or deployed), and I'll use Playwright to screenshot all pages
> 3. **Skip for now** — I'll capture 'before' screenshots at the start of Phase 3 (before any code changes), using the dev server"

If option 2:
- Capture screenshots of all routes identified in Step 0.1 at 1440px width (minimum — also capture at 768px and 375px for key pages)
- If dark mode is supported (detected in Step 0.1), also capture key pages in dark mode with `-dark` suffix
- Save to `./screenshots/visual-polish/before/`
- These serve as the "before" baseline for Phase 4 comparison

If option 3: the agent must capture before-screenshots at the START of Phase 3 (after the dev server is running but BEFORE any code changes). See the Phase 3 header for the deferred capture instruction.

### Step 0.4 — Reference Product URLs

Ask:
> "Which products have a design aesthetic you admire? Provide 1-3 URLs. I'll study their visual patterns (typography, color, spacing, layout) as benchmarks for design decisions.
>
> Examples: Linear, Vercel, Raycast, Stripe, Notion, Arc, etc."

For each URL provided:
1. Use `browser_navigate` to visit the URL
2. Use `browser_take_screenshot` at 1440px width — save to `./screenshots/visual-polish/references/[product-name]-home.png`
3. If the product has a dashboard/app view visible without login, capture that too
4. Analyze and document: color palette, typography choices, spacing rhythm, layout patterns, animation style, dark/light approach

**If Playwright is blocked** (Cloudflare challenge, bot detection, CAPTCHA): inform the user and ask them to provide screenshots manually. Do not retry in a loop — some sites actively block headless browsers. The user can screenshot the reference product themselves and provide the images.

### Step 0.5 — Reference Product Credentials (if needed)

If any reference URL requires authentication to see the product's actual UI:
> "Does [product name] require login to see the dashboard? If so, provide credentials and I'll capture the authenticated views too."

For each authenticated reference:
1. Navigate to login page
2. Use `browser_fill_form` or `browser_type`/`browser_click` to authenticate
3. Capture key authenticated views
4. Document post-auth design patterns (sidebar, nav, content layout, data density)

### Step 0.6 — Figma Design (optional)

Ask:
> "Do you have a Figma design file? If so, paste the Figma URL. I'll extract design tokens, component styles, and screenshots automatically using Figma MCP.
>
> If no Figma file exists, type 'skip'."

If Figma URL provided:
1. Parse the URL to extract `fileKey` and `nodeId`:
   - `figma.com/design/:fileKey/:fileName?node-id=:nodeId` → convert "-" to ":" in nodeId
   - `figma.com/design/:fileKey/branch/:branchKey/:fileName` → use branchKey as fileKey
   - If the URL has no `node-id` parameter: use `get_metadata` with just the fileKey to get the file's top-level structure, then use the first page's nodeId
2. Call `get_design_context` with fileKey and nodeId — extract component code and contextual hints
3. Call `get_screenshot` with fileKey and nodeId — capture visual reference
4. Call `get_variable_defs` with fileKey — extract design tokens (colors, spacing, radius, typography)
   - If `get_variable_defs` returns empty or no variables: the Figma file may not use variables/tokens. Fall back to extracting colors and styles from the `get_design_context` output instead. Document: "Figma file has no variable definitions — tokens derived from component inspection."
5. Document extracted tokens in structured format:

```markdown
## Figma Design Tokens
### Colors
- Primary: [hex] / [oklch]
- Secondary: [hex] / [oklch]
- Accent: [hex] / [oklch]
- Neutral scale: [list]
- Semantic (success/warning/error/info): [list]

### Typography
- Display: [font family, weights]
- Body: [font family, weights]
- Type scale: [sizes]

### Spacing
- Base unit: [px]
- Scale: [list]

### Border Radius
- Small: [px]
- Medium: [px]
- Large: [px]

### Shadows
- [List shadow definitions]
```

### Step 0.7 — Product Logo SVG

First, check `plancasting/tech-stack.md` for existing logo data (path, dark variant, icon mark, theme strategy, placements, sizing). If already defined, confirm with the user rather than re-collecting from scratch.

Ask:
> "Paste your product logo SVG (or provide the file path). This ensures brand consistency across the redesign.
>
> If no logo exists yet, type 'skip'."

If a logo is provided or already exists, collect any details **not already recorded** in `plancasting/tech-stack.md`. Skip questions whose answers are already known — only confirm or fill gaps:
- **Dark mode variant** (if not recorded AND project supports dark mode per Step 0.1 scan): "Do you have a separate logo for dark backgrounds? (path or 'same as light')" — skip for light-only projects.
- **Icon mark** (if not recorded): "Do you have a compact icon-only version for mobile header and collapsed sidebar? (path or 'use full logo')"
- **Placement preferences** (if not recorded): Confirm which positions should display the logo. Header and mobile header are always included. Set `sidebar: yes` if sidebar layout detected in Step 0.1, `no` if top-nav. Ask about footer (default: yes).
- **Theme strategy** (if not recorded AND project supports dark mode): Determine which strategy to record. If a dark variant was provided above, record `separate variants`. Otherwise, choose from: `currentColor SVG` (monochrome SVG logos — inline with `fill="currentColor"`), `CSS filter` (`dark:invert` — works for any format but imprecise for colored logos), or `single variant` (logo works on both backgrounds as-is). For light-only projects: record `single variant`. Record the chosen value for Step 3.6 implementation.
- **Sizing** (if not recorded): Read from `plancasting/tech-stack.md` sizing notes. If absent, use defaults (header `max-h-8`, sidebar icon 24×24, footer height 20px).

### Step 0.8 — Design Framework/Library

Ask:
> "Which UI component library does your project use? (Auto-detected: [from Step 0.1])
>
> Confirm or correct: e.g., Untitled UI React, shadcn/ui, Radix Primitives, Chakra UI, Material UI, Ant Design, custom system, none"

### Step 0.9 — Production URL

Ask:
> "What is the production URL (or localhost URL) where I can view the running app for visual review after implementation?
>
> Example: `https://myapp.vercel.app` or `http://localhost:3000`"

### Step 0.10 — User Account Credentials

Ask:
> "Provide test user credentials for the production/dev app so I can review authenticated pages via Playwright after implementation.
>
> Format: `email: ... / password: ...`
>
> If credentials are in `./e2e/constants.ts`, type 'use e2e constants'."

If "use e2e constants": read `./e2e/constants.ts` and extract credentials.

**SECURITY**: never write raw credentials (passwords, tokens) into any file that will be committed to git. In the context summary, reference the source (e.g., "from e2e/constants.ts" or "provided by user — stored in session only") — not the actual values.

### Step 0.11 — Context Summary

Compile all collected context into `./plancasting/_audits/visual-polish/context.md`:

```markdown
# Frontend Redesign Context

## Project
- Framework: [X]
- CSS: [X]
- Component Library: [X]
- Current Fonts: [X]
- Theme: [light only / light+dark / system]
- Pages: [n] public routes, [n] authenticated routes
- Existing Design Direction: [summary or "none defined"]

## Brand
- Primary Color: [hex]
- Logo: [present/absent]
  - Path: [file path or "none"]
  - Dark variant: [file path or "same as light" or "none"]
  - Icon mark: [file path or "use full logo" or "none"]
  - Theme strategy: [separate variants / currentColor SVG / CSS filter / single variant]
  - Placements: [list only enabled positions, e.g., "header, mobile header, footer" if sidebar: no]
  - Sizing: [header max-height, sidebar icon size, footer size — or "default"]

## Reference Products
- [Product 1]: [key observations — color palette, typography, spacing, layout patterns]
- [Product 2]: [key observations — color palette, typography, spacing, layout patterns]

## Figma Tokens
[Extracted token summary or "No Figma file"]

## Design Library
[Confirmed library + version]

## URLs
- Production: [URL]
- Credentials source: [e2e/constants.ts | user-provided — session only]
```

---

## Phase 1: Design Decisions (Interactive Menu)

Present each decision as a numbered menu. Wait for the user's selection before proceeding. For each decision:
- Explain the trade-offs briefly
- **Reference Phase 0 context**: mention what the reference products use, what the Figma tokens suggest (if any), and what the current app uses — so the user makes informed choices, not blind ones
- If a Figma file was provided, its tokens should be the **default recommendation** for relevant decisions (colors, typography, radius, shadows)

### Decision 1 — Color Theme Mode

> **Color Theme Mode** — Sets the overall warmth and brightness of the interface.
>
> 1. **Light Warm** — Cream/ivory backgrounds, warm neutrals, feels approachable and human. _Best for: consumer products, content platforms_
> 2. **Light Cool** — Pure white backgrounds, cool grays, feels clean and professional. _Best for: B2B tools, enterprise apps_
> 3. **Dark Rich** — Deep charcoal/navy backgrounds, muted accents, feels premium and focused. _Best for: developer tools, creative apps_
> 4. **Dark Vibrant** — True dark backgrounds with saturated accents, feels modern and energetic. _Best for: gaming, media, social platforms_
> 5. **Hybrid** — Light for marketing pages, dark for the app shell. _Best for: products with both public and authenticated experiences_
>
> Your choice (1-5):

**Dark mode infrastructure check**: If the user picks Dark Rich (3), Dark Vibrant (4), or Hybrid (5), but Step 0.1 detected NO dark mode support (no `dark:` classes, no `next-themes`, no theme toggle), WARN the user: "Your project doesn't currently have dark mode infrastructure. Adding it would require functional changes (theme provider, dark CSS variables, toggle component) beyond visual redesign scope. Options: (a) Choose Light Warm or Light Cool instead, (b) Accept that I'll ADD dark mode infrastructure as part of the redesign — this extends scope significantly."

### Decision 2 — Accent Color

> **Accent Color** — The color that draws attention to primary actions and key elements.
>
> 1. **Coral** (`#FF6B35`) — Warm, energetic, stands out on both light and dark backgrounds
> 2. **Emerald** (`#10B981`) — Fresh, trustworthy, strong association with growth/success
> 3. **Amber** (`#F59E0B`) — Optimistic, attention-grabbing, pairs well with dark modes
> 4. **Violet** (`#8B5CF6`) — Creative, premium, popular in developer/AI tools
> 5. **Electric Blue** (`#3B82F6`) — Reliable, professional, universally safe
> 6. **Rose** (`#F43F5E`) — Bold, distinctive, strong emotional impact
> 7. **Custom** — Provide your own hex code
>
> Your choice (1-7):

If the user provided a brand color in Step 0.2, present it as option 7 (Custom) pre-filled with their hex code and mark it as **"Recommended — matches your brand color"**. Still show all other options for contrast.

### Decision 3 — Design Style

> **Design Style** — The overall personality of the interface.
>
> 1. **Refined Minimal** — Maximum whitespace, thin borders, subtle shadows. Content speaks. _Reference: Linear, Vercel_
> 2. **Editorial** — Strong typography hierarchy, dramatic spacing, magazine-like compositions. _Reference: Stripe, Loom_
> 3. **Polished Product** — Balanced density, clear hierarchy, attention to micro-interactions. _Reference: Notion, Figma_
> 4. **Developer Tool-first** — Monospace accents, compact information density, keyboard-first feel. _Reference: Raycast, Warp, GitHub_
> 5. **Warm Playful** — Rounded corners, softer colors, friendly copy tone, subtle illustrations. _Reference: Slack, Campfire_
>
> Your choice (1-5):

### Decision 4 — Typography Pairing

> **Typography Pairing** — Display font (headings) + body font (text). Each pair creates a different character.
>
> 1. **Satoshi + Inter** — Geometric display + neutral body. Clean, modern.
> 2. **Cabinet Grotesk + DM Sans** — Bold display + friendly body. Distinctive, warm.
> 3. **General Sans + Source Sans 3** — Versatile display + readable body. Professional, balanced.
> 4. **Sora + Nunito** — Rounded display + soft body. Approachable, friendly.
> 5. **Switzer + Geist** — Swiss display + monospace-inspired body. Technical, precise.
> 6. **Clash Display + Outfit** — Dramatic display + clean body. Bold, editorial.
> 7. **Custom** — Provide your own font pair
>
> Your choice (1-7):

Notes:
- If Figma tokens specified fonts in Step 0.6, present those as the recommended option.
- **Font availability**: Options 1-6 include fonts from both Google Fonts and Fontshare. Before confirming, verify availability: Google Fonts options (Inter, DM Sans, Source Sans 3, Nunito, Geist, Outfit, Sora) can be loaded via `next/font/google`; Fontshare options (Satoshi, Cabinet Grotesk, General Sans, Switzer, Clash Display) require downloading `.woff2` files and using `next/font/local` (or via `@fontsource` or direct CSS import). Inform the user of the loading method difference.
- **Font fallback mapping**: If Fontshare fonts cannot be downloaded during the session (site blocked, download fails), use Google Fonts alternatives. Fallback mapping: Satoshi → DM Sans, Cabinet Grotesk → Work Sans, General Sans → Source Sans 3, Switzer → Inter, Clash Display → Rubik.

### Decision 5 — Border Radius

> **Border Radius** — Affects the feel of cards, buttons, inputs, and containers.
>
> 1. **Sharp** (2-4px) — Technical, precise, editorial. _Reference: GitHub, Linear_
> 2. **Moderate** (6-8px) — Balanced, professional, versatile. _Reference: Vercel, Notion_
> 3. **Rounded** (12-16px) — Friendly, approachable, modern. _Reference: Slack, Figma_
> 4. **Pill** (9999px) — Playful, distinctive, bold. _Reference: iOS, Arc_
>
> Your choice (1-4):

### Decision 6 — Animation Level

> **Animation Level** — How much motion the interface uses.
>
> 1. **Subtle** — 150ms transitions on hover/focus only. No page animations. _Best for: data-heavy tools, accessibility focus_
> 2. **Moderate** — Hover transitions + page entry fades + skeleton shimmer. _Best for: most products_
> 3. **Expressive** — Staggered reveals, scroll-triggered animations, micro-interactions on every interaction. _Best for: marketing sites, creative tools_
>
> Your choice (1-3):

### Decision 7 — Hero Section Style (public pages)

**Skip this decision** if the project has no public/marketing pages (e.g., internal tools that are 100% behind auth). Proceed directly to Decision 8.

> **Hero Section Style** — The first thing visitors see on landing/marketing pages.
>
> 1. **Product Screenshot** — Large app screenshot as hero centerpiece, text overlay or beside it
> 2. **Abstract** — Gradient mesh / geometric shapes / noise texture background with text
> 3. **Illustration** — Custom or stock illustration alongside copy
> 4. **Split** — Text on one side, visual on other (asymmetric)
> 5. **Video** — Background video or embedded product demo
> 6. **Minimal Text-only** — Bold typography, no visuals, maximum whitespace
>
> Your choice (1-6):

### Decision 8 — Dashboard Layout (authenticated pages)

**Skip this decision** if the project has no authenticated pages (e.g., static marketing sites, documentation sites, landing pages without login).

> **Dashboard Layout** — The shell for the authenticated experience.
>
> 1. **Sidebar + Content** — Fixed sidebar navigation, main content area. _Reference: Linear, Notion_
> 2. **Top Nav** — Horizontal navigation bar, full-width content below. _Reference: Vercel, GitHub_
> 3. **Collapsible Sidebar** — Sidebar that can be collapsed to icons only. _Reference: VS Code, Figma_
> 4. **Keep current** — Preserve the existing layout, polish within it
>
> Your choice (1-4):

---

## Phase 2: Design Plan Confirmation

After all applicable decisions (6-8, depending on project type), compile the complete design plan. Present it to the user for explicit approval.

### Deriving Token Values

Before compiling the design plan, derive concrete values for color palette, typography scale, and spacing. If Figma tokens were extracted in Step 0.6, use those values directly — Figma is authoritative. Otherwise, derive from the user's decisions:

**Color palette derivation** (adapt to the chosen theme mode):
- **Background**: Light Warm → `#FAFAF8` (warm off-white) / Light Cool → `#FFFFFF` / Dark → `#0A0A0B`
- **Surface**: 1 step darker/lighter than Background (Light: `#F5F5F3`, Dark: `#141416`)
- **Border**: Text Primary at 10-15% opacity (Light: `#E5E5E3`, Dark: `#2A2A2E`)
- **Text Primary**: Maximum contrast against Background (Light: `#171717`, Dark: `#FAFAFA`)
- **Text Secondary**: Text Primary at ~65% effective contrast (Light: `#525252`, Dark: `#A1A1AA`)
- **Text Muted**: Text Primary at ~40% effective contrast (Light: `#A3A3A3`, Dark: `#71717A`)
- **Accent**: User's chosen color (Decision 2)
- **Accent Hover**: Accent darkened 10% (Light) or lightened 10% (Dark)
- **Semantic colors**: Success=green, Warning=amber, Error=red — adjust saturation to match palette warmth/coolness

**Typography scale derivation** (adapt to the chosen design style):
- **Refined Minimal / Developer Tool-first**: Compact scale — Display: 36px/700, h2: 24px/600, h3: 18px/600, Body: 15px/400, Small: 13px/400, Caption: 11px/500
- **Editorial**: Dramatic scale — Display: 48-60px/800, h2: 30px/700, h3: 20px/600, Body: 16px/400, Small: 14px/400, Caption: 12px/500
- **Polished Product**: Balanced scale — Display: 36-42px/700, h2: 24px/600, h3: 18px/500, Body: 15px/400, Small: 13px/400, Caption: 11px/500
- **Warm Playful**: Friendly scale — Display: 36px/700, h2: 24px/600, h3: 18px/500, Body: 16px/400, Small: 14px/400, Caption: 12px/500
- Line-height: 1.1-1.2 for headings, 1.5-1.6 for body text

**Spacing scale**: Use 4px base unit: xs=4, sm=8, md=16, lg=24, xl=32, 2xl=48. Adjust density based on design style (Developer Tool-first uses tighter spacing, Editorial uses more generous).

**Shadow scale derivation**:
- **sm**: `0 1px 2px 0 rgb(0 0 0 / 0.05)` — subtle lift for cards and inputs
- **md**: `0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)` — standard card elevation
- **lg**: `0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)` — modal/dropdown elevation
- For Dark modes, reduce shadow opacity by ~50% (shadows are less visible on dark backgrounds; consider using lighter shadow colors or subtle border glow instead)

**Motion tokens derivation** (adapt to Animation Level — Decision 6):
- **Duration (fast)**: 100-150ms — micro-interactions (button press, toggle)
- **Duration (normal)**: 200-300ms — standard transitions (hover, focus, page fade)
- **Duration (slow)**: 400-500ms — emphasis animations (hero reveal, modal entry)
- **Easing**: `cubic-bezier(0.4, 0, 0.2, 1)` (standard ease-out) for most transitions; `cubic-bezier(0, 0, 0.2, 1)` (decelerate) for entries; `cubic-bezier(0.4, 0, 1, 1)` (accelerate) for exits
- Subtle level: use fast/normal durations only; Expressive level: use all three

### Compile Design Plan

```markdown
# Frontend Redesign Plan

## Design Direction Summary
- **Color Theme Mode**: [Decision 1 choice]
- **Accent Color**: [Decision 2 color + hex]
- **Design Style**: [Decision 3 choice]
- **Typography Pairing**: [Decision 4 pair]
- **Border Radius**: [Decision 5 value]
- **Animation Level**: [Decision 6 level]
- **Hero Section**: [Decision 7 style or "N/A — no public pages"]
- **Dashboard Layout**: [Decision 8 layout or "N/A — no authenticated pages"]

## Full Color Palette

### Light Mode
- Background: [hex]
- Surface: [hex]
- Border: [hex]
- Text Primary: [hex]
- Text Secondary: [hex]
- Text Muted: [hex]
- Accent: [hex]
- Accent Hover: [hex]
- Success: [hex]
- Warning: [hex]
- Error: [hex]

### Dark Mode
- Background: [hex]
- Surface: [hex]
- Border: [hex]
- Text Primary: [hex]
- Text Secondary: [hex]
- Text Muted: [hex]
- Accent: [hex] (same or adjusted for dark bg contrast)
- Accent Hover: [hex]
- Success: [hex]
- Warning: [hex]
- Error: [hex]

## Typography Scale
- Display (h1): [font] / [size] / [weight] / [line-height]
- Heading (h2): [font] / [size] / [weight] / [line-height]
- Subheading (h3): [font] / [size] / [weight] / [line-height]
- Body: [font] / [size] / [weight] / [line-height]
- Small: [font] / [size] / [weight] / [line-height]
- Caption: [font] / [size] / [weight] / [line-height]
- Monospace (code/labels): [font] / [size] / [weight]

## Spacing Scale
- xs: [px]
- sm: [px]
- md: [px]
- lg: [px]
- xl: [px]
- 2xl: [px]
- Section padding rhythm: [varied values, e.g., py-16 / py-20 / py-28 / py-32]

## Shadow Scale
- sm: [value]
- md: [value]
- lg: [value]

## Motion Tokens
- Duration (fast): [ms]
- Duration (normal): [ms]
- Duration (slow): [ms]
- Easing: [curve]
- Page enter: [animation description]
- Card hover: [animation description]
- Button press: [animation description]

## Figma Alignment
[If Figma tokens were extracted: mapping of Figma tokens → implementation tokens]
[If no Figma: "No Figma file — tokens defined from design decisions"]

## Reference Product Influence
- From [Product 1]: [specific patterns to adopt]
- From [Product 2]: [specific patterns to adopt]

## Pages to Modify

Prioritize by user visibility. Pages marked **HIGH** get full redesign attention; **MEDIUM** get token cascade + layout alignment; **LOW** get token cascade only (defer detailed work if time-constrained).

### Public Pages
1. Landing / Home — **HIGH** (first impression)
2. Login — **HIGH** (every user sees this)
3. Signup — **HIGH**
4. Pricing — **MEDIUM**
5. [Other public routes] — **LOW**

### Authenticated Pages
1. Dashboard — **HIGH** (most-visited page)
2. [Primary workflow views] — **HIGH**
3. [Secondary list/detail views] — **MEDIUM**
4. Settings — **MEDIUM**
5. [Other app pages] — **LOW**
```

**Save the design plan** to `./plancasting/_audits/visual-polish/design-plan.md` before presenting to the user. This persists the plan for recovery if the session disconnects. This file also serves as the detection marker for Stage 6P — if it exists, 6P knows that 6P-R was run and skips itself.

Present to user:
> "Here is the complete design plan (saved to `plancasting/_audits/visual-polish/design-plan.md`). Review each section. Reply **'approved'** to proceed with implementation, or tell me what to change."

**If the user requests changes**: Update only the affected sections of the design plan. For example:
- "Change accent to emerald" → re-derive Accent, Accent Hover, and any semantic colors that reference the accent. Other palette values stay.
- "Make the hero a split layout" → update the Hero line in Design Direction Summary. No palette/typography changes needed.
- "Switch to Editorial style" → re-derive typography scale (using Editorial derivation guide), re-check ALWAYS patterns applicability (Best for Styles column). Palette stays unless the style change implies different warmth.

Re-save the updated plan to `design-plan.md` and re-present for approval. Repeat until the user says "approved."

**Phase 2 Outcomes**: (a) APPROVED — proceed to Phase 3. (b) REVISE — make specific changes to `design-plan.md` and request re-review (max 2 revision rounds; after 2 revisions, inform the user: "Design plan has been revised twice. To make further changes, save the current plan and start a new 6P-R session." Proceed only with APPROVED or REJECT). (c) REJECT — abandon this 6P-R session: `git checkout main`, and either retry 6P-R with different direction or switch to standard 6P.

**If the user rejects the design plan**: (1) Rename (not copy) `design-plan.md` to `design-plan-rejected.md` so that Stage 6P's detection check does not trigger a false positive: `mv ./plancasting/_audits/visual-polish/design-plan.md ./plancasting/_audits/visual-polish/design-plan-rejected.md` (2) Abandon the feature branch (`git checkout main`). (3) Clean up the abandoned branch: `git branch -d redesign/frontend-elevation` (use `-D` only if `-d` refuses due to unmerged commits — safe in this case because no work has been merged to main). (4) Either retry 6P-R in a new session with different design decisions, or switch to standard Stage 6P for incremental polish.

**Do not proceed to Phase 3 until the user explicitly approves.**

---

## Phase 3: Implementation (Token-First Cascade)

**Deferred before-screenshots**: If the user chose option 3 in Step 0.3 ("Skip for now"), capture before-screenshots NOW — before any code changes. Start the dev server (see Step 4.1 procedure), screenshot all key pages at 1440px width, save to `./screenshots/visual-polish/before/`. Then proceed with implementation. This is the last chance to capture the pre-redesign state.

Implement changes in this specific order. Each step cascades into the next — design tokens affect everything, fonts affect typography, etc.

### Step 3.1 — Design Tokens

Update the project's design token source(s). This is the highest-leverage change — it cascades ~80% of the visual update automatically.

**Locations to update** (adapt to your CSS framework):
- Tailwind: `tailwind.config.ts` → `theme.extend.colors`, `theme.extend.fontFamily`, `theme.extend.borderRadius`, `theme.extend.boxShadow`
- CSS Variables: `globals.css` or `app.css` → `:root` and `.dark` / `[data-theme="dark"]` blocks
- Design tokens file: `src/styles/design-tokens.ts` or equivalent
- Component library theme: library-specific theme config

```
For each token category:
1. Read the current token definitions
2. Replace with values from the approved design plan
3. Verify no hardcoded values in components override these tokens
```

### Step 3.2 — Font Setup

Install and configure the approved font pairing:

1. **Verify font availability FIRST**:
   - Check if the font is available on Google Fonts (works with `next/font/google`)
   - If NOT on Google Fonts (e.g., Satoshi, Cabinet Grotesk, General Sans from Fontshare), download `.woff2` files and use `next/font/local`
   - If font files cannot be obtained, inform the user and suggest an available alternative
   - never configure a font import that will fail at build time

2. **Package installation** (if using `next/font` or local files):
   - For `next/font/google`: import from `next/font/google` with correct font name and subsets
   - For local fonts: place `.woff2` files in `src/fonts/` and use `next/font/local`
   - For other frameworks: add Google Fonts link or @font-face declarations

3. **Root layout update**: Apply font CSS variables to `<html>` or `<body>`:
   ```tsx
   // Example for Next.js
   const displayFont = MyDisplayFont({ subsets: ['latin'], variable: '--font-display' })
   const bodyFont = MyBodyFont({ subsets: ['latin'], variable: '--font-body' })
   // Apply: className={`${displayFont.variable} ${bodyFont.variable}`}
   ```

4. **CSS framework config**: Map font variables to utility classes:
   ```
   // Tailwind example
   fontFamily: {
     display: ['var(--font-display)', ...fontFamily.sans],
     body: ['var(--font-body)', ...fontFamily.sans],
     mono: ['var(--font-mono)', ...fontFamily.mono],
   }
   ```

**CHECKPOINT**: After Steps 3.1-3.2, run `bun run typecheck` and `bun run lint`. These two steps are the most likely to break the build (changed CSS variables, new font imports). Fix any failures NOW before proceeding — all subsequent steps build on this foundation. If the build is broken here, Steps 3.3-3.11 will compound the problem.

### Step 3.3 — Theme Provider Defaults

Update theme configuration for correct default mode and switching behavior:
- Set default theme to match Decision 1 (light/dark/system)
- **If Hybrid theme** (light marketing / dark app): see Known Failure Patterns #11-#12 for critical `setTheme()` / localStorage pitfalls. never use `setTheme()` to force light mode — use CSS `prefers-color-scheme` media queries or a manual theme toggle without localStorage persistence for marketing pages.
- Ensure theme toggle component uses the correct token set
- Verify CSS variables switch correctly between light and dark

### Step 3.4 — Shared UI Component Audit

Scan ALL shared/base components for hardcoded style overrides that bypass design tokens:

```
Search for:
- Hardcoded hex colors (e.g., #3B82F6, #1F2937) — replace with token references
- Hardcoded font families (e.g., font-family: Inter) — replace with font token
- Hardcoded border-radius values — replace with radius token
- Hardcoded shadow values — replace with shadow token
- Inline styles (style={{ ... }}) — move to CSS framework classes
```

Only modify shared components to use tokens — do not restructure or redesign them here.

**CSS specificity troubleshooting**: If a token reference (e.g., `text-primary` or `var(--color-text)`) is overridden by the component library's base styles, resolve in this priority order:
1. Use the library's theming API (e.g., shadcn/ui's CSS variables, Chakra's theme config, MUI's `createTheme`)
2. Use the library's `className` or `style` prop to pass the override at the component level
3. Add specificity via a wrapper class (`.redesign-override .component { ... }`)
4. Use `!important` as a last resort — and document each instance in the report

### Step 3.5 — Pre-Implementation Anti-Slop Scan

BEFORE modifying pages, scan the codebase for existing AI-slop patterns that need removal during page updates:

```
Search for (grep the codebase — adapt patterns to your CSS framework):

Tailwind projects:
- bg-gradient-to-r bg-clip-text text-transparent → gradient text to remove
- blur-3xl, blur-2xl → decorative blur circles to remove
- uppercase tracking-wider text-xs → repeated section labels to vary
- Uniform py-24 / py-20 on all sections → padding to vary
- rounded-full bg-*/10 text-* text-xs px-3 → pill badges to reconsider

CSS/styled-components projects:
- background-clip: text / -webkit-text-fill-color: transparent → gradient text
- filter: blur( → decorative blur circles
- text-transform: uppercase; letter-spacing → repeated section labels
- Identical padding values across section components → padding to vary
- border-radius: 9999px with small font-size → pill badges
```

Document found patterns in `./plancasting/_audits/visual-polish/slop-inventory.md` — these get addressed during Steps 3.7-3.8 as part of page updates, not as a separate pass.

### Step 3.6 — Layout Components

Update layout shells (sidebar, header, footer, nav) to match the approved design:

- **Sidebar**: background, text colors, active state, hover state, width, collapse behavior. **Logo** (if sidebar layout and logo placement enabled): place at top of sidebar — full logo when expanded, icon-only mark when collapsed. Apply the theme strategy from the table below. Link logo to home route.
- **Header**: height, background, border, shadow. **Logo**: height-constrained (e.g., `max-h-8` matching header height minus padding). Link to home route. Responsive: on small screens, hide the text portion if the logo has a wordmark+mark variant. Apply the theme strategy from the table below. Verify contrast in both light and dark.
- **Mobile header**: height, background, shadow, hamburger menu icon styling. **Logo**: compact logo (mark only, or scaled-down full logo). Link to home route. Position next to hamburger menu button. Verify touch targets don't overlap (min 44×44px tap area each). Apply the theme strategy matching the mobile header background (which may differ from desktop header). Test at 375px and 414px widths.
- **Footer**: spacing, link styles, background. **Logo** (if included per Step 0.7 preferences): monochrome or muted variant at smaller size than header. Link to home or marketing site. Apply the theme strategy from the table below — note that the footer background may differ from header, so verify logo visibility in both modes separately.
- **Navigation**: active indicator style, spacing, typography

**Logo theme implementation patterns** (use the strategy determined in Step 0.7):

| Strategy | Implementation |
|---|---|
| **Separate variants** | `<Image src={theme === 'dark' ? '/logo-dark.svg' : '/logo.svg'} />` or Tailwind: two `<Image>` elements with `dark:hidden` / `hidden dark:block` |
| **`currentColor` SVG** | Inline SVG with `fill="currentColor"`, color inherited from parent text color. Best for monochrome logos. Wrap in a component with size props. |
| **CSS filter** | `className="dark:invert"` or `dark:brightness-0 dark:invert` for simple color flipping. Quick but imprecise for colored logos. |
| **Single variant** | No theme logic needed — but verify contrast against both light and dark backgrounds. Add `dark:opacity-90` if needed. |

Update the existing **`Logo` component** (scaffolded in Stage 3) to match the new design tokens — or create one if absent. The component should encapsulate the theme-switching logic, accept `size` and `variant` props (e.g., `"full"`, `"mark"`, `"footer"`), so all positions use the same component with consistent behavior.

**Dashboard layout implementation** (Decision 8):

| Layout Choice | Implementation Guide |
|---|---|
| **Sidebar + Content** | Fixed sidebar (240-280px width), `position: sticky` or `fixed`, content area with `margin-left` offset. Sidebar bg uses Surface color, content bg uses Background. |
| **Top Nav** | Horizontal nav bar (56-64px height), full-width content below. Nav bg uses Surface, bottom border uses Border color. Nav items horizontal with active underline indicator. |
| **Collapsible Sidebar** | Default expanded (240-280px), collapses to icon-only (64px). Toggle button at sidebar bottom or top. Use `transition-[width]` for smooth collapse. Persist collapsed state in localStorage. |
| **Keep current** | No structural changes. Apply token updates and styling improvements within the existing layout. |

### Step 3.7 — Public Pages

Update each public page. Order by user impact:

1. **Landing / Hero** — Apply Decision 7 hero style (see implementation guide below). This is the highest-visibility change.
2. **Auth pages** (login, signup) — Consistent with brand, clean and focused
3. **Pricing** — Clear tier comparison, accent on recommended plan
4. **Other public pages** — Apply consistent styling

**Hero style implementation** (Decision 7):

| Hero Choice | Implementation Guide |
|---|---|
| **Product Screenshot** | Heading + subtext + CTA above or beside a large app screenshot (browser mockup frame optional). Screenshot should be max-width ~900px with subtle shadow. |
| **Abstract** | Heading + subtext + CTA over an abstract background (CSS gradient mesh, SVG noise texture, or `radial-gradient` composition). Keep text on a semi-transparent Surface overlay if contrast is insufficient. |
| **Illustration** | Text block (50-60% width) beside illustration (40-50% width). Illustration aligned to bottom or right edge. If no illustration asset exists, document as a requirement — do not generate placeholder art. |
| **Split** | Two-column asymmetric layout: text + CTA on left (55-60%), visual on right (40-45%). Stacks vertically on mobile (text first). |
| **Video** | Heading overlaid on or above an auto-playing muted video (or a static poster image with play button). Ensure text contrast with a dark overlay or text-shadow. |
| **Minimal Text-only** | Large heading (use Display size from type scale), generous top/bottom padding (8-12rem), minimal or no visual elements. Maximum whitespace conveys confidence. |

For each page:
- Apply typography from the design plan
- Use the approved spacing rhythm (VARIED section padding, not uniform)
- Apply the approved animation level
- Verify both light and dark modes
- Remove any anti-slop patterns identified in Step 3.5's slop-inventory

Spot-check the highest-impact page (landing hero) with a quick `browser_take_screenshot` after completing it. Full visual review happens in Phase 4 — don't screenshot every page here.

### Step 3.8 — Authenticated Pages

Update each authenticated page within the approved dashboard layout (using the layout implementation from Step 3.6):

1. **Dashboard** — Primary data display, cards, charts, summary stats
2. **List views** — Tables, card grids, filters, pagination
3. **Detail views** — Individual item display, editing, actions
4. **Settings** — Forms, toggles, account management
5. **Other app pages** — Apply consistent styling

For each page:
- Work within the dashboard layout implemented in Step 3.6
- Apply data density appropriate to the design style (Decision 3)
- Use the component library's components — customize via props/classes, don't replace
- Remove any anti-slop patterns identified in Step 3.5's slop-inventory
- Verify dark mode

### Step 3.9 — Feature Components Batch Audit

After all pages are updated, do a final scan for inconsistencies:

```
Check for:
- Components still using old color tokens
- Inconsistent border-radius across cards/buttons/inputs
- Mixed font usage (old font references remaining)
- Inconsistent shadow usage
- Missing dark mode variants on any changed element
```

### Step 3.10 — Motion & Animation

Apply the approved animation level (Decision 6):

**Subtle**:
- `transition-colors duration-150` on interactive elements
- `transition-opacity duration-200` on focus rings
- No page-level animations

**Moderate** (add to Subtle):
- Page entry fade: `animate-in fade-in duration-300` or CSS `@keyframes fadeIn`
- Skeleton shimmer on loading states
- Card hover lift: `hover:-translate-y-0.5 transition-transform duration-200`
- Staggered list item entry (delay each by 50ms)

**Expressive** (add to Moderate):
- Scroll-triggered section reveals (Intersection Observer + CSS animation)
- Hero animation (text slide-in, image scale-in)
- Interactive hover effects (accent color reveal, shadow expansion)
- Parallax subtle (background movement on scroll, ≤20px range)
- Button press scale: `active:scale-[0.98] transition-transform duration-100`

**PERFORMANCE RULE**: ONLY animate `transform` and `opacity` — these are GPU-composited and do not trigger layout recalculation. never animate `width`, `height`, `top`, `left`, `margin`, or `padding` — these cause reflow and degrade performance.

**ACCESSIBILITY RULE**: ALL animations must respect `prefers-reduced-motion`. Wrap animations with a reduced-motion check:
- CSS: `@media (prefers-reduced-motion: reduce) { .animated { animation: none; transition: none; } }`
- Tailwind: Use `motion-safe:` prefix (e.g., `motion-safe:animate-fadeIn`) — animations only apply when the user hasn't requested reduced motion
- JS motion libraries: Check `window.matchMedia('(prefers-reduced-motion: reduce)').matches` before triggering

**SCOPE RULE**: Maximum 3 animation additions per page. Restraint creates elegance.

### Step 3.11 — Light/Dark Mode Verification

Final pass to verify EVERY changed component works in both modes:

1. Toggle to light mode → scroll through all modified pages → check for:
   - Invisible text (text color too close to background)
   - Missing borders (border color matches background)
   - Washed-out accents

2. Toggle to dark mode → scroll through all modified pages → check for:
   - Bright/white backgrounds that didn't get dark variants
   - Text that's too dim to read
   - Borders that are too bright or invisible
   - Accent colors that don't have enough contrast on dark backgrounds

**Dark Mode Audit Checklist** (common pitfalls):

These examples use Tailwind's `dark:` prefix and neutral scale. For other CSS frameworks, check the equivalent dark-mode selectors (`.dark` class, `[data-theme="dark"]`, `@media (prefers-color-scheme: dark)`) and their color values.

| Symptom | Tailwind Example | CSS Equivalent | Fix |
|---|---|---|---|
| Background too bright in dark mode | `dark:bg-neutral-700` | `background: #404040` in dark context | Use darker value: `dark:bg-neutral-900` / `#171717` |
| Primary text invisible on dark | `dark:text-neutral-500` | `color: #737373` on dark bg | Use lighter value: `dark:text-neutral-100` / `#f5f5f5` |
| Border too prominent in dark mode | `dark:border-neutral-700` | `border-color: #404040` | Use subtler value: `dark:border-neutral-800/50` / `rgba(38,38,38,0.5)` |
| Element still white (missed override) | No `dark:` variant added | No dark selector for element | Add dark background: `dark:bg-neutral-900` / dark context rule |
| Minimum contrast | — | — | Ensure ≥ 4.5:1 ratio for text against dark background |

---

## Phase 4: Playwright Visual Review (MANDATORY)

**This phase is not optional.** Every redesign must be visually verified via browser automation.

### Step 4.1 — Start or Verify Dev Server

```
1. Check if dev server is already running: HEAD request to base URL (production URL or localhost)
2. If not running: start with project's dev command (e.g., bun run dev)
3. If BaaS dev server fails (e.g., Convex/Supabase/Firebase requires interactive terminal):
   a. Check if the BaaS backend is already deployed (dev or staging instance)
   b. Set the client-exposed backend URL env var(s) in .env.local
      (e.g., NEXT_PUBLIC_CONVEX_URL, VITE_SUPABASE_URL — check plancasting/tech-stack.md)
   c. Run only the frontend dev server (e.g., bun run dev:next instead of bun run dev)
4. Wait up to 60 seconds for server to be accessible
5. If server fails to start: try using the production URL instead for visual review
6. If neither works: ABORT — do not proceed without visual verification
```

### Step 4.2 — Capture ALL Public Pages

For each public route:
1. `browser_navigate` to the route
2. `browser_resize` to 1440px width
3. `browser_take_screenshot` → save to `./screenshots/visual-polish/after/[page]-desktop.png`
4. `browser_resize` to 768px width
5. `browser_take_screenshot` → save to `./screenshots/visual-polish/after/[page]-tablet.png`
6. `browser_resize` to 375px width
7. `browser_take_screenshot` → save to `./screenshots/visual-polish/after/[page]-mobile.png`
8. `browser_console_messages` → check for errors

Pages to capture:
- Landing / Home page
- Login page
- Signup page
- Pricing page
- Any other public routes identified in Phase 0

### Step 4.3 — Authenticate and Capture ALL Post-Auth Pages

1. `browser_navigate` to login page
2. `browser_fill_form` or `browser_type`/`browser_click` with user credentials (from Phase 0)
3. Verify login succeeded (check for redirect to dashboard or authenticated UI)
4. For each authenticated route:
   - Capture at all 3 breakpoints (1440, 768, 375)
   - Save to `./screenshots/visual-polish/after/[page]-[breakpoint].png`
   - Check console for errors

Pages to capture:
- Dashboard
- All list views
- At least one detail view (with data)
- Settings pages
- Any empty state views (if testable)

### Step 4.4 — Dark Mode Captures

If the project supports dark mode:
1. Toggle dark mode via app's theme switcher (`browser_click`) or inject:
   ```javascript
   document.documentElement.classList.add('dark')
   ```
2. Re-capture ALL pages with `-dark` suffix at 1440px width (minimum)
3. Key pages also at 768px and 375px

### Step 4.5 — Visual Quality Review

For each captured screenshot, evaluate quality using the reference product screenshots from Phase 0 Step 0.4 as **quality benchmarks** (not pixel-level targets). The goal is not to replicate the reference product's design — it's to match their level of visual polish, consistency, and attention to detail.

Review checklist:
   - **Contrast issues** — any text hard to read?
   - **Broken dark mode overrides** — white backgrounds, invisible text?
   - **Inconsistent accents** — old accent color still showing?
   - **Surviving AI-slop patterns** — centered-everything, gradient text, blur circles?
   - **Typography consistency** — old font still rendering anywhere?
   - **Spacing rhythm** — uniform padding where it should be varied?
   - **Layout breaks** — anything overflowing or collapsing at breakpoints?
   - **Missing states** — hover, focus, active states working?
   - **Logo placement** (if logo exists) — verify in all configured positions (header, mobile header, sidebar if applicable, footer if included):
     - Correct theme variant displayed in both light and dark modes?
     - No clipping, overflow, or distortion at all breakpoints (1440px, 768px, 375px)?
     - Sufficient contrast against each position's background?
     - Mobile touch targets not overlapping (logo vs hamburger menu)?

Document ALL issues found in the next step.

### Step 4.6 — Issue Documentation

Create `./plancasting/_audits/visual-polish/review-issues.md`:

```markdown
# Visual Review Issues

## Critical (must fix before proceeding)
| # | Page | Breakpoint | Issue | Screenshot |
|---|------|-----------|-------|------------|
| 1 | Dashboard | Mobile | Sidebar overlaps content | after/dashboard-mobile.png |

## Major (should fix)
| # | Page | Breakpoint | Issue | Screenshot |
|---|------|-----------|-------|------------|

## Minor (nice to fix)
| # | Page | Breakpoint | Issue | Screenshot |
|---|------|-----------|-------|------------|
```

---

## Phase 5: Anti-AI-Slop Refinement

This phase VERIFIES that AI-slop patterns were removed and catches any NEW patterns introduced during implementation.

Cross-reference the slop inventory from Step 3.5 (`./plancasting/_audits/visual-polish/slop-inventory.md`) with the visual review screenshots from Phase 4:
1. **Check resolved**: Which patterns from the inventory were already fixed during Steps 3.7-3.8? Mark them as resolved.
2. **Check surviving**: Which inventory patterns still appear in Phase 4 screenshots? These need fixing now.
3. **Check new**: Did the implementation introduce NEW slop patterns not in the original inventory? (This is common — the agent fixes gradient text on the hero but adds a pill badge above the new heading.) Fix these too.

If the `frontend-design` skill is available, invoke it once here — submit all remaining fixes together in a single consolidated invocation (not per-fix).

### never Patterns — Detect and Remove

Detection examples below use Tailwind class names. For other CSS frameworks, search for the equivalent CSS properties (e.g., `background-clip: text` instead of `bg-clip-text`, `filter: blur(64px)` instead of `blur-3xl`, `padding: 6rem 0` instead of `py-24`).

| Pattern | Detection (Tailwind / CSS) | Fix |
|---|---|---|
| Centered-everything hero with gradient text | `bg-gradient-to-r bg-clip-text text-transparent` / `background-clip: text; -webkit-text-fill-color: transparent` | Left-aligned or asymmetric hero with solid-color heading |
| Decorative blur circles | `blur-3xl` with low-opacity accent bg / `filter: blur(64px)` on decorative elements | Remove entirely, or replace with subtle CSS gradient mesh |
| Giant decorative quotation marks on testimonials | Oversized `"` or `<span>` with large font-size as decoration | Remove — let the testimonial text and attribution speak |
| Identical uppercase tracked section labels | Same `uppercase tracking-wider text-xs` / `text-transform: uppercase; letter-spacing` on every section | Vary label styles: some monospace, some regular case, some omitted |
| Uniform section padding throughout | Every section uses identical `py-24` / `padding: 6rem 0` | Vary rhythm: 4rem → 5rem → 7rem → 8rem (not uniform) |
| Generic dark-band CTA sections | Full-width dark background CTA at page bottom | Bordered card CTA, or split layout, or inline CTA within content |
| Pill badge at top of hero | `rounded-full` small pill / `border-radius: 9999px` with accent tint above heading | Remove or replace with monospace breadcrumb-style label |
| Purple/blue gradient backgrounds | `from-purple-600 to-blue-500` / `linear-gradient(to bottom right, #9333EA, #3B82F6)` | Solid background with subtle texture or noise overlay |
| Uniform card grids with identical cards | `grid-cols-3 gap-6` / identical repeated card in uniform grid | Vary card sizes (span-2 + span-1), add featured card treatment, break grid rhythm |
| Decorative floating shapes/dots | `position: absolute` circles, squares, dots as decoration | Remove unless they serve information hierarchy |

### always Patterns — Apply Where Missing

These patterns prevent generic AI output. Implementation examples use Tailwind classes — adapt to your CSS framework's equivalents. **Adapt intensity to the approved Design Style** (Decision 3) — e.g., "compact page titles" suit Developer Tool-first but would undermine Editorial's dramatic typography. Use judgment: the spirit is distinctiveness, not a rigid checklist.

| Pattern | Where to Apply | Implementation | Best for Styles |
|---|---|---|---|
| Left-aligned asymmetric hero | Landing page hero section | Heading left-aligned, max-width constraining text, visual on right or below asymmetrically | All styles |
| Monospace accents | Taglines, timestamps, breadcrumbs, email addresses, metadata labels | `font-mono text-xs tracking-wide` or equivalent | Refined Minimal, Developer Tool-first, Editorial |
| Varied section padding | Between major page sections | Alternate: `py-16` → `py-20` → `py-28` → `py-32` (not uniform) | All styles |
| Solid accent color on key words | Hero heading, section titles, key metrics | `text-accent` on 1-2 words per heading, NOT gradient | All styles |
| Arrow icon on primary CTA | Main call-to-action buttons | Add `→` or arrow icon after button text | Refined Minimal, Developer Tool-first |
| Inline social proof | Near hero or pricing sections | Small avatar circles + count text, inline, not a separate section | Polished Product, Warm Playful |
| Split header/subtitle for section intros | Section headings throughout | Small monospace label above, large heading below — not centered pill badge | Refined Minimal, Editorial, Developer Tool-first |
| Bordered card CTA | Bottom of marketing pages | Card with border, headline, description, button — not full-width dark band | All styles |
| Subtle active state in sidebar | Navigation sidebar | `bg-neutral-100 dark:bg-neutral-800` on active item, not heavy highlight | All styles |
| Compact page titles | Dashboard and app page headings | Smaller `text-lg font-semibold`, not oversized `text-3xl font-bold` — tool-first feel | Developer Tool-first, Refined Minimal |
| Card hover accent reveal | Cards in grid or list views | On hover: title text shifts to accent color, subtle shadow increase | All styles |

---

## Phase 6: Fix & Re-Review Cycle

For each issue documented in Phase 4 and anti-slop pattern detected in Phase 5:

### Step 6.1 — Fix Each Issue

1. Read the file containing the issue
2. Apply the fix
3. If the fix involves CSS class changes (e.g., dark mode, token replacement), use `browser_snapshot` to inspect the DOM and verify the expected classes are present — visual screenshots alone may miss subtle CSS specificity issues where the class is applied but overridden
4. Run `bun run typecheck` and `bun run lint` (or equivalent)

### Step 6.2 — Re-Capture the Specific Page

1. `browser_navigate` to the affected page
2. `browser_resize` to the relevant breakpoint
3. `browser_take_screenshot` → overwrite the previous "after" screenshot
4. `browser_console_messages` → verify no new errors

### Step 6.3 — Confirm Fix Visually

1. View the new screenshot
2. Verify the issue is resolved
3. Verify no regressions were introduced (check adjacent elements)

### Step 6.4 — Repeat Until All Pages Pass

Continue the fix → re-capture → confirm cycle until:
- All critical issues resolved
- All major issues resolved
- All anti-slop patterns addressed
- All pages pass visual review at all breakpoints
- Dark mode verified on all modified pages

**Max iteration guard**: If after 3 full fix-and-review cycles any issues remain unresolved, document them as known limitations in the report rather than continuing indefinitely. Persistent issues usually indicate a deeper architectural constraint (e.g., component library limitation, CSS specificity conflict) that requires a different approach — flag these for the user to decide.

### Step 6.5 — Final Validation

Run full validation suite:
```bash
bun run typecheck    # Must pass
bun run lint         # Must pass
bun run test         # Must pass (or match pre-redesign baseline)
bun run test:e2e     # Must pass — visual changes can break E2E test selectors
```

If any validation fails:
- Fix the issue
- If the fix would compromise the design, revert that specific design change and document as a known limitation
- Re-run validation

---

## Phase 7: Documentation & Downstream Updates

### Step 7.1 — Update Design Tokens Documentation

If the project has a `src/styles/design-tokens.ts` or equivalent, ensure it reflects the final state of all tokens.

### Step 7.2 — Update Tech Stack Design Direction

Update `plancasting/tech-stack.md` with the new design direction (if this section exists):
- New font pairing
- New color palette
- New design style
- New animation approach

### Step 7.3 — Documentation Config & Screenshot Preparation

This updates docs.json brand colors and existing screenshots — it is not a full 7D re-run. A full 7D re-run from scratch is RECOMMENDED after merging to main (see Phase 9 Shutdown).

If the project has a documentation site (Mintlify, Docusaurus, etc.):

1. **Update docs config colors**: Find the docs configuration file (e.g., `docs.json` for Mintlify, `docusaurus.config.js` for Docusaurus) and update brand colors to match the new palette. Do this in the SAME commit as the accent color change — not as a follow-up.

2. **Discover the actual screenshot path**: Before capturing any screenshots, grep the docs content files to find where images are referenced:
   ```bash
   grep -r 'src="/\|!\[' user-guide/ --include='*.mdx' --include='*.md' | grep -oE 'src="[^"]*\.(png|jpg)' | sort -u
   ```
   Common patterns:
   - Mintlify: images typically go in `images/` at the docs root (e.g., `user-guide/images/`) — see Stage 7D Known Failure Pattern #18
   - Docusaurus: `![](../static/img/...)` → save to `docs/static/img/`
   - Custom: varies — always verify before capturing

3. **Capture screenshots to the CORRECT path**: Save directly to the path the docs framework references, NOT to a separate `images/` directory. Verify the files will be served by the docs build.

4. **Verify docs deployment**: After committing and pushing, confirm the docs site redeploys and the new screenshots are visible. Mintlify auto-deploys from git push; other frameworks may need a manual deploy trigger.

5. Document this in the report: "Stage 7D re-run complete — [N] screenshots recaptured to [path], docs config colors updated."

---

## Phase 8: Final Report

Generate `./plancasting/_audits/visual-polish/redesign-report.md` (note: uses `redesign-report.md`, NOT `report.md`, to preserve any prior 6P report for audit trail):

```markdown
# Stage 6P-R Frontend Redesign Report

## Summary
- **Date**: [date]
- **Commit (before)**: [git hash before redesign]
- **Color Theme Mode**: [Decision 1 choice]
- **Accent Color**: [Decision 2 hex]
- **Design Style**: [Decision 3 choice]
- **Typography Pairing**: [Decision 4 pair]
- **Reference Products**: [list]
- **Figma Alignment**: [yes/no — if yes, token mapping summary]

## Design Decisions
1. Color Theme Mode: [choice + rationale]
2. Accent Color: [hex + name]
3. Design Style: [choice]
4. Typography Pairing: [display + body]
5. Border Radius: [value]
6. Animation Level: [choice]
7. Hero Section: [style or "N/A — no public pages"]
8. Dashboard Layout: [choice or "N/A — no authenticated pages"]

## Implementation Summary
| Step | Description | Status |
|------|-------------|--------|
| 3.1 | Design tokens | ✅ / ❌ |
| 3.2 | Font setup | ✅ / ❌ |
| 3.3 | Theme provider | ✅ / ❌ |
| 3.4 | UI component audit | ✅ / ❌ |
| 3.5 | Anti-slop pre-scan | ✅ / ❌ |
| 3.6 | Layout components | ✅ / ❌ |
| 3.7 | Public pages | ✅ / ❌ |
| 3.8 | Authenticated pages | ✅ / ❌ |
| 3.9 | Feature component audit | ✅ / ❌ |
| 3.10 | Motion & animation | ✅ / ❌ |
| 3.11 | Light/dark verification | ✅ / ❌ |

## Visual Review Results
- Issues found: [n] critical, [n] major, [n] minor
- Issues fixed: [n]
- Anti-slop patterns addressed: [n]
- Remaining known issues: [n] (with explanations)

## Anti-AI-Slop Audit
| Pattern | Found | Fixed | Notes |
|---------|-------|-------|-------|
| Centered-everything hero + gradient text | Yes/No | ✅/❌ | [details] |
| Decorative blur circles | Yes/No | ✅/❌ | [details] |
| Giant decorative quotation marks | Yes/No | ✅/❌ | [details] |
| Identical uppercase section labels | Yes/No | ✅/❌ | [details] |
| Uniform section padding | Yes/No | ✅/❌ | [details] |
| Generic dark-band CTA | Yes/No | ✅/❌ | [details] |
| Pill badge at top of hero | Yes/No | ✅/❌ | [details] |
| Purple/blue gradient backgrounds | Yes/No | ✅/❌ | [details] |
| Uniform card grids | Yes/No | ✅/❌ | [details] |
| Decorative floating shapes/dots | Yes/No | ✅/❌ | [details] |

## Responsive Verification
| Page | Desktop (1440) | Tablet (768) | Mobile (375) | Dark Mode |
|------|---------------|-------------|-------------|-----------|
| Landing | ✅ / ❌ | ✅ / ❌ | ✅ / ❌ | ✅ / ❌ |
| Login | ✅ / ❌ | ✅ / ❌ | ✅ / ❌ | ✅ / ❌ |
| Dashboard | ✅ / ❌ | ✅ / ❌ | ✅ / ❌ | ✅ / ❌ |
| [... all pages] | | | | |

## Files Modified
[List of all files changed with brief description]

## Validation
- TypeScript: ✅ PASS / ❌ FAIL
- ESLint: ✅ PASS / ❌ FAIL
- Tests: ✅ PASS ([n] passed) / ❌ FAIL ([n] failed)

## Downstream Actions
- [ ] Deploy via Stage 7
- [ ] Update docs.json / config with new brand colors (do this BEFORE deploying docs — see Known Failure Pattern 14)
- [ ] Re-run Stage 7D for updated screenshots — must grep docs content for actual image path before capturing (see Known Failure Pattern 13)
- [ ] Verify Hybrid theme has no flicker: navigate public → login → dashboard and confirm no light→dark flash (see Known Failure Patterns 11-12)

## Gate Decision

**Category note**: 6P-R uses Critical/Major/Minor severity for review issues, distinct from 6P's O/E/D visual categories. Both systems are independent of the 6V/6R fixability-based A/B/C categories.

**Severity classification**:
- **Critical**: Design system not applied to key pages, broken dark mode, validation failures
- **Major**: Inconsistent design token usage across 3+ components, missing responsive breakpoint
- **Minor**: Single-component spacing issue, minor color inconsistency

- **PASS**: All design decisions implemented, visual review passed, validation clean → proceed to Stage 7
- **CONDITIONAL PASS**: Minor visual issues remain but documented → proceed to Stage 7, address in next iteration
- **FAIL**: Any critical visual issue on a HIGH-priority page (landing, dashboard, auth), OR validation failures (typecheck/lint/test), OR broken dark mode on 3+ pages → fix before proceeding

## Screenshots
- Before: `./screenshots/visual-polish/before/`
- After: `./screenshots/visual-polish/after/`
- References: `./screenshots/visual-polish/references/`

Note: Screenshot directories (`./screenshots/`) are for local reference. Add to `.gitignore` — do not commit large binary files.
```

---

## Phase 9: Shutdown

1. **Commit all redesign changes**:
   Stage modified files for commit using targeted `git add`. Avoid `git add -A` which may capture screenshots, temp files, or credential data.
   ```bash
   # Add your source directory + audit output. Adapt paths to your project.
   git add src/ [audit-output-dir] && git commit -m "style: frontend redesign — [design style] with [font pair], [n] pages updated"
   ```
   For Transmute Framework projects:
   ```bash
   git add src/ plancasting/_audits/visual-polish/redesign-report.md plancasting/_audits/visual-polish/redesign-*.md plancasting/tech-stack.md && git commit -m "style(design): Stage 6P-R frontend redesign — [design style] with [font pair]"
   ```

2. **Save the redesign commit hash**:
   ```bash
   git rev-parse HEAD > ./plancasting/_audits/visual-polish/last-polished-commit.txt
   ```

3. **Stop the dev server** if it was started by this stage (check if it was already running from a prior session — if so, leave it running).

4. **Verify `.gitignore`** includes `screenshots/` to prevent binary bloat in the repository.

5. **Next Steps** (output to operator):
   > ⚠️ **Critical**: After this stage completes, merge the redesign branch to main FIRST:
   > ```bash
   > git checkout main && git merge <your-redesign-branch>
   > ```
   > (default branch name: `redesign/frontend-elevation`)
   > THEN re-run Stage 7D (User Guide Generation) in a fresh session to recapture all screenshots and docs content with the new design. Update `docs.json` color tokens to match the new palette. Do not run Stage 7D before merging the branch. This is required even if 7D ran before 6P-R.

---

## Session Recovery

If this stage is interrupted mid-execution:
1. Check if `./plancasting/_audits/visual-polish/` directory exists with any phase output files
2. Check the `redesign/frontend-elevation` branch: `git log --oneline redesign/frontend-elevation` to see what was committed
3. **Phase 0–2 interrupted** (interactive discovery): Prior outputs are preserved in audit files. Resume by re-pasting the prompt — the lead will detect existing Phase 0–2 outputs and skip completed phases. Do not repeat interactive decisions already made.
4. **Phase 3–8 interrupted** (autonomous implementation): Check which components were already redesigned by reviewing git diff on the redesign branch. Resume by re-pasting the prompt — the lead will detect the redesign branch and resume from the first incomplete component group.
5. **Phase 9 interrupted** (shutdown): Manually commit remaining changes on the redesign branch and proceed to operator merge decision.

**After merging to main**: Always re-run Stage 7D to recapture screenshots with the new design. Verify image paths: `grep -r 'src="' user-guide/ --include='*.mdx'`.

---

## Critical Rules

1. **never change functional behavior.** This stage changes ONLY visual presentation. If a change would alter routing, data flow, API calls, auth, or form submission logic, it is OUT OF SCOPE. **Exception**: If the user explicitly approves adding dark mode infrastructure in Decision 1 (because the project lacks it but they chose a dark theme), that scope extension is authorized.

2. **never replace design system components with custom implementations.** Work within the existing UI library's API. Use className, variant props, and CSS overrides — not component replacements.

3. **always get explicit user approval on the design plan** (Phase 2) before implementing anything. The user's design preferences override any default recommendations.

4. **always use the `frontend-design` skill** (if available) for aesthetic decisions. It prevents generic AI-generated aesthetics. **The lead invokes the frontend-design skill once during this stage (in Phase 5 — Anti-AI-Slop Refinement), not per-fix or per-pattern**. Teammates read the shared output — they do not invoke the skill themselves. This ensures design consistency across all phases.

5. **always take before/after screenshots.** Every change must be visually documented and verified.

6. **always run validation** (typecheck + lint + test) after implementation. A beautiful design that breaks the build is worthless.

7. **always verify at all 3 breakpoints** (1440, 768, 375). A desktop-only redesign is half a redesign.

8. **always verify dark mode** if the project supports it. Every color change needs a dark variant.

9. **never introduce new dependencies without checking `package.json`.** If an animation library or font loader isn't already installed, check with the user before adding it.

10. **always apply the anti-AI-slop patterns** from Phase 5. These are non-negotiable — they prevent the redesign from looking like generic AI output.

11. **Maximum 3 animation additions per page.** (See Step 3.10 SCOPE RULE.)

12. **always preserve accessibility.** Focus rings, ARIA labels, semantic HTML, keyboard navigation — if a design change would compromise any of these, find an alternative approach.

13. **Token-first implementation.** Always start with design tokens (Step 3.1) — they cascade ~80% of changes automatically. Only after tokens are set should you modify individual components.

14. **always check console errors during Playwright screenshots.** Use `browser_console_messages` after each capture. (See Steps 4.2, 4.3, 6.2.)

15. **Collect ALL context in Phase 0 before any design work.** Do not skip interactive collection steps — they prevent wasted implementation effort from wrong assumptions.

16. **always use Figma MCP tokens when available.** If the user provided a Figma file, the extracted tokens are the design authority. Implementation must align with Figma, not deviate from it.

17. **always compare against reference product screenshots.** The user chose references for a reason — use them as quality benchmarks during the visual review cycle.

18. **never skip the fix-and-re-review cycle** (Phase 6). First-pass implementation always has issues. The iterative cycle is what produces production-quality results.

19. **Default to one question at a time** in Phase 0 and Phase 1. Offer the batch-mode fast-path (see Phase 0 header) but default to sequential — it prevents overwhelm and incomplete answers. In batch mode, still validate that all required inputs were provided before proceeding.

20. **Treat the design plan as a contract.** Once approved in Phase 2, implement it faithfully. If you discover a decision doesn't work during implementation, go back to the user with a specific alternative — don't silently deviate.

21. **ONLY animate `transform` and `opacity`.** (See Step 3.10 PERFORMANCE RULE for details.)

22. **never write credentials to committed files.** Reference the credential source (e.g., "from e2e/constants.ts") in reports — never the raw values.

23. **always verify font availability before configuring.** Google Fonts work with `next/font/google`. Non-Google fonts (Fontshare, paid, custom) require `.woff2` downloads and `next/font/local`. A misconfigured font import breaks the build at compile time.

24. **Scan for hardcoded values AFTER updating tokens.** (See Step 3.4 for the full audit checklist.)

25. **Treat contrast ratios as non-negotiable.** WCAG AA (4.5:1 for normal text, 3:1 for large text) is the MINIMUM. If an approved design decision produces insufficient contrast, adjust the specific shade — do not compromise readability for aesthetics.

26. **ALL animations must respect `prefers-reduced-motion`.** Use `motion-safe:` Tailwind prefix or CSS `@media (prefers-reduced-motion: reduce)` to disable animations for users who request it. This is a WCAG 2.1 requirement, not optional.

27. **Adapt anti-slop ALWAYS patterns to the approved Design Style.** The always table includes a "Best for Styles" column — skip patterns that conflict with the user's chosen style. The goal is distinctiveness, not a rigid checklist. A "compact page titles" pattern makes no sense for an Editorial design that deliberately uses dramatic typography.

28. **Maximum 3 fix-and-review cycles.** (See Step 6.4 max iteration guard.)
````
