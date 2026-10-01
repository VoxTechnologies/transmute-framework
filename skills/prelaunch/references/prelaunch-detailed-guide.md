# Transmute — Pre-Launch Verification

## Stage 6H: Final Check Before Production Deployment

````text
You are a senior release manager acting as the TEAM LEAD for a multi-agent pre-launch verification project using Claude Code Agent Teams. Your task is to perform a comprehensive final check of the COMPLETE product before it goes live in production. This is the last gate between development and real users.

**Stage Sequence**: Stage 5B → 6A/6B/6C (parallel) → 6E → 6F → 6G → 6D (Documentation) → **6H (this stage)** → 6V (Verification) → [6R (Remediation) — only if 6V finds 6V-A/B issues] → 6P or 6P-R (Visual Polish) → 7 (Deploy) → 7V (Production Smoke) → 7D (User Guide) → 8 (Feedback) / 9 (Maintenance)

## Context

This prompt runs AFTER all Stage 6 audits (6A Security, 6B Accessibility, 6C Performance, 6E Refactoring, 6F Seed Data, 6G Resilience, 6D Documentation) have completed. It is the final verification that everything is correctly configured, all tests pass, all documentation is in place, and the product is truly ready for production.

## Prerequisites

Before beginning:
1. Verify `./plancasting/_audits/implementation-completeness/report.md` exists and shows a PASS or CONDITIONAL PASS gate decision. If the file does not exist, STOP — Stage 5B is a prerequisite gate for all Stage 6 work. Do not proceed until 5B has been run and produced a report. (These checks are re-verified in Phase 1 for session resumption safety.)
2. **5B Gate Decision**:
   - **PASS**: Proceed to 6H verification
   - **CONDITIONAL PASS**: Proceed only if each remaining issue has a documented workaround or explicit deferral decision (see execution-guide.md § "Gate Decision Outcomes" for canonical 5B CONDITIONAL PASS criteria — multiple valid paths exist based on A/B and C issue counts)
   - **FAIL-RETRY**: STOP — resolve 5B issues and re-run 5B before proceeding to 6H (see execution-guide.md § "Gate Decision Outcomes" for definitions)
   - **FAIL-ESCALATE**: STOP — escalate to operator; do not proceed until 5B achieves PASS or CONDITIONAL PASS
3. Verify all Stage 6 audit reports exist:
   - `./plancasting/_audits/security/report.md` (6A)
   - `./plancasting/_audits/accessibility/report.md` (6B)
   - `./plancasting/_audits/performance/report.md` (6C)
   - `./plancasting/_audits/documentation/report.md` and `./docs/` (6D) — Stage 6D always runs for software products; skip only for non-software product types (e.g., pure hardware) where no codebase documentation applies
   - `./plancasting/_audits/refactoring/report.md` (6E)
   - `./seed/README.md` and `./plancasting/_audits/seed-data/report.md` (6F) — skip if `plancasting/tech-stack.md` indicates seed data generation was not applicable (adapt seed directory path per tech-stack.md if your project uses a different seed data location)
   - `./plancasting/_audits/resilience/report.md` (6G)
   If both 6D and 6F were skipped per `tech-stack.md`, instruct Teammate 3 to note this in findings — do not flag missing docs/seed-data as launch blockers when the tech stack explicitly excludes them.
   For any missing report (except 6D or 6F if skipped per tech-stack.md), STOP — the prerequisite stage was not completed.
   For each existing report, read its `## Gate Decision` heading (case-sensitive, h2 level) and extract the outcome (PASS / CONDITIONAL PASS / FAIL). If any report is missing this heading, STOP — re-run that audit stage with instructions to include the `## Gate Decision` section. If any Stage 6 audit report shows FAIL, STOP — that audit must be resolved before pre-launch verification. If CONDITIONAL PASS, evaluate each documented condition: documented workarounds that don't block core functionality → acceptable for launch; unresolved blockers awaiting human decision → NOT READY unless operator explicitly accepts risk (see execution-guide.md § "Gate Decision Outcomes (Universal)").
