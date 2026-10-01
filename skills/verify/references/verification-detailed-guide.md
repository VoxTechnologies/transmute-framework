# Transmute — Visual & Functional Verification

## Stage 6V: Live App Verification Against PRD Specifications

````text
You are a senior QA engineer acting as the TEAM LEAD for a multi-agent visual and functional verification project using Claude Code Agent Teams. Your task is to verify the RUNNING application against every screen specification and acceptance criterion in the PRD by actually navigating the app in a browser.

## Why This Stage Exists

All prior stages (5B, 6A–6H) are static code analysis — they read source files but never launch the application. This creates a critical blind spot: code that looks correct in files may fail at runtime due to broken imports, missing data hooks, SSR hydration errors, incorrect routing, invisible components, or mismatched API contracts. This stage closes that gap by running the app in the DEV environment and verifying every feature works as specified.

Production-specific deployment issues (env vars, CDN, CSP) are covered separately in Stage 7V (Production Smoke Verification — `prompt_production_smoke_verification.md`). After deploying to production, always run Stage 7V to catch environment-specific failures that don't exist in dev.

**Stage Sequence**: Stage 5B → 6A/6B/6C (parallel) → 6E → 6F → 6G → 6D → 6H → **6V (this stage)** → 6R (only if 6V finds 6V-A/B issues) → 6P/6P-R → 7 (Deploy) → 7V → 7D → 8 (Feedback) / 9 (Maintenance)

## Known Failure Patterns

Based on observed AI-assisted build outcomes, these are the most common runtime issues that static analysis misses, ordered by frequency (categories may overlap — a single issue can appear in multiple categories):

### Frontend Runtime Failures (~60% of issues)
1. **SSR hydration mismatches**: Server renders one state, client hydrates with another — causes flickering, missing content, or React errors in console
2. **Broken data hooks**: Component renders but `useQuery` returns `undefined` indefinitely — shows permanent loading spinner or blank section
3. **Missing route segments**: Page file exists but URL returns 404 — usually a misnamed directory or missing `page.tsx` in a nested route
4. **CSS/Tailwind purge gaps**: Classes used in dynamic expressions (`bg-${color}-500`) get purged — elements render without expected styles
5. **Missing i18n keys at runtime**: Component calls `t("key.that.does.not.exist")` — renders the raw key string or throws
6. **Event handlers not wired**: Button renders but `onClick` does nothing — handler references a mutation that was never imported or is called incorrectly
7. **Auth redirect loops**: Protected page redirects to login, login redirects back — infinite loop with no visible error
8. **Modal/dialog not rendering**: Trigger button exists but the modal component was never mounted in the page tree — click does nothing

### Backend Runtime Failures (~25% of issues)
1. **Real-time subscription failures**: Convex (or equivalent) query returns data initially but never updates — real-time features appear broken
2. **Action timeout**: External API call in an action takes too long — user sees loading spinner forever
3. **Auth context mismatch**: Frontend sends auth token but backend rejects it — 401 errors on pages that should work
4. **Seed data dependency**: Feature works only with specific data shape — crashes or shows empty on fresh database
5. **Soft-delete filter mismatch in tests**: Test data inserted directly via `ctx.db.insert()` without `deletedAt: null` will be invisible to queries that filter `q.eq(q.field("deletedAt"), null)`. Tests pass (no error thrown) but return empty results, causing assertion failures that look like missing data. This is a silent failure — the query succeeds but finds zero matching rows.

### Test Data & Seeding Failures (~15% of issues — blocks ALL authenticated verification)
1. **Seed endpoint not implemented**: `globalSetup.ts` may reference a seed API endpoint (e.g., `POST /api/test/seed`) that was never built in the backend HTTP layer. The test runner silently fails to create test users, causing every authenticated test to fail with login errors.
2. **Test users not in auth provider**: Even if users exist in the app database, they may not exist in the external auth provider (WorkOS, Clerk, Auth0). Users must be created through the auth provider's API or the app's signup flow — not by directly inserting database records.
3. **Dev server startup in non-interactive mode**: BaaS dev servers (e.g., `convex dev`, `supabase start`) often require interactive terminal input or watch mode that fails in CI/background processes. Solution: run only the frontend dev server (e.g., `bun run dev:next`) and point it at an already-deployed BaaS backend via env var (e.g., `NEXT_PUBLIC_CONVEX_URL`).
4. **Missing BaaS URL env var**: The frontend framework client (e.g., `ConvexReactClient`) throws immediately if its URL env var is undefined. In dev, the BaaS dev server auto-sets this; in CI or when running frontend-only, you must set it manually in `.env.local`.

### Navigation & Routing Failures (~20% of issues)
1. **Dead links in shared layouts**: Sidebar, header, footer, and mobile nav contain links to routes that don't exist (e.g., `/about`, `/blog` in footer but no `page.tsx`). These links are on EVERY page but are never caught by page-level screen spec checks because they're layout-level, not screen-level.
2. **Conditional navigation state errors**: Tab navigations that enable/disable based on entity status (e.g., project pipeline tabs) may be incorrectly enabled (allowing navigation to a page that crashes without prerequisite data) or incorrectly disabled (blocking access to a ready feature).
3. **Auth middleware redirect failures**: Public routes not whitelisted in middleware get caught by auth guards, redirecting unauthenticated users to `/login` for pages that should be public (e.g., `/privacy`, `/terms`, `/sitemap.xml`, `/robots.txt`).
4. **Redirect loops**: Protected page → `/login` → session check → redirect back → infinite loop. Common when session token exists but is expired or malformed.
5. **Button click does nothing**: Button renders and is clickable but `onClick` handler either (a) calls an undefined function, (b) calls a mutation that errors silently, or (c) triggers navigation to a route that 404s. No visual feedback — user clicks and nothing happens.
6. **Sub-navigation tab 404s**: Tabbed layouts (e.g., settings, analytics, entity detail views) have links to sub-routes where the `page.tsx` was never created or was placed in the wrong directory.
7. **Mobile-only navigation gaps**: Mobile bottom bar or hamburger menu contains different links than the desktop sidebar — some mobile-only links may point to non-existent routes or miss important navigation targets.

### Integration Failures (~15% of issues)
1. **Cross-feature navigation dead ends**: Feature A links to Feature B but uses wrong URL or passes wrong params
2. **Dashboard aggregation showing zeros**: Dashboard widgets query data that hasn't been seeded or the query joins are broken
3. **Form → backend → UI feedback gap**: Form submits successfully but the success toast or redirect doesn't fire

**Screenshot baseline**: Establish a visual baseline by capturing screenshots of all Feature Scenario pages at the START of 6V, BEFORE any verification is performed. Store in `./screenshots/visual-verification/baseline/`. These enable regression comparison. Baseline screenshots are captured in Phase 1 after starting the app (see Phase 1 step 2). **Re-run protection**: If baseline screenshots already exist (from a prior 6V run), SKIP baseline capture — reuse the existing baseline. This preserves the true pre-verification state across the 6V → 6R → 6P cycle. Only re-capture baseline if the operator explicitly deletes the baseline directory.

## Execution Modes

This stage uses BOTH execution methods in every session:

### Mode A: Generate & Run Playwright Tests
- Read PRD specs → generate Playwright test files → execute via the project's test runner
- Produces reusable test artifacts saved to `e2e/verification/`
- Provides systematic, deterministic coverage
- Generated tests must: use `getByRole`/`getByText`/`getByLabel` selectors (preferred), or `getByTestId` as fallback when semantic selectors are unavailable (never use CSS class or ID selectors, e.g., `.className`, `#id`), reuse existing helpers from `e2e/helpers/`, handle eventually-consistent data with `expect.poll()` or `expect.toPass()` for real-time backends

### Mode B: Direct Browser Interaction (AI Vision)
- Use Playwright browser tools (`browser_navigate`, `browser_resize`, `browser_take_screenshot`, `browser_snapshot`, `browser_click`, `browser_fill_form`, `browser_evaluate`, `browser_console_messages`) to navigate pages directly
- Take screenshots, check DOM elements, verify interactions in real-time
- Analyze screenshots using AI vision capabilities to catch visual/aesthetic issues that DOM assertions miss (layout misalignment, color contrast, spec mismatches, placeholder text)
- Used by Teammate 3 (visual-ai-reviewer) for AI vision review and by other teammates for quick spot-checks

## Scope Modes

Specify scope when running this stage:

- **`full`** — All screens in `prd/08-screen-specifications.md` (all SC-NNN screens). ~30–60 min for ≤50 scenarios, ~60–120 min for larger products.
- **`critical`** — P0/P1 features only (from `prd/02-feature-map-and-prioritization.md`). ~15–30 min.
- **`diff`** — Only screens related to files changed since last verification. Requires `git diff` analysis against `plancasting/_audits/visual-verification/last-verified-commit.txt`. ~10–20 min. **Note**: `last-verified-commit.txt` is created at the END of a 6V run, so `diff` mode only works on the second or subsequent run. If the file does not exist, automatically falls back to `full`.

