# Transmute — Visual Polish & UI Refinement

## Stage 6P: Automated UI Enhancement Using Frontend Design Expertise

````text
You are a senior frontend designer and engineer acting as the TEAM LEAD for a multi-agent visual polish project using Claude Code Agent Teams. Your task is to analyze the RUNNING application's visual quality, identify UI issues (visibility, layout, typography, spacing, motion, responsiveness), and automatically refine the frontend to production-grade aesthetic quality — using the `frontend-design` skill for all design decisions (if available; if the skill is unavailable in your environment, use the design token file path from `plancasting/tech-stack.md` or CLAUDE.md Part 2 Technology Stack table (common default: `src/styles/design-tokens.ts`) and the design guidance in CLAUDE.md Part 1 § "Design & Visual Identity" as your primary authority instead).

## Why This Stage Exists

Stages 6V and 6R ensure the application is **functionally correct** — every route loads, every button works, every auth flow succeeds. But functional correctness ≠ visual quality. Common issues that survive 6V/6R:

1. **Invisible or low-contrast elements**: Text that renders but is barely visible against its background (e.g., gray-on-white, white-on-light-gradient)
2. **Layout collapse at breakpoints**: Components that work at desktop but stack awkwardly or overflow at tablet/mobile
3. **Inconsistent spacing**: Some pages use tight spacing, others use generous spacing — no rhythm
4. **Missing micro-interactions**: Buttons that feel dead (no hover state, no press feedback, no transition)
5. **Typography hierarchy gaps**: All text looks the same size/weight — no visual hierarchy guiding the eye
6. **Empty state aesthetics**: Functional empty states that look like placeholder UI (centered gray text + icon)
7. **Loading state jank**: Skeleton loaders that don't match the final layout, causing content shift
8. **Dark mode gaps**: Light mode looks polished, dark mode has contrast issues or unstyled sections. If the project currently lacks dark mode and the 6V/6R report suggests it should be added, escalate to 6P-R instead of implementing within 6P.
9. **Animation absence**: Page transitions and component reveals feel abrupt — no entry animations
10. **Generic "AI slop" aesthetics**: The application looks like every other AI-generated SaaS — Inter font, purple gradients, predictable card layouts

This stage transforms a functionally correct app into a **visually distinctive** product. It runs AFTER 6R (all mechanical issues fixed) and BEFORE deployment.

**Stage Sequence**: ... → 6V (Verification) → [6R (Runtime Remediation) — only if 6V found 6V-A/B issues] → **6P (this stage)** → 7 (Deploy) → 7V (Production Smoke) → 7D (User Guide) → 8 (Feedback) / 9 (Maintenance)

**Mutual Exclusivity**: This stage (6P) and Stage 6P-R (Frontend Design Elevation) are alternatives — run exactly ONE, not both. If 6P has already been run and you want to switch to 6P-R, revert 6P changes first (`git revert` the 6P commit). See execution-guide.md § "6P vs 6P-R" for details.

**Switching to 6P-R**: If you've run 6P and now need a full design overhaul:
1. Commit all 6P work: `git add src/ plancasting/_audits/visual-polish/ && git commit -m "chore(6p): Stage 6P visual polish changes"`
2. Revert the commit: `git revert <commit-hash>` (NOT `git reset --hard`)
3. Start a new session and run `prompt_frontend_redesign.md` (6P-R)

## Relationship to the `frontend-design` Skill

This stage uses the **`frontend-design` skill** (Claude Code plugin) for all aesthetic decisions. The skill's core principles:

- **Typography**: Distinctive, characterful font choices — never generic Inter/Roboto/Arial
- **Color & Theme**: Cohesive aesthetic with dominant colors and sharp accents
- **Motion**: High-impact animations at key moments (page load, hover, transitions)
- **Spatial Composition**: Unexpected layouts, asymmetry, generous negative space or controlled density
- **Visual Depth**: Gradient meshes, noise textures, layered transparencies, dramatic shadows

**KEY CONSTRAINT**: This stage operates WITHIN the project's existing design system. You are not redesigning from scratch.

**Scope Prioritization**: Focus on HIGH-IMPACT pages first: (1) landing/marketing pages (first impression), (2) auth pages (signup/login — conversion-critical), (3) primary dashboard (most-used screen), (4) core feature pages (P0/P1 features from PRD). Polish secondary pages (settings, profile, admin) only after key pages pass visual review. Target: 10–15 key screens, not every component in the codebase.

**Component modification decision matrix**:
| Scenario | Action |
|---|---|
| Component needs hover transition but library doesn't support via className | Add transition via wrapper `<div className="transition-colors">`, do not replace component |
| Component styling is completely incompatible with design direction | Escalate to Category D (document for design review), do not replace component |
| Text contrast fails WCAG AA in dark mode | Adjust color variant via className (e.g., `dark:text-slate-200`), do not replace component |

You are:
- **Elevating** the existing aesthetic using the design system's tokens (colors, spacing, typography scale)
- **Adding** missing polish (micro-interactions, transitions, hover states, loading refinements). Mandatory interaction states: hover, focus-visible, and active for all interactive elements (buttons, links, form inputs). Optional: press feedback (scale transform), loading spinners, and staggered reveal animations.
- **Fixing** objective visual defects (contrast failures, layout breaks, spacing inconsistencies)
- **Enhancing** key screens with the frontend-design skill's aesthetics guidelines (within the design system's vocabulary)

If the project uses a UI library (e.g., Untitled UI, shadcn/ui, Chakra), work WITHIN its component API. Do not replace library components with custom implementations unless fixing a specific defect that the library cannot handle. Replace a library component ONLY if: (1) the defect cannot be fixed via the component's API/props, (2) accessibility is broken, AND (3) the change is scoped to a single component. In all other cases, use wrapper components, CSS overrides, or configuration changes.

> **Component modification boundary**: Use the library's component API (className, props, variants) for styling changes. Escalate to Category D if the component API doesn't support the needed styling. never replace a UI library component just for styling — only escalate for accessibility fixes where the library offers no API path forward.

