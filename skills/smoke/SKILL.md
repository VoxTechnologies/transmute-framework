---
name: smoke
description: >-
  Runs production smoke tests to verify the deployed application works correctly in the live environment.
  This skill should be used when the user asks to "run production smoke tests",
  "verify the production deployment", "smoke test the live app",
  "check if production is working", "run post-deployment verification",
  "run stage 7V", or "verify the deployed application",
  or when the transmute-pipeline agent reaches Stage 7V of the pipeline.
metadata:
  version: 1.1.0
effort: medium
---

# Production Smoke Verification — Stage 7V

Read the detailed guide at `${CLAUDE_SKILL_DIR}/references/smoke-detailed-guide.md` for the full verification checklist, report template, known failure patterns, and rollback guidance. Read `${CLAUDE_SKILL_DIR}/references/feature-scenario-generation.md` for the scenario generation algorithm.

## Prerequisites

1. Verify the production URL is accessible and responding. Check with `curl -sI <production-url> | head -1` (expect HTTP 200 or 301/302). If unreachable, STOP and verify deployment status.
2. Check `./plancasting/_launch/readiness-report.md` exists. If it shows FAIL, stop and report the blocker. If READY or CONDITIONAL PASS with documented minor issues, proceed. If it does not exist, proceed but note in the report: "Stage 6H pre-launch verification was not completed."
3. If 6R was run, verify `./plancasting/_audits/runtime-remediation/report.md` shows PASS or CONDITIONAL PASS. If FAIL, STOP — 6R must pass before Stage 7.
4. Verify `./plancasting/_audits/visual-verification/report.md` or `./plancasting/_audits/visual-polish/report.md` exists. Warn if neither is found.
5. Verify scenario generation file exists: `./plancasting/transmute-framework/feature_scenario_generation.md`. If missing, copy from the Transmute Framework Template directory. See CLAUDE.md § "Pre-6V Setup" for copy instructions.
6. Create output directories:
   ```bash
   mkdir -p ./plancasting/_audits/production-smoke
   mkdir -p ./screenshots/production
   ```
7. Read `CLAUDE.md`, `plancasting/tech-stack.md`, and check `plancasting/tech-stack.md` for the `Session Language` setting. Generate all reports in the specified language.

## Inputs

- **Production URL**: The live application URL
- **Scenario Generation Guide**: `${CLAUDE_SKILL_DIR}/references/feature-scenario-generation.md` (if not available, use PRD files directly)
- **6V Scenario Matrix** (if exists): `./plancasting/_audits/visual-verification/feature-scenario-matrix.md`
- **6V Report**: `./plancasting/_audits/visual-verification/report.md`
- **6R Report** (if exists): `./plancasting/_audits/runtime-remediation/report.md`
- **6P/6P-R Report** (if exists): `./plancasting/_audits/visual-polish/report.md`
- **PRD files**: `./plancasting/prd/02-feature-map-and-prioritization.md`, `04-epics-and-user-stories.md`, `06-user-flows.md`, `07-information-architecture.md`, `08-screen-specifications.md`
- **Tech Stack**: `./plancasting/tech-stack.md`
- **E2E Config**: `./playwright.config.ts`, `./e2e/constants.ts`

## Execution Flow

This is a single-agent sequential check. Target completion: 25-45 minutes (3-5 min scenario generation + 15-25 min core checks + 5-8 min for 6R/6P/navigation verification + 2-5 min performance/integrations). If the application exceeds 50+ pages or 10+ integrations, consider running a scoped Stage 6V (`critical` mode) against the production URL instead.

### Step 0: Generate Smoke Scenario Matrix

Before any verification, generate a targeted test plan. Save to `./plancasting/_audits/production-smoke/smoke-scenario-matrix.md`.

Scope: SMOKE — P0+P1 features only, max 15 scenarios.

**Generation mode: SMOKE** — P0/P1 features only, happy path Feature Scenarios + one authenticated/unauthenticated Auth Context check per route. No Entity State, Role Permission, or Negative Scenarios. Target: 15 scenarios max.

**If 6V scenario matrix exists**: Filter to P0 + P1 feature scenarios only, happy path, no negative variants. Filter auth contexts to unauthenticated + one authenticated role. Skip entity state and role permission scenarios. Target ~10-15 scenarios.

**If no 6V matrix exists**: Read the scenario generation guide and PRD files. Generate feature scenarios for P0 + P1 features only, one scenario per flow (happy path). Target ~10-15 scenarios.

**If generation fails**: Fall back to hardcoded minimum flows (authentication, core feature, settings).

### Steps 1-3: Infrastructure and Baseline

1. **Infrastructure Checks**: Verify DNS resolution, SSL certificate validity (not expired, not self-signed), HTTPS redirect (HTTP -> HTTPS), and security headers (CSP, X-Frame-Options, etc.). Use CLI tools (`nslookup`, `openssl`, `curl`) if available; fall back to Playwright browser tools.

2. **Environment Variable Spot-Check**: Check for missing or misconfigured env vars. Verify BaaS URLs, auth provider URLs, naming consistency across all `process.env.*` reads, and backend deployment target. Cross-check third-party service tier limits. **Early AI model validation**: Check all AI model IDs used in code against the provider's documentation; send a 1-token test request for each model to verify they exist and respond.

