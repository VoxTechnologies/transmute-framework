---
name: prelaunch
description: >-
  Performs a comprehensive pre-launch verification checklist before production deployment.
  This skill should be used when the user asks to "run pre-launch checks",
  "verify launch readiness", "check production configuration",
  "validate deployment readiness", "generate launch checklist",
  "are we ready to go live", or "can we ship"
  — or when the transmute-pipeline agent reaches Stage 6H of the pipeline.
metadata:
  version: 1.0.0
effort: medium
---

# Stage 6H: Final Check Before Production Deployment

Read the detailed guide at `${CLAUDE_SKILL_DIR}/references/prelaunch-detailed-guide.md` for the complete verification procedures, checklist templates, and report format.

Lead a multi-agent pre-launch verification project. Perform a comprehensive final check of the COMPLETE product before it goes live. This is the last gate between development and real users.

**Stage Sequence** (recommended ordering): Stage 5B → 6A/6B/6C (parallel) → 6E → 6F → 6G → 6D (Documentation) → **6H (this stage)** → 6V (Verification) → [6R] → 6P or 6P-R → 7 (Deploy) → 7V → 7D

## Prerequisites

Verify before starting — this stage has the strictest prerequisite checks:

1. `./plancasting/_audits/implementation-completeness/report.md` exists with PASS or CONDITIONAL PASS. If missing, STOP — 5B is a prerequisite gate. CONDITIONAL PASS requires each Category C issue to have a documented workaround. FAIL means STOP.
2. ALL Stage 6 audit reports exist:
   - `./plancasting/_audits/security/report.md` (6A)
   - `./plancasting/_audits/accessibility/report.md` (6B)
   - `./plancasting/_audits/performance/report.md` (6C)
   - `./plancasting/_audits/documentation/report.md` and `./docs/` (6D) — mandatory for software products; skip only if plancasting/tech-stack.md indicates non-software product or documentation explicitly marked N/A
   - `./plancasting/_audits/refactoring/report.md` (6E)
   - `./seed/README.md` and `./plancasting/_audits/seed-data/report.md` (6F) — skip if plancasting/tech-stack.md indicates N/A
   - `./plancasting/_audits/resilience/report.md` (6G)
   For any missing report (except 6D/6F if skipped), STOP — prerequisite not completed.
   For each existing report, read its `## Gate Decision` heading and verify the gate passed. If any shows FAIL, STOP. If CONDITIONAL PASS, verify the conditions are acceptable for launch.
3. **Check for unfixable violation files** from prior stages (not all stages produce these): `./plancasting/_audits/security/unfixable-violations.md`, `./plancasting/_audits/accessibility/unfixable-violations.md`, `./plancasting/_audits/performance/unfixable-violations.md`, `./plancasting/_audits/refactoring/unfixable-violations.md`, `./plancasting/_audits/resilience/unfixable-violations.md`, `./plancasting/_audits/documentation/unfixable-violations.md`, `./plancasting/_audits/seed-data/unfixable-violations.md`. If any exist, read them and treat CRITICAL items as launch blockers. If a file does not exist, that stage had no unfixable violations — skip it.
4. Read `./CLAUDE.md` and `./plancasting/tech-stack.md` for project conventions.

Check `./plancasting/tech-stack.md` for the `Session Language` setting. Generate all reports in that language. Code and file names remain in English.

## Stack Adaptation

Source examples use Next.js + Convex + Vercel. Adapt ALL references to your actual stack:

| This prompt says | Adapt to your stack |
|---|---|
| `next.config.ts` | Your framework config (e.g., `vite.config.ts`, `svelte.config.js`) |
| `npx convex deploy` | Your backend deploy command |
| `npx vercel env ls` | Your hosting platform's env var command |
| `bun run` | Your package manager command |
| `NEXT_PUBLIC_*` | Your client-exposed prefix (e.g., `VITE_*`, `PUBLIC_*`) |

Skip sections marked "If using [technology]" when your stack does not include that technology.

## Known Failure Patterns

**General (all stacks):**
1. **Missing hosting env vars**: Client-exposed backend URL env vars (e.g., `NEXT_PUBLIC_CONVEX_URL`, `VITE_API_URL`) are often auto-set by the dev server but NOT present on the hosting platform — causes blank pages or runtime errors.
2. **Dark mode border contrast**: Secondary/outline button variants using `border-primary-*` produce harsh bright borders in dark mode. Should use `border-border` neutral token.