## Known Failure Patterns

Based on observed visual polish outcomes:

1. **Replacing UI library components wholesale**: Agent replaces Untitled UI / shadcn/ui buttons with custom-styled `<button>` elements to add hover transitions. This breaks accessibility (ARIA), variant consistency, and future library updates. always use the library's component API (className, variant props) to add styling — never replace the component itself.
2. **CSS specificity wars**: Agent adds Tailwind utility classes that are overridden by the UI library's base styles. Fix: use `!important` sparingly and only as a last resort, or add styles via the library's theming/customization API.
3. **Breaking existing dark mode**: Agent fixes a light-mode contrast issue by hardcoding a color value (e.g., `text-gray-900`) without adding the `dark:` variant, breaking dark mode. always add both light and dark variants when modifying colors.
4. **Animation performance regression**: Agent adds CSS transitions/animations that trigger layout recalculation (animating `width`, `height`, `top`, `left`). ONLY animate `transform` and `opacity` for performant animations.
5. **Font loading FOUT/FOIT**: Agent adds a distinctive display font via CDN `<link>` without `font-display: swap` or preloading, causing Flash of Unstyled Text or Invisible Text on slow connections. Use `next/font` (or equivalent) with `display: swap`.
6. **Overzealous enhancement scope**: Agent "improves" 50+ components when only 10 key screens need attention. This stage targets high-impact pages — do not polish every minor component.
7. **Hybrid theme localStorage flicker**: In projects with light/dark mode, using `setTheme()` or similar JS-based theme toggles causes a flash of the wrong theme on page load because `localStorage` is read after initial render. never use `setTheme()` for initial theme — use CSS `prefers-color-scheme` media query as the default, with `setTheme()` only for user-initiated overrides. This pattern is documented in detail in Stage 6P-R's Known Failure Patterns.

## Refinement Categories

Every visual issue falls into one of three categories:

### Category O: Objective Defects (Auto-Fix, No Judgment)
Issues with a clear right/wrong answer. The agent must fix these.

| Issue Type | Detection Method | Fix Pattern |
|---|---|---|
| WCAG contrast failure (< 4.5:1 for text, < 3:1 for large text) | Automated contrast ratio check on screenshots | Adjust text color or background to meet ratio |
| Text invisible or near-invisible against background | AI vision analysis of screenshots | Adjust color, add text-shadow, or change background |
| Layout overflow at any standard breakpoint | Screenshot at 320/768/1024/1440px widths | Fix overflow with proper responsive utilities |
| Content clipped by parent container | AI vision — text/elements cut off | Fix overflow property or adjust sizing |
| Skeleton loader doesn't match content layout | Compare loading vs loaded screenshots | Adjust skeleton dimensions to match rendered content |
| Focus ring missing on interactive elements | Tab through all interactive elements | Add `focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2` |
| Z-index stacking error (element hidden behind another) | AI vision — overlapping elements | Fix z-index hierarchy |
| Dark mode unstyled section (default white background persists) | Screenshot in dark mode | Add dark mode variants to unstyled sections |
| Image/icon not rendering (broken src or missing asset) | AI vision — broken image placeholder visible | Fix asset path or provide fallback |
| Touch target too small (< 44×44px on mobile) | Measure interactive elements in mobile screenshots | Increase padding/size to meet minimum |

**Category boundary decision rules** (use in order — first match wins):
1. Is it a measurable WCAG/accessibility failure or functional breakage? → **Category O** (objective defect)
2. Does it block a user action or hide content? → **Category O**
3. Is it a visual improvement with no functional impact, following an established pattern in the codebase? → **Category E** (enhancement)
4. Does it require choosing a new design direction, font, color palette, or brand-level decision? → **Category D** (design elevation)

Examples — Category O: missing focus ring (WCAG violation), layout overflow (content hidden), broken image. Category E: missing hover state (button works but lacks feedback), no page entry animation, inconsistent spacing. Category D: suggests new font pairing, color palette redesign, illustration style.

### Category E: Enhancement (Pattern-Based, Apply Where Feasible)
Issues where the fix follows established patterns in the codebase. Apply the fix, then verify visually. Category E is discretionary — skip if the enhancement conflicts with the design system, has negligible visual impact, or risks regression.

| Issue Type | Detection Method | Fix Pattern | Verify |
|---|---|---|---|
| Missing hover state on buttons/links | Interact with element, compare to design system | Add hover transition using project's existing hover patterns | Verify hover doesn't break layout or overlap adjacent elements |
| Missing page transition animation | Navigate between pages, observe jarring cut | Add entry animation using project's motion library/CSS | Verify animation doesn't delay perceived load time |
| Inconsistent spacing between similar sections | Compare spacing across pages | Standardize to project's spacing scale tokens | Verify content still fits at all breakpoints |
| Empty state visually weak (just text) | AI vision — sparse empty state | Enhance with icon or call-to-action using project's existing design system assets (do not source new illustrations — if none exist, document as Category D suggestion instead) | Verify CTA navigation works |
| Typography hierarchy flat (all same size) | AI vision — no visual hierarchy on page | Apply heading/subheading/body scale from design system | Verify text doesn't overflow containers |
| Card/container missing depth (looks flat) | AI vision — no shadow, border, or gradient | Add subtle shadow or border using design system tokens | Verify depth doesn't look inconsistent with surrounding cards |
| Loading state too plain (no skeleton, just spinner) | Observe loading state | Replace with skeleton matching content layout | Verify skeleton-to-content transition is smooth |
| Form input styling inconsistent | Compare form inputs across pages | Standardize to project's form component styling | Verify all states (focus, error, disabled) still work |

### Category D: Design Elevation (Needs Design Review)
Subjective improvements that would elevate the aesthetic but may conflict with brand intent. Document as suggestions for human review.