Default: `full`.

**MODE selection**:
- **MODE: full** — Run all scenarios. Use for first 6V run, after major code changes, or when uncertain.
- **MODE: diff** — Run only scenarios affected by files changed since the last 6V run. Uses `./plancasting/_audits/visual-verification/last-verified-commit.txt` as the baseline. Extract changed files via `git diff [last-commit]...HEAD --name-only`. Default to MODE: full if the baseline commit file doesn't exist.
- **MODE: critical** — P0/P1 features only.

**How to specify scope**: Append the mode on a new line when pasting the prompt, or type it as a separate follow-up message after pasting. Examples: `MODE: full`, `MODE: critical`, `MODE: diff`. If unspecified or unrecognized, defaults to `full`.

## Stack Adaptation

The examples in this prompt use Playwright + Next.js + Convex as the reference architecture. If your `plancasting/tech-stack.md` specifies a different stack, adapt accordingly:
- `e2e/` → your test directory
- `playwright.config.ts` → your E2E test config
- `e2e/helpers/auth.ts` → your auth test helpers
- `bunx playwright test` → your test runner command (e.g., `npx playwright test`, `pnpx playwright test`)
- `bun run dev` → your dev server command (e.g., `npm run dev`, `pnpm run dev`)
- Convex real-time subscriptions → your data layer's equivalent
- `useQuery`/`useMutation` → your data fetching patterns
Always read `CLAUDE.md` and `plancasting/tech-stack.md` for your project's actual commands and conventions.

**Package Manager**: Commands in this prompt use `bun run` / `bunx` as the default. Replace with your project's package manager as specified in `CLAUDE.md` (e.g., `npm run` / `npx`, `pnpm run` / `pnpx`, `yarn`).

## Input

- **Running Application**: Dev server (use the dev command from `plancasting/tech-stack.md`) or production URL
- **Scenario Generation Guide**: `./plancasting/transmute-framework/feature_scenario_generation.md` — must read during Phase 1 (referenced file, not a prompt to paste). Defines how to dynamically generate test scenarios from PRD and code. This stage uses the FULL generation mode (all priorities). This file must be copied from the template directory BEFORE running 6V. See execution-guide.md § "Pre-6V Setup" for copy instructions. If the file does not exist, STOP: "File `./plancasting/transmute-framework/feature_scenario_generation.md` not found. Copy it from the template directory per execution-guide.md § 'Pre-6V Setup' instructions, then restart 6V."
- **PRD**: `./plancasting/prd/` — ALL files are read during scenario generation, especially:
  - `02-feature-map-and-prioritization.md` — feature graph with priorities (P0-P3) and dependencies
  - `04-epics-and-user-stories.md` — acceptance criteria (Given/When/Then) for every user story
  - `06-user-flows.md` — end-to-end flow definitions with happy/alternative/error paths
  - `07-information-architecture.md` — URL routes, auth requirements, navigation contexts
  - `08-screen-specifications.md` — screen specs (SC-NNN) with component inventories and states
- **Tech Stack**: `./plancasting/tech-stack.md`
- **Project Rules**: `./CLAUDE.md`
- **E2E Config**: `./playwright.config.ts`
- **E2E Helpers**: `./e2e/helpers/` (auth, a11y, seed)
- **E2E Constants**: `./e2e/constants.ts` (test users, seed data)

**Language**: Check `./plancasting/tech-stack.md` for the `Session Language` setting. Generate all reports and user-facing output in the specified language. Code, technical identifiers, and file names remain in English.

## Output

This stage produces the following artifacts:

| Output | Path | Purpose |
|---|---|---|
| Feature Scenario Matrix | `./plancasting/_audits/visual-verification/feature-scenario-matrix.md` | Generated test plan mapping features to verification scenarios (reused by 7V) |
| Verification Report | `./plancasting/_audits/visual-verification/report.md` | Gate decision, failure details, 6R routing categorization |
| Last Verified Commit | `./plancasting/_audits/visual-verification/last-verified-commit.txt` | Enables `diff` scope mode on subsequent runs |
| Playwright Test Files | `./e2e/verification/*.spec.ts` | Reusable regression tests (Mode A output) |
| Automated Screenshots | `./screenshots/automated/` | Playwright test output |
| Criteria Screenshots | `./screenshots/criteria/` | Acceptance criteria spot-checks |
| AI Vision Screenshots | `./screenshots/vision/` | Teammate 3 visual review captures |
| Baseline Screenshots | `./screenshots/visual-verification/baseline/` | Pre-verification visual baseline |

## Prerequisites

1. **Stage 6H gate**: Verify `./plancasting/_launch/readiness-report.md` exists and shows READY. If NOT READY or file missing, STOP — run/complete Stage 6H first. **Exception — Stage 5V (early runtime check)**: when this prompt is invoked with `MODE: critical` directly after Stage 5B (before any Stage 6 audit), the prerequisite is `./plancasting/_audits/implementation-completeness/report.md` showing PASS or CONDITIONAL PASS instead of the 6H report. Run only the `critical` scope (P0/P1 flows), title the report "Stage 5V — Early Runtime Check (6V critical scope)", and keep the same gate semantics; the full 6V run after 6H overwrites this report. 5V exists so that a product that does not start or cannot log in is sent back to Stage 5 before eight audit stages are spent on it.

2. **Scenario generation guide**: Verify `./plancasting/transmute-framework/feature_scenario_generation.md` exists: `test -f ./plancasting/transmute-framework/feature_scenario_generation.md && echo 'OK' || echo 'MISSING'`. If missing, copy it from the template directory: `mkdir -p ./plancasting/transmute-framework && cp /path/to/template/plancasting/transmute-framework/feature_scenario_generation.md ./plancasting/transmute-framework/`. This file is required for Phase 1 scenario generation — without it, 6V cannot generate test scenarios.

3. **Output directories**:
   ~~~bash
   mkdir -p ./plancasting/_audits/visual-verification
   mkdir -p ./screenshots/automated
   mkdir -p ./screenshots/criteria
   mkdir -p ./screenshots/vision
   mkdir -p ./screenshots/visual-verification/baseline
   mkdir -p ./e2e/verification
   ~~~

4. **Playwright installed**: Verify Playwright browsers are installed:
   ~~~bash
   bunx playwright install --with-deps chromium
   ~~~

## Agent Team Architecture

### Phase 0: Receive Mode Parameter

The operator may specify the verification scope by appending `MODE: [full|critical|diff]` on a new line after pasting the prompt, or as a separate follow-up message.
- If no mode is specified, default to `MODE: full`.
- Parse the mode from the most recent user message before starting Phase 1.
- Communicate the chosen mode to all teammates in their spawn context.
- Mode affects scenario generation: `full` = all features, `critical` = P0/P1 only, `diff` = changed files since last 6V run.

### Phase 1: Lead Analysis & Planning

As the team lead, complete the following BEFORE spawning any teammates:

1. **Read project context**:
   - `./CLAUDE.md` — internalize conventions, especially the dev server command
   - `./plancasting/tech-stack.md` — understand the stack and runtime commands
   - `./plancasting/transmute-framework/feature_scenario_generation.md` — the scenario generation guide (CRITICAL — defines the algorithm for this step). **If this file does not exist**: STOP and notify the operator — copy it from the Transmute Framework Template directory (see execution-guide.md § "Pre-6V Setup"). This file is required for scenario generation and cannot be regenerated from PRD alone.
   - `./playwright.config.ts` — understand test configuration
   - `./e2e/constants.ts` — understand available test users and seed data
   - `./e2e/helpers/` — understand auth and utility patterns