4. Check for unfixable violation files from prior stages (if they exist — not all audit stages produce these files): `./plancasting/_audits/security/unfixable-violations.md`, `./plancasting/_audits/accessibility/unfixable-violations.md`, `./plancasting/_audits/performance/unfixable-violations.md`, `./plancasting/_audits/refactoring/unfixable-violations.md`, `./plancasting/_audits/resilience/unfixable-violations.md`, `./plancasting/_audits/documentation/unfixable-violations.md`, `./plancasting/_audits/seed-data/unfixable-violations.md`. If any exist, read them and treat CRITICAL items as launch blockers — the readiness report must flag them. If a file does not exist, that audit stage had no unfixable violations — skip it.
5. Read `./CLAUDE.md` and `./plancasting/tech-stack.md` for project conventions
6. Read the relevant PRD sections for context on what was implemented

## Input

- **Codebase**: Complete project directory
- **Tech Stack**: `./plancasting/tech-stack.md`
- **PRD**: `./plancasting/prd/` (especially non-functional specs, operational readiness)
- **BRD**: `./plancasting/brd/` (compliance and security requirements)
- **Project Rules**: `./CLAUDE.md`
- **Audit Reports**: `./plancasting/_audits/` (security, accessibility, performance, refactoring, resilience, seed-data) and `./docs/` for documentation (Stage 6D) and `./seed/README.md` for seed data verification
- **Implementation Report**: `./plancasting/_audits/implementation-completeness/report.md`
- **Environment Config**: `.env.local`, `.env.local.example`

**Language**: Check `./plancasting/tech-stack.md` for the `Session Language` setting. Generate all reports and user-facing output in the specified language. Code, technical identifiers, and file names remain in English.

## Stack Adaptation

The examples in this prompt use Next.js + Convex + Vercel as the reference architecture. **Your project may use a completely different stack.** Always read `plancasting/tech-stack.md` and `CLAUDE.md` to determine your actual stack, then adapt all references accordingly:

| This prompt says | Adapt to your stack |
|---|---|
| `next.config.ts` | Your framework's config file (e.g., `vite.config.ts`, `svelte.config.js`, `remix.config.ts`) |
| `npx convex deploy` | Your backend deployment command (e.g., `supabase db push`, `firebase deploy`, `prisma migrate deploy`) |
| `npx vercel env ls` | Your hosting platform's env var command (e.g., `netlify env:list`, `railway variables`, `flyctl secrets list`) |
| `bun run` | Your package manager command (e.g., `npm run`, `pnpm run`, `yarn`) |
| `NEXT_PUBLIC_*` env vars | Your framework's client-exposed prefix (e.g., `VITE_*`, `PUBLIC_*`, `EXPO_PUBLIC_*`) |
| Convex deployment config | Your backend deployment configuration (e.g., Supabase project settings, Firebase project config) |
| Convex WebSocket | Your backend's real-time connection (e.g., Supabase Realtime, Firebase listeners, WebSocket server) |

Sections marked with **"If using [technology]:"** are conditional — skip them if your stack does not include that technology.

## Known Failure Patterns

These patterns have caused production failures in previous Plan Casts. ALL teammates should be aware of them. Some are framework-specific — check your `plancasting/tech-stack.md` and skip patterns that do not apply.

**General (all stacks):**

1. **Missing hosting env vars**: Client-exposed backend URL env vars (e.g., `NEXT_PUBLIC_CONVEX_URL` for Next.js, `VITE_API_URL` for Vite) are often auto-set by the dev server but NOT present in `.env.local` — missing from the hosting platform causes blank pages or runtime errors.
2. **Dark mode border contrast**: Secondary/outline button variants using `border-primary-*` produce harsh bright borders in dark mode. Should use `border-border` neutral token.

**If using Next.js:**

3. **CSP blocks Next.js**: `script-src 'strict-dynamic'` without nonce-based CSP blocks ALL `/_next/static/` script loading, causing a blank page.
4. **i18n alias misconfiguration**: i18n plugin's Turbopack alias set but webpack alias missing (or vice versa), causing SSR crashes in production but not in dev.

**If using Tailwind CSS v4:**

5. **Tailwind v4 silent failure**: Missing `@config "../../tailwind.config.ts"` after `@import "tailwindcss"` causes the entire JS config to be ignored — zero CSS output, completely unstyled UI, no build error.
6. **Tailwind v4 semantic tokens**: `border-border` looks up `colors.border` in v4, not `borderColor.DEFAULT`. Missing entries cause white borders (browser default) with no build error.

## Output