| Issue Type | What To Document |
|---|---|
| Font pairing opportunity — current fonts are generic | Suggested distinctive font pair, visual mockup (screenshot with annotation) |
| Color palette feels flat or generic | Suggested accent colors, gradient direction, visual mockup |
| Hero/landing section lacks visual impact | Suggested composition change, background treatment, motion concept |
| Illustration style opportunity | Suggested style (geometric, organic, isometric, etc.), example references |
| Micro-interaction opportunity (scroll-triggered, parallax, etc.) | Interaction description, which elements, expected delight factor |
| Overall aesthetic direction suggestion | Named direction (from frontend-design skill), rationale, which pages would change |

Category D suggestions are for POST-LAUNCH review. They do not block Stage 7 deployment. The operator may implement them in a future 6P-R run or defer indefinitely.

## Prerequisites

> **Mutual exclusivity check**: Before proceeding with ANY prerequisite below, check if `./plancasting/_audits/visual-polish/design-plan.md` exists. If it does, Stage 6P-R was already run — **STOP immediately**. 6P and 6P-R are mutually exclusive (run exactly one, never both). If you need to run 6P after a 6P-R run, first `git revert` the 6P-R commit, then start a new session. See CLAUDE.md § Safety-Critical Rules.

0. **Check if 6P-R was run instead**: If Stage 6P-R (Frontend Design Elevation) was run instead of 6P, skip this stage entirely — 6P-R subsumes all 6P work. Proceed directly to Stage 7. Check for `./plancasting/_audits/visual-polish/design-plan.md` — this file is only generated by Stage 6P-R. If `./plancasting/_audits/visual-polish/design-plan.md` exists, check 6P-R completion status:
   - If `progress.md` in the same directory shows all phases completed → 6P-R is done. Skip this stage (6P).
   - If `progress.md` is missing or shows incomplete phases → 6P-R failed mid-execution. Do not proceed — request operator approval before continuing.
   - If `design-plan.md` exists but 6P-R's `progress.md` shows incomplete status, verify with the operator whether 6P-R was intentionally abandoned before proceeding.
   - If `design-plan.md` does not exist → 6P-R was not run. Proceed with 6P.

1. **`frontend-design` plugin** (recommended but has a fallback):
   Check if the skill file exists at `/mnt/skills/public/frontend-design/SKILL.md`.
   - **If available**: The plugin is loaded at the session level — spawned teammates inherit access automatically. However, slash command invocation (`/frontend-design`) only works in the lead's session (see Rule 17). The lead invokes the skill once and saves the output for teammates to read.
   - **If NOT available** (file missing — e.g., local CLI environment): Skip Phase 1 Step 8 (design guidelines generation) and Phase 3 Step 4 (design elevation brief). Teammates 1 and 3 proceed normally. Teammate 2 uses the project's existing design patterns instead: read `plancasting/tech-stack.md` design direction section, `src/styles/design-tokens.ts` (or equivalent), and existing component styling in the codebase for aesthetic guidance. The existing design system IS the authority — apply it consistently rather than inventing new patterns. If the design token file does not exist at the expected path, check `plancasting/tech-stack.md` § Design Tokens for the actual location. If no design tokens exist, escalate to operator — 6P cannot proceed without a design direction.

   Fallback when frontend-design skill is unavailable:
   - Use CLAUDE.md § 'Design & Visual Identity' (Part 1) as the primary design authority
   - Use the project's existing `src/styles/design-tokens.ts` and Tailwind configuration
   - Use PRD screen specifications (`plancasting/prd/08-screen-specifications.md`) for design guidance
   - Focus on objective defect fixes (Category O/E) only; skip design elevation work (Category D)

2. **Stage 6R must PASS or CONDITIONAL PASS (if 6R was required)**:
   - **If 6R report exists** (`./plancasting/_audits/runtime-remediation/report.md`): check its Gate Decision. If FAIL → STOP, return to 6R first. If PASS or CONDITIONAL PASS (regardless of remaining 6V-C issues) → proceed. 6V-C issues from 6V/6R are documented for human review and do not block 6P.
   - **If 6R report does not exist**: check `./plancasting/_audits/visual-verification/report.md`:
     - If 6V reports **PASS** → 6R was correctly skipped (no failures to remediate), proceed to 6P.
     - If 6V reports **FAIL** → STOP: "Stage 6V reported FAIL. Fix critical issues manually and re-run Stage 6V before starting Stage 6P." (Do not run 6R against a FAIL report — 6R rejects FAIL inputs in its own prerequisites.)
     - If 6V reports **CONDITIONAL PASS** with only 6V-C issues (human judgment required — not auto-fixable): 6R was correctly skipped (6R cannot fix 6V-C). Proceed to 6P. Document unresolved 6V-C issues in the 6P report.
     - If 6V reports **CONDITIONAL PASS** with 6V-A or 6V-B issues → STOP: "Stage 6V found auto-fixable issues but Stage 6R has not been run yet. Run Stage 6R before starting Stage 6P."
   - **If NEITHER report exists** (both 6V and 6R were skipped): this is unusual — verify with the operator that prior stages were intentionally skipped before proceeding.

   **Important**: If 6R ran, it may have updated the 6V report's gate decision (from CONDITIONAL PASS to PASS). Re-read `./plancasting/_audits/visual-verification/report.md` — check for a `## Post-Remediation Gate Update` section. If present, use that gate status (it reflects post-6R results). If absent, use the original `## Gate Decision`. This ensures you read the CURRENT gate status, not the original pre-6R status.

3. **Dev server port available**: Before running this stage, verify the dev server port is available (`lsof -i :3000` — if busy, `kill -9 <PID>`). This prompt starts the dev server internally. The lead will start it in Phase 1 (or reuse an existing instance).

4. **Output directories**:
   ~~~bash
   mkdir -p ./plancasting/_audits/visual-polish
   mkdir -p ./screenshots/visual-polish/before
   mkdir -p ./screenshots/visual-polish/after
   ~~~

## Input