**If using Next.js:**
3. **CSP blocks scripts**: `script-src 'strict-dynamic'` without nonce-based CSP blocks ALL `/_next/static/` script loading, causing a blank page.
4. **i18n alias misconfiguration**: Turbopack alias set but webpack alias missing (or vice versa), causing SSR crashes in production but not in dev.

**If using Tailwind v4:**
5. **Silent config failure**: Missing `@config "../../tailwind.config.ts"` after `@import "tailwindcss"` causes entire JS config to be ignored — zero CSS output, completely unstyled UI, no build error.
6. **Semantic token lookup**: `border-border` looks up `colors.border` in v4, not `borderColor.DEFAULT`. Missing entries cause white borders with no build error.

## Phase 1: Lead Analysis and Planning

Complete BEFORE spawning teammates:

1. Read `./CLAUDE.md`, `./plancasting/tech-stack.md`, and all audit reports in `./plancasting/_audits/`.
2. Read `./plancasting/_audits/implementation-completeness/report.md` for known issues. If missing, STOP.
3. Verify all audit reports exist. Missing reports indicate skipped stages — note in readiness report.
4. Read unfixable violation files if they exist. Include critical items in Blocking Issues.
5. Create `./plancasting/_launch/checklist.md` — master pre-launch checklist.

## Phase 2: Spawn Verification Teammates

### Teammate 1: "code-and-test-verifier"

Scope: Code quality, test coverage, build verification.

Tasks:

1. **Build verification**: Run typecheck, lint, build — zero errors each. Verify production build size against performance budgets.
2. **Test suite verification**: Run all unit, integration, and E2E tests — all pass. Verify test count is reasonable (no dramatic drop). Investigate skipped/pending tests.
3. **Code quality final check**: No `console.log` in production code. No `TODO`/`FIXME`/`HACK` without issue references. No hardcoded secrets. No unexplained `@ts-ignore`/`@ts-expect-error`. No dev-only code (mock data, test backdoors) in production paths.
4. **Dependency audit**: Run `npm audit` (or `bunx audit-ci`/`npx snyk test` for Bun). Flag critical/high vulnerabilities. Verify license compatibility.

### Teammate 2: "config-and-environment-verifier"

Scope: Environment configuration, credentials, infrastructure readiness.

Tasks:

1. **Environment variables**: Compare `.env.local.example` against `.env.local`. No dev/test values in production config. No placeholder text ('YOUR_KEY_HERE', 'CHANGE_ME', 'test-', 'TODO'). Client-exposed variables contain only safe values. Cross-check hosting platform env vars against `.env.local.example` — verify production equivalents exist. **Cross-check naming**: grep codebase for `process.env.\w+` (or `import.meta.env.\w+` for Vite) and verify every referenced var matches `.env.local.example` exactly. Mismatched names cause silent failures.
2. **Production configuration**: Verify framework config has production-appropriate settings. For Next.js: validate CSP (no `strict-dynamic` without nonces — verify by inspecting actual HTML response), i18n aliases (both Turbopack and webpack). For Tailwind v4: verify `@config` bridge and semantic color tokens in `theme.extend.colors`. Verify backend deployment points to production. Auth provider and email service use production credentials. Feature flags have correct defaults.
3. **CI/CD pipeline**: Config exists. Deploy pipeline runs tests before deploying. Rollback procedure documented. For forward-only backends (e.g., Convex): verify backward-compatible schema changes, feature flag strategy (with unit tests covering both states), compensating mutations. Preview deployment works.
4. **Monitoring and alerting**: Error monitoring configured. Analytics instrumented. Health check endpoints exist and return correct responses. Logging configured for production (structured, appropriate levels, no debug).

### Teammate 3: "user-facing-verifier"

Scope: User-facing completeness, SEO, legal, documentation. Focus on launch-blocking items. Do not duplicate Stage 6D (docs audit) or 6P (visual polish).

Tasks:

1. **SEO and metadata**: Every page has `<title>` (30-60 chars, unique) and `<meta description>` (50-160 chars, unique). Open Graph tags set. Sitemap generated. `robots.txt` exists. Canonical URLs set. JSON-LD structured data where appropriate.
2. **Legal and compliance**: Privacy policy page exists and linked from footer/signup. Terms of service exists and linked. Cookie consent mechanism (if required by target markets). GDPR data export/deletion (if EU-targeted). Cross-reference BRD compliance requirements.
3. **User-facing content**: No placeholder text ("Lorem ipsum", "[TODO]", "Coming soon" on launched features). Error messages are helpful and non-technical. Empty states have guidance and CTAs. 404 page works with home link. Onboarding flow works for new users.
4. **Cross-browser, responsive, dark mode**: Critical flows work in Chromium, Firefox, Safari. Responsive at 375px, 768px, 1440px. No horizontal scrolling. **Dark mode visual check**: verify borders use neutral tokens (`border-border`), not harsh primary colors. Check auth forms, dashboard, settings in dark mode.
5. **Documentation completeness**: `./docs/` exists with help docs, API docs, developer guide (from 6D — skip if tech-stack.md indicates N/A). README has setup and deployment instructions. ARCHITECTURE.md is up to date (or `docs/developer/architecture.md`).

