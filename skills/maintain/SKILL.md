---
name: maintain
description: >-
  Updates dependencies, applies security patches, and manages package versions on a regular cadence.
  This skill should be used when the user asks to "update dependencies",
  "run dependency maintenance", "check for outdated packages",
  "apply security patches", "update npm packages", "run stage 9",
  "check for vulnerabilities", or "upgrade dependencies",
  or when the transmute-pipeline agent reaches Stage 9 of the pipeline.
metadata:
  version: 1.1.0
effort: medium
---

# Dependency Maintenance — Stage 9

Read the detailed guide at `${CLAUDE_SKILL_DIR}/references/maintain-detailed-guide.md` for the complete maintenance procedures, teammate spawn prompts, update strategies, and report templates.

## Context

Designed to be run on a regular cadence (monthly or quarterly) to keep the codebase healthy. Outdated dependencies accumulate security vulnerabilities, miss performance improvements, and eventually create painful migration cliffs.

## Prerequisites

1. Read `CLAUDE.md` and `plancasting/tech-stack.md`.
2. Ensure `git status` shows a clean working directory. Commit or stash all uncommitted changes.
3. Check `plancasting/tech-stack.md` for the `Session Language` setting. Generate all reports in the specified language.
4. Infer package manager from lock files if CLAUDE.md Part 2 'Commands' section is empty: `bun.lockb` -> bun, `package-lock.json` -> npm, `pnpm-lock.yaml` -> pnpm. Log the inferred package manager in the report.

## Inputs

- **Codebase**: Complete project directory
- **Tech Stack**: `./plancasting/tech-stack.md`
- **Project Rules**: `./CLAUDE.md`
- **Lock file**: `package-lock.json`, `bun.lockb`, or `pnpm-lock.yaml`

## Stack Adaptation

Examples use `bun` commands. Adapt to your package manager:
- `npm audit` -> Bun has no built-in audit. Use `npm audit` if `package-lock.json` exists; otherwise use `bunx audit-ci` or `npx snyk test`. Document which audit tool was used in the report.
- `npm update` -> `bun update`
- `npm outdated` -> `bunx npm-check-updates` (Bun has no built-in `outdated` command)
Always read `CLAUDE.md` and `plancasting/tech-stack.md` for actual conventions.

## Execution Flow

### Phase 1: Lead Analysis and Planning

**Branch safety**: Create a dedicated branch: `git checkout -b chore/dependency-update-$(date +%Y-%m-%d-%H%M%S)`. The HMS suffix prevents collisions if Stage 9 is re-run the same day. Do not commit directly to main.

**Pre-flight Concurrency Check**: Before proceeding, verify that Stage 8 (Feedback Loop) is not currently in progress. Check: (1) `git log --oneline -5 | grep -i 'feedback'` — if the most recent commit is an in-progress feedback batch from the current day, STOP; (2) `git branch --list 'feedback/*'` — if a `feedback/batch-*` branch exists, Stage 8 may be active. Do not run Stage 9 concurrently with Stage 8 (both modify `package.json` and lock files). Wait for Stage 8 to complete and commit before starting Stage 9.

1. Read `CLAUDE.md` and `plancasting/tech-stack.md`.
2. Verify clean working directory.
3. Create maintenance directory: `mkdir -p ./plancasting/_maintenance`
4. Record the current baseline:
   ```bash
   bun run typecheck
   bun run lint
   bun run test
   bun run test:e2e
   bun run build
   ```
   Save results to `./plancasting/_maintenance/baseline-$(date +%Y-%m-%d).md`. If baseline tests show NEW regressions (not pre-existing), STOP -- resolve regressions before proceeding. Compare test results against the last green CI run or previous commit's output. Document any pre-existing failures in the baseline.