- **6V/6R Screenshots**: `./screenshots/` — captured during Stage 6V verification
- **6V Report**: `./plancasting/_audits/visual-verification/report.md` — visual assessment notes
- **6R Report**: `./plancasting/_audits/runtime-remediation/report.md` — confirms functional fixes are applied
- **Design System**: Identified from `plancasting/tech-stack.md` (e.g., Untitled UI, shadcn/ui, custom)
- **Codebase**: Your frontend directory (e.g., `./src/`) — components, styles, layouts. Adapt paths per `plancasting/tech-stack.md`
- **PRD Screen Specs**: `./plancasting/prd/08-screen-specifications.md` — intended visual design
- **Tech Stack**: `./plancasting/tech-stack.md` — design direction, fonts, color profile, UI library
- **Project Rules**: `./CLAUDE.md` — coding conventions, focus ring spec, component rules
- **E2E Constants**: `./e2e/constants.ts` — test user credentials for authenticated page screenshots

**Language**: Check `./plancasting/tech-stack.md` for the `Session Language` setting. Generate all reports and user-facing output in the specified language. Code, technical identifiers, and file names remain in English.

## Stack Adaptation

The examples in this prompt use Next.js + Tailwind CSS + Untitled UI as the reference architecture. If your `plancasting/tech-stack.md` specifies a different stack, adapt accordingly:
- Tailwind utilities → your CSS framework's equivalents
- Untitled UI components → your UI library's components
- `src/components/ui/` → your component directory
- CSS variables in `globals.css` → your design token location
- Motion/Framer Motion → your animation library or CSS-only approach
Always read `CLAUDE.md` and `plancasting/tech-stack.md` for your project's actual conventions.

**Package Manager**: Commands in this prompt use `bun run` as the default. Replace with your project's package manager as specified in `CLAUDE.md` (e.g., `npm run`, `pnpm run`, `yarn`).

**Category System Note**: This stage uses DIFFERENT categories than 6V/6R. 6P categories: O (objective defects), E (enhancements), D (design elevation). 6V/6R categories: 6V-A/6V-B (agent-fixable), 6V-C (human judgment). Do not confuse the two systems when reading 6V/6R reports.

**Browser Tools**: This prompt uses Playwright MCP tools (`browser_navigate`, `browser_resize`, `browser_take_screenshot`, `browser_console_messages`, `browser_fill_form`, `browser_click`, `browser_type`, `browser_evaluate`). If your project uses a different browser automation tool (Cypress, Puppeteer, etc.), adapt the tool names accordingly.

## Agent Team Architecture

**Phase numbering note**: This stage uses Phases 1–4. For comparison, 6P-R (the full redesign alternative) uses Phases 0–9 due to its broader scope.

### Phase 1: Lead Visual Audit

As the team lead, complete the following BEFORE spawning any teammates:

1. **Read project context**:
   - `./CLAUDE.md` — component rules, focus ring spec, styling conventions
   - `./plancasting/tech-stack.md` — design direction, UI library, fonts, color profile, aesthetic choices from Stage 0. Check the `Session Language` setting — generate all reports in that language; code remains in English.
   - `./plancasting/prd/08-screen-specifications.md` — intended visual design per screen
   - `./plancasting/_audits/visual-verification/report.md` — 6V visual assessment notes
   - `./plancasting/_audits/runtime-remediation/report.md` — confirm all functional fixes are applied

2. **Identify the design system** (search these locations in order):
   a. `src/styles/design-tokens.ts` (or equivalent) — primary design token definitions
   b. `tailwind.config.ts` (or `tailwind.config.js`) — `theme.extend` tokens for colors, fonts, spacing
   c. Global styles (`globals.css`, `app.css`, or equivalent) — CSS variables for runtime tokens
   d. `plancasting/tech-stack.md` "Design Direction" section — aesthetic intent and reference URLs from Stage 0
   e. Theme configuration (if using a UI library like Untitled UI, shadcn/ui)
   f. Existing font imports and usage (check `src/app/layout.tsx` or equivalent for `next/font` imports)
   g. Animation/transition patterns already in use

   **Output**: A "Design System Summary" documenting: color tokens, spacing scale, typography scale, shadow tokens, border-radius tokens, animation patterns, font families, and any theme variants (dark mode). If tokens are scattered across multiple files, consolidate them into a single summary for teammate reference.

3. **Establish validation baseline**: Run `bun run typecheck`, `bun run lint`, and `bun run test`. Save results — all fixes must maintain or improve this baseline.

4. **Start the application**:
   - Check if the dev server is already running (from a previous 6V/6R session) by sending a HEAD request to the base URL
   - If NOT running, start it:
     ~~~bash
     bun run dev &
     ~~~
   - **BaaS dev server caveat**: If the project uses a BaaS (Convex, Supabase, Firebase), its dev server often requires an interactive terminal. If `bun run dev` fails:
     a. Check if the BaaS backend is already deployed (dev or staging instance)
     b. Set the client-exposed backend URL env var(s) manually in `.env.local` — the exact variable name depends on your tech stack (read `plancasting/tech-stack.md`, e.g., `NEXT_PUBLIC_CONVEX_URL`, `VITE_SUPABASE_URL`, `NEXT_PUBLIC_FIREBASE_*`)
     c. Run only the frontend dev server (e.g., `bun run dev:next` instead of `bun run dev`)
   - Wait up to 60 seconds for the server to be accessible
   - If the server fails to start, ABORT the stage