## Unfixable Violation Protocol

If a violation cannot be fixed without architectural changes:
1. Document the full conflict with evidence.
2. Mark as **REQUIRES HUMAN DECISION**.
3. Include recommended approach and estimated effort.
4. Document in `./plancasting/_launch/unfixable-violations.md` with: violation title, conflict description, evidence, recommended approach, estimated effort, and whether it blocks launch (Yes/No).
5. Continue with remaining fixable violations.

## Phase 3: Coordination

Escalate critical blockers immediately:
- Failing tests: STOP. Abort all teammates, fix, restart from Phase 1.
- Missing production credentials: STOP. Collect them.
- Legal compliance gaps: STOP. Address before launch.
- Non-critical issues: document for post-launch fixes.

## Phase 4: Launch Readiness Report

Generate `./plancasting/_launch/readiness-report.md`:

**Launch Readiness Summary** (checkmark or X for each):
- Build passes
- All tests pass (unit: X, component: X, E2E: X)
- No critical code quality issues
- No critical dependency vulnerabilities
- All environment variables configured for production
- CI/CD pipeline ready
- Monitoring and alerting configured
- SEO and metadata complete
- Legal and compliance requirements met
- No placeholder content remaining
- Responsive design verified
- Documentation complete

**Launch Decision**: READY / NOT READY (with blockers listed)

**Note**: This stage uses READY/NOT READY (binary) — there is no 'conditional' deployment. The product is either deployable or it is not.

## Gate Decision

**READY** = ALL of the following:
1. Build passes without errors
2. All tests pass (zero failures)
3. No critical-severity dependency vulnerabilities (high-severity: document for post-launch fix)
4. All production environment variables configured
5. No launch-blocking unfixable violations (critical-severity issues preventing core user flows)

**NOT READY** = one or more criteria above fail.

**Launch-blocking definition**: An unfixable violation is launch-blocking ONLY if it prevents core business functionality (auth broken, payment cannot complete, data loss possible). Non-critical unfixable issues (minor a11y gap on secondary feature, performance slightly over target) are not launch-blocking — document as post-launch items.

**Operator Override Procedure**: If NOT READY but operator decides to launch: (1) document override in readiness report under '## Launch Override' with reason, accepted blockers, risk assessment, mitigation plan. (2) Proceed to Stage 6V with documented override.

**Non-Critical Issues**: Items that can be addressed post-launch.

**Post-Launch Checklist**:
- [ ] Verify DNS propagation
- [ ] Verify SSL certificate
- [ ] Run smoke test on production URL
- [ ] Verify monitoring dashboards show live data
- [ ] Verify error tracking receives test errors
- [ ] Send test transactional email from production
- [ ] Verify auth flow on production domain

**Next Steps after 6H**:
- If READY, proceed to Stage 6V (Visual and Functional Verification).
- If NOT READY, fix blockers and re-run 6H.
- Post-6V routing: see execution-guide.md § "Gate Decision Outcomes" -> "Post-6V routing" for the decision table. 6V never routes directly to deploy; 6P always runs before deployment.

## Phase 5: Shutdown

Request shutdown for all teammates. Verify all modifications are saved and committed.

## Critical Rules

1. never launch with failing tests — no exceptions.
2. never launch with critical/high dependency vulnerabilities unaddressed. High-severity: document with post-launch remediation timeline.
3. never assume env vars are set just because they exist in `.env.local` — verify on hosting platform.
4. never launch without a tested rollback procedure documented.
5. Readiness report must be saved before deployment begins.
6. always verify ALL prior stage audit reports exist. For documentation: verify `./docs/` AND `./plancasting/_audits/documentation/report.md`. For seed data: verify `./seed/README.md` AND `./plancasting/_audits/seed-data/report.md`.
7. For forward-only schema backends: verify backward-compatible schema changes and feature flag strategy.
8. always verify CORS headers allow the production frontend domain.
9. Use commands from CLAUDE.md for testing.
10. After this stage passes, proceed to Stage 6V as the final live-app gate.