Stage 6H generates:
- `./plancasting/_launch/checklist.md` — comprehensive pre-launch checklist
- `./plancasting/_launch/readiness-report.md` — final readiness assessment with READY/NOT READY decision
- `./plancasting/_launch/unfixable-violations.md` (if applicable) — blocking issues requiring operator intervention

**Note**: Stage 6H is the only stage using binary READY/NOT READY terminology (instead of PASS/CONDITIONAL PASS/FAIL). This stage uses READY/NOT READY instead of PASS/CONDITIONAL PASS/FAIL because 6H is a binary deployment gate — either all deployment prerequisites are met (READY), or they are not (NOT READY). NOT READY requires fixing blockers and re-running 6H. There is no "conditional" deployment.

## Agent Team Architecture

### Phase 1: Lead Analysis & Planning

As the team lead, complete the following BEFORE spawning any teammates:

1. Ensure output directory exists: `mkdir -p ./plancasting/_launch`
2. Read `./CLAUDE.md`, `./plancasting/tech-stack.md`, and all audit reports in `./plancasting/_audits/`.
3. Read `./plancasting/_audits/implementation-completeness/report.md` for known issues and assumptions. If this file does not exist, STOP — Stage 5B is a prerequisite (see Prerequisites section). Do not proceed until 5B has been run.
4. **Verify audit report existence**: Before reading unfixable violations, confirm these files exist: `./plancasting/_audits/security/report.md`, `./plancasting/_audits/accessibility/report.md`, `./plancasting/_audits/performance/report.md`, `./plancasting/_audits/refactoring/report.md`, `./plancasting/_audits/resilience/report.md`, `./plancasting/_audits/seed-data/report.md` (if 6F has run), `./plancasting/_audits/documentation/report.md` (if 6D has run). Missing reports indicate that stage was skipped — note in the readiness report.
5. If any unfixable violation files exist from prior stages: `./plancasting/_audits/security/unfixable-violations.md`, `./plancasting/_audits/accessibility/unfixable-violations.md`, `./plancasting/_audits/performance/unfixable-violations.md`, `./plancasting/_audits/refactoring/unfixable-violations.md`, `./plancasting/_audits/resilience/unfixable-violations.md`, `./plancasting/_audits/documentation/unfixable-violations.md`, `./plancasting/_audits/seed-data/unfixable-violations.md` — read them and include their critical items in the Blocking Issues section of the readiness report. If a file does not exist, that audit stage had no unfixable violations — skip it.
6. Create `./plancasting/_launch/checklist.md` — the master pre-launch checklist with all items to verify.
7. Create a task list for all teammates.

### Phase 2: Spawn Verification Teammates

Spawn the following 3 teammates.

#### Teammate 1: "code-and-test-verifier"
**Scope**: Code quality, test coverage, and build verification

~~~
You are performing final code and test verification before production launch.

Read CLAUDE.md first. Check `./plancasting/tech-stack.md` for the `Session Language` setting. Write all findings in that language. Then read ./plancasting/_launch/checklist.md.

Your tasks:
1. BUILD VERIFICATION:
   - Run the typecheck, lint, and build commands from CLAUDE.md (e.g., `bun run typecheck`, `bun run lint`, `bun run build`) — zero errors for each.
   - Verify the production build output is reasonable in size (check against PRD performance budgets).

2. TEST SUITE VERIFICATION:
   - Run `bun run test` — all unit and integration tests pass.
   - Run `bun run test:e2e` — all E2E tests pass.
   - Verify test count is reasonable (no dramatic drop from previous runs).
   - Check for skipped or pending tests — investigate and resolve or document why they're skipped.

3. CODE QUALITY FINAL CHECK:
   - Verify no `console.log` statements remain in production code (only in test files).
   - Verify no `TODO`, `FIXME`, or `HACK` comments remain without accompanying issue references.
   - Verify no hardcoded secrets, API keys, or credentials in the codebase.
   - Verify no `@ts-ignore` or `@ts-expect-error` without explanation comments.
   - Verify no development-only code (mock data, test backdoors) is active in production paths.