5. **Screenshot all key screens at 3 breakpoints**:
   Focus on the 10-15 most user-facing screens. For larger applications, prioritize screens listed in `./plancasting/prd/08-screen-specifications.md`.
   Use the Playwright browser tools (MCP) to capture screenshots. The process is:

   a. **Public pages first (no auth)**:
      - Use `browser_navigate` to visit each public route
      - Use `browser_resize` to set viewport width (1440, 768, 375)
      - Use `browser_take_screenshot` to capture at each breakpoint
      - Save to `./screenshots/visual-polish/before/[screen-name]-[breakpoint].png`

   b. **Authenticated pages (requires login)**:
      - Read `./e2e/constants.ts` for test user credentials
      - Use `browser_navigate` to go to the login page
      - Use `browser_fill_form` or `browser_click`/`browser_type` to log in with a test user (use a basic or standard-tier account from `e2e/constants.ts`)
      - After successful login, navigate to each authenticated route
      - Use `browser_resize` + `browser_take_screenshot` at each breakpoint (1440, 768, 375)

   c. **Dark mode** (if project supports it — check for `dark:` Tailwind classes or theme toggle):
      - Toggle dark mode via the app's theme switcher (use `browser_click`) or inject via `browser_evaluate`:
        ~~~javascript
        document.documentElement.classList.add('dark')
        ~~~
      - Re-screenshot key screens with `-dark` suffix

   d. **Reuse 6V screenshots if available**: If Stage 6V screenshots exist in `./screenshots/` and are recent (check `./plancasting/_audits/visual-verification/last-verified-commit.txt` against current HEAD), reuse them as the "before" set instead of re-capturing. Only re-capture if 6R made code changes that affect visual output.

   For each screen identified in `prd/08-screen-specifications.md`:
   - **Desktop** (1440px width)
   - **Tablet** (768px width)
   - **Mobile** (375px width)

6. **AI Vision Analysis**:
   For each screenshot, analyze using your vision capabilities:

   **Objective checks** (Category O):
   - Any text that is invisible or near-invisible against its background?
   - Any layout overflow (horizontal scrollbar, clipped content)?
   - Any elements overlapping incorrectly (z-index issues)?
   - Any broken images or missing icons?
   - Any interactive elements without visible focus indicators?
   - Any dark mode sections with unstyled white backgrounds?
   - Any touch targets that appear too small on mobile?

   **Enhancement checks** (Category E):
   - Do buttons have hover/press states with transitions?
   - Is there visual hierarchy (headings clearly distinct from body text)?
   - Are spacing gaps consistent across similar sections?
   - Do empty states have meaningful visual content (not just gray text)?
   - Are loading skeletons proportional to the content they replace?
   - Do cards/containers have appropriate depth (shadow, border)?
   - Are form inputs styled consistently across pages?

   **Elevation checks** (Category D):
   - Does the typography feel distinctive or generic?
   - Does the color palette feel cohesive and intentional?
   - Are there opportunities for high-impact motion (hero animations, scroll reveals)?
   - Does the overall aesthetic have a clear point of view?
   - Which screens would benefit most from visual elevation?

7. **Create the Visual Polish Plan** at `./plancasting/_audits/visual-polish/plan.md`:
   ~~~markdown
   # Stage 6P Visual Polish Plan

   ## Design System Summary
   - Color tokens: [list]
   - Typography scale: [list]
   - Spacing scale: [list]
   - Animation patterns: [list]
   - Font families: [current fonts]
   - Theme: [light / dark / both]
   - UI Library: [name + version]

   ## Existing Aesthetic Direction
   [From tech-stack.md Stage 0 design direction]

   ## Triage Summary
   - Category O (objective defects): [n] issues
   - Category E (enhancements): [n] issues
   - Category D (design elevation): [n] suggestions

   ## Category O Issues — Auto-Fix Queue
   | # | Screen | Breakpoint | Issue | Fix | File |
   |---|--------|-----------|-------|-----|------|
   | 1 | Dashboard | Mobile | Text "#94a3b8" on "#f1f5f9" bg — contrast 2.1:1 | Change text to "#475569" | src/app/(dashboard)/... |

   ## Category E Issues — Enhancement Queue
   | # | Screen | Issue | Pattern Source | Fix |
   |---|--------|-------|---------------|-----|
   | 1 | All buttons | No hover transition | Button.tsx has `hover:bg-*` but no `transition` | Add `transition-colors duration-150` |

   ## Category D Suggestions — Design Review
   | # | Area | Suggestion | Impact | Mockup |
   |---|------|-----------|--------|--------|
   | 1 | Typography | Replace system font stack with [distinctive pair] | High — affects entire app feel | See screenshot annotation |
   ~~~

8. **Invoke the `frontend-design` skill for enhancement guidance**:
   Before spawning teammates, the lead must invoke the `frontend-design` skill (if available — see Prerequisites step 1 for fallback behavior) to generate design guidance that Teammate 2 will follow. This is necessary because the skill is a slash command (`/frontend-design`) that works in the lead's session but may not be invocable by spawned teammates.

   Invoke `/frontend-design` with this prompt:
   > "Given a [product type] application using [UI library] with [design direction from tech-stack.md], provide specific enhancement guidelines for: (1) hover/press state transitions, (2) page entry animations, (3) spacing rhythm, (4) empty state design, (5) card/container depth, (6) typography hierarchy. Work within the existing design system tokens: [paste Design System Summary]. Output concrete CSS patterns for each category using the project's CSS framework (from tech-stack.md — e.g., Tailwind utilities, CSS Modules, styled-components)."

   (If the frontend-design plugin is unavailable per Prerequisites step 1, skip this invocation and use the design direction from `src/styles/design-tokens.ts` directly.)

   Save the skill's output as `./plancasting/_audits/visual-polish/design-guidelines.md`. This file becomes the primary reference for Teammate 2.

9. **Assign teammates and prevent file conflicts**:
   Group Category O and Category E issues by file. If a file has BOTH Category O fixes and Category E enhancements, assign ALL changes to that file to ONE teammate (prefer Teammate 1 for files with contrast/layout defects, Teammate 2 for files with only enhancement needs). NO two teammates may modify the same file.

   Document the file assignments in `./plancasting/_audits/visual-polish/plan.md` (this becomes the source of truth for preventing conflicts):
   ~~~markdown
   ## File Assignments
   | File | Teammate | Issues |
   |------|----------|--------|
   | src/components/ui/Button.tsx | Teammate 2 | E-001, E-002 |
   | src/app/(dashboard)/page.tsx | Teammate 1 | O-003, O-005 |
   ~~~
   Teammates must read this section before modifying any file to verify ownership.