3. **Reuse 6V Playwright Tests** (if `e2e/verification/` exists): Run them against production URL with `BASE_URL=https://[domain]`. **Flaky = FAIL**: If any test requires a retry to pass, treat it as FAIL for gate purposes — production flakiness is unacceptable.

### Steps 4-8: Core Verification

4. **Critical Page Load Verification**: Test all public pages in a FRESH browser context (no cookies/localStorage). Verify HTTP 200, correct body content (not login page served with 200), and no auth console errors. Test protected route redirect behavior. Test authenticated pages after logging in as a test user. For each page: verify HTTP 200, no console errors, content renders, CSS loads, JS executes, data loads, take screenshot.

5. **6R Fix Verification** (if 6R report exists): Re-test each auto-fixed issue on production. Verify deployed commit hash matches 6R report commit hash. If any fix is missing, flag as CRITICAL and check deployed commit hash.

6. **6P/6P-R Visual Polish Verification** (if visual polish report exists): Spot-check top 3 most impactful visual changes survived production build. **6P-R branch merge check**: If 6P-R was used (check for `design-plan.md`), verify `redesign/frontend-elevation` branch was merged to main before deployment. Flag missing changes as MEDIUM severity.

7. **Navigation Smoke Test** (~5 min max): Test desktop sidebar, footer, mobile nav, sub-navigation tabs. Check CSS styling intact at both viewports. Flag invisible/unstyled links as CRITICAL (likely Tailwind CSS purging).

8. **Critical User Flow Verification**: Execute P0 scenarios from smoke matrix. Follow dependency graph. If P0 fails, mark dependents as BLOCKED. Fall back to minimum flows if no matrix exists.

### Steps 9-11: Visual, Performance, Integrations

9. **AI Vision Spot-Check**: Screenshot 5 most important pages. Compare against 6V screenshots for visual differences.

10. **Performance Spot-Check**: Measure TTFB and LCP for landing page and dashboard. Flag if >2x slower than dev.

11. **Third-Party Integration Verification**: Verify auth, database, payments, email, analytics, error monitoring, webhooks, real-time connections. Verify AI model IDs first (grep codebase, send minimal test request). Run external API health checks with minimal requests (cost warning: real API calls against production keys). Verify OAuth integration health for each connected service (check redirect_uri matches, client IDs, provider app registration).

## Output

Generate `./plancasting/_audits/production-smoke/report.md` following the report template in the detailed guide. The report includes: summary, infrastructure results, page load results, public route access, protected route redirect, 6R/6P/6P-R verification, navigation smoke test, scenario results, visual comparison, performance, third-party integrations, gate decision, next steps, issues found, and screenshot references.

## Gate Decision

- **PASS**: All critical flows work, all pages load, no console errors, all external APIs respond 2xx. Proceed to Stage 7D (User Guide Generation).
- **CONDITIONAL PASS**: All P0 critical flows pass, all pages load, but minor issues exist in P1/P2 features (e.g., non-critical integration timeout, minor visual discrepancy from 6V baseline). Document issues for post-launch fix. Stage 7D and Stage 8 can proceed.
- **FAIL**: Any critical flow broken, pages don't load, critical navigation failure (invisible/unstyled links), external API health check fails, or 6R fixes missing from deployment. Immediate action required per rollback guidance.

**Flaky = FAIL**: If a scenario fails once but passes on retry, treat it as FAIL. Production flakiness is unacceptable. Non-critical visual issues do not trigger FAIL; document them for Stage 8.

**FAIL decision tree**: (1) If issue is localized (1-2 files, <100 LOC fix): hotfix in code, re-deploy, re-run 7V. (2) If issue affects multiple systems or requires >2 hours to fix: execute rollback (`git revert HEAD`), verify reverted deploy is stable, investigate offline.

## Failure Escalation Protocol

| Failure Type | Action |
|---|---|
| Auth completely broken (login 500s) | Rollback deployment immediately |
| Core data query empty (DB inaccessible) | Check backend deployment status; rollback if needed |
| SSR hydration errors on landing page | Check Tailwind CSS purging; hotfix if CSS issue |
| 3rd-party integration failure | Do not rollback; escalate to operator to verify API keys |

## Critical Rules

1. always use the PRODUCTION URL -- never test against localhost.
2. never modify production data beyond test accounts.
3. never test payment flows with real payment methods.
4. Use identifiable test accounts (`smoke-test-*@domain`).
5. If ANY critical flow fails, follow rollback guidance. Do not mark as "known issue for later."
6. Keep this stage FAST -- 25-45 minutes max.
7. always compare against Stage 6V results for deployment-specific regressions.
7a. Flaky scenarios = FAIL in production. Do not mark as passing if it required a retry.
8. always clean up test accounts after verification.
9. always verify test user login works BEFORE authenticated page checks.
10. always test public utility routes (`/sitemap.xml`, `/robots.txt`, `/api/health`) WITHOUT authentication.
11. always verify 6R fixes BEFORE detailed feature/navigation checks if 6R report exists.
12. always test navigation at BOTH desktop and mobile viewports.
13. always check deployed commit hash against 6R remediation commit hash if 6R report exists.
14. Spot-check 6P/6P-R visual polish changes if visual polish report exists.
15. never modify application code, production configuration, or database records during this stage (except test account creation/cleanup).