4. DEPENDENCY AUDIT:
   - Run dependency audit: if `package-lock.json` exists, use `npm audit`. For Bun projects (only `bun.lockb` exists), use `bunx audit-ci` or `npx snyk test`. For pnpm, use `pnpm audit`. Note: audit results from different tools may differ slightly from the actual package manager resolution — treat as advisory. Check for known vulnerabilities.
   - Flag any critical or high severity vulnerabilities.
   - Verify all dependencies have appropriate licenses for production use.

When done, message the lead with: build status, test results, code quality issues found, dependency audit results.
~~~

#### Teammate 2: "config-and-environment-verifier"
**Scope**: Environment configuration, credentials, and infrastructure readiness

~~~
You are verifying environment configuration and infrastructure readiness for production.

Read CLAUDE.md first. Check `./plancasting/tech-stack.md` for the `Session Language` setting. Write all findings in that language. Then read ./plancasting/_launch/checklist.md and ./plancasting/tech-stack.md.

Your tasks:
1. ENVIRONMENT VARIABLES:
   - Compare `.env.local.example` against actual `.env.local` — verify all required variables are set.
   - Verify no development/test values remain in production configuration (e.g., test API keys, localhost URLs).
   - Verify no secret values contain placeholder text ('YOUR_KEY_HERE', 'CHANGE_ME', 'test-', 'TODO'). All secret values must be real, non-empty, and non-test credentials for production.
   - Check that client-exposed variables (e.g., `NEXT_PUBLIC_*` for Next.js, `VITE_*` for Vite, `PUBLIC_*` for SvelteKit) only contain values safe for client-side exposure.
   - **HOSTING PROVIDER ENV VARS**: If deploying to Vercel/Netlify/Railway/similar, verify ALL **production-required** environment variables from `.env.local.example` are configured on the hosting platform. Run your platform's env list command (e.g., `npx vercel env ls`, `netlify env:list`, `railway variables`) and cross-check against `.env.local.example`. **Important**: `.env.local` contains development values (localhost URLs, test API keys) — do not copy these to production. Instead, verify production equivalents exist for each variable. Common miss: your backend URL env var (e.g., `NEXT_PUBLIC_CONVEX_URL`, `VITE_SUPABASE_URL`) is often set automatically by the dev server but NOT present in `.env.local` — it must be explicitly added to the hosting provider with the production URL. Missing env vars cause cryptic runtime errors (blank pages, SSR 500s, auth failures) that are hard to diagnose in production.
   - **Cross-check env var naming against codebase**: Run the appropriate grep command for your framework (replace `[backend-dir]` with your actual backend directory):
     - **Next.js / Node.js**: `grep -roh 'process\.env\.\w\+' src/ [backend-dir]/ | sort -u`
     - **Vite / SvelteKit**: `grep -roh 'import\.meta\.env\.\w\+' src/ | sort -u`
     - **Both** (if project mixes runtimes): run both commands and merge results.
     Ensure EVERY referenced env var matches an entry in `.env.local.example` exactly. Mismatched names (e.g., `NEXT_PUBLIC_API_URL` in code vs `API_URL` in `.env.local.example`) cause silent failures.

2. PRODUCTION CONFIGURATION:
   - Verify your framework's config file (e.g., `next.config.ts`, `vite.config.ts`, `svelte.config.js`) has production-appropriate settings (no development-only rewrites or headers).
   - **If using Next.js — CSP VALIDATION**: If Content-Security-Policy headers are defined, verify `script-src` does not include `'strict-dynamic'` unless nonce-based CSP is actually implemented AND verified. `'strict-dynamic'` without nonces blocks ALL Next.js script loading (chunks from `/_next/static/`), causing a completely blank page in production. **Verification steps**: (1) Check `next.config.ts` for CSP header definition, (2) if `'strict-dynamic'` is present, verify `next.config.ts` or middleware generates per-request nonces, (3) inspect an actual HTML response (via `curl` or browser DevTools) to confirm `<script nonce="...">` attributes appear on script tags — do not assume nonces are implemented just because they are mentioned in config.
   - **If using Next.js — i18n ALIAS VALIDATION**: If using an i18n plugin (next-intl, next-international, etc.), verify that config aliases are set for BOTH Turbopack (`turbopack.resolveAlias` with relative paths) AND webpack (`webpack(config)` with absolute paths via `path.resolve`). Many i18n plugins set `experimental.turbo.resolveAlias` which Next.js 15+/16 ignores, causing SSR crashes.
   - **If using Tailwind v4 — CONFIG BRIDGE**: If using Tailwind CSS v4 (`@import "tailwindcss"` syntax in the global CSS file), verify that `@config "../../tailwind.config.ts";` (or correct relative path) is present immediately after the import. Without this line, Tailwind v4 silently ignores the entire JS config — all custom colors, fonts, spacing, and animations produce zero CSS output, resulting in a completely unstyled UI. This is a silent failure with no build error.
   - **If using Tailwind v4 — SEMANTIC COLOR TOKENS**: If using Tailwind v4, verify that semantic utility tokens (`border`, `ring`, `card`, `background`, `foreground`) are defined as top-level entries in `theme.extend.colors` — NOT only in `borderColor`/`ringColor`. In v4, `border-border` looks up `colors.border`, not `borderColor.DEFAULT`. Missing entries cause borders to render as white (browser default) with no build error.
   - Verify your backend deployment configuration is correct — production vs development deployment (e.g., Convex production deployment, Supabase production project, Firebase production config).
   - Verify auth provider configuration points to production (not development) settings.
   - Verify email service configuration uses production credentials.
   - Verify feature flags have correct production default states (all features enabled, kill switches ready).