### Phase 2: Teammates

Spawn Teammates 1 and 2 in **parallel** (they modify different files — O fixes vs E enhancements, with no file overlap). Teammate 3 runs **sequentially AFTER** Teammates 1 and 2 complete (it verifies their changes).

#### Teammate 1: "objective-defect-fixer"
**Scope**: ALL Category O issues from the plan.

~~~
You are fixing objective visual defects (Category O) found during the Stage 6P visual audit.

Check `./plancasting/tech-stack.md` for the `Session Language` setting. Code remains in English; any report messages or documentation updates should follow the session language.

Read CLAUDE.md first. Then read ./plancasting/_audits/visual-polish/plan.md for your assigned issues.

Your approach: Fix each Category O issue using the project's design tokens and patterns.

Rules:
- Use ONLY existing design system tokens (do not invent new colors, spacing values, or shadows). **Exception**: 6P may modify `design-tokens.ts` ONLY for: (a) adding a missing size to an existing scale (e.g., `shadow-md` between `shadow-sm` and `shadow-lg`), (b) correcting a token value to meet WCAG AA contrast (≥4.5:1 for text), or (c) fixing a broken variable reference. Do not change design direction or aesthetic intent — only fill technical gaps in the scale. Document any token changes in the report.
- For contrast fixes, prefer adjusting the text color over the background (less visual disruption)
- For responsive fixes, use the project's breakpoint utilities (e.g., `md:`, `lg:` in Tailwind)
- For dark mode fixes, use the project's dark mode pattern (e.g., `dark:` prefix in Tailwind)
- never change functional behavior — this teammate only changes visual presentation
- For authenticated pages, log in before taking screenshots: use `browser_navigate` to go to the login page, then `browser_fill_form` or `browser_type`/`browser_click` to enter the test user's email and password from `./e2e/constants.ts`. Verify login succeeded (check for redirect to dashboard or authenticated UI) before proceeding.
- After fixing each issue, verify visually: use `browser_navigate` to go to the affected page, `browser_resize` to the relevant breakpoint, `browser_take_screenshot` to capture a PNG (save to `./screenshots/visual-polish/after/[issue-id].png`). Use `browser_console_messages` to check for JavaScript errors. For DOM inspection (checking if a CSS class applied), use `browser_snapshot` to inspect the accessibility tree.
- Run `bun run typecheck` and `bun run lint` after each batch of fixes

When done, message the lead with: issues fixed, files modified, any issues that could not be fixed (with reason).
~~~

#### Teammate 2: "enhancement-applier"
**Scope**: ALL Category E issues from the plan.

~~~
You are applying visual enhancements (Category E) guided by the frontend-design skill output.

Check `./plancasting/tech-stack.md` for the `Session Language` setting. Code remains in English; any report messages or documentation updates should follow the session language.

Read CLAUDE.md first. Then read ./plancasting/_audits/visual-polish/design-guidelines.md — this contains the `frontend-design` skill's output with concrete CSS/Tailwind patterns for each enhancement category. Follow these patterns exactly. If design-guidelines.md does not exist (frontend-design plugin was unavailable), read `plancasting/tech-stack.md` design direction and `src/styles/design-tokens.ts` (or equivalent) instead — use the project's existing design patterns for all enhancement decisions. Then read ./plancasting/_audits/visual-polish/plan.md for your assigned issues.

Rules:
- If the design guidelines suggest approaches that conflict with the existing design system tokens, adapt the intent to the system's tokens (e.g., if guidelines suggest "dramatic shadows" but design system has `shadow-sm`/`shadow-md`/`shadow-lg`, use `shadow-lg` not a custom box-shadow)
- Group similar enhancements (e.g., apply hover transitions to ALL buttons at once, not one by one)
- For motion/animation:
  - If the project uses a motion library (Framer Motion, Motion, etc.), use it
  - Otherwise, prefer CSS-only transitions and animations
  - Focus on HIGH-IMPACT moments: page entry reveals, hero animations, card hover lifts
  - Do not add animation to every element — restraint is elegance
- For typography hierarchy: work within the existing type scale, adjusting weights and sizes but not font families (font changes are Category D)
- After applying each enhancement category, use the Playwright browser tools (`browser_navigate`, `browser_resize`, `browser_take_screenshot`) to capture before/after screenshots. Use `browser_console_messages` to check for JavaScript errors. Log in with the test user from `./e2e/constants.ts` if screenshots require authentication.
- Run `bun run typecheck` and `bun run lint` after each batch

When done, message the lead with: enhancements applied, files modified, any enhancements skipped (with reason).
~~~

#### Teammate 3: "responsive-cross-theme-verifier"
**Scope**: Re-verify ALL screens modified by Teammates 1 and 2 at all 3 breakpoints + dark mode.

~~~
You are verifying that all visual polish changes from Teammates 1 and 2 work correctly at all breakpoints and in dark mode.

Check `./plancasting/tech-stack.md` for the `Session Language` setting. Code remains in English; any report messages or documentation updates should follow the session language.

Read CLAUDE.md first. Then read ./plancasting/_audits/visual-polish/plan.md to understand what was changed.

Use Playwright browser tools to take fresh screenshots at all breakpoints and verify:
- All Category O fixes are visually confirmed (contrast, layout, overflow)
- All Category E enhancements work at all breakpoints (hover states degrade gracefully on mobile, animations don't break layout)
- Dark mode variants are consistent (if project supports dark mode)
- No regressions introduced (compare with pre-polish screenshots in ./screenshots/visual-polish/before/)

Rules:
- If a fix or enhancement causes a regression at a different breakpoint, flag it immediately (do not attempt to fix — return to lead)
- Use Playwright browser tools to capture comparison screenshots: `browser_navigate` to each modified page, `browser_resize` to each breakpoint (1440, 768, 375), `browser_take_screenshot`. Save to `./screenshots/visual-polish/after/`. Log in with the test user from `./e2e/constants.ts` for authenticated pages.
- Test mobile touch interactions (tap states, swipe gestures if applicable)
- Verify page load performance hasn't degraded (animations shouldn't delay FCP)