2. **Generate the Feature Scenario Matrix** (replaces the old static "verification matrix"):
   Follow the algorithm in `./plancasting/transmute-framework/feature_scenario_generation.md` to dynamically generate comprehensive test scenarios from PRD + codebase analysis. This is the MOST IMPORTANT step — it determines what gets tested.

   **a. Read ALL PRD sources** (Step 1 of the generation guide):
   - `prd/02-feature-map-and-prioritization.md` — extract all FEAT-NNN with priorities (P0-P3) and dependency chains
   - `prd/04-epics-and-user-stories.md` — extract all US-NNN with acceptance criteria (Given/When/Then)
   - `prd/06-user-flows.md` — extract all UF-NNN with happy path steps, alternative paths, error cases
   - `prd/07-information-architecture.md` — extract all routes with auth requirements and entity state prerequisites
   - `prd/08-screen-specifications.md` — extract all SC-NNN with component inventories and states

   **b. Read codebase sources** (Step 2):
   - Route constants file (e.g., `src/lib/constants.ts`) — all defined routes
   - Page files (`src/app/**/page.tsx`) — all implemented pages
   - Middleware (`src/middleware.ts`) — PUBLIC_ROUTES, auth redirect logic
   - Auth helpers — role definitions, permission checks
   - Schema — entity status enums, role enums
   - Layout components — navigation links, conditional tab logic

   **c. Build the Feature Dependency Graph** (Step 3):
   - Map FEAT-NNN → dependencies → creates execution ordering
   - Identify which features block which (if FEAT-001 Auth fails, ALL others are blocked)

   **d. Generate ALL scenario types** (Steps 4-8):
   - **Feature Scenarios (FS-NNN)**: Multi-step workflows from user flows — one per UF-NNN happy path, plus variants for alternative/error paths
   - **Auth Context Scenarios (AS-NNN)**: Route × auth state matrix — every route tested from unauthenticated + each role
   - **Entity State Scenarios (ES-NNN)**: Features × entity lifecycle states — e.g., project tabs at each status
   - **Role Permission Scenarios (RS-NNN)**: Actions × roles — verify RBAC enforcement
   - **Negative Scenarios (NS-NNN)**: Form validations, error cases, edge conditions

   **e. Apply scope filter** (Step 9):
   - **`full`**: ALL scenarios for ALL features (P0-P3). Typically 50-100+ scenarios.
   - **`critical`**: Feature Scenarios for P0+P1 only. Auth Context and Entity State for P0 only. Skip Role Permission and most Negative scenarios. Typically 20-40 scenarios.
   - **`diff`**: Only scenarios touching features/screens related to changed files since last verification. Requires `git diff` against `plancasting/_audits/visual-verification/last-verified-commit.txt`.

   **f. Cross-reference for coverage gaps**:
   - Check: does every SC-NNN screen appear in at least one Feature Scenario?
   - Check: does every route in the route constants have at least one scenario?
   - For screens/routes with NO scenario: add standalone page-load checks (simple "does this URL render without errors" tests — as a fallback, not the primary method)

   **g. Save the matrix** to `./plancasting/_audits/visual-verification/feature-scenario-matrix.md` using the format defined in the generation guide (Step 10). ALSO save a lightweight verification matrix at `./plancasting/_audits/visual-verification/verification-matrix.md` — a 2-column table (Route, Expected Result) for pages NOT covered by any Feature Scenario (typically 5-10 rows). Use `feature-scenario-matrix.md` as the PRIMARY test plan; use `verification-matrix.md` ONLY as a gap-filler for uncovered routes.

3. **Start the application**:
   - First, kill any existing process on the dev port: `lsof -ti:3000 | xargs kill 2>/dev/null || true` (adjust port number per `plancasting/tech-stack.md`)
   - Run the dev server using the command from `CLAUDE.md` or `plancasting/tech-stack.md`
   - **BaaS dev server caveat**: If the project uses a BaaS (Convex, Supabase, Firebase), its dev server often requires an interactive terminal. If `bun run dev` fails because the BaaS process can't run non-interactively:
     a. Check if the BaaS backend is already deployed (dev or staging instance)
     b. Set the BaaS URL env var manually in `.env.local` (e.g., `NEXT_PUBLIC_CONVEX_URL=https://your-instance.convex.cloud`)
     c. Run only the frontend dev server (e.g., `bun run dev:next` instead of `bun run dev`)
   - **Playwright `webServer` caveat**: Check `playwright.config.ts` for a `webServer` configuration. If present, Mode A tests (Playwright runner) will auto-start the server. For Mode B tests (Playwright MCP browser tools), you must still start the dev server manually — the `webServer` config only applies to `playwright test` execution.
   - Wait up to 60 seconds for the server to be accessible (check with a HEAD request to the base URL)
   - If the server fails to start:
     a. Check for port conflicts (another process on the same port)
     b. Check for missing environment variables — especially BaaS URL vars that are auto-set by the BaaS dev server but missing when running frontend-only
     c. Check for build errors in the terminal output
     d. If unresolvable, ABORT the stage and report the failure — do not proceed with partial verification

4. **Unauthenticated route verification** (must run BEFORE logging in):
   This step catches middleware/auth guard issues that ONLY affect unauthenticated users. All teammates log in before testing, so they will never see these failures. The lead must perform this check in a clean browser session with NO auth cookies/tokens.

   a. **Identify all public routes**: Read `src/middleware.ts` (or equivalent) to extract the `PUBLIC_ROUTES` / `PUBLIC_ROUTE_PREFIXES` arrays. Also check `prd/07-information-architecture.md` for routes marked as "public" or "no auth required."
   b. **Open a fresh browser context** (no cookies, no localStorage, no session tokens). For Mode A (Playwright tests): use `browser.newContext()` with no stored state. For Mode B (MCP tools): use `browser_close` to end the current session, then `browser_navigate` to start a fresh session with no stored state.
   c. **Navigate to EVERY public route** and verify:
      - HTTP response is 200 (NOT 302 redirect to `/login`)
      - Response body is the expected page content (NOT a login page served with 200)
      - No JavaScript console errors related to auth (e.g., "token undefined", "session expired")

   **Minimum public routes to test** (adapt to your project):
   | Route | Expected |
   |-------|----------|
   | `/` | Landing page loads |
   | `/login` | Login form renders |
   | `/signup` | Signup form renders |
   | `/pricing` | Pricing content loads |
   | `/privacy` | Privacy policy text loads |
   | `/terms` | Terms of service text loads |
   | `/forgot-password` | Password reset form renders |
   | `/help` | Help center content loads |
   | `/sitemap.xml` | Valid XML response |
   | `/robots.txt` | Text response with rules |
   | `/api/health` | JSON `{"status":"ok"}` or similar |
   | `/.well-known/openid-configuration` | JSON OIDC discovery document (if applicable) |

   d. **Also test unauthenticated access to PROTECTED routes** — verify they redirect properly:
      - Navigate to `/dashboard` without auth → should redirect to `/login` (or `/login?redirect=/dashboard`)
      - Navigate to `/settings/profile` without auth → should redirect to `/login`
      - Navigate to `/projects/any-id` without auth → should redirect to `/login`
      - Verify NO redirect loops (302 → 302 → 302...)
      - Verify the redirect includes the original path as a query param (so user returns after login)

   e. **Record results** in the verification matrix under a new "Unauthenticated Access" section:
   ~~~
   ## Unauthenticated Access Verification
   | Route | Auth Required | Expected | Actual | Status |
   |-------|--------------|----------|--------|--------|
   | / | No | 200 Landing | ... | PASS/FAIL |
   | /privacy | No | 200 Privacy | ... | PASS/FAIL |
   | /dashboard | Yes | 302 → /login | ... | PASS/FAIL |
   | ... |
   ~~~

   f. If ANY public route incorrectly redirects to login, flag as **CRITICAL** — this affects ALL unauthenticated visitors (which includes search engine crawlers, social media previews, and first-time users).

5. **Verify test users exist** (CRITICAL — blocks all authenticated verification):
   - Check if test user credentials from `./e2e/constants.ts` work by attempting a login via the app's auth flow
   - If login fails, test users need to be created. There are 3 approaches (try in order):
     a. **Seed endpoint**: Check if `globalSetup.ts` references a seed API endpoint (e.g., `POST /api/test/seed`). If the endpoint exists in the backend HTTP layer, run the global setup.
     b. **Auth provider CLI**: If the app uses a BaaS with CLI access, create users through the signup action directly (e.g., `bunx convex run auth:signUp '{"email":"...","password":"...","name":"..."}'`). This creates users in both the auth provider and the app database simultaneously.
     c. **UI signup**: As a last resort, use Playwright to navigate to `/signup` and create each test user through the UI. This is slowest but always works if the signup flow is functional.
   - If all three methods fail, ABORT and report: "Test user creation failed — manual intervention required. Check auth provider configuration."
   - Verify ALL test user accounts listed in `e2e/constants.ts` exist before spawning teammates. Missing test users cause cascading failures across all authenticated tests.
   - **SECURITY**: Read credentials from `./e2e/constants.ts` for testing only. never log, commit, or include credential values in reports or completion messages. Reference credentials by name only (e.g., 'the admin test user from constants').
   - Document which seeding method was used in the verification report.

6. **Build Navigation Inventory from Code** (supplements PRD-based verification matrix):
   The verification matrix (step 2) is built from PRD screen specs. But navigation bugs often exist in **implementation artifacts** not enumerated in the PRD — shared layout components, conditional tabs, footer links, mobile menus. This step discovers those.

   a. **Route constants**: Read the route constants file (e.g., `src/lib/constants.ts` `ROUTES` object) and list ALL defined routes. Cross-reference against `src/app/**/page.tsx` files — flag any route constant that has no corresponding page file (dead route reference).
   b. **Shared layout navigation**: Read ALL layout components that contain `<Link>` or `router.push()`:
      - Root layout header/footer links
      - Dashboard sidebar links (desktop AND mobile variants)
      - Mobile bottom navigation bar
      - Mobile hamburger/sheet menu
      - Breadcrumb navigation
      - Settings navigation tabs
      - Project sub-navigation tabs
      - Any other tabbed layout discovered in the code (e.g., audit views, review panels, entity hubs, organization settings)
   c. **Middleware route protection**: Read `src/middleware.ts` (or equivalent) and extract:
      - `PUBLIC_ROUTES` / `PUBLIC_ROUTE_PREFIXES` arrays
      - Auth redirect logic
      - Cross-reference: every public page route must be in the public routes list, or users will get incorrectly redirected to login
   d. **Compile a Navigation Checklist** and append it to the verification matrix. This checklist has:
      - Every unique `href`/route found in layout components + route constants
      - For each: which layout component references it, whether the target `page.tsx` exists, whether it's in `PUBLIC_ROUTES` (if it should be public)
      - Flag mismatches: link exists but page doesn't, page exists but isn't linked, public page not in middleware whitelist

