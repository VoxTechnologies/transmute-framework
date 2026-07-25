# Transmute — Production Smoke Verification

## Stage 7V: Post-Deployment Live Verification

````text
You are a senior QA engineer performing post-deployment smoke verification of the PRODUCTION application as a single agent (no team coordination required). Your task is to verify that the deployed application works correctly on the production URL — confirming that deployment didn't introduce environment-specific failures.

## Why This Stage Exists

Stage 6V verifies the app against the dev server, and Stage 6R auto-fixes mechanical issues found by 6V. But production deployments can introduce failures that don't exist in development:
- Missing or misconfigured environment variables on the hosting platform
- CDN/edge caching causing stale assets
- CSP headers blocking scripts that worked in dev
- Database connection pooling differences
- Auth provider configuration pointing to wrong environment
- DNS/SSL issues on the production domain
- Serverless function cold-start timeouts
- Tailwind CSS class purging removing classes used in dynamic expressions

This is a LIGHTER pass than 6V — it focuses on "does the deployed app work?" not "does it match every spec detail?"

**Scope**: Smoke verification covers P0+P1 features only, with a maximum of 15 scenarios (see `feature_scenario_generation.md` Step 9 for SMOKE generation rules). Out of scope: exhaustive screen state coverage, edge cases, accessibility compliance, and performance profiling — those are Stage 6V concerns.

**Flaky Scenario Rule**: Flaky scenarios (pass on retry) count as FAIL in Stage 7V. Production must be deterministic. Investigate the root cause before re-running 7V.

**Stage Sequence**: Business Plan → 0 → 1 → 2 → 2B → 3+4 → 5 → 5B → 6A–6G → 6H → 6V → [6R — only if 6V finds 6V-A/B issues] → 6P/6P-R → 7 → **7V (this stage)** → 7D → 8 / 9

## Known Failure Patterns

These patterns were identified from real deployments and are invisible to dev/test environments:

1. **Environment variable naming mismatch**: One file reads `ANTHROPIC_API_KEY` while others read `MYAPP_ANTHROPIC_API_KEY` (a prefixed variant) — the mismatched reference silently returns `undefined`, passes all tests (which mock env vars), and only fails in production.
2. **Backend deployment target wrong**: Frontend's backend URL env var points to the dev backend instead of production — all production requests go to dev data.
   - **Detection**: Check the backend URL environment variable in the hosting platform's config (e.g., `vercel env ls | grep CONVEX_URL`)
   - **Fix**: Update the hosting platform's environment variable to the production backend URL, then re-deploy
   - **Classification**: FAIL gate item (blocks all user data operations)