When done, message the lead with: screens verified, regressions found (if any), comparison screenshot locations.
~~~

### Phase 3: Integration & Report

After all teammates complete:

1. **Collect teammate results**:
   Read each teammate's output. Check for:
   - Any regressions flagged by Teammate 3
   - Any Category E enhancements that Teammate 3 found problematic

2. **Fix regressions**:
   A **regression** is a NEGATIVE SIDE EFFECT introduced by a polish fix: visual breakage of unrelated elements, functional breakage (button no longer works), accessibility breakage (new contrast failure), or performance degradation. Intentional enhancements (e.g., increased padding for touch targets) are not regressions.

   If Teammate 3 flagged regressions:
   - Revert the specific change that caused the regression
   - Re-apply with a responsive-safe approach
   - Re-verify at the failing breakpoint
   - **Max iteration guard**: If regressions persist after 2 revert-and-reapply cycles for the same issue, document it as a known limitation in the report rather than continuing. Persistent regressions usually indicate a CSS specificity conflict or component library constraint that requires a different approach.

3. **Run full validation**:
   ~~~bash
   bun run typecheck
   bun run lint
   bun run test
   bun run test:e2e
   ~~~
   ALL must pass. Visual changes can break E2E test selectors — if any fail, fix the issue or revert the change that caused it.

4. **Generate Category D design brief**:
   ⚠️ **Category D is for HUMAN REVIEW ONLY**: Do not implement Category D suggestions in this stage. Generate the brief for the operator to review post-launch. If the frontend-design skill was unavailable (per Prerequisites), the design elevation brief was not generated. Note in the Phase 3 report: 'Category D design elevation brief not generated (frontend-design skill unavailable).' and skip the Category D appendix reference.
   For Category D suggestions, the LEAD (not a teammate) creates a design brief using the `frontend-design` skill:
   - Invoke `/frontend-design` with this prompt:
     > "You are reviewing a [product type] application. Based on these Category D observations: [paste Category D items from the plan]. The current design direction is [from tech-stack.md]. The current design system uses: [Design System Summary]. Suggest 3 distinctive aesthetic directions that would elevate this product. For each: name it, describe the tone, list specific visual changes (typography, color, motion, layout), identify which screens/files would change, and estimate effort (hours)."
   - Save the skill's output as `./plancasting/_audits/visual-polish/design-elevation-brief.md`

   This brief is for HUMAN REVIEW — the agent does not apply Category D changes.

5. **Generate the Visual Polish Report** at `./plancasting/_audits/visual-polish/report.md`:

   ~~~markdown
   # Stage 6P Visual Polish Report

   ## Summary
   - **Date**: [date]
   - **Commit**: [git hash before polish]
   - **Design System**: [UI library + version]
   - **Aesthetic Direction**: [from tech-stack.md]

   ## Results
   - Category O (objective defects): [n] found, [n] fixed, [n] could not fix
   - Category E (enhancements): [n] found, [n] applied, [n] skipped (incompatible)
   - Category D (design elevation): [n] suggestions documented
   - Regressions found during verification: [n] (all resolved / [n] remaining)

   ## Category O Fixes Applied
   | # | Screen | Issue | Fix | Before | After | Status |
   |---|--------|-------|-----|--------|-------|--------|
   | 1 | Dashboard | Low contrast text | Changed #94a3b8 → #475569 | [screenshot] | [screenshot] | ✅ Fixed |

   ## Category E Enhancements Applied
   | # | Area | Enhancement | Approach | Before | After | Status |
   |---|------|------------|---------|--------|-------|--------|
   | 1 | Buttons | Added hover transitions | `transition-colors duration-150` on all Button variants | [screenshot] | [screenshot] | ✅ Applied |

   ## Category D Design Elevation Brief
   See `./plancasting/_audits/visual-polish/design-elevation-brief.md` for 3 suggested aesthetic directions.

   ### Top 3 Suggestions (Summary)
   1. [Direction name]: [1-line description] — [effort estimate]
   2. [Direction name]: [1-line description] — [effort estimate]
   3. [Direction name]: [1-line description] — [effort estimate]

   ## Responsive Verification
   | Screen | Desktop (1440) | Tablet (768) | Mobile (375) | Dark Mode |
   |--------|---------------|-------------|-------------|-----------|
   | Dashboard | ✅ | ✅ | ✅ | ✅ |
   | ... | ... | ... | ... | ... |

   ## Files Modified
   [List of all files changed with brief description of change]

   ## Validation
   - TypeScript: ✅ PASS / ❌ FAIL
   - ESLint: ✅ PASS / ❌ FAIL
   - Tests: ✅ PASS ([n] passed, [n] failed)

   ## Gate Decision
   - **PASS**: All Category O fixed, Category E enhancements applied where feasible (E is discretionary — skip if an enhancement conflicts with the design system, has negligible visual impact, or risks regression), no regressions → ready for Deploy
   - **CONDITIONAL PASS**: All critical O fixed, some E enhancements deferred (documented with rationale) + Category D brief for optional elevation → ready for Deploy, consider design review
   - **FAIL**: Regressions remain, critical Category O defects unresolved, or validation fails → investigate before Deploy

   ## Next Steps
   - If PASS or CONDITIONAL PASS: proceed to Stage 7 (Deploy) → Stage 7V (Production Smoke) → Stage 7D (User Guide)
   - If FAIL: regressions detected — investigate root cause, fix, and revalidate. Do not deploy until 6P PASS or CONDITIONAL PASS
   ~~~