5. Analyze current dependencies:
   ```bash
   bunx npm-check-updates > ./plancasting/_maintenance/outdated.txt
   # Security audit (choose based on lock file)
   if [ -f bun.lockb ]; then
     bunx audit-ci > ./plancasting/_maintenance/audit.json
   elif [ -f package-lock.json ]; then
     npm audit --json > ./plancasting/_maintenance/audit.json
   elif [ -f pnpm-lock.yaml ]; then
     pnpm audit --json > ./plancasting/_maintenance/audit.json
   fi
   ```
   If no outdated dependencies and no vulnerabilities, generate a brief all-clear report and exit early.

6. **Categorize updates into tiered batches**:
   - **Security patches** (any severity): must update. Sub-classify by CVSS severity if available: CRITICAL (9-10) = patch immediately, can trigger emergency Stage 9; HIGH (7-8) = patch within 24-48 hours; MEDIUM (4-6) = patch in current run; LOW (0-3) = patch in next planned run. Process CRITICAL patches in a dedicated fast-tracked batch before other updates.
   - **Patch versions** (x.y.Z): Low risk, usually safe -- BUT verify the changelog first
   - **Minor versions** (x.Y.z): Medium risk, may add features or deprecations
   - **Major versions** (X.y.z): High risk, likely breaking changes

7. Create `./plancasting/_maintenance/update-plan.md` with ordered updates (security first, then patch, minor, major). For major versions, search for migration guides and breaking change notes. If web search is unavailable, check `node_modules/<package>/CHANGELOG.md`. Include risk assessment per update (scale 1-5): 1 = security patch, zero API changes; 5 = major version with significant architectural changes.

8. Create task list for teammates.

### Phase 2: Spawn Maintenance Teammates

Spawn 3 teammates SEQUENTIALLY (low risk -> medium -> high risk). **Rationale**: Security patches may change APIs that affect minor version compatibility; minor updates must land before major upgrades.

**Teammate 1 -- "security-and-patch-updater"**: Apply security patches and patch version updates. For each vulnerability: update to patched version or research alternatives. Run typecheck, test, and lint after each batch. Run test:e2e if updates touch auth libraries, HTTP clients, or test frameworks. **Lock file stability check** (Bun only): After `bun install`, run `bun install` again -- should be idempotent (no changes). If lock file changes on second install, dependency resolution is unstable -- investigate.

**Teammate 2 -- "minor-version-updater"** (BLOCKED by Teammate 1): Apply minor version updates. Check changelogs for deprecations and behavioral changes. Handle environment variable changes (update `.env.local.example`, never commit `.env.local`). Replace deprecated API usage. Run verification after each update. If Playwright was updated, run `bunx playwright install --with-deps` before E2E tests.

**Teammate 3 -- "major-version-updater"** (BLOCKED by Teammate 2): Apply major version updates ONE AT A TIME. Follow migration guides. Run full verification suite (typecheck, lint, test, test:e2e, build) after EACH major update. Handle framework updates with extra care (check config file changes). **Backend SDK codegen re-run requirement**: When updating any backend SDK, re-run code generation IMMEDIATELY and UNCONDITIONALLY after `bun install` but BEFORE tests:
- **Convex**: `bunx convex codegen` (regenerates `convex/_generated/`)
- **Prisma**: `npx prisma generate` (regenerates Prisma Client). If schema changed: `npx prisma migrate dev`
- **Drizzle**: No codegen required, but review `schema.ts` for type compatibility
- **Supabase**: Run `supabase gen types typescript` if using type generation
- **Firebase Admin SDK**: No codegen required, but verify function signatures

**Codegen is a GATE**: Generated files and runtime SDK versions must stay in sync -- tests WILL fail with type mismatches if codegen is not run first. If codegen fails, revert the update and mark as deferred.

If a major update is too complex to resolve, revert and document.

### Phase 3: Coordination

Monitor progress. Enforce sequential dependency. Help research breaking changes.

### Phase 4: Final Verification and Report