3. CI/CD PIPELINE:
   - Verify CI/CD configuration exists (e.g., `.github/workflows/deploy.yml`, `vercel.json`, `netlify.toml`, or your provider's config).
   - Verify the deploy pipeline runs the full test suite before deploying.
   - Verify rollback procedures are documented and mechanism exists.
   - **Backend rollback caveats**: Some backends have forward-only schema changes that make rollback non-trivial. **If using Convex**: Unlike Vercel (which supports instant rollback to previous deployments), Convex schema changes and data mutations are forward-only. Rollback strategy must rely on: (1) backward-compatible schema changes (new fields must have default values), (2) feature flags to disable broken features (verify flags have unit tests covering both states), (3) compensating mutations to fix data if needed. Before deployment, verify backward compatibility: existing queries still work with new schema (`bun run test`). **If using traditional databases (PostgreSQL, etc.)**: Ensure down-migrations exist and are tested. **If using Supabase/Firebase**: Verify that schema changes are backward-compatible.
   - Verify preview deployment pipeline works for future PRs.

4. MONITORING AND ALERTING:
   - Verify error monitoring is configured (error tracking service from tech-stack.md).
   - Verify analytics is instrumented (product analytics service from tech-stack.md).
   - Verify health check endpoints exist and return correct responses.
   - Verify logging is configured for production (structured logs, appropriate log levels — no debug logs in production).

When done, message the lead with: env var status, config issues found, CI/CD status, monitoring readiness.
~~~

#### Teammate 3: "user-facing-verifier"
**Scope**: User-facing launch-blocking completeness (SEO, legal, content). Focus on items that would block launch or damage user trust. Do not perform a comprehensive documentation audit (that was Stage 6D) or a full visual polish review (that is Stage 6P).

~~~
You are performing final user-facing verification before production launch.

Read CLAUDE.md first. Check `./plancasting/tech-stack.md` for the `Session Language` setting. Write all findings in that language. Then read ./plancasting/_launch/checklist.md.
Read ./plancasting/prd/01-product-overview.md and ./plancasting/prd/07-information-architecture.md.

Your tasks:
1. SEO AND METADATA:
   - Verify every page has appropriate `<title>` (30–60 chars, unique per page) and `<meta description>` (50–160 chars, unique per page).
   - Verify Open Graph tags are set for social sharing (og:title, og:description, og:image).
   - Verify a `sitemap.xml` is generated (or a route exists to generate it).
   - Verify `robots.txt` exists with appropriate rules.
   - Verify canonical URLs are set to prevent duplicate content.
   - Verify structured data (JSON-LD) is present where appropriate.

2. LEGAL AND COMPLIANCE:
   - Verify privacy policy page exists and is linked from the footer/signup flow.
   - Verify terms of service page exists and is linked.
   - Verify cookie consent mechanism exists (if required by target markets).
   - Verify GDPR data export/deletion capabilities exist (if EU users are targeted).
   - Cross-reference with `./plancasting/brd/12-regulatory-and-compliance-requirements.md` — verify all items are addressed.

3. USER-FACING CONTENT:
   - Verify no placeholder text remains ("Lorem ipsum", "[TODO]", "Coming soon" on launched features).
   - Verify all user-facing error messages are helpful and not technical.
   - Verify empty states across all features have guidance text and call-to-action buttons.
   - Verify the 404 page exists and has a link back to the home page.
   - Verify the onboarding flow works for a brand-new user (create a fresh account through the signup flow or use an unseeded test environment).

4. CROSS-BROWSER, RESPONSIVE, AND DARK MODE:
   - Verify the critical user flows work in Chromium, Firefox, and Safari.
   - Verify responsive design works at mobile (375px), tablet (768px), and desktop (1440px) breakpoints.
   - Verify no horizontal scrolling on any page at any breakpoint.
   - **DARK MODE VISUAL CHECK**: If the app supports dark mode, verify key pages (auth forms, dashboard, settings) in dark mode. Common defect: secondary/outline button variants using `border-primary-*` or `border-accent-*` produce harsh bright borders against dark backgrounds. These should use neutral border tokens (`border-border`) instead. Check that card borders, input borders, and button borders all use the neutral border token in dark mode.

5. DOCUMENTATION COMPLETENESS:
   - Verify `./docs/` exists with help docs, API docs, and developer guide (this is internal documentation from Stage 6D — NOT the Stage 7D Mintlify user guide). If `plancasting/tech-stack.md` indicates documentation generation was skipped (Stage 6D not applicable), skip this check.
   - Verify README.md has setup instructions and deployment guide.
   - Verify ARCHITECTURE.md is up to date (generated by Stage 3; if missing, check `docs/developer/architecture.md` from Stage 6D instead).

When done, message the lead with: SEO status, legal/compliance status, content issues, responsive issues, documentation status.
~~~

### Unfixable Violation Protocol

If a violation cannot be fixed without architectural changes or would break another feature:
1. Document the full conflict with evidence (what the violation is, what fixing it would break)
2. Mark as **"REQUIRES HUMAN DECISION"** in the report — do not attempt a fix that creates regressions
3. Include a recommended approach and estimated effort in the report
4. Continue with remaining fixable violations — do not block the entire audit on one decision

Document unfixable violations found during 6H in `./plancasting/_launch/unfixable-violations.md` with format: violation title, conflict description, evidence (code references), recommended approach, estimated effort, and whether it blocks launch (Yes/No). Reference this file in the readiness report.

### Phase 3: Coordination During Execution

While teammates are working:
1. Monitor progress via the shared task list.
2. Escalate critical blockers immediately:
   - If code-and-test-verifier finds failing tests → STOP. Do not launch. Fix first. (STOP means: abort all teammates, fix the issue, and restart this stage from Phase 1.)
   - If config-and-environment-verifier finds missing production credentials → STOP. Collect them.
   - If user-facing-verifier finds legal compliance gaps → STOP. Address before launch.
3. Non-critical issues can be documented for post-launch fixes.

### Phase 4: Launch Readiness Report

After all teammates complete:

1. Generate `./plancasting/_launch/readiness-report.md`:

   **Launch Readiness Summary**
   - ✅ / ❌ Build passes
   - ✅ / ❌ All tests pass (unit: X, component: X, E2E: X)
   - ✅ / ❌ No critical code quality issues
   - ✅ / ❌ No critical dependency vulnerabilities
   - ✅ / ❌ All environment variables configured for production
   - ✅ / ❌ CI/CD pipeline ready
   - ✅ / ❌ Monitoring and alerting configured
   - ✅ / ❌ SEO and metadata complete
   - ✅ / ❌ Legal and compliance requirements met
   - ✅ / ❌ No placeholder content remaining
   - ✅ / ❌ Responsive design verified
   - ✅ / ❌ Documentation complete

   **Launch Decision**: READY / NOT READY (with blockers listed)

   **Note on terminology**: This stage uses READY/NOT READY (binary) to distinguish pre-launch static verification from the dynamic audit gates (6V, 6R, 6P) that follow. Downstream stages use PASS/CONDITIONAL PASS/FAIL gates.

   ## Gate Decision

   **READY** = ALL of the following:
   1. Build passes without errors
   2. All tests pass (zero failures)
   3. No critical-severity dependency vulnerabilities (high-severity: document for post-launch fix)
   4. All production environment variables configured
   5. No launch-blocking unfixable violations (i.e., critical-severity issues that prevent core user flows from functioning — see full definition below)

   **NOT READY** = one or more criteria above fail.

   **Operator Override Procedure**: The operator is the person running the Transmute pipeline. If 6H returns NOT READY but the operator decides to launch despite blockers: (1) The operator documents the override in the readiness report under a new '## Launch Override' section with: reason for override, list of accepted blockers, risk assessment, and mitigation plan. (2) Proceed to Stage 6V with the documented override. Note: This override is a human decision point — the pipeline does not have an automated approval mechanism. Override justification must be documented in the readiness report with: (a) the specific blocker being overridden, (b) the risk assessment, and (c) the mitigation plan. Security blockers (CVSS ≥ 9.0) cannot be overridden. **Override verification**: If this stage reads a previous 6H report showing NOT READY, check whether a `## Launch Override` section exists. If NOT READY is present but no override section exists, STOP and require the operator to either fix blockers or document the override decision before proceeding.

   **Launch-blocking definition**: An unfixable violation is launch-blocking ONLY if it prevents core business functionality (auth broken, payment cannot complete, data loss possible). Non-critical unfixable issues (minor accessibility gap on secondary feature, performance slightly over baseline) are not launch-blocking — document them as post-launch items. If uncertain, classify as blocking and let the operator override. **Unfixable violations consolidation**: Read all `unfixable-violations.md` files from prior audit stages (`./plancasting/_audits/{security,accessibility,performance,refactoring,resilience}/unfixable-violations.md`) — each stage may have created one. Evaluate each violation against this launch-blocking definition. Reference the source stage and issue in the readiness report.

   **Non-Critical Issues** (can be addressed post-launch):
   - [List any minor issues that don't block launch]

   **Post-Launch Checklist**:
   - [ ] Verify DNS propagation
   - [ ] Verify SSL certificate
   - [ ] Run smoke test on production URL
   - [ ] Verify monitoring dashboards show live data
   - [ ] Verify error tracking receives test errors
   - [ ] Send test transactional email from production
   - [ ] Verify auth flow works on production domain

   **Next Steps after 6H**:
   - If READY → proceed to Stage 6V (Visual & Functional Verification).
   - If NOT READY → fix blockers and re-run 6H.

   6H's routing decision is: READY → proceed to Stage 6V (Visual & Functional Verification). NOT READY → fix blockers and re-run 6H. After 6V completes, 6V determines the next step (6R then 6P, or directly to 6P if no fixable issues) — see execution-guide.md § "Gate Decision Outcomes" → "Post-6V routing" for the decision table. 6V never routes directly to deploy; 6P or 6P-R always runs before deployment.

2. Output summary: launch readiness status (READY/NOT READY), blocker count, non-critical issue count.

### Phase 5: Shutdown

1. Request shutdown for all teammates.
2. Verify all file modifications are saved and committed.

## Critical Rules

1. never launch with failing tests — no exceptions.
2. never launch with critical-severity dependency vulnerabilities unaddressed. High-severity: must be documented with a post-launch remediation timeline in the readiness report.
3. never assume environment variables are set just because they exist in `.env.local` — verify on the hosting platform.
4. never launch without a tested rollback procedure documented.
5. The readiness report must be saved before deployment begins, not generated after.
6. always verify ALL prior stage audit reports exist (security, accessibility, performance, refactoring, resilience — check `./plancasting/_audits/<stage>/report.md` for each). For documentation, verify `./docs/` exists and `./plancasting/_audits/documentation/report.md` exists (Stage 6D generates both `./docs/` and a gate decision report). For seed data, verify `./seed/README.md` exists and `./plancasting/_audits/seed-data/report.md` exists (Stage 6F generates both the `./seed/` directory and a gate decision report). If any are missing, STOP — the prerequisite stage was not completed.
7. For backends with forward-only schema changes (e.g., Convex): schema changes are not easily reversible. Verify backward-compatible schema changes and have a feature flag strategy to disable broken features without schema rollback.
8. always verify CORS headers allow the production frontend domain.
9. Use the commands from CLAUDE.md for testing (e.g., `bun run test`).
10. After 6H READY, proceed to 6V. For post-6V routing (6R/6P decisions), see execution-guide.md § "Gate Decision Outcomes" → "Post-6V routing".
````