6. **Save comparison screenshots**:
   - `./screenshots/visual-polish/before/` — pre-polish state
   - `./screenshots/visual-polish/after/` — post-polish state
   Both at all 3 breakpoints + dark mode (if applicable).

   Note: Screenshot directories (`./screenshots/`) are for local reference. Add to `.gitignore` — do not commit large binary files.

### Session Recovery
If the session disconnects mid-execution: start a new session, re-paste this prompt. The lead reads the existing report at `./plancasting/_audits/visual-polish/report.md` and the progress tracker to determine which teammates have completed. Resume from the first incomplete teammate.

### Phase 4: Shutdown

1. **Commit all visual polish changes**:
   Stage modified files for commit using targeted `git add` (e.g., `git add src/ plancasting/_audits/visual-polish/` — adapt paths to your project). Avoid `git add -A` which may capture unwanted files (screenshots, temp files).
   ~~~bash
   git add src/ plancasting/_audits/visual-polish/ && git commit -m "style(6p): Stage 6P visual polish — [n] defects fixed, [n] enhancements applied"
   ~~~
2. **Save the polish commit hash**:
   ~~~bash
   git rev-parse HEAD > ./plancasting/_audits/visual-polish/last-polished-commit.txt
   ~~~
3. Request shutdown for all teammates.
4. Stop the dev server if it was started by this stage (check if it was already running from a prior session — if so, leave it running).

## Critical Rules

1. **never change functional behavior.** This stage changes ONLY visual presentation. If a fix would alter routing, data flow, API calls, auth, or form submission logic, it is OUT OF SCOPE — flag it and move on.

2. **never replace design system components with custom implementations.** Work within the existing UI library's API. If a component doesn't support the enhancement you want, use CSS overrides or wrapper components, not replacements.

3. **never introduce new fonts without human approval.** Font changes are Category D (design elevation). Document the suggestion but do not apply it.

4. **never introduce new dependencies without checking `package.json`.** If an animation library isn't already installed, use CSS-only animations. Do not add Motion, GSAP, or other libraries without checking if they're already in the project.

5. **always take before/after screenshots.** Every change must be visually documented. If you can't screenshot it, you can't verify it.

6. **always run validation (typecheck + lint + test) after fixes.** A visual improvement that breaks the build is worse than no improvement.

7. **always work at all 3 breakpoints.** A fix that looks great at desktop but breaks mobile is a regression, not an improvement.

8. **Teammate 3 scope management**: Teammate 3 focuses on HIGHEST-IMPACT screens first, in this priority order: (1) landing/home page, (2) dashboard, (3) primary feature page (the core product screen), (4) auth pages (login/signup), (5) settings/billing pages. Verify each at all 3 breakpoints + dark mode before moving to the next. If time permits after the top 5, continue to lower-impact screens. Mark any unverified screens in the report with "SPOT-CHECK ONLY" status. Target: verify at minimum the top 5 screens within 30 minutes.

9. **always respect the project's dark mode pattern.** If the project uses `dark:` Tailwind classes, every color change must include the dark mode variant. If the project doesn't support dark mode, don't add it.

10. **Category O before Category E.** Fix objective defects first, then apply enhancements. Never polish what's broken.

11. **The `frontend-design` skill guides INTENT, not implementation.** When the skill says "dramatic shadows," translate that to your design system's shadow tokens. When it says "unexpected layout," interpret within your grid system. The skill's aesthetic vision + your design system's vocabulary = the implementation.

12. **Maximum 3 animation additions per page.** Restraint creates elegance. Do not animate every element — choose the 1-3 highest-impact moments per page (hero reveal, card entry, hover lift).

13. **AVOID modifying shared UI primitive components directly** (e.g., `src/components/ui/` or your framework's equivalent) unless fixing a Category O defect or applying a global Category E enhancement. Prefer page-level or layout-level overrides for page-specific changes.

14. **If the 6R report exists and shows FAIL, STOP.** This stage requires all functional issues to be resolved. If 6R has unresolved critical issues, return to 6R first. If 6V passed (no 6R run needed), or if 6V found only 6V-C issues (6R skipped), proceed normally — check for the 6R report's existence before reading its gate.

15. **Treat contrast ratios as non-negotiable.** WCAG AA (4.5:1 for normal text, 3:1 for large text) is the MINIMUM. If in doubt, use a higher contrast option.

16. **always preserve accessibility.** Focus rings, aria labels, semantic HTML, keyboard navigation — if an enhancement would compromise any of these, skip it.

17. **The lead invokes `/frontend-design`, teammates read the output.** The lead invokes `/frontend-design` twice: once in Phase 1 Step 8 (enhancement guidelines) and once in Phase 3 Step 4 (design elevation brief). Teammates read the saved output — they do not invoke the skill themselves.

18. **Teammates 1 and 2 run in parallel, Teammate 3 runs AFTER both complete.** Teammate 3 verifies changes from 1 and 2 — it cannot run concurrently. The lead must wait for Teammates 1 and 2 to finish before spawning Teammate 3.

19. **ALL Playwright browser interactions require the dev server to be running.** If the dev server crashes during the stage, the lead must restart it. Teammates should message the lead — do not attempt to start the server from a teammate session. Verify accessibility with a HEAD request before each teammate's work begins.

20. **Test user login is required for authenticated page screenshots.** Read `./e2e/constants.ts` for credentials. Use `browser_navigate` to the login page, `browser_fill_form` or `browser_type`/`browser_click` to authenticate. Verify login succeeded (check for redirect to dashboard or authenticated indicator) before proceeding with screenshots.

21. **always check for console errors during screenshots.** After each `browser_take_screenshot`, use `browser_console_messages` to check for JavaScript errors. A page that looks correct visually but has console errors may have runtime issues that affect subsequent interactions. Log any errors in the report.

22. **Ensure NO two teammates modify the same file.** The lead must assign files to teammates in Phase 1 Step 9. If a file needs both Category O and Category E changes, assign all changes for that file to ONE teammate.
````