1. Run COMPLETE test suite. Compare to baseline.
2. **Runtime version check**: If major updates changed `engines` requirements, verify Node.js/Bun version compatibility. If runtime does not satisfy new requirements: update local runtime, update CI/CD pipeline, or revert the dependency update.
3. Re-run security audit. Compare to baseline.
4. Generate `./plancasting/_maintenance/report-$(date +%Y-%m-%d).md`:
   - Updates applied (security, patch, minor, major counts)
   - Deferred updates with rationale
   - Test results: baseline vs post-update
   - Security audit: before vs after vulnerability count
   - Recommendations for future updates
   - Rules hygiene (populated in step 9)
   - Next maintenance date suggestion. Default: 30 days. Accelerate if: (1) critical vulnerabilities exist, (2) breaking changes deferred, (3) major framework updates pending
5. **Stage 6V/7D re-run decision**: If major updates touched React, Next.js, Tailwind, CSS framework, or UI component library, add to report: "Recommend re-running Stage 6V to validate UI rendering."
6. Update `plancasting/tech-stack.md` with new version numbers for core dependencies.
7. Update CLAUDE.md Part 2 if major framework versions changed.
8. Note affected features in `plancasting/_progress.md` if behavioral code changes were made.
9. **Path-scoped rules staleness review**: Read all rule files in `.claude/rules/`. Remove rules referencing deprecated APIs, removed packages, renamed functions, or non-existent file paths. Remove stale candidates from `plancasting/_rules-candidates.md` (pending 2+ maintenance cycles without promotion). Log all changes in the report under a "Rules Hygiene" section:
   ```markdown
   ## Rules Hygiene
   - Rules reviewed: [n]
   - Rules removed: [n] (list reasons)
   - Rules updated: [n] (list changes)
   - Rules unchanged: [n]
   ```
10. **Complete Gate Decision BEFORE merging**. If PASS or CONDITIONAL PASS, merge: `git checkout main && git merge chore/dependency-update-YYYY-MM-DD-HHMMSS`. If merge fails due to lock file conflicts, rebase, reinstall, re-verify, retry.
11. Output summary.

## Gate Decision

- **PASS**: All tests pass post-update, no remaining critical/high vulnerabilities, build succeeds. Proceed to deployment and Stage 7V.
- **CONDITIONAL PASS**: Tests pass but some major updates deferred. Schedule follow-up.
- **FAIL**: Test suite fails and cannot be resolved, or critical vulnerabilities remain unpatched. Do not merge to main. Fix failing tests or revert problematic updates. Re-run Phase 4 verification.

**Post-gate routing**:
- **PASS**: Merge, deploy via Stage 7, verify with Stage 7V.
- **CONDITIONAL PASS**: Merge and deploy resolved updates. Schedule follow-up Stage 9 for deferred major updates.
- **FAIL**: Do not merge. Fix or revert. Re-run verification.

## Known Failure Patterns

1. **Peer dependency conflicts**: Package A requires React 18, Package B requires React 19. Find compatible versions first; AVOID `--legacy-peer-deps`. **Resolution flowchart**: (1) Do versions overlap? Update to higher. (2) Can one be downgraded? Downgrade less-critical. (3) Substitute available? Switch packages. (4) Last resort: document, add `--legacy-peer-deps` with rationale.
2. **Lock file regeneration**: never delete the lock file. See Lock File Strategy below.
3. **Type definition mismatches**: always update `@types/*` alongside runtime packages.
4. **PostCSS/Tailwind breakage**: CSS toolchain is fragile across versions (especially Tailwind v4). Test styling thoroughly after CSS-related updates.
5. **Backend SDK updates**: May require schema migration or codegen re-runs (see Teammate 3 instructions).
6. **Build-only breakage**: Tests pass but production build fails. always run `build` after major updates.
7. **Node.js/Bun version requirements**: New versions may require newer runtime.
8. **Environment variable changes**: Auth/payment SDK updates may rename env vars.
9. **Playwright browser binary mismatch**: Run `bunx playwright install --with-deps` after updating Playwright.

## `.claude/rules/` Staleness Review