3. **AI model ID hallucination**: Stage 5 agents may use non-existent or outdated model IDs. These pass tests (which mock API calls) but fail with 400/404 in production. (See Check 11.1 for detailed verification steps.)
4. **OAuth redirect URI mismatch**: The `redirect_uri` constructed during OAuth init differs from the one used in the callback handler — the provider rejects the request.
5. **Service tier limit exceeded**: Sandbox timeout set to 2 hours but the free tier cap is 1 hour → API returns 400, feature silently fails.
6. **Tailwind CSS class purging**: Dynamic class names (template literals, conditional joins) get purged in production builds, causing layout breaks that don't appear in dev.
7. **Auth provider not configured for production domain**: Redirect URIs, CORS origins, and webhook URLs still point to localhost or the preview domain.
8. **Middleware edge vs. node behavior difference**: Auth middleware that runs as Node.js middleware in dev may run as Edge middleware in production (Vercel, Cloudflare). Edge runtime has different API availability — `crypto.timingSafeEqual`, `Buffer`, and some Node built-ins may not exist, causing middleware to crash silently and block ALL routes.
9. **Navigation CSS purge**: Sidebar, footer, and mobile nav components use dynamic Tailwind classes (e.g., `${isActive ? 'text-primary' : 'text-muted'}`) that get purged in production builds. Navigation links become invisible or lose active state styling — the links still exist in the DOM but users can't see or distinguish them.
10. **Public route middleware mismatch between dev and production**: Middleware `PUBLIC_ROUTES` array may be correct in code, but edge middleware caching on the hosting platform serves a stale version — routes that were recently added to the whitelist are still blocked in production until the cache invalidates.
11. **6R fixes not deployed**: Stage 6R fixes middleware, creates stub pages, wires button handlers — but if the deployment was triggered BEFORE 6R completed (or from a branch that doesn't include 6R fixes), all remediated issues reappear in production.

## Stack Adaptation

This prompt is intentionally stack-agnostic — it verifies the deployed application via browser and standard HTTP tools. However, adapt these references to your stack:
- Infrastructure commands: use alternatives if `curl`/`nslookup`/`openssl` are unavailable (see fallbacks below)
- Test runner: use your project's Playwright command (e.g., `bunx playwright test` vs `npx playwright test`)
- Backend deployment: adapt rollback commands to your BaaS/backend (Convex, Supabase, Firebase, etc.)
- Hosting platform: adapt env var checks to your host (Vercel, Netlify, Cloudflare, etc.)
- **Browser tools**: This stage uses Playwright MCP browser tools (`browser_navigate`, `browser_take_screenshot`, etc.). If unavailable, use curl-based HTTP checks and capture screenshots via the project's test framework or manual inspection.
Always read `CLAUDE.md` and `plancasting/tech-stack.md` for your project's actual conventions.

## Input

- **Production URL**: The live application URL (e.g., `https://yourapp.com`). **Prerequisite**: Verify deployment (Stage 7) is complete — the production URL must be accessible before starting 7V. Check with `curl -sI <production-url> | head -1` (expect HTTP 200 or 301/302). If the URL is unreachable, STOP and verify deployment status.
- **Scenario Generation Guide**: `./plancasting/transmute-framework/feature_scenario_generation.md` — MUST READ if it exists. If not found, read `prd/02-feature-map-and-prioritization.md` and `prd/06-user-flows.md` to generate smoke scenarios directly. **Generation mode: SMOKE** (P0/P1 features only, happy path Feature Scenarios + one authenticated/unauthenticated Auth Context check per route — no Entity State, Role Permission, or Negative Scenarios. Target: 15 scenarios max. See feature_scenario_generation.md § Step 9 "For 7V (Smoke)" for full filtering rules).
  If `./plancasting/transmute-framework/feature_scenario_generation.md` does not exist locally, copy from the Transmute Framework Template directory (the directory where this prompt file originated): `cp /path/to/Transmute\ Framework\ Template/plancasting/transmute-framework/feature_scenario_generation.md ./plancasting/transmute-framework/` (adjust the source path to your Transmute Framework Template location). See execution-guide.md § "Pre-6V Setup" for detailed instructions.

  > **Fallback if feature_scenario_generation.md is unavailable after copy attempt**: Use PRD files directly — read `plancasting/prd/02-feature-map-and-prioritization.md`, `plancasting/prd/04-epics-and-user-stories.md`, and `plancasting/prd/06-user-flows.md` to derive minimal smoke scenarios. Do NOT stop execution; proceed with PRD-derived scenarios.
- **6V Scenario Matrix** (if exists): `./plancasting/_audits/visual-verification/feature-scenario-matrix.md` — reuse and filter to P0/P1 instead of regenerating. If this file doesn't exist, generate smoke scenarios from scratch using the guide.
- **Stage 6V Report**: `./plancasting/_audits/visual-verification/report.md` (baseline — what passed in dev)
- **Stage 6R Report** (if exists): `./plancasting/_audits/runtime-remediation/report.md` (fixes applied — must verify they survived deployment)
- **Stage 6P Report** (if exists): `./plancasting/_audits/visual-polish/report.md` (visual polish applied — verify enhancements survived deployment)
- **PRD**: `./plancasting/prd/` — read during scenario generation:
  - `02-feature-map-and-prioritization.md` — feature priorities and dependencies
  - `04-epics-and-user-stories.md` — acceptance criteria for P0/P1 features
  - `06-user-flows.md` — critical user flows
  - `07-information-architecture.md` — routes and auth requirements
  - `08-screen-specifications.md` — screen specs for critical pages
- **Tech Stack**: `./plancasting/tech-stack.md`
- **Project Rules**: `./CLAUDE.md`
- **E2E Config**: `./playwright.config.ts`
- **E2E Constants**: `./e2e/constants.ts`

**Language**: Check `./plancasting/tech-stack.md` for the `Session Language` setting. Generate all reports and user-facing output in the specified language. Code, technical identifiers, and file names remain in English.

## Prerequisites

**Pre-Check: 6P-R Branch Merge Verification**: If `./plancasting/_audits/visual-polish/design-plan.md` exists (indicating 6P-R was run), verify the `redesign/frontend-elevation` branch has been merged into main before proceeding with ANY smoke checks. If not merged, all subsequent checks would test a deployment without visual polish changes. Run: `git log --oneline main | head -20` and verify a merge commit or redesign commits are present.

1. **Stage 7 (Deployment) must be complete**: The application must be deployed to the production URL specified in `plancasting/tech-stack.md`. Do not start 7V until deployment has finished successfully.

2. **Production URL must be accessible**: Verify with a basic HTTP check: `curl -sI <production-url> | head -1` (expect HTTP 200 or 301/302). If the URL is unreachable, STOP and verify deployment status before proceeding.

3. **Stage 6V must be complete**: Stage 6V provides the baseline comparison for production verification. Its report (`./plancasting/_audits/visual-verification/report.md`) is required input — 7V compares production behavior against what passed in dev. If 6V was not run, 7V cannot detect deployment-specific regressions.

4. **Recommended sanity check**: If `./plancasting/_launch/readiness-report.md` exists, verify it shows READY. If it shows NOT READY, STOP — resolve pre-launch blockers first. If the file does not exist, proceed but note in the 7V report: "Stage 6H pre-launch verification was not completed." Also verify that either `./plancasting/_audits/visual-verification/report.md` or `./plancasting/_audits/visual-polish/report.md` exists. If neither exists, warn that pre-deployment verification may not have been completed — proceed with caution.

5. **Scenario generation file**: If the smoke test will generate scenarios from scratch (no 6V matrix exists), verify `./plancasting/transmute-framework/feature_scenario_generation.md` exists. If missing, copy from the template directory before proceeding (see execution-guide.md § "Pre-6V Setup" for copy instructions).

6. **Output directories**:
   ~~~bash
   mkdir -p ./plancasting/_audits/production-smoke
   mkdir -p ./screenshots/production
   ~~~
   Also verify `./screenshots/visual-verification/baseline/` exists if you plan to compare production screenshots against Stage 6V baseline screenshots (Check 9).

Stage 7V captures production smoke test screenshots to `./screenshots/production/`. Naming format: `[scenario-id]-[breakpoint].png` (e.g., `SS-001-desktop.png`, `SS-003-mobile.png`).

## Session Recovery

If the session disconnects mid-verification, start a new session and re-paste this prompt. The verification is idempotent — completed checks will be re-run but results will be consistent.

## Verification Checklist

This stage does NOT use agent teams — it is a single-agent sequential check. This stage should complete in 25–45 minutes (3–5 min scenario generation + 15–25 min core checks + 5–8 min for 6R/6P/navigation verification + 2–5 min performance/integrations). If the application has grown beyond what can be verified in 45 minutes (50+ pages, 10+ integrations — 'pages' = distinct routes in the application's routing config; 'integrations' = external services configured in `.env.local`), consider running a scoped Stage 6V (`critical` mode) against the production URL instead.

**Language**: Check `./plancasting/tech-stack.md` for the `Session Language` setting. Generate the report in the specified language. Code, URLs, and technical identifiers remain in English.

### Check 0. Generate Smoke Scenario Matrix (MUST run FIRST)

Before any verification, generate a targeted test plan for production smoke testing. This replaces the hardcoded page lists with dynamically generated scenarios based on YOUR project's actual features.

**If the 6V scenario matrix exists** (`./plancasting/_audits/visual-verification/feature-scenario-matrix.md`):
1. Read the 6V matrix
2. Filter to P0 Feature Scenarios (all) + P1 Feature Scenarios (top 5 by user impact scoring per `feature_scenario_generation.md` Step 9) — happy path only, no negative variants
3. Filter Auth Context Scenarios to: unauthenticated column + one authenticated role only
4. Skip Entity State and Role Permission scenarios (too detailed for smoke testing)
5. Result: ~10-15 scenarios

**If NO 6V scenario matrix exists** (first deployment, or 6V was skipped):
1. Read `./plancasting/transmute-framework/feature_scenario_generation.md` for the generation algorithm
2. Read PRD files: `prd/02-feature-map-and-prioritization.md` (feature priorities), `prd/06-user-flows.md` (critical flows), `prd/07-information-architecture.md` (routes + auth)
3. Scan codebase: route constants, middleware PUBLIC_ROUTES, page files
4. Generate Feature Scenarios for P0 + P1 features only:
   - One scenario per P0 user flow (happy path only)
   - One scenario per P1 user flow (happy path only)
   - Auth Context: all public routes + protected route redirect check
5. Result: ~10-15 scenarios

**If scenario generation fails** (PRD files missing or unreadable): Fall back to the hardcoded minimum flows in the "Critical User Flow Verification" section below (Check 8 of this document — not to be confused with pipeline Stage 8). Note the failure in the report.

This stage generates `./plancasting/_audits/production-smoke/smoke-scenario-matrix.md` — a lighter matrix than 6V's `feature-scenario-matrix.md`. Use only P0/P1 features + Auth Context scenarios. Do NOT use the 6V matrix as-is — filter it to P0/P1 smoke scenarios as described above.

**Save to** `./plancasting/_audits/production-smoke/smoke-scenario-matrix.md`:
~~~markdown
# Production Smoke Scenario Matrix
- **Generated**: [date]
- **Source**: 6V matrix (filtered) / generated from PRD
- **Production URL**: [url]

## Smoke Scenarios (P0 — must all pass)
| ID | Scenario | Source | Steps | Est. Time |
|----|----------|--------|-------|-----------|
| SS-001 | Signup → Onboarding → Dashboard | UF-001, FEAT-001 | 8 steps | 3 min |
| SS-002 | Project Creation → BP Upload | UF-002, FEAT-003/004 | 6 steps | 2 min |
| ... |

## Smoke Scenarios (P1 — should pass)
| ID | Scenario | Source | Steps | Est. Time |
| ... |

## Auth Context Checks
| Route | Unauthenticated Expected | Authenticated Expected |
| ... |

## Total: [n] scenarios, est. [n] minutes
~~~

**The remaining checklist checks (1-11) now execute the scenarios from this matrix rather than hardcoded page lists.** Check 4 (Critical Page Load) uses the Auth Context Checks. Checks 5-8 (6R Fix, 6P Visual Polish, Navigation, Critical Flows) use the Feature Scenarios. Infrastructure checks (Checks 1-3) remain unchanged.

### Check 1. Infrastructure Checks

Verify the production infrastructure is correctly configured:

**Primary approach** (if CLI tools are available):
~~~bash
# DNS resolves correctly
nslookup [production-domain]

# SSL certificate is valid and not expiring soon
echo | openssl s_client -servername [domain] -connect [domain]:443 2>/dev/null | openssl x509 -noout -dates

# Site responds with 200 and check security headers
curl -sI https://[domain] | head -20
~~~

**Fallback approach** (if CLI tools are unavailable in the execution environment):
~~~
Use Playwright browser tools to verify:
- Use `browser_navigate` to the production URL — if it loads, DNS and SSL are working
- Use `browser_evaluate` to inspect `window.location.protocol` — verify it starts with `https:`
- Use `browser_evaluate` to read security headers via `fetch(url, { method: 'HEAD' }).then(r => Object.fromEntries(r.headers))`
- Use `browser_console_messages` to check for CSP violations or blocked script errors
- Flag SSL/DNS details as "manual verification recommended" in the report
~~~

Checklist:
- Verify DNS resolves to the correct IP/CDN
- Verify SSL certificate is valid (not self-signed, not expired)
- Verify HTTPS redirect works (HTTP → HTTPS)
- Verify the response includes expected security headers (CSP, X-Frame-Options, etc.)

### Check 2. Environment Variable Spot-Check

**Early AI model validation**: Check all AI model IDs used in code (e.g., `claude-opus-5`, `gpt-4-turbo`) against the provider's documentation. Send a 1-token test request for each model to verify they exist and respond. If any model ID is invalid, flag as CRITICAL — all AI-powered features will fail.

Before testing pages, check for common env var issues:
- Navigate to the app and view page source or `__NEXT_DATA__` (for Next.js) — check that `NEXT_PUBLIC_*` values are present and not `"undefined"` or empty
- If the hosting platform CLI is available (e.g., `vercel env ls`, `netlify env:list`), cross-check against `.env.local.example`
- Check the browser console for errors like "API URL is undefined" or "Missing configuration" — these indicate missing env vars
- **Common miss**: BaaS URL (e.g., `NEXT_PUBLIC_CONVEX_URL`) is auto-set by the BaaS dev server in development but must be manually configured on the hosting platform. If this is missing, the frontend client constructor throws immediately and NO pages will render. Verify this env var FIRST — it blocks everything.
- **Auth provider URLs**: Auth callback URLs, JWKS endpoints, and OIDC discovery URLs must point to the production domain, not localhost. Check auth provider dashboard (WorkOS, Clerk, Auth0) to confirm redirect URIs include the production URL.
- **Environment variable naming consistency** (see Known Production Failure Pattern #1): Grep the codebase for all `process.env.*` reads of each critical secret (API keys, auth secrets). Verify every file uses the EXACT same variable name.
- **Backend deployment target verification (CRITICAL)** (see Known Production Failure Pattern #2): Verify the frontend's backend URL env var (e.g., `NEXT_PUBLIC_CONVEX_URL`) points to the PRODUCTION backend, not the dev backend. Cross-check: the URL in the env var should match the hosting platform's production deployment name.
- **Third-party service tier limits** (see Known Production Failure Pattern #5): For each external service used at runtime (E2B sandboxes, AI APIs, email providers), verify that configuration values (timeouts, batch sizes, rate limits) are within the service tier's actual limits.

### Check 3. Reuse Stage 6V Playwright Tests (if available)

If Stage 6V generated Playwright test files in `e2e/verification/`, run them against the production URL as a quick baseline:
~~~bash
BASE_URL=https://[production-domain] bunx playwright test e2e/verification/ --grep "@verification" --retries=0
~~~
Verify `playwright.config.ts` reads `BASE_URL` from environment (e.g., `use: { baseURL: process.env.BASE_URL || 'http://localhost:3000' }`). If it doesn't, configure it before running tests.

**Why `--retries=0`**: Retries are disabled in 7V because a scenario that passes on retry is classified as flaky, which is FAIL in production. Use the manual single-retest procedure from `feature_scenario_generation.md` to detect flakiness.

This gives fast, automated coverage of critical pages. **Important**: If any test requires a retry to pass (reported as 'flaky' in Playwright output), treat it as FAIL for gate purposes — production flakiness is unacceptable (see Critical Rule 7a). If tests pass cleanly (no retries), the manual checks below can focus on production-specific concerns (env vars, performance, third-party integrations). If no test files exist in `e2e/verification/` (6V was skipped or didn't generate them), skip this step and proceed with the manual checks below.

### Check 4. Critical Page Load Verification

Navigate to EACH of these pages on the production URL and verify they load:

**Public pages** — **CRITICAL**: Use a FRESH browser context (no cookies, no localStorage, no session tokens) for all unauthenticated route testing. Do NOT reuse a context that was previously authenticated. If using MCP browser tools: use `browser_close` to end any existing session, then `browser_navigate` to start fresh. If using Playwright tests: use `browser.newContext()` with no stored state. Do NOT merely "skip login" in the same context where you previously logged in — stale cookies or localStorage tokens may still grant access, masking middleware failures that affect real unauthenticated users.

- Landing/home page (`/`)
- Login page (`/login`)
- Signup page (`/signup`)
- Pricing page (`/pricing`, if applicable)
- Forgot password (`/forgot-password`)
- Legal pages (`/privacy`, `/terms`)
- Help pages (`/help`, `/help/troubleshoot`)
- **Utility routes** (most commonly blocked by middleware in production):
  - `/sitemap.xml` — verify returns valid XML, not a login redirect
  - `/robots.txt` — verify returns text content, not a login redirect
  - `/api/health` (if exists) — verify returns 200 JSON, not auth-blocked
  - `/.well-known/openid-configuration` (if exists) — verify returns OIDC discovery JSON
- **Verification method**: For EACH public page, check ALL THREE:
  1. HTTP response status is **200** (not 302 redirect to `/login`)
  2. Response body is the **expected page content** (not an HTML login page served with 200 status — some middleware configs serve the login page with 200 instead of redirecting)
  3. No auth-related console errors (`token undefined`, `session expired`, `unauthorized`)
- **Also verify protected route redirect**: Navigate to `/dashboard` and `/settings/profile` in the same unauthenticated context — verify they redirect to `/login?redirect=[path]` (not crash, not blank page, not redirect loop)
  Protected routes MUST redirect to `/login?redirect=[original-path]` (with the redirect query param). If a protected route redirects to `/login` without the redirect param, flag as MEDIUM severity (not critical, but poor UX — user loses their destination after login).
- If ANY public page redirects to login, this is a **CRITICAL** failure — the auth middleware is blocking public routes in production. Check: edge middleware cache, middleware deployment version, `PUBLIC_ROUTES` array contents in the deployed code. This affects ALL unauthenticated visitors including search engine crawlers and social media link previews.

**Authenticated pages** (log in as test user):
- **PREREQUISITE — Production test users (MUST complete before proceeding)**:
  Production test users MUST exist BEFORE running smoke tests. Unlike dev (where `globalSetup.ts` or CLI seeding can create them), production requires pre-provisioned accounts.

  1. **Verify**: Check whether production test users already exist by attempting to log in with credentials from `e2e/constants.ts` (look for a `PRODUCTION_TEST_USERS` section) or from the 7V report of a previous run.
  2. **If test users do NOT exist, create them** using one of these methods (in order of preference):
     a. Use the auth provider's admin API to create users directly (e.g., WorkOS User Management API, Clerk Backend API)
     b. If the app has a BaaS CLI that can target production (e.g., `bunx convex run --prod auth:signUp`), use it to create users through the same auth flow as the app
     c. Create dedicated smoke test accounts via the app's signup flow on production (use identifiable emails like `smoke-test-starter@[domain]`)
  3. **If test users cannot be created** (no admin access, no CLI access, signup disabled), ask the operator to create test accounts manually via the application's admin panel or auth provider dashboard. If all automated and manual methods fail, FAIL this stage with error: "BLOCKED: Cannot create production test users. Authenticated page verification requires test accounts. Contact infrastructure team to provision test users. Resolve access before re-running Stage 7V." Exit with status FAIL.
  4. **Document** which test accounts exist in `e2e/constants.ts` with a `PRODUCTION_TEST_USERS` section, and note them in the 7V report for future runs.
- Dashboard
- Main feature page (the core product page)
- Settings page
- Billing page (if applicable)

For each page:
- HTTP 200 response
- No console errors (use `browser_console_messages` to check after each page load)
- Page renders content (not blank white page)
- CSS loads correctly (not unstyled HTML)
- JavaScript executes (interactive elements work)
- Data loads from backend (not stuck on loading spinners)
- Take screenshot as evidence

### Check 5. Stage 6R Fix Verification (if 6R report exists)

If Stage 6R was run, verify its fixes in production. If 6R was skipped (6V returned PASS or CONDITIONAL PASS with only 6V-C issues), skip this verification.

If Stage 6R was run (`./plancasting/_audits/runtime-remediation/report.md` exists), verify that ALL auto-applied fixes survived the build and deployment pipeline. This catches cases where:
- The deployment was triggered from a commit before 6R fixes were applied
- Edge middleware caching serves a stale version that doesn't include the fixes
- Build-time optimizations (tree-shaking, CSS purging) removed fix artifacts

**How to verify**:
1. Read the 6R report (from `./plancasting/_audits/runtime-remediation/report.md`) "Auto-Fixed (6V-A)" and "Semi-Auto-Fixed (6V-B)" tables
2. For EACH fix listed as "Verified: PASS" in the 6R report, re-test the specific issue on production:

| Fix Type | Re-Test Method |
|---|---|
| Public route added to middleware whitelist | Navigate to the route without auth — must load, not redirect to `/login` |
| Dead link removed from layout | Navigate to the page that contained the link — verify the link is gone |
| Stub page created for missing route | Navigate to the route — must load the stub page content |
| Button handler wired | Navigate to the page, click the button — verify the action occurs |
| Loading state added | Navigate to the page — verify skeleton/spinner appears during load, not blank |
| i18n key added | Navigate to the page — verify translated text appears, not raw key string |
| Broken href fixed | Click the link — verify it navigates to the correct destination |

3. If ANY 6R fix is NOT present in production:
   - Flag as **CRITICAL** — the deployment doesn't include the remediation
   - Check: deployed commit hash vs. 6R report commit hash
   - Resolution: redeploy from the correct commit that includes 6R fixes

**Output**:
~~~
### 6R Fix Verification
- Total 6R fixes: [n]
- Verified in production: [n]
- Missing in production: [n] — [list with fix # and description]
- Deployment commit matches 6R: YES / NO (deployed: [hash], 6R: [hash])
~~~

### Check 6. Stage 6P / 6P-R Visual Polish Verification (if 6P or 6P-R report exists)

If Stage 6P was run (`./plancasting/_audits/visual-polish/report.md` exists) or Stage 6P-R was run (`./plancasting/_audits/visual-polish/redesign-report.md` exists), spot-check that visual polish enhancements survived the production build.

**6P-R branch merge check**: If 6P-R was used (check for `./plancasting/_audits/visual-polish/design-plan.md` — only 6P-R creates this file), verify that the `redesign/frontend-elevation` branch was merged to main before deployment. Run `git log --oneline -5` and confirm the merge commit is present. If the branch was NOT merged, all 6P-R visual changes will be missing from production — flag as **CRITICAL** and abort the rest of 7V until the branch is merged and redeployed.

This catches:
- CSS purging removing enhancement classes (transitions, shadows, hover states)
- Font imports failing in production (CDN blocked, CORS, missing preload)
- Animation libraries not included in the production bundle (tree-shaking)

**How to verify** (quick visual spot-check — 3-5 minutes max):
1. Read the 6P report's "Category O Fixes Applied" and "Category E Enhancements Applied" tables
2. Pick the TOP 3 most impactful changes (e.g., contrast fix on dashboard, hover transitions on buttons, typography hierarchy on landing page)
3. For each: navigate to the affected page on production, take a screenshot, compare with the 6P "after" screenshot

| Check | Method | Pass Criteria |
|---|---|---|
| Contrast fixes visible | Compare text colors against 6P report values | Text has the corrected color, not the original low-contrast color |
| Hover transitions working | Hover over buttons/links | Smooth color/shadow transition occurs (not instant snap) |
| Typography hierarchy intact | Visual inspection of headings vs body | Heading sizes/weights match 6P report, not flat hierarchy |
| Dark mode enhancements | Toggle dark mode (if applicable) | Dark mode fixes from 6P are present |

If visual polish changes are MISSING in production, flag as **MEDIUM** (not CRITICAL — the app is functional, just less polished). Check: CSS purge config, font import tags in `<head>`, animation library in production bundle.

**Output**:
~~~
### 6P Visual Polish Verification
- Total 6P changes: [n]
- Spot-checked: [n]
- Present in production: [n]
- Missing in production: [n] — [list]
- Impact: LOW / MEDIUM (functional app, visual regression only)
~~~

### Check 7. Navigation Smoke Test

Test that navigation paths work on production. This catches CSS purge issues (nav links invisible), edge middleware blocking (redirects), and deployment-specific routing failures.

**This is NOT a comprehensive navigation crawl (that's 6V's job). Test only the highest-traffic navigation paths — ~5 minutes max.**

#### 7a. Shared Layout Navigation (Desktop)
While logged in, from the dashboard:
- Click EACH link in the **sidebar/main navigation** — verify each destination loads
- Click EACH link in the **footer** (if visible) — verify each destination loads
- Click the **logo/home link** — verify it navigates to the expected page
- Click a **breadcrumb link** (if visible) — verify it navigates correctly

#### 7b. Shared Layout Navigation (Mobile)
Resize viewport to mobile (375px width):
- Open the **hamburger menu / mobile menu** — verify it appears
- Click EACH link in the mobile menu — verify each destination loads
- If there's a **mobile bottom navigation bar** — click each icon and verify navigation
- Verify the mobile menu **closes** after clicking a link (not stuck open)

#### 7c. Key Sub-Navigation
Test ONE instance of each major tabbed navigation:
- **Settings**: Click 3 different settings tabs — verify each loads content
- **Project detail** (if applicable): Click 3 different project tabs — verify each loads
- **Any other tabbed layout**: Click 2-3 tabs — verify content switches

#### 7d. CSS Purge Check for Navigation
Visually inspect the navigation components for styling issues:
- Are sidebar links **visible** with correct text and icons? (CSS purge can hide them)
- Do **active state** indicators work? (Navigate between pages — does the active link change?)
- Are **hover/focus** states visible? (Hover over links — does the cursor/color change?)
- On mobile: are **touch targets** adequate size? (Not tiny/clipped due to purge)

If navigation links are invisible or unstyled, flag as **CRITICAL** — this is likely Tailwind CSS purging dynamic classes in the production build.

**Output**:
~~~
### Navigation Smoke Test
- Desktop sidebar links: [n] tested, [n] working, [n] broken
- Footer links: [n] tested, [n] working, [n] broken
- Mobile nav links: [n] tested, [n] working, [n] broken
- Sub-navigation tabs: [n] tested, [n] working, [n] broken
- CSS styling intact: YES / NO ([details])
- Issues: [list any broken links, invisible elements, or styling failures]
~~~

### Check 8. Critical User Flow Verification (Scenario-Driven)

Execute the P0 Feature Scenarios from the smoke scenario matrix (Check 0). These are dynamically generated based on YOUR project's actual features, not hardcoded generic flows.

**Execution order**: Follow the Feature Dependency Graph from the scenario matrix — P0 scenarios first, then P1. If a P0 scenario fails, mark dependent scenarios as BLOCKED. For 7V, block only immediate dependents (not transitive) per `feature_scenario_generation.md` Execution Rule 1 exception.

For each Feature Scenario (SS-NNN):
1. Check prerequisites listed in the scenario (entity states, auth context)
2. Execute EACH step in order on the PRODUCTION URL
3. At each step: verify the expected result matches the actual result
4. If a step fails: screenshot, record the error, mark remaining steps as BLOCKED
5. Map results back to the scenario's acceptance criteria references

**Fallback** (if no smoke scenario matrix was generated): Execute these minimum flows:

**Flow 1: Authentication**
- Sign up with a new test account (or log in with existing)
- Verify session persists (navigate to protected page)
- Log out and verify redirect to login

**Flow 2: Core Feature**
- Navigate to the main feature
- Perform the primary action (create/submit/run whatever the product's core action is)
- Verify the result is saved/displayed

**Flow 3: Settings/Account**
- Navigate to settings
- Verify user profile data loads
- Verify organization data loads (if multi-tenant)

For each flow/scenario:
- Flow completes without errors
- Data persists correctly
- Failure point and error details (if failed)

### Check 9. AI Vision Spot-Check

Take screenshots of the 5 most important pages and compare against Stage 6V screenshots:
- Are there visual differences between dev and production?
- Are all assets loading (images, icons, fonts)?
- Is the layout consistent (no CSS differences due to missing Tailwind classes or purge issues)?

### Check 10. Performance Spot-Check

For the landing page and dashboard:
- **TTFB**: Measure via `curl -o /dev/null -w "%{time_starttransfer}" https://[domain]` (if CLI available), or use `browser_evaluate` with `const nav = performance.getEntriesByType('navigation')[0]; const ttfb = nav.responseStart - nav.requestStart;`
- **LCP**: Use `browser_evaluate` with PerformanceObserver (`new PerformanceObserver(...)` to read `largest-contentful-paint` entries), or run `bunx lighthouse [url] --only-categories=performance --output=json` if CLI is available
- Flag if significantly slower than dev (>2x)
- Check for any failed network requests using `browser_network_requests` or `browser_console_messages`

### Check 11. Third-Party Integration Verification

Check each external service connection:
- **Auth provider**: Can users log in? (Already tested in Flow 1)
- **Database/BaaS**: Does data load? (Already tested in Flow 2)
- **Payment provider**: Does the billing page load pricing? (No need to complete payment)
- **Email service**: Trigger a test email if possible (password reset, welcome email)
- **Analytics**: Verify tracking script loads (check network tab for analytics requests)
- **Error monitoring**: Verify error monitoring is configured by checking the monitoring service's project settings or API (e.g., Sentry project exists and has the correct DSN). Do NOT trigger deliberate errors in production — they pollute monitoring data and may trigger on-call alerts
- **Webhook endpoints**: If webhook URLs are configured (Stripe, auth provider), verify they return 200 for health checks. Check the provider dashboard for recent delivery status if accessible.
- **Real-time/WebSocket**: If the app uses a real-time backend (Convex, Supabase Realtime, Firebase), verify WebSocket connections establish successfully — check browser console for WebSocket errors and verify live data updates appear.

#### 11.1 AI Model ID Verification (CRITICAL — MUST COMPLETE FIRST)

Before running general API health checks, explicitly verify AI model IDs used in the codebase:
1. Search the codebase for all AI model references (replace `[backend-dir]` with your actual backend directory from `plancasting/tech-stack.md`, e.g., `convex/`): `grep -rE 'claude-|gpt-|gemini-' [backend-dir]/ --include='*.ts' --include='*.js' | grep -v node_modules | grep -v test`
2. For each unique model ID found, send a minimal test request (1-token prompt) to verify the model exists
3. If any model returns 400 "invalid model" or 404, flag as **CRITICAL** — the model ID is likely hallucinated by a Stage 5 agent
4. Common hallucinated patterns: wrong date suffixes, non-existent model tiers, outdated model names. Note: Model IDs change over time — always verify against the provider's current model documentation (e.g., console.anthropic.com/docs for Anthropic, platform.openai.com/docs for OpenAI) rather than relying on hardcoded examples.

#### 11.2 External API Health Check (CRITICAL for AI-powered features)

> **Cost warning**: These checks make real API calls against production keys. Use minimal requests (1-token completions, smallest possible payloads) to keep costs negligible. Do NOT run large completions, batch operations, or load tests. Each check should cost fractions of a cent.

For each action that calls an external API (Anthropic/Claude, Stripe, GitHub, WorkOS, etc.):
1. Verify the API key env var is set and non-empty in the production environment
2. Send a minimal test request (e.g., a 1-token completion for Anthropic, a test mode charge for Stripe)
3. Verify the response is 2xx — not 400 (bad model ID), 401 (bad key), or 404 (bad endpoint)
4. If any API returns an error, log the full response status and body, flag as CRITICAL

**Why this matters**: See Check 11.1 above for common model ID hallucination patterns. Stage 5 teammates may also use invented API endpoints. These pass all test stages because unit tests skip external API calls and E2E tests may not have API keys configured. The invalid configuration only fails when a real user triggers the feature in production.

**Common API failures**:
- AI model ID doesn't exist → Anthropic returns 400/404, feature shows generic error
- API key is a placeholder → 401 Unauthorized
- API version header outdated → unexpected response format
- Error handler swallows the response without logging → no server-side visibility into the failure

Concrete verification examples (adapt to your stack):
- **Anthropic**: `messages.create({ model: "<model-id-from-codebase>", max_tokens: 10, messages: [{ role: "user", content: "Say OK" }] })` — use the actual model ID found in the production code (search for `model:` in backend files). Verify 200 response, not 400 "invalid model"
- **Stripe**: **IMPORTANT**: Verify the Stripe API key starts with `sk_test_` (test mode). NEVER create charges with a `sk_live_` key during smoke testing. Test-mode API key → `stripe.charges.create({ amount: 100, currency: 'usd', source: 'tok_visa' })` — verify charge succeeds
- **Auth provider**: GET user list endpoint with production API key — verify 200, not 401

#### 11.3 OAuth Integration Health Check (CRITICAL for multi-service connections)

OAuth flows span multiple domains (your app → provider → your app) and are **invisible to all test layers** — unit tests skip external calls, E2E tests can't follow cross-domain redirects.

For each OAuth integration (GitHub, Vercel, Google, etc.):
1. Verify all required env vars exist and are non-empty: `*_CLIENT_ID`, `*_CLIENT_SECRET`
2. Verify the `redirect_uri` sent during authorization **exactly matches** the URI used in the callback handler code — even a trailing `/callback` suffix mismatch causes GitHub to reject the request
3. Verify the `redirect_uri` is registered in the OAuth provider's app settings (GitHub → Settings → Developer Settings → OAuth Apps → Authorization callback URL)
4. Click the "Connect" button in the UI and verify the provider's authorization page loads correctly (not a 404, not a "redirect_uri mismatch" error)
5. If possible, complete the full OAuth round-trip with a test account

**Common OAuth failures**:
- `redirect_uri` constructed differently in init vs callback code → provider rejects with "not associated"
- OAuth `CLIENT_ID` env var missing → authorization URL is malformed → provider returns 404
- OAuth provider requires app registration that was never completed (e.g., Vercel Integration)
- OAuth callback route doesn't exist in the app → user returns to a 404 after authorizing

## Report

Generate `./plancasting/_audits/production-smoke/report.md`:

~~~markdown
# Production Smoke Verification Report — Stage 7V

## Summary
- **Verification Date**: [date]
- **Production URL**: [url]
- **Deployment Commit**: [git hash]
- **Hosting Platform**: [e.g., Vercel]
- **Backend Deployment**: [e.g., Convex production-instance-name]
- **Region**: [e.g., iad1 / us-east-1]

## Infrastructure
- DNS: PASS / FAIL
- SSL: PASS / FAIL (expires: [date])
- HTTPS Redirect: PASS / FAIL
- Security Headers: PASS / FAIL
- Environment Variables: PASS / FAIL / WARN ([details])

## Page Load Results
| Page | Status | Console Errors | Renders | CSS | JS | Data |
|------|--------|---------------|---------|-----|-----|------|
| Landing | PASS/FAIL | PASS/FAIL | PASS/FAIL | PASS/FAIL | PASS/FAIL | PASS/FAIL |
| Login | ... | ... | ... | ... | ... | ... |
| Dashboard | ... | ... | ... | ... | ... | ... |
| [etc] | ... | ... | ... | ... | ... | ... |

## Unauthenticated Public Route Access (tested in fresh context, no auth)
| Route | Expected | HTTP Status | Body Check | Console Errors | Status |
|-------|----------|------------|------------|----------------|--------|
| / | Landing page | ... | ... | ... | PASS/FAIL |
| /login | Login form | ... | ... | ... | PASS/FAIL |
| /signup | Signup form | ... | ... | ... | PASS/FAIL |
| /pricing | Pricing content | ... | ... | ... | PASS/FAIL |
| /privacy | Privacy policy | ... | ... | ... | PASS/FAIL |
| /terms | Terms of service | ... | ... | ... | PASS/FAIL |
| /help | Help center | ... | ... | ... | PASS/FAIL |
| /forgot-password | Reset form | ... | ... | ... | PASS/FAIL |
| /sitemap.xml | Valid XML | ... | ... | ... | PASS/FAIL |
| /robots.txt | Text rules | ... | ... | ... | PASS/FAIL |
| /api/health | JSON 200 | ... | ... | ... | PASS/FAIL |

## Protected Route Redirect (tested in fresh context, no auth)
| Route | Expected | Actual | Redirect Loop | Status |
|-------|----------|--------|--------------|--------|
| /dashboard | 302 → /login?redirect=/dashboard | ... | No | PASS/FAIL |
| /settings/profile | 302 → /login?redirect=... | ... | No | PASS/FAIL |

## 6R Fix Verification (if applicable)
- Total 6R fixes: [n]
- Verified in production: [n]
- Missing in production: [n] — [list]
- Deployment commit matches 6R: YES / NO

## 6P Visual Polish Verification (if applicable)
- Total 6P changes: [n]
- Spot-checked: [n]
- Present in production: [n]
- Missing in production: [n] — [list]

## Navigation Smoke Test
| Area | Links Tested | Working | Broken | Issues |
|------|-------------|---------|--------|--------|
| Desktop sidebar | [n] | [n] | [n] | [list] |
| Footer | [n] | [n] | [n] | [list] |
| Mobile nav | [n] | [n] | [n] | [list] |
| Sub-nav tabs | [n] | [n] | [n] | [list] |
| CSS styling | — | — | — | Intact / [issues] |

## Smoke Scenario Results (Dynamically Generated)
- Scenarios generated: [n] (P0: [n], P1: [n])
- Source: 6V matrix (filtered) / generated from PRD
| Scenario ID | Name | Priority | Steps | Passed Steps | Result | Failure Point | Error |
|-------------|------|----------|-------|-------------|--------|--------------|-------|
| SS-001 | [name] | P0 | [n] | [n]/[n] | PASS/FAIL/BLOCKED | [step] | [error] |
| SS-002 | [name] | P0 | [n] | [n]/[n] | PASS/FAIL/BLOCKED | [step] | [error] |
| ... |

## Critical Flow Results (Fallback — only if no scenario matrix)
**Include this section ONLY if no scenario matrix was generated in the section above.**
| Flow | Result | Failure Point | Error Details |
|------|--------|--------------|---------------|
| Authentication | PASS/FAIL | [step] | [error] |
| Core Feature | PASS/FAIL | [step] | [error] |
| Settings | PASS/FAIL | [step] | [error] |

## Visual Comparison (Dev vs Production)
- [Any visual differences noted]

## Performance
| Page | TTFB | LCP | vs Dev |
|------|------|-----|--------|
| Landing | [ms] | [ms] | [comparison] |
| Dashboard | [ms] | [ms] | [comparison] |

## Third-Party Integrations
| Service | Status | Notes |
|---------|--------|-------|
| Auth | PASS/FAIL | |
| Database | PASS/FAIL | |
| Payments | PASS/FAIL | |
| Email | PASS/FAIL | |
| Analytics | PASS/FAIL | |
| Error Monitoring | PASS/FAIL | |
| Webhooks | PASS/FAIL | |
| AI Models | PASS/FAIL | |
| OAuth | PASS/FAIL | |

## Gate Decision
- **PASS**: All critical flows work, all pages load, no console errors, all external APIs respond 2xx
- **CONDITIONAL PASS**: All P0 critical flows pass (happy paths complete), all pages load, but minor non-blocking issues exist in P0/P1 features (e.g., non-critical integration timeout, minor visual discrepancy from 6V baseline). Document issues for post-launch fix. Stage 7D and Stage 8 can proceed.
- **FAIL**: Any critical flow broken OR pages don't load OR critical navigation failure (invisible/unstyled links) OR external API health check fails — immediate action required (see Rollback Guidance)

Note: Stage 7V uses the universal three-outcome gate system: PASS, CONDITIONAL PASS, FAIL. CONDITIONAL PASS handles minor P1 issues that do not block downstream stages (P2 features are out of 7V's SMOKE scope). **FAIL triggers**: critical infrastructure broken, critical user flows broken, critical navigation invisible/unstyled, external API health checks fail, or 6R fixes missing from deployment. **Does NOT trigger FAIL**: non-critical visual issues (missing 6P enhancements, minor layout differences from dev), non-functional performance metrics below target. Non-critical issues are documented in the report but do NOT affect the gate decision — address them through Stage 8 (Feedback Loop).

**Flaky handling (7V vs 6V)**: In 6V, flaky scenarios are excluded from the pass-rate denominator. In 7V, flaky scenarios count as FAIL — see the Flaky Scenario Rule above.

**Critical Production Failures**: If 7V result is FAIL (critical functionality broken in production), do NOT proceed to Stage 7D. Halt and escalate for hotfix + re-deploy or rollback. Only proceed to Stage 7D after 7V achieves PASS or CONDITIONAL PASS. After hotfix is deployed, re-run Stage 7V in full to verify the fix. If 7V PASS or CONDITIONAL PASS, continue to Stage 7D. Do NOT proceed to 7D based on partial re-verification — 7V must produce a full report.

## Next Steps
- If PASS or CONDITIONAL PASS: proceed to Stage 7D (User Guide Generation) — if `plancasting/tech-stack.md` documentation section says "not needed," skip 7D and move to Stage 8 (Feedback Loop) / 9 (Maintenance). If CONDITIONAL PASS, document minor issues for post-launch fix via Stage 8.
- If FAIL due to deployment config (env vars, DNS, CORS): fix config, redeploy, re-run 7V
- If FAIL due to code regression (something that passed in 6V but fails in production): rollback deployment (`git revert`, not `git reset --hard`), investigate the discrepancy, fix, redeploy, re-run 7V. Do NOT proceed to 7D until 7V achieves PASS or CONDITIONAL PASS — documenting a broken product wastes effort

**FAIL decision tree**: (1) If issue is localized (1–2 files, <100 LOC fix): hotfix in code, re-deploy, re-run 7V. (2) If issue affects multiple systems or requires >2 hours to fix: execute rollback (`git revert HEAD`), verify reverted deploy is stable, investigate offline. Schedule follow-up implementation session.

**Session recovery**: If Stage 7V is interrupted mid-execution, check if `./plancasting/_audits/production-smoke/report.md` exists with a `## Gate Decision` heading. If complete, the stage finished — no re-run needed. If missing or incomplete, re-run the full prompt in a new session. 7V is idempotent — re-running against the same production URL is safe.

## Issues Found
[Detailed list of any issues with severity and recommended action]

## Screenshots
[Reference to screenshot files in ./screenshots/production/]
~~~

## Rollback Guidance

If a critical failure is found:

1. **Determine if it's configuration-only** (env var, DNS, CDN cache):
   - Fix the configuration directly on the hosting platform
   - Re-run the failing checks to verify the fix
   - No code rollback needed

2. **If it's a code regression** (something that passed in 6V but fails in production):
   - **Vercel**: `bunx vercel rollback` or redeploy the previous known-good commit
   - **Convex**: Redeploy the previous known-good backend version
   - **Other hosts**: Use the hosting platform's rollback mechanism or `git revert` + redeploy
   - Document the rollback in the report

3. **After rollback or fix**:
   - Re-run this smoke check against the corrected deployment
   - Document the root cause for future prevention (add to Stage 6H checklist if it's a recurring pattern)

## Test Account Cleanup

**Production data hygiene**: Minimize test data in production. Use clearly identifiable names (e.g., `smoke-test-YYYY-MM-DD-xxxxx`). Clean up immediately after verification.

After verification completes:
- Delete or deactivate any test accounts/organizations created during the smoke test
- If the app uses soft delete, mark test entities with `deletedAt` immediately. Note: soft-deleted records remain in the database for a retention period before permanent deletion. Check `plancasting/tech-stack.md` § Soft Delete Policy for the retention period, or CLAUDE.md Part 2 § Architecture if tech-stack.md does not define it. Ensure smoke test records don't pollute analytics during this window.
- If cleanup is not possible without admin access, document the test account details for manual cleanup

**Cleanup scope**: Only clean up accounts created DURING THIS 7V run. To distinguish: check the account creation timestamp against the 7V start time, or use identifiable naming patterns (e.g., `smoke-test-YYYY-MM-DD-HHMMSS@domain`). Pre-existing test accounts (from previous 7V runs or manual creation) should be preserved unless explicitly requested by the operator — they may be needed for future 7V runs.

## Shutdown & Cleanup

After verification completes (regardless of gate decision):

1. **Close browser session**: Use `browser_close` to end the Playwright browser session cleanly.
2. **Clean up test accounts**: Follow the Test Account Cleanup protocol above.
3. **Save the report**: Verify `./plancasting/_audits/production-smoke/report.md` is saved.
4. **Commit verification artifacts**: `git add plancasting/_audits/production-smoke/ screenshots/production/ && git commit -m 'chore(7v): complete Stage 7V production smoke verification'`.

## Critical Rules

1. ALWAYS use the PRODUCTION URL — never accidentally test against localhost.
2. NEVER modify production data beyond what's needed for testing (use test accounts with identifiable names like `smoke-test@[domain]`).
3. NEVER test payment flows with real payment methods — use test card numbers or skip the actual charge step.
4. Use clearly identifiable test accounts (e.g., `smoke-test-*@domain`) that cannot be confused with real users. See Check 4 for the test user creation protocol.
5. If ANY critical flow fails, follow the Rollback Guidance above. Do NOT mark as "known issue for later."
6. Keep this stage FAST — 25–45 minutes max. This is smoke testing, not comprehensive regression. The navigation smoke test (Check 7) should take ~5 minutes — test highest-traffic paths only, not every link.
7. ALWAYS compare against Stage 6V results — if something passed in 6V but fails in 7V, it's a deployment-specific issue (environment, config, infrastructure).
7a. **Flaky scenarios**: See the Flaky Scenario Rule at the top of this prompt. Do NOT mark a scenario as passing if it required a retry. Document the flaky behavior in the report.
8. ALWAYS clean up test accounts after verification to avoid polluting production data and analytics.
9. ALWAYS verify test user login works BEFORE proceeding to authenticated page checks. If login fails, check: auth provider redirect URIs include production domain, auth env vars point to production (not dev), test users exist in the auth provider (not just the app database).
10. ALWAYS test public utility routes (`/sitemap.xml`, `/robots.txt`, `/api/health`) WITHOUT authentication. These are the most commonly broken routes in production because they're easy to forget when configuring middleware whitelists.
11. If a Stage 6R report exists, ALWAYS verify 6R fixes in production BEFORE detailed feature/navigation checks (Checks 7-8). Check 4 (page loads) is a prerequisite that must run first. If 6R fixes are missing, the deployment is wrong — flag immediately rather than discovering the same issues again through later checks. If 6R was skipped (6V returned PASS or CONDITIONAL PASS with only 6V-C issues), skip this check.
12. ALWAYS test navigation at BOTH desktop and mobile viewports on production. CSS purging affects production builds differently than dev — navigation links that are visible in dev may be invisible in production due to dynamic Tailwind class purging.
13. If a Stage 6R report exists, ALWAYS check the deployed commit hash against the 6R remediation commit hash (stored in `./plancasting/_audits/runtime-remediation/last-remediated-commit.txt` and in the 6R report's `Commit Hash` field). If they don't match, the production deployment doesn't include the remediation fixes. If 6R was skipped (6V returned PASS or CONDITIONAL PASS with only 6V-C issues, so no report exists), skip this check.
14. If a Stage 6P report exists, spot-check visual polish changes in production. CSS purging, font loading, and tree-shaking can silently remove visual enhancements that work in dev. These are MEDIUM severity (not blocking) but should be documented.
15. NEVER modify application code, production configuration, or database records during this stage (except for creating/cleaning up test accounts as documented). This stage is verification-only. If issues are found, document them in the report for the Rollback Guidance procedure.

## Failure Escalation Protocol

If 7V detects a critical production failure:

| Failure Type | Action |
|---|---|
| Auth completely broken (login 500s) | Rollback deployment immediately. Document in `./plancasting/_audits/production-smoke/rollback-log.md` |
| Core data query empty (DB inaccessible) | Check backend deployment status. Rollback if backend deployed successfully but data is inaccessible |
| SSR hydration errors on landing page | Check Tailwind CSS purging. Hotfix if CSS issue, rollback if structural |
| 3rd-party integration failure (Stripe, Auth0) | Do NOT rollback. Escalate to operator to verify API keys and service status |

**Agent Abort Procedure** (for Tier 1 failures — Auth broken, DB inaccessible, landing page non-functional):
1. Stop all further verification checks.
2. Do NOT attempt fixes — 7V is verification-only.
3. Output partial report with gate decision FAIL and escalation details.
4. Recommend rollback or hotfix + re-deploy + re-run 7V.
5. Do NOT proceed to Stage 7D.
````