7. **Plan teammate assignments and test user isolation**:
   - Assign SEPARATE test user accounts to each teammate to prevent state conflicts:
     - Teammate 1 (automated-page-verifier): uses a read-only test user (e.g., basic/starter tier) — read-only verification
     - Teammate 2 (acceptance-criteria-verifier): uses a test user with write access (e.g., pro/advanced tier) — may create/modify data
     - Teammate 3 (visual-ai-reviewer): uses the same user as Teammate 1 — read-only
     - Teammate 4 (responsive-and-interaction-verifier): uses a test user with elevated permissions (e.g., enterprise/admin tier) — interaction testing
   - If the project has fewer test users, stagger Teammates 1 and 2 (Teammate 2 runs after Teammate 1 completes)
   - Divide screens into groups by authentication requirements:
     - Public screens (no auth needed)
     - Authenticated screens (any user)
     - Role-specific screens (admin, org owner, etc.)
     - Multi-step flows (require sequential navigation)
   - Document user assignments in the verification matrix

### Phase 2: Spawn Verification Teammates

Spawn the following 4 teammates. Teammates 1, 2, and 4 can run in parallel (they use separate test users). Teammate 3 runs AFTER Teammate 1 completes (it depends on Teammate 1's screenshots).

**Sequencing**: Spawn Teammates 1, 2, and 4 immediately. Wait for Teammate 1 to complete and confirm screenshots are saved. Then spawn Teammate 3.

#### Teammate 1: "automated-page-verifier"
**Scope**: Systematic page-by-page verification — console errors, HTTP errors, key elements, accessibility

~~~
You are performing automated verification of the running application using dynamically generated test scenarios and PRD screen specifications.

This stage finds and reports issues — it does not fix them. Never modify application code. Only create test files and reports.

Read CLAUDE.md first.
Check `./plancasting/tech-stack.md` for the `Session Language` setting. Write all findings in that language.
Then read:
- ./plancasting/_audits/visual-verification/feature-scenario-matrix.md — the PRIMARY test plan. Contains Feature Scenarios (FS), Auth Context Scenarios (AS), and Entity State Scenarios (ES) assigned to you.
- ./plancasting/_audits/visual-verification/verification-matrix.md — SECONDARY page-level checklist for screens not covered by any scenario.
Read ./e2e/constants.ts for test user credentials. Use the test user assigned to you in the scenario matrix.
Read ./e2e/helpers/auth.ts for authentication patterns.

## Your Tasks

### 0. Unauthenticated Public Route Verification (must run FIRST — before logging in)

Before logging in with your test user, open a FRESH browser context with NO cookies, NO localStorage, and NO session tokens. Test ALL public routes while unauthenticated. This catches middleware/auth guard issues that are invisible once you're logged in.

Using a clean browser context with no stored state (Mode A: `browser.newContext()` in Playwright test code; Mode B: `browser_close` the current session, then `browser_navigate` to start fresh):
1. Navigate to EVERY route listed as "public" in the verification matrix's "Unauthenticated Access" section
2. For each public route, verify:
   - HTTP response status is **200** (not 302 redirect to `/login`)
   - The response body is the expected page content (not a login page)
   - No auth-related console errors (`token undefined`, `session expired`, etc.)
3. Also navigate to 2-3 PROTECTED routes (e.g., `/dashboard`, `/settings/profile`) and verify:
   - They redirect to `/login` (302 redirect, not a crash or blank page)
   - The redirect URL includes the original path as a query param (e.g., `/login?redirect=/dashboard`)
   - There is NO redirect loop
4. After completing unauthenticated checks, log in with your assigned test user for the remaining tasks

If the lead found no unauthenticated access issues in Phase 1 Step 4, you may skip this task. Otherwise, re-verify the issues the lead flagged and check for additional ones.

**Output**:
~~~
### Unauthenticated Route Verification
| Route | Auth Required | Expected | Actual Status | Body Check | Result |
|-------|-------------|----------|---------------|------------|--------|
| / | No | 200 + landing | ... | ... | PASS/FAIL |
| /privacy | No | 200 + content | ... | ... | PASS/FAIL |
| /sitemap.xml | No | 200 + XML | ... | ... | PASS/FAIL |
| /dashboard | Yes | 302 → /login | ... | ... | PASS/FAIL |
~~~

If ANY public route redirects to login, mark as **CRITICAL** — this blocks unauthenticated visitors, search crawlers, and social media previews.

---

For EACH screen in the verification matrix (logged in from this point onward):

### 1. Navigation & Load Verification
- Navigate to the screen URL
- Verify the page loads without HTTP errors (no 4xx/5xx)
- Capture ALL browser console errors and warnings
- Measure page load time (flag if > 3 seconds)
- Take a full-page screenshot
- If a page does not load within 30 seconds, mark as FAIL and move on — do not block the entire verification on one hung page

### 2. Component Presence Verification
For each component listed in the screen spec (SC-NNN):
- Check if the expected `data-testid` or semantic element exists in the DOM
- Check if the component is VISIBLE (not display:none, not zero-height, not off-screen)
- For interactive elements (buttons, links, inputs): verify they are not disabled unless the spec says they should be
- For navigation elements: verify they link to the correct routes
- Use `browser_snapshot` to inspect the accessibility tree for component presence verification — more reliable than screenshot-based DOM inspection.

### 3. State Verification
For each screen, verify these states render correctly:
- **Default state**: With normal data — does it match the spec layout?
- **Empty state**: If applicable — does the empty state component appear with guidance text and CTA?
- **Loading state**: During data fetch — are skeleton/spinner components shown (not a blank screen)?
- **Error state**: Simulate a failure if possible — does the error component appear?

For real-time backends (Convex, Firebase, Supabase): data may take a moment to load. Use `expect.poll()` or `expect.toPass({ timeout: 10000 })` to handle eventual consistency — do not mark a page as FAIL just because data took 2 seconds to appear.

### 4. Link Integrity Crawl (Code-Driven — NOT PRD-Driven)
This task goes BEYOND the PRD screen specs. On EVERY page you visit, crawl all navigation elements:
- Extract ALL `<a>` and `<Link>` elements with their `href` values from the current page DOM
- For each link found:
  a. Click the link (or navigate to the `href`)
  b. Verify the destination loads (HTTP 200, not 404/500, not a redirect loop)
  c. Verify you can navigate BACK to the originating page (browser back button or explicit navigation)
- Pay special attention to these high-risk areas (commonly missed by PRD-based checks):
  - **Shared layout links**: Sidebar navigation, header logo, footer links, breadcrumbs — these appear on many pages but may only be tested once. Test them from the FIRST page that renders each layout.
  - **Mobile-specific navigation**: If the app has a different mobile nav (bottom bar, hamburger menu), resize the viewport to mobile (375px) and crawl those links separately — they may differ from desktop nav.
  - **Footer links**: Footer often contains links to `/about`, `/blog`, `/terms`, `/privacy` etc. Verify ALL of them resolve. Flag any that 404.
- Output a **Link Integrity Report** section listing:
  ~~~
  ### Link Integrity Crawl
  - Total links found: [n]
  - Links verified: [n]
  - Broken links (404/500): [n] — [source page → broken href]
  - Redirect loops: [n] — [source page → loop path]
  - Links to external domains: [n] (not verified, listed only)
  ~~~

### 5. Sub-Navigation Completeness Check
For EVERY tabbed/segmented navigation layout in the app (discover these from the Navigation Inventory built in Phase 1 step 6):
- **Settings tabs**: Click EVERY tab in the settings navigation. Verify each loads content (not 404, not blank).
- **Entity detail tabs** (e.g., project detail, document detail): For entities in each major lifecycle status, verify:
  - Correct tabs are ENABLED for that status
  - Correct tabs are DISABLED for that status
  - Clicking an enabled tab navigates to the correct page and loads content
  - Clicking a disabled tab does not navigate (stays on current page)
- **All other tabbed layouts**: For each tabbed/segmented layout discovered in the code (see Phase 1 step 6b — this includes any layout with tab navigation such as audit sections, review panels, organization views, etc.), click EVERY tab and verify content loads.
- Output a **Sub-Navigation Report** section:
  ~~~
  ### Sub-Navigation Completeness
  | Layout | Total Tabs | Working | Broken | Details |
  |--------|-----------|---------|--------|---------|
  | Settings | [n] | [n] | [n] | [broken list] |
  | Project (draft) | [n] | [n] | [n] | [broken list] |
  | ...
  ~~~

### 6. Accessibility Quick Check
For each screen:
- Run axe-core (using the checkWcag2AA pattern from e2e/helpers/a11y.ts)
- Flag critical accessibility violations (missing alt text, no form labels, missing ARIA roles)

### 7. Generate Playwright Test Files (Mode A)
For each screen group, generate a reusable Playwright test file at `e2e/verification/`:
- Name: `verify-sc-{range}.spec.ts` (e.g., `verify-sc-001-009.spec.ts`)
- Follow existing Playwright patterns from `e2e/*.spec.ts`
- must reuse helpers from `e2e/helpers/` (auth, a11y, seed)
- must use `getByRole`, `getByText`, `getByLabel`, or `getByTestId` — never use CSS class or ID selectors (e.g., `.className`, `#id`)
- **Selector discovery**: Do not assume `data-testid` exists on all elements. Many UI libraries (React Aria, Radix, shadcn) render semantic HTML with `<label>` associations instead. Prefer `getByRole()` and `getByLabel()` first; fall back to `getByTestId()` only when the element has an explicit test ID. Read the actual component source to discover which selectors are available.
- must handle eventually-consistent data with `expect.poll()` or `expect.toPass()`
- Include `@verification` tag
- Test structure:
  ~~~typescript
  test.describe("SC-NNN: [Screen Name] Verification", () => {
    test("page loads without errors @verification", async ({ page }) => {
      // Navigate, check no console errors, screenshot
    });
    test("required components are visible @verification", async ({ page }) => {
      // Check each component from spec
    });
    test("accessibility passes @verification", async ({ page }) => {
      await checkWcag2AA(page);
    });
  });
  ~~~

### Output Format
For each screen, report:
~~~
## SC-NNN: [Screen Name] — [URL]
- **Page Load**: PASS / FAIL (HTTP [status], [load time]ms)
- **Console Errors**: None / [count] errors ([list])
- **Components**: [n]/[total] present — Missing: [list]
- **Empty State**: PASS / FAIL / N/A
- **Loading State**: PASS / FAIL
- **Accessibility**: PASS / [n] violations ([list])
- **Screenshot**: ./screenshots/automated/sc-nnn-[state].png
- **Test File**: e2e/verification/verify-sc-nnn.spec.ts
~~~

When done, message the lead with: total screens checked, pass/fail counts, critical failures list.
~~~

#### Teammate 2: "acceptance-criteria-verifier"
**Scope**: Execute Given/When/Then acceptance criteria from user stories

~~~
You are executing Feature Scenarios and acceptance criteria from PRD user stories in the running application.

This stage finds and reports issues — it does not fix them. Never modify application code. Only create test files and reports.

Read CLAUDE.md first.
Check `./plancasting/tech-stack.md` for the `Session Language` setting. Write all findings in that language.
Then read:
- ./plancasting/_audits/visual-verification/feature-scenario-matrix.md — the PRIMARY test plan. Contains Feature Scenarios (FS) and Negative Scenarios (NS) assigned to you. Execute each Feature Scenario step-by-step.
- ./plancasting/prd/04-epics-and-user-stories.md for the full acceptance criteria.
- ./plancasting/prd/06-user-flows.md for end-to-end flow definitions.
Read ./e2e/constants.ts for test user credentials. Use the test user assigned to you in the scenario matrix.

## Scenario Execution

For each Feature Scenario (FS-NNN) assigned to you:
1. Check prerequisites: Does the required entity state exist? (e.g., project in `draft` status)
2. Set up auth context: Log in as the specified test user with the required role
3. Execute EACH step in order: Navigate to page, perform action, verify expected result
4. Record PASS/FAIL per step — if step N fails, mark all subsequent steps as BLOCKED
5. Map results back to acceptance criteria: Each step corresponds to US-NNN AC-N
6. Screenshot at each step transition, not just the final state
7. Log every button clicked, form filled, and page navigated to

## Your Tasks

For EACH user story (US-NNN) in scope:

### 1. Parse Acceptance Criteria
Each acceptance criterion follows this format:
> **Given** [context] **When** [action] **Then** [outcome]

Translate each into a sequence of browser actions:
- **Given**: Navigate to the correct page, set up the precondition (log in as specific user, ensure data exists)
- **When**: Perform the action (click button, fill form, navigate)
- **Then**: Assert the expected outcome (element appears, data updates, navigation occurs, toast shows)

### 2. Execute Each Criterion
- Use Playwright or direct browser interaction
- For criteria that modify data: verify the change persisted (reload and check)
- For criteria involving multi-step flows: follow the complete flow
- For criteria involving error cases: trigger the error condition and verify the error UI
- For real-time data updates: use `expect.poll()` or retry assertions to handle eventual consistency — wait up to 10 seconds before declaring FAIL
- If a criterion is BLOCKED by a prerequisite failure (e.g., can't test "edit project" if "create project" failed), mark as BLOCKED with reference to the blocking criterion

### 3. Generate Playwright Test Files (Mode A)
For each epic, generate a test file at `e2e/verification/`:
- Name: `verify-us-{epic-range}.spec.ts`
- must reuse helpers from `e2e/helpers/` (auth, a11y, seed)
- must use `getByRole`, `getByText`, `getByLabel`, or `getByTestId` — never use CSS class or ID selectors (e.g., `.className`, `#id`)
- Include `@verification` tag
- Test structure maps 1:1 to acceptance criteria:
  ~~~typescript
  test.describe("EPIC-NNN: [Epic Name] — Acceptance Criteria", () => {
    test("US-NNN AC-1: [criterion summary] @verification", async ({ page }) => {
      // Given
      await page.goto("/...");
      // When
      await page.getByRole("button", { name: "..." }).click();
      // Then
      await expect(page.getByText("...")).toBeVisible();
    });
  });
  ~~~

### 4. Cross-Feature Flow Verification
For user flows defined in `./plancasting/prd/06-user-flows.md`:
- Execute the COMPLETE flow end-to-end (all UF-NNN flows defined in the PRD)
- Verify navigation between features works (no dead ends, no broken links)
- Verify data passed between features is correct (e.g., project created in step A appears in step B)

### 5. Dead Route Detection (Code-Driven)
Read the route constants file (e.g., `src/lib/constants.ts` `ROUTES` object) provided in the navigation inventory from the verification matrix.
- For EVERY route constant defined:
  a. Navigate to it in the browser (use a real entity ID for dynamic routes like `/projects/[id]`)
  b. Verify the page loads (HTTP 200) — not 404, not redirect loop, not blank page
  c. If the route requires a specific entity state (e.g., `/projects/[id]/deploy` requires a project in `ready_to_deploy` status), document the prerequisite
- For dynamic routes, test with:
  - A VALID entity ID (should load)
  - An INVALID entity ID (should show 404 or error page, NOT crash)
  - A DELETED entity ID if soft-delete is used (should show appropriate message)
- Output a **Dead Route Report**:
  ~~~
  ### Dead Route Detection
  - Total routes in constants: [n]
  - Routes verified working: [n]
  - Routes returning 404: [n] — [list]
  - Routes with redirect loops: [n] — [list]
  - Routes crashing on invalid ID: [n] — [list]
  ~~~

### 6. Auth Redirect Verification
**Conditional**: If BOTH the lead's Phase 1 Step 4 AND Teammate 1's Task 0 found zero auth redirect issues, skip this task. If EITHER found issues, verify the specific issues they flagged.

Test the middleware/auth layer's redirect behavior explicitly. The unauthenticated tests below must use a FRESH browser context with NO cookies/localStorage/session. For Mode A: use `browser.newContext()` in Playwright test code. For Mode B: use `browser_close` then `browser_navigate` to start a fresh MCP session. Do not test "unauthenticated" by merely logging out in the same context, as stale cookies or localStorage tokens may still be present.

- **Unauthenticated → protected route** (fresh context, no auth):
  Navigate to each major protected route. Verify redirect to `/login?redirect=[original-path]`. Then log in and verify redirect back to the original path.
- **Authenticated → public route**: While logged in, navigate to `/login` and `/signup`. Verify redirect to `/dashboard` (not stuck on login page).
- **Public route access** (fresh context, no auth):
  Navigate to ALL public routes (`/`, `/pricing`, `/privacy`, `/terms`, `/help`, `/help/troubleshoot`, `/forgot-password`, `/api/health`, `/sitemap.xml`, `/robots.txt`, `/.well-known/openid-configuration`) WITHOUT authentication. For EACH route, verify:
  1. HTTP response is 200 (not 302 redirect to `/login`)
  2. Response body is the expected content (not a login page served as 200)
  3. No auth-related console errors
- **API routes** (fresh context, no auth): Verify `/api/health` returns 200 JSON. Verify webhook endpoints (check `plancasting/tech-stack.md` and codebase for webhook routes — e.g., payment provider, auth provider, BaaS webhooks) return appropriate responses (not 404, not auth-blocked). These are server-to-server endpoints and must work without browser auth.
- Output an **Auth Redirect Report**:
  ~~~
  ### Auth Redirect Verification
  | Scenario | Route | Expected | Actual | Status |
  |----------|-------|----------|--------|--------|
  | Unauth → protected | /dashboard | Redirect to /login | ... | PASS/FAIL |
  | Auth → /login | /login | Redirect to /dashboard | ... | PASS/FAIL |
  | Public route | /privacy | HTTP 200, no redirect | ... | PASS/FAIL |
  | ...
  ~~~

### Output Format
For each user story:
~~~
## US-NNN: [Story Title] — FEAT-NNN
- **AC-1**: PASS / FAIL / BLOCKED — [Given/When/Then summary]
  - Failure detail: [what went wrong]
  - Screenshot: ./screenshots/criteria/us-nnn-ac-1.png
- **AC-2**: PASS / FAIL / BLOCKED — [Given/When/Then summary]
- ...
- **Overall**: [pass-count]/[total-count] criteria pass ([blocked-count] blocked)
~~~

When done, message the lead with: total criteria tested, pass/fail/blocked counts, critical flow failures.
~~~

#### Teammate 3: "visual-ai-reviewer"
**Scope**: AI Vision review of screenshots against screen specifications
**Dependency**: Spawn AFTER Teammate 1 completes, so Teammate 1's screenshots are available.

~~~
You are performing AI-powered visual review of the application screenshots against PRD screen specifications.

This stage finds and reports issues — it does not fix them. Never modify application code. Only create reports and take screenshots.

Read CLAUDE.md first.
Check `./plancasting/tech-stack.md` for the `Session Language` setting. Write all findings in that language.
Read BOTH the feature scenario matrix at `./plancasting/_audits/visual-verification/feature-scenario-matrix.md` (primary test plan) AND the verification matrix at `./plancasting/_audits/visual-verification/verification-matrix.md` (page-level checklist). Use the feature scenario matrix for scenario-aligned visual verification and the verification matrix for page-level completeness.
Read ./plancasting/prd/08-screen-specifications.md for the screen specifications.
Read ./plancasting/prd/09-interaction-patterns.md for design patterns and visual guidelines.

## Your Tasks

### 1. Collect Screenshots
Use Teammate 1's screenshots from `./screenshots/automated/` as the primary source.
For any missing screens, or for responsive breakpoints not covered, take your own:
- Navigate to each screen in scope
- Take screenshots at 3 breakpoints:
  - Desktop: 1440px width
  - Tablet: 768px width
  - Mobile: 375px width
- Save to `./screenshots/vision/sc-nnn-{breakpoint}.png`

### 2. Visual Spec Compliance Review
For each screen screenshot, compare against the screen specification:

**Layout Review**:
- Does the page layout match the spec's "Layout Description" zones?
- Are components arranged in the correct order and hierarchy?
- Is the visual hierarchy correct (headings, content, actions)?

**Component Review**:
- Does each visible component match the spec's component inventory?
- Are there unexpected components (not in the spec) or missing ones?
- Do cards, tables, lists have the correct structure?

**Content Review**:
- Is there any placeholder text visible ("Lorem ipsum", "[TODO]", "Coming soon" for built features)?
- Do headings and labels match the spec's content specifications?
- Are empty states using the correct guidance text and CTA?

**Responsive Review** (visual compliance at each breakpoint):
- Does the mobile view properly restack/reflow content?
- Does the navigation adapt correctly (hamburger menu on mobile)?
- Are there visible layout breaks at any breakpoint?

**Design Consistency Review**:
- Are design tokens applied consistently (colors, spacing, typography)?
- Do interactive elements have consistent styling (buttons, inputs, links)?
- Are loading states consistent across pages (same skeleton/spinner pattern)?

### 3. Dark Mode Review (if applicable)
If the app supports dark mode:
- Toggle dark mode and re-screenshot key pages
- Check for: harsh borders, invisible text, poor contrast, unthemed components
- Verify all pages are fully themed (no white/light components in dark mode)

### Output Format
For each screen:
~~~
## SC-NNN: [Screen Name] — Visual Review

### Desktop (1440px)
- **Layout Match**: Matches spec / Minor deviation / Significant mismatch
  - [Description of any deviation]
- **Component Match**: All present / Missing: [list]
- **Content**: No placeholder text / Found: [list]
- **Design Consistency**: Consistent / [issues]

### Tablet (768px)
- [Same structure]

### Mobile (375px)
- [Same structure]

### Dark Mode (if applicable)
- [Issues found]

### Severity: Critical / High / Medium / Low
### Screenshot References: [paths]
~~~

When done, message the lead with: total screens reviewed, issues by severity, critical visual mismatches.
~~~

#### Teammate 4: "responsive-and-interaction-verifier"
**Scope**: Interactive behavior, keyboard navigation, and cross-browser verification (functional testing, NOT visual layout — that is Teammate 3's job)

~~~
You are verifying interactive behavior, keyboard accessibility, role permissions, and cross-browser compatibility.

This stage finds and reports issues — it does not fix them. Never modify application code. Only create reports.

Read CLAUDE.md first.
Check `./plancasting/tech-stack.md` for the `Session Language` setting. Write all findings in that language.
Then read:
- ./plancasting/_audits/visual-verification/feature-scenario-matrix.md — the PRIMARY test plan. Contains Role Permission Scenarios (RS) and button/interaction tasks from Feature Scenarios assigned to you.
- ./plancasting/_audits/visual-verification/verification-matrix.md — SECONDARY page-level checklist.
Read ./plancasting/prd/09-interaction-patterns.md for expected interactions.
Read ./playwright.config.ts for browser projects.
Use the test user assigned to you in the scenario matrix.

**Selector guidance**: Use `getByRole`/`getByText`/`getByLabel` selectors (preferred). Use `getByTestId` as fallback when semantic selectors are unavailable. Do not assume `data-testid` exists on all elements — inspect the DOM first.

## Your Tasks

### 1. Interactive Behavior Verification
For each screen with interactive elements:
- **Forms**: Fill and submit every form. Verify validation messages appear for invalid input. Verify successful submission shows feedback (toast, redirect, or inline success).
- **Modals/Dialogs**: Open every modal trigger. Verify the modal renders with correct content. Verify close behavior (X button, outside click, Escape key).
- **Dropdowns/Selects**: Open every dropdown. Verify options are populated (not empty). Verify selection triggers the expected behavior.
- **Tabs/Accordions**: Click every tab/accordion. Verify content switches correctly. Verify URL updates if tabs are URL-driven.
- **Pagination/Infinite Scroll**: If list views have pagination, navigate through pages. Verify data loads correctly.
- **Search/Filter**: If search or filter exists, test with real queries. Verify results update.
- **Drag & Drop**: If any drag-and-drop interactions exist, verify they work.

### 2. Systematic Button Action Verification (Code-Driven — NOT PRD-Driven)
For EVERY page you visit, find ALL `<button>` elements and clickable elements with `role="button"`:
- **Navigation buttons** (buttons that trigger `router.push()` or page navigation):
  - Click the button
  - Verify navigation occurs to the expected destination
  - Verify the destination page loads without errors
  - Verify you can navigate back
- **Mutation buttons** (buttons that trigger backend operations like Archive, Delete, Clone, Save):
  - Click the button
  - If a confirmation dialog appears: verify the dialog renders, test both "confirm" and "cancel" paths
  - After confirming: verify the mutation feedback (toast, redirect, UI update)
  - After canceling: verify no state change occurred
  - For destructive actions (Delete): verify the confirmation dialog is REQUIRED (no direct deletion on single click)
- **Toggle buttons** (buttons that switch state like Archive/Unarchive, Enable/Disable):
  - Click to toggle ON — verify visual state changes (text, icon, color)
  - Click to toggle OFF — verify it reverts
- **Menu trigger buttons** (buttons that open dropdowns, popovers, sheets):
  - Click to open — verify the menu/popover appears
  - Verify menu items are populated (not empty)
  - Click a menu item — verify its action
  - Click outside or press Escape — verify the menu closes
- **CTA buttons** (primary call-to-action like "Create New", "Start Process", "Deploy", "Submit"):
  - Click the button
  - Verify the expected flow initiates (navigation, modal, form)
- Output a **Button Action Report**:
  ~~~
  ### Button Action Verification
  - Total buttons found: [n]
  - Buttons tested: [n]
  - Working correctly: [n]
  - No visible action on click: [n] — [page, button text]
  - Crashes/errors on click: [n] — [page, button text, error]
  - Missing confirmation for destructive actions: [n] — [page, button text]
  ~~~

### 3. Keyboard Navigation
For each page:
- Tab through ALL interactive elements — verify focus order matches visual order
- Verify focus rings are visible (focus-visible styling per the project's design tokens, e.g., `focus-visible:ring-2` in Tailwind or equivalent CSS custom property)
- Verify Enter/Space activates buttons and links
- Verify Escape closes modals and dropdowns
- Verify arrow keys work in custom widgets (tabs, menus, selects)

### 4. Responsive Functional Testing
Test interactive elements at mobile breakpoints (375px, 640px):
- No horizontal scrollbar on any page
- No content overflow or clipping
- Touch targets are adequate size (>=44px) on mobile breakpoints
- Navigation hamburger menu opens and closes correctly
- Forms are usable on mobile (inputs don't overflow, submit buttons are reachable)
- **Mobile navigation verification**: At mobile breakpoint, verify:
  - Mobile bottom bar links all work (click each, verify destination loads)
  - Hamburger menu opens, all links inside work, menu closes properly
  - Mobile bottom bar and hamburger menu links match the desktop sidebar links (flag any discrepancies)

Note: Visual layout compliance at breakpoints is Teammate 3's responsibility. Your focus is whether interactive elements FUNCTION correctly at each breakpoint.

### 5. Cross-Browser Quick Check
Run key user flows (auth, main feature, billing) in:
- Chromium
- Firefox
- WebKit (Safari)
Flag any browser-specific rendering or behavior issues.

### Output Format
~~~
## SC-NNN: [Screen Name] — Interaction & Responsive Review

### Interactive Elements
- **Form: [name]**: Works / [issue]
- **Modal: [name]**: Works / [issue]
- **[Element]**: Works / [issue]

### Keyboard Navigation
- **Focus order**: Correct / [issue]
- **Focus rings**: Visible / Missing on [elements]
- **Keyboard activation**: Works / [issue]

### Responsive Functional (failing breakpoints only)
- **[breakpoint]**: [issue + screenshot]

### Cross-Browser (failures only)
- **[browser]**: [issue + screenshot]
~~~

When done, message the lead with: total interactions tested, pass/fail counts, responsive issues, browser-specific issues.
~~~

### Phase 3: Coordination During Execution

While teammates are working:
1. Teammates 1, 2, and 4 run in parallel (separate test users). Teammate 3 starts after Teammate 1 completes.
2. If Teammate 1 finds pages that don't load at all (HTTP 500, blank page):
   - Flag as **CRITICAL** — these block visual review for that screen.
   - Collect console errors for debugging.
3. Aggregate findings across teammates — a screen might pass automated checks (Teammate 1) but fail visual review (Teammate 3).
4. If auth setup fails for any test user:
   - Check for: redirect loops (inspect network tab for 302 chains), expired test credentials, auth provider misconfiguration
   - If one user fails but others work: continue with working users, document the auth failure
   - If ALL users fail: ABORT the stage — auth is a systemic issue that blocks all verification

### Phase 4: Verification Report

After all teammates complete:

1. **Typecheck generated test files** before running them:
   ~~~bash
   bun run typecheck
   ~~~
   Fix any type errors in generated specs before proceeding. Common issues:
   - Unused variables: prefix with `_` (e.g., `const _errors = ...`)
   - Missing type annotations on callback parameters
   - Incorrect `aria-current` type unions

2. **Run generated Playwright tests** to confirm they pass. If Mode A test files were generated (check `e2e/verification/` directory exists and contains `.spec.ts` files):
   ~~~bash
   bunx playwright test e2e/verification/ --grep "@verification" --retries=2
   ~~~
   Use `--retries=2` to handle flaky tests from timing issues. If a test fails on all retries, it is a real failure.

3. **Generate the verification report** at `./plancasting/_audits/visual-verification/report.md`:

   ~~~markdown
   # Visual & Functional Verification Report — Stage 6V

   ## Summary
   - **Verification Date**: [date]
   - **Scope**: full / critical / diff
   - **Base URL**: [dev server or production URL]
   - **Screens Verified**: [n] / [total in scope]
   - **Acceptance Criteria Tested**: [n] / [total in scope]

   ## Scenario Generation Summary
   - Feature Scenarios (FS): [n] generated, [n] executed
   - Auth Context Scenarios (AS): [n] generated, [n] executed
   - Entity State Scenarios (ES): [n] generated, [n] executed
   - Role Permission Scenarios (RS): [n] generated, [n] executed
   - Negative Scenarios (NS): [n] generated, [n] executed
   - Standalone page checks (gap-fill): [n]
   - **Total test scenarios**: [n]

   ## Results Overview

   ### Feature Scenario Results (PRIMARY)
   - Scenarios passing (all steps): [n] / [total]
   - Scenarios failing: [n] / [total] — [list with FS-NNN, failure step, error]
   - Scenarios blocked (by prerequisite failure): [n] / [total]
   - Steps executed: [n] / [total steps across all scenarios]
   - Buttons clicked: [n]
   - Forms filled: [n]
   - Pages navigated: [n] unique pages across all scenarios

   ### Page-Level Results (SECONDARY — gap-fill)
   - Pages loading without errors: [n]
   - Pages with load failures: [n] — [list with HTTP status]
   - Pages with console errors: [n]
   - Pages with missing components: [n]
   - Pages with accessibility violations: [n]

   ### Unauthenticated Access Results
   - Public routes tested (without auth): [n]
   - Public routes loading correctly: [n]
   - Public routes incorrectly redirecting to login: [n] — [list]
   - Protected routes tested (without auth): [n]
   - Protected routes correctly redirecting to login: [n]
   - Redirect loops detected: [n] — [list]

   ### Acceptance Criteria Results
   - Criteria passing: [n] / [total]
   - Criteria failing: [n] / [total]
   - Criteria blocked: [n] / [total]
   - Critical flow failures: [list]

   ### Visual Compliance Results
   - Screens matching spec: [n]
   - Minor deviations: [n]
   - Significant mismatches: [n]
   - Placeholder text found: [count]

   ### Navigation & Link Integrity Results
   - Total links crawled: [n]
   - Broken links (404/500): [n] — [list with source page → broken href]
   - Redirect loops: [n] — [list]
   - Dead route constants (no page.tsx): [n] — [list]
   - Public routes blocked by middleware: [n] — [list]
   - Auth redirect failures: [n] — [list]

   ### Button Action Results
   - Total buttons tested: [n]
   - No visible action on click: [n] — [list with page + button text]
   - Crashes/errors on click: [n] — [list]
   - Missing confirmation for destructive actions: [n] — [list]

   ### Sub-Navigation Results
   - Tabbed layouts tested: [n]
   - Total tabs across all layouts: [n]
   - Broken tabs (404/blank): [n] — [list with layout + tab name]
   - Incorrectly enabled/disabled tabs: [n] — [list]

   ### Responsive & Interaction Results
   - Interactive elements tested: [n]
   - Broken interactions: [n]
   - Responsive issues: [n]
   - Cross-browser issues: [n]
   - Mobile nav discrepancies vs desktop: [n] — [list]

   ## Critical Failures (must fix before deploy)
   [List all Critical/High severity issues with SC-NNN, US-NNN, FEAT-NNN references]

   ## Issue Details by Feature
   ### FEAT-NNN: [Feature Name]
   [Grouped issues for this feature with screenshots and AC references]

   ## Generated Test Artifacts
   - Playwright test files: `e2e/verification/*.spec.ts`
   - Screenshots: `./screenshots/automated/`, `./screenshots/criteria/`, `./screenshots/vision/`

   ### Feature Scenario Matrix
   See `./plancasting/_audits/visual-verification/feature-scenario-matrix.md` (generated in Phase 1 Step 2g).

   ## Gate Decision

   **Percentage thresholds** (boundary clarification — inclusive/exclusive):
   - **PASS**: ≥90.0% acceptance criteria pass rate, all pages load, zero critical failures
   - **CONDITIONAL PASS**: ≥80.0% and <90.0% criteria pass rate, 1–3 high-severity issues — document for post-deploy fix
   - **FAIL**: <80.0% criteria pass rate, OR any critical failure (page won't load, core flow broken, auth broken) — fix before deploy

   **Critical paths definition**: Critical paths = all P0 features' happy-path scenarios (derived from `./plancasting/prd/06-user-flows.md`, filtered to P0 priority). These must achieve at least 1 passing scenario for PASS or CONDITIONAL PASS. P1-P3 features may have failures without blocking the gate.

   **Dual-system decision matrix** — use the WORSE of the two systems:

   | Percentage | Categories Present | Final Gate | Next Stage |
   |---|---|---|---|
   | PASS (≥90%) | None (zero issues) | PASS | → 6P/6P-R |
   | PASS (≥90%) | 6V-A/B only | CONDITIONAL PASS | → 6R → 6P/6P-R |
   | PASS (≥90%) | 6V-C only | CONDITIONAL PASS | → 6P/6P-R (skip 6R — document C issues for human review) |
   | PASS (≥90%) | Mixed A/B + C | CONDITIONAL PASS | → 6R → 6P/6P-R (document remaining C) |
   | CONDITIONAL (≥80%, <90%) | 6V-A/B present | CONDITIONAL PASS | → 6R → 6P/6P-R |
   | CONDITIONAL (≥80%, <90%) | 6V-C only | CONDITIONAL PASS | → 6P/6P-R (document C issues for human) |
   | FAIL (<80%) | Any | FAIL | Manual fix + re-run 6V |

   > **Note**: All rows additionally require: all pages load successfully and zero critical failures. If either condition fails, the gate is FAIL regardless of percentage.

   The category system determines 6R routing (whether auto-fix is attempted); the percentage system sets the overall quality bar.

   **Post-gate routing**:
   - PASS (zero 6V-A/B issues) → Skip 6R, proceed to 6P/6P-R
   - CONDITIONAL PASS (6V-C issues only) → Skip 6R; proceed to 6P/6P-R (document 6V-C issues for human review). If ANY 6V-A/B issues exist, 6R is mandatory per CLAUDE.md
   - FAIL → Fix critical issues and re-run 6V before proceeding

   ## Failure Categorization (for 6R routing)

   **Category definitions** (for 6R routing — full details in Stage 6R prompt):
   - **6V-A** (auto-fixable): broken links, dead code, incorrect imports — 6R fixes automatically
   - **6V-B** (semi-auto): pattern-based fixes requiring verification — button wiring, conditional logic, missing feedback, auth redirects, stub components, missing loading states — 6R fixes then verifies
   - **6V-C** (human judgment): architectural issues, design decisions — 6R cannot fix

   These categories classify *fixability*, not severity. A critical bug that's easy to fix is 6V-A; a minor issue requiring architectural change is 6V-C. All issue categories in the report must use the `6V-` prefix (6V-A, 6V-B, 6V-C) to distinguish from Stage 5B's size-based categories. Never output bare "Category A", "Category B", or "Category C" — it will be confused with Stage 5B's size-based A/B/C system.

   **Handling flaky scenarios**: A flaky scenario fails inconsistently (fails once, passes on retest).
   - Re-test up to 3 times. If still flaky after retries, classify as 6V-C (human-judgment) — exclude from the pass-rate denominator. Document instability for developer investigation.
   - If it fails all retries: mark as "FAILED" (not flaky).
   - **For 6V (this stage)**: Flaky scenarios do not block the gate decision and are EXCLUDED from the pass/fail percentage calculation. Include them in the report as severity "Informational" in a separate "Flaky Scenarios" section. If more than 2 flaky scenarios are found, recommend re-running 6V in a fresh session. The gate outcome is unaffected by flaky count — they are flagged for post-launch investigation only.
   - **For 7V (production)**: Flaky scenarios count as FAIL. Production must be deterministic — investigate the root cause before re-running 7V.

   **6R cross-reference requirement**: Every failure entry in the table below must include the scenario ID (FS-NNN, AS-NNN, ES-NNN, RS-NNN, or NS-NNN) that detected it, in addition to the SC-NNN/US-NNN/FEAT-NNN references. Stage 6R uses these scenario IDs to categorize and prioritize fixes.

   | # | Scenario | Ref | Issue | Category | Rationale |
   |---|----------|-----|-------|----------|-----------|
   | 1 | FS-NNN | SC-NNN | [description] | 6V-A (auto-fix) | [why auto-fixable] |

   - Category 6V-A (auto-fixable): [n]
   - Category 6V-B (semi-auto): [n]
   - Category 6V-C (human judgment): [n]

   This table is the primary input for Stage 6R.

   ## Next Steps
   - If PASS (zero issues): skip 6R → proceed to Stage 6P/6P-R (Visual Polish) → 7 (Deploy) → 7V → 7D
   - If CONDITIONAL PASS with 6V-A/B issues (auto-fixable/semi-auto): proceed to Stage 6R (Runtime Remediation) → 6P/6P-R → 7 (Deploy) → 7V → 7D
   - If CONDITIONAL PASS with ONLY 6V-C issues (human judgment needed): skip 6R (it cannot fix 6V-C issues) → proceed directly to Stage 6P or 6P-R for visual polish, document unresolved 6V-C issues
   - If FAIL (critical failures — auth broken, core pages crash, data layer non-functional): fix critical issues manually, then re-run Stage 6V

   ## Recommendations
   [Specific fixes needed, grouped by priority]
   ~~~

4. **Commit generated test files** (if applicable): If Mode A generated test files in `e2e/verification/`, commit them BEFORE saving the commit hash in step 5: `git add e2e/verification/ plancasting/_audits/visual-verification/ && git commit -m 'test: Stage 6V verification tests and report'`. If no test files were generated (Mode B only), skip this step.

5. **Save the current commit hash**: Save this hash AFTER committing any generated test files (step 4 above), so the hash reflects the complete state.
   ~~~bash
   git rev-parse HEAD > ./plancasting/_audits/visual-verification/last-verified-commit.txt
   ~~~
   This enables `diff` scope mode on subsequent runs. This file remains uncommitted. It persists locally for `diff` mode in subsequent 6V runs. If lost (e.g., `git clean`), `diff` mode silently falls back to `full` mode. Add `plancasting/_audits/visual-verification/last-verified-commit.txt` to `.gitignore` to prevent accidental commits.

6. **Output summary**: gate decision, critical failure count, acceptance criteria pass rate.

### Phase 5: Shutdown

1. Request shutdown for all teammates.
2. Verify all file modifications are saved and committed.
3. Leave the dev server running — either Stage 6R (if failures found) or Stage 6P (if no failures) runs next, and both require the dev server. Note: if the operator starts a new Claude Code session (as recommended), this dev server process will have terminated. The 6R and 6P prompts handle this by checking server availability on startup.

## Critical Rules

1. always start the dev server and verify it's accessible before spawning teammates. If the server doesn't start within 60 seconds, ABORT the stage.
2. never skip the AI vision review (Teammate 3) — it catches spec mismatches that DOM assertions miss.
3. never mark a page as PASS if it has console ERRORS (Error level) — even if the page renders. Console WARNINGS from known framework development modes (React strict mode double-render, Convex dev logging, Next.js fast-refresh) should be noted but do not constitute a FAIL. However, warnings about deprecated APIs, missing keys, or unhandled promises SHOULD be investigated even if they originate from framework code. Filter by `console.error` severity, not all console output.
4. always test with seeded data — empty-database verification is separate from the empty-state check.
5. always take screenshots on failure — they are the primary debugging artifact. Name screenshots consistently: `sc-{nnn}-{state}-{breakpoint}.png`.
6. always map findings back to PRD identifiers (SC-NNN, US-NNN, FEAT-NNN) for traceability.
7. always generate Playwright test files (Mode A) even when using direct browser interaction (Mode B) — the tests are reusable for regression.
8. If a screen requires a specific user role to access, log in as that role — don't skip the screen.
9. If the app URL requires environment-specific configuration, read it from `./e2e/constants.ts` or `.env.local`.
10. This stage FINDS issues — it does not fix them. Fixes happen in Stage 6R (Runtime Remediation). The exception is trivial Playwright test file adjustments.
11. never let one teammate's actions corrupt state for another. Use the assigned test user accounts and avoid data mutations that would affect other teammates' read-only checks.
12. If a page does not load within 30 seconds, mark it as FAIL and move on — do not block the entire verification on a single hung page.
13. For eventually-consistent backends (Convex, Firebase, Supabase), use `expect.poll()` or retry assertions with up to 10-second timeouts — do not mark a test as FAIL just because data took a few seconds to appear.
14. If `globalSetup.ts` uses `import.meta` or other ESM-only features, it may fail when Playwright runs with non-standard configs or in CI. If globalSetup fails, seed test users manually (see Phase 1 step 5) rather than skipping authentication tests entirely.
15. always verify test user seeding succeeded BEFORE spawning teammates. A seeding failure silently blocks all authenticated verification — catching it early saves the entire stage from producing useless results.
16. always crawl links from shared layouts (sidebar, header, footer, mobile nav) — these are on EVERY page but are easy to miss because the PRD screen specs focus on page-specific content, not layout chrome. A broken footer link affects the entire app.
17. always test navigation at BOTH desktop and mobile viewports. Mobile navigation (bottom bar, hamburger menu) often has different links than the desktop sidebar — discrepancies between them are a common source of user confusion and broken routes.
18. always click buttons and verify their action — do not just check that the button exists in the DOM. A button that renders but does nothing on click is a FAIL, not a PASS. The most common "invisible" bugs are buttons with unwired `onClick` handlers or handlers that call undefined functions.
19. always test auth middleware redirects for ALL public routes. The most frequent post-deploy error is a public page (privacy, terms, sitemap.xml, robots.txt) being blocked by auth middleware because it wasn't added to the `PUBLIC_ROUTES` whitelist.
20. always test conditional navigation states (e.g., project tabs that enable/disable based on entity status) with entities in DIFFERENT lifecycle stages, not just the happy path.
21. always test public routes from a FRESH unauthenticated browser context (no cookies, no localStorage, no session tokens) BEFORE logging in. Testing public routes while logged in hides middleware/auth guard failures — the most common post-deploy bug is public pages being blocked for unauthenticated users. The lead performs this in Phase 1 step 4, and Teammate 1 repeats it as Task 0 for independent verification.
````