During each maintenance run, review all path-scoped rules for staleness:
1. Read all rule files in `.claude/rules/`.
2. For each rule, check: deprecated API reference? Removed package? Renamed function? Non-existent file paths? Tech stack changed since rule was generated? Issue structurally resolved by framework upgrade?
3. Remove or update stale rules. Log changes in the report.
4. Review `plancasting/_rules-candidates.md`: Remove candidates >60 calendar days old without promotion or re-trigger, or pending 2+ maintenance cycles without promotion — whichever comes first.

## Monorepo Adaptation

If the project uses workspaces (npm/yarn/pnpm workspaces, Turborepo, Nx):
- Update ROOT `package.json` and lock file first
- Update shared/library workspace packages before consumer packages (e.g., `packages/shared` before `packages/web`)
- Update consumer workspace packages last
- Verify consistent versions across workspaces: `npm list [package-name]`
- **Yarn workspaces**: `yarn workspaces foreach --all run test` (Yarn 3+)
- **pnpm workspaces**: `pnpm -r run test`

## Lock File Strategy

- never delete the lock file to resolve conflicts. Lock file deletion creates unpredictable transitive dependency changes.
- Instead: (1) identify the conflicting package, (2) downgrade or upgrade that specific package, (3) run install to update the lock file.
- For `bun.lockb` (binary): cannot be manually edited -- regenerated by `bun install` after resolving conflicts in `package.json`. Do not attempt manual edits.
- For `package-lock.json` or `pnpm-lock.yaml` (text): resolve conflicting entries directly, then reinstall.
- Commit the updated lock file after each successful update batch.
- For `bun.lockb`, verify integrity:
  1. Record hash before update: `{ shasum -a 256 2>/dev/null || sha256sum; } < bun.lockb`
  2. After `bun install`, run `bun install` again (should be idempotent)
  3. If lock file changes on second install, dependency resolution is unstable -- investigate
- Only as absolute last resort (after all strategies exhausted): delete, fresh install, document in report, flag for architecture review.

## Running Cadence

- **Monthly**: Products with strict security requirements or rapidly evolving dependencies.
- **Quarterly**: Most products in active development.
- **On trigger**: When `npm audit` reports a critical vulnerability.

Each run produces a report in `./plancasting/_maintenance/` with the date, building a maintenance history.

## Cross-Stage References

- UI regressions from updates: run **Stage 6V** (Visual & Functional Verification).
- After deploying updates: run **Stage 7V** (Production Smoke Verification).
- User-reported issues from dependency changes: process through **Stage 8** (Feedback Loop).
- If UI component library or styling framework updated: consider re-running **Stage 6D** (developer docs) if they reference the old API, and **Stage 7D** (user guide) to recapture screenshots.

## Critical Rules

1. never update all dependencies at once -- batch by risk tier (security -> patch -> minor -> major).
2. AVOID `--legacy-peer-deps` to force-resolve conflicts. Document if absolutely necessary with rationale: (1) conflict between uncontrolled packages, (2) tested together without issues, (3) no CVE for mismatched versions. Note: `--legacy-peer-deps` is npm-specific. Bun handles peers differently; pnpm uses `--strict-peer-dependencies=false`.
3. never delete the lock file to resolve conflicts.
4. always commit to the maintenance branch after each successful tier for granular rollback.
5. always run `build` (not just `test`) after major updates.
6. always run `lint` after updates -- new plugin versions may introduce rules.
7. Re-run backend code generation IMMEDIATELY and UNCONDITIONALLY after backend SDK updates (e.g., `bunx convex codegen`). Codegen is a GATE -- do not run tests before codegen.
8. For major framework updates, recommend re-running Stage 6V.
9. After deploying, run Stage 7V.
10. Co-dependent packages must be updated together (e.g., `react` + `@types/react`, all `@radix-ui/*`).
11. never run Stage 9 and Stage 8 concurrently. Complete one and commit before starting the other.
