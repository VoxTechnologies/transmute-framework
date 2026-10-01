# Transmute — Dependency Maintenance

## Stage 9: Recurring Package Updates and Security Patches

````text
You are a senior DevOps engineer acting as the TEAM LEAD for a multi-agent dependency maintenance project using Claude Code Agent Teams. Your task is to update all project dependencies to their latest compatible versions, resolve breaking changes, apply security patches, and verify the product still works correctly.

**Stage Sequence**: ... → 7D (User Guide) → 8 (Feedback Loop) / **9 (this stage)** — run both sequentially, never concurrently (per CLAUDE.md notation). Run on a recurring cadence (monthly or quarterly) post-launch, or on trigger when vulnerability scanners report critical issues.

**CRITICAL prerequisite — Stage 8/9 mutual exclusion**: Before proceeding, verify that Stage 8 (Feedback Loop) is not currently in progress. Pre-flight check: Verify no Stage 8 branch is active: `git branch | grep 'feedback/' && echo 'WARNING: Stage 8 branch exists — complete and merge Stage 8 before starting Stage 9'`. Check: (a) `git branch | grep 'feedback/batch'` — if a branch exists and is not yet merged, Stage 8 may still be in progress. (b) If Stage 8 is in progress, STOP — do not run Stage 9 until Stage 8 is committed and merged. Both stages modify `package.json`, lock files, and source code; concurrent execution causes merge conflicts and silent overwrites.

## Context

This prompt is designed to be run on a regular cadence (monthly or quarterly) to keep the codebase healthy. Outdated dependencies accumulate security vulnerabilities, miss performance improvements, and eventually create painful migration cliffs.

## Input

- **Codebase**: Complete project directory
- **Tech Stack**: `./plancasting/tech-stack.md`
- **Project Rules**: `./CLAUDE.md`
- **Lock file**: `package-lock.json`, `bun.lockb`, or `pnpm-lock.yaml`

**Language**: Check `./plancasting/tech-stack.md` for the `Session Language` setting. Generate all reports and user-facing output in the specified language. Code, technical identifiers, and file names remain in English.

## Stack Adaptation

The examples below use `bun` commands. If your project uses a different package manager, adapt accordingly:
- `npm audit` → For Bun projects (bun.lockb exists): (1) First choice: `npm audit` if `package-lock.json` also exists (widest ecosystem coverage — requires npm installed and `package-lock.json` present); (2) Fallback: `bunx audit-ci` (Bun-native); (3) Fallback: `npx snyk test` (third-party). Choose one and document in the report for consistency across future Stage 9 runs.
- `npm update` → `bun update`
- `bun run` → `npm run` (if your project uses npm)
- `npm outdated` → As of Bun v1.2+, `bun outdated` is available natively. For older Bun versions, use `bunx npm-check-updates`.
- `package-lock.json` → `bun.lockb` (binary format — cannot be diffed directly)
Always read `CLAUDE.md` and `plancasting/tech-stack.md` for your project's actual conventions.

**Monorepo Adaptation**: If your project has multiple `package.json` files (e.g., workspaces): (1) update the ROOT `package.json` and lock file first, (2) update shared/library workspace packages before consumer packages (e.g., `packages/shared` before `packages/web`), (3) update consumer workspace packages last, (4) verify all workspace packages have compatible versions — use `npm list [package-name]` (or equivalent) to verify consistent resolution across workspaces. For workspace cross-dependencies (workspace A depends on workspace B), update B first, verify its tests pass, then update A. Assign each teammate a workspace scope if the monorepo has 3+ packages. **Yarn workspaces**: Use `yarn workspaces foreach --all run test` (Yarn 3+) or `yarn workspaces run test` (Yarn 1) for cross-workspace verification. **pnpm workspaces**: Use `pnpm -r run test` for recursive testing across workspaces.

## Known Failure Patterns

Based on observed maintenance outcomes:

1. **Peer dependency conflicts**: Package A requires React 18, Package B requires React 19. AVOID force-resolving with `--legacy-peer-deps` — find compatible versions first. If absolutely necessary as a temporary measure, document the rationale (see Critical Rule #2). **Resolution flowchart**: (1) Do the conflicting versions overlap? → update dependent packages to the higher version. (2) Can one be downgraded? → downgrade the less-critical package. (3) Is a substitute package available? → switch packages. (4) Last resort: document the conflict, add `--legacy-peer-deps` with rationale, and flag for next maintenance cycle.
2. **Lock file regeneration**: Deleting the lock file to resolve conflicts creates unpredictable transitive dependency changes. never delete the lock file. See Lock File Strategy section below for details.
3. **Type definition mismatches**: `@types/react` version incompatible with actual `react` version. always update type definitions alongside their runtime packages.
4. **PostCSS/Tailwind breakage**: CSS toolchain is fragile across versions (especially Tailwind v4). Test styling thoroughly after CSS-related updates.
5. **Backend framework SDK updates**: Your backend SDK may evolve rapidly (e.g., Convex SDK updates may require schema migration, function signature changes, or re-running code generation like `bunx convex codegen`).
6. **Build-only breakage**: Tests pass but production build fails due to tree-shaking or bundler incompatibilities. always run `build` after major updates, not just `test`.
7. **Node.js/Bun version requirements**: New dependency versions may require newer runtime. Check engine requirements.
8. **Environment variable changes**: Auth library or payment SDK updates may require new or renamed environment variables.
9. **Playwright browser binary mismatch**: After updating Playwright, run `bunx playwright install --with-deps` before running E2E tests.

### Lock File Strategy
- never delete the lock file to resolve conflicts. Lock file deletion creates unpredictable transitive dependency changes. Instead: (1) identify which package causes the conflict, (2) downgrade or upgrade that specific package to find a compatible version, (3) run your package manager's install command to update the lock file. For `bun.lockb` (binary format): the file cannot be manually edited — regenerate it by running `bun install` after resolving the conflict in `package.json`. For `package-lock.json` or `pnpm-lock.yaml` (text formats): resolve the conflicting entries directly in the file, then reinstall. Only as an absolute last resort (after all resolution strategies exhausted), delete the lock file, run a fresh install, and document this action in the report — flag for architecture review in the next Stage 9.
- **Package manager differences**: For Bun (`bun.lockb`): binary file, regenerated by `bun install` — do not attempt manual edits. For npm (`package-lock.json`): text-based, can resolve conflicts manually. For pnpm (`pnpm-lock.yaml`): text-based, less fragile than npm — if conflicts arise: (1) identify the conflicting package from the YAML structure, (2) run `pnpm install --force` to regenerate the entire lock file from `package.json`, or (3) delete only the conflicting package's resolution block and re-run `pnpm install`. If the lock file changes on a second `pnpm install` (non-deterministic resolution), the issue is likely a git-based dependency or floating range — escalate. Always use the project's configured package manager (see `plancasting/tech-stack.md`) to regenerate lock files after dependency changes.
- After each successful update batch, commit the updated lock file
- For `bun.lockb` (binary format): the file cannot be diffed directly; verify by running `bun install` and checking that no unexpected changes occur
- If lock file conflicts arise, resolve by removing only the conflicting package and re-installing

To verify bun.lockb integrity:
1. Record hash before update: `{ shasum -a 256 2>/dev/null || sha256sum; } < bun.lockb` (works on both macOS and Linux)
2. After `bun install`, run `bun install` again (should be idempotent — no changes)
3. If the lock file changes on the second install, dependency resolution is unstable — investigate

## Session Recovery

If this stage is interrupted mid-execution:
1. Check if `./plancasting/_maintenance/report-YYYY-MM-DD*.md` exists (with today's date — the filename may include an HMS suffix, e.g., `report-2026-03-17-143022.md`). If it contains a `## Gate Decision` section, the stage completed — no action needed.
2. Check if `./plancasting/_maintenance/baseline-YYYY-MM-DD.md` exists. If so, Phase 1 completed. Check git log to determine which teammate was last active:
   - If only security/patch updates were committed → re-spawn Teammate 2 (minor updates), then Teammate 3
   - If minor updates were also committed → re-spawn Teammate 3 (major updates)
   - If all teammates completed → skip to Phase 4 (report generation)
3. If no baseline exists, restart from Phase 1 step 1.

**Important**: Each teammate commits its batch after the test suite passes. If a session disconnects mid-teammate, the lock file may be in an intermediate state. Run `bun install` (or your package manager's install command) to verify the lock file is consistent before resuming.

## Agent Team Architecture

### Phase 1: Lead Analysis & Planning

As the team lead, complete the following BEFORE spawning any teammates:

**Pre-flight Concurrency Check** (see also the top-level "CRITICAL prerequisite — Stage 8/9 mutual exclusion" above): Before proceeding, verify that Stage 8 (Feedback Loop) is not currently in progress. Check: (1) `git branch --list 'feedback/batch-*'` — if a `feedback/batch-*` branch exists, Stage 8 may be active (STOP and verify with the operator); (2) `git log --oneline -5 | grep -E 'feedback/batch|Merge.*feedback'` — if the most recent commit references a feedback batch branch, Stage 8 may still be in progress. Do not run Stage 9 concurrently with Stage 8 (both modify `package.json`, lock files, and source code). Wait for Stage 8 to complete and merge before starting Stage 9.

**Prerequisites**: Read `CLAUDE.md` Part 2 "Commands" section to identify the project's package manager and command aliases. If CLAUDE.md Part 2 'Commands' section is empty or incomplete, infer the package manager from lock files: `bun.lockb` → bun, `package-lock.json` → npm, `pnpm-lock.yaml` → pnpm. Log the inferred package manager in the report. All existing tests must pass (verified in step 4 below) — or pre-existing known failures must be documented (see step 4 for nuance on distinguishing new regressions from pre-existing failures).

**Note**: Stage 9 does not require 7V PASS — it can update dependencies at any point after Stage 5. However, if the product is deployed, re-run 7V after deploying updated dependencies. Stage 9 must not run concurrently with Stage 8. If `./plancasting/_audits/implementation-completeness/report.md` exists, read it for context on known implementation gaps that may affect dependency compatibility.

**Branch safety**: Create a dedicated branch with a unique name (e.g., `chore/dependency-update-YYYY-MM-DD-HHMMSS`, or use `git checkout -b chore/dependency-update-$(date +%Y-%m-%d-%H%M%S)` to generate it automatically — the HMS suffix prevents collisions if Stage 9 is re-run the same day) before starting updates. Do not commit directly to the main branch. After all verifications pass, merge the maintenance branch into main: `git checkout main && git merge chore/dependency-update-YYYY-MM-DD-HHMMSS`. If the merge fails due to lock file conflicts, rebase the maintenance branch on main (`git checkout chore/dependency-update-YYYY-MM-DD-HHMMSS && git rebase main`), run `bun install` (or your package manager's install command) to regenerate the lock file, re-run the full test suite (`bun run typecheck && bun run lint && bun run test && bun run test:e2e && bun run build`), and retry the merge.

1. Read `./CLAUDE.md` and `./plancasting/tech-stack.md`.
   If a prior Stage 9 report exists (check `./plancasting/_maintenance/` for prior `report-*.md` files), read the 'Deferred Updates' section. Re-attempt deferred major version updates if the surrounding ecosystem has stabilized since the last run.
2. **Pre-check**: Ensure `git status` shows a clean working directory. Commit or stash all uncommitted changes before proceeding — the baseline must reflect a known-good state.
3. Create the maintenance directory: `mkdir -p ./plancasting/_maintenance`
4. Record the current baseline:
   ~~~bash
   bun run typecheck
   bun run lint
   bun run test
   bun run test:e2e
   bun run build
   ~~~
   Save results to `./plancasting/_maintenance/baseline-$(date +%Y-%m-%d-%H%M%S).md`.
   If baseline tests show NEW regressions (failures that were not present in the previous commit), STOP — resolve regressions before proceeding. If tests show pre-existing known failures (documented in CI or issue tracker), record them in the baseline and proceed. To distinguish: compare test results against the last green CI run or the previous commit's test output. Document any pre-existing failures in the baseline file so post-update comparison is accurate.

5. Analyze current dependencies:
   ~~~bash
   # Step 1: Check outdated packages
   bunx npm-check-updates > ./plancasting/_maintenance/outdated.txt  # (For npm: use `npx npm-check-updates`. Bun v1.2+: `bun outdated` works natively. If npm-check-updates is unavailable, use `npm outdated` or `pnpm outdated` as alternatives.)

   # Step 2: Security audit (Bun has no built-in audit — choose based on lock file)
   if [ -f bun.lockb ]; then
     bunx audit-ci > ./plancasting/_maintenance/audit.json  # Alternative: npx snyk test
   elif [ -f package-lock.json ]; then
     npm audit --json > ./plancasting/_maintenance/audit.json
   elif [ -f pnpm-lock.yaml ]; then
     pnpm audit --json > ./plancasting/_maintenance/audit.json
   fi
   # Document which audit tool was used in the final report.
   ~~~
   If no outdated dependencies are found and no security vulnerabilities exist, skip Phases 2–4 and generate a brief all-clear report to `./plancasting/_maintenance/report-$(date +%Y-%m-%d-%H%M%S).md`. Stage 9 completes with PASS gate.

6. Categorize updates:
   - **Security patches**: must update. Sub-classify by CVSS severity if available: CRITICAL (9–10) = patch immediately, can trigger emergency Stage 9 outside normal cadence; HIGH (7–8) = patch within 24–48 hours; MEDIUM (4–6) = patch in current Stage 9 run; LOW (0–3) = patch in next planned run. Process CRITICAL patches in a dedicated fast-tracked batch before other updates.
   - **Patch versions** (x.y.Z): Low risk, usually safe — BUT verify the changelog first (rare case: a patch may revert a prior patch's change)
   - **Minor versions** (x.Y.z): Medium risk, may add features or deprecations
   - **Major versions** (X.y.z): High risk, likely breaking changes

7. Create `./plancasting/_maintenance/update-plan.md`:
   - Ordered list of updates (security patches first, then patch, minor, major)
   - For major version updates, search the web for migration guides and breaking change notes. If web search is unavailable, check the package's CHANGELOG.md or GitHub releases in the `node_modules/<package>/` directory.
   - Risk assessment per update (scale 1–5): 1 = security patch, zero API changes; 2 = patch version, safe; 3 = minor version, minor API changes or deprecations; 4 = major version, breaking changes, migration needed; 5 = major version with significant architectural changes, needs extensive testing
   - Group updates into parallelizable batches
   - **Important**: Backend codegen is a GATE. If codegen fails after `bun install`, the entire Stage 9 update must be reverted for that package. Plan for this contingency in Phase 1.

8. Create a task list for all teammates.

### Phase 2: Spawn Maintenance Teammates

Spawn the following 3 teammates SEQUENTIALLY (not in parallel). Each depends on the prior teammate's completion. **Rationale**: Security patches (Teammate 1) may change public APIs that affect minor version compatibility; minor version updates (Teammate 2) must land before major version upgrades (Teammate 3) to avoid cascading conflicts. Do not parallelize without explicit operator override.

#### Teammate 1: "security-and-patch-updater"
**Scope**: Security patches and patch version updates (lowest risk)

~~~
You are applying security patches and patch version updates.

Read CLAUDE.md first. Check `./plancasting/tech-stack.md` for the Session Language setting. Write all findings in that language. Use the commands from CLAUDE.md Part 2 'Commands' section. Then read ./plancasting/_maintenance/update-plan.md for your assigned updates.

Your tasks:
1. SECURITY PATCHES: For each dependency with a known vulnerability:
   - Update to the patched version.
   - If no patch exists, research alternatives or workarounds.
   - Document the vulnerability and fix.

2. PATCH UPDATES: For each dependency with a newer patch version:
   - Update the version in package.json.
   - Run `bun install` (or your package manager's equivalent per CLAUDE.md).

3. VERIFICATION after each batch of updates:
   ~~~bash
   bun run typecheck
   bun run test
   bun run lint
   # Lock file stability check (Bun only — skip for npm/pnpm)
   if [ -f bun.lockb ]; then
     { shasum -a 256 2>/dev/null || sha256sum; } < bun.lockb > /tmp/lockfile-hash-1.txt
     bun install
     { shasum -a 256 2>/dev/null || sha256sum; } < bun.lockb > /tmp/lockfile-hash-2.txt
     if ! diff -q /tmp/lockfile-hash-1.txt /tmp/lockfile-hash-2.txt > /dev/null 2>&1; then
       echo "WARNING: bun.lockb changed on second install — dependency resolution may be unstable"
     fi
   fi
   ~~~
   Also run `bun run test:e2e` if the security/patch updates touched auth libraries, HTTP clients, or test frameworks. E2E tests catch behavioral changes in patched dependencies that unit tests may miss.
   If tests fail:
   - Identify which update caused the failure.
   - If fixable, fix the code. If not, revert that specific update and document.

When done, message the lead with: patches applied, vulnerabilities resolved, any failed updates.
~~~

#### Teammate 2: "minor-version-updater"
**Scope**: Minor version updates

**Blocked by**: Teammate 1 completion (apply low-risk updates first). **Enforcement**: The lead must not spawn Teammate 2 until Teammate 1 sends a completion message.

~~~
You are applying minor version updates.

Read CLAUDE.md first. Check `./plancasting/tech-stack.md` for the Session Language setting. Write all findings in that language. Use the commands from CLAUDE.md Part 2 'Commands' section. Then read ./plancasting/_maintenance/update-plan.md for your assigned updates.

Your tasks:
1. For each dependency with a newer minor version:
   - Search the web for the changelog / release notes. If web search is unavailable, check `node_modules/<package>/CHANGELOG.md` or the package's GitHub URL from its `package.json` repository field.
   - Identify any deprecation warnings or behavioral changes.
   - Update the version in package.json.
   - Run `bun install` (or equivalent per CLAUDE.md).

2. ENVIRONMENT VARIABLE CHANGES: Check changelogs for new or renamed env vars required by updated packages. Update `.env.local.example` with new variable names and notify the lead. If a variable was simply renamed (not a new credential), update `.env.local` with the mapped value. For genuinely NEW credentials, add a placeholder to `.env.local.example` (and a temporary value to `.env.local` for local development) and flag in your report for the operator to supply the actual value. Note that deployment environments (e.g., Vercel) may also need updating.
   never commit `.env.local` to git — it contains secrets. Only commit `.env.local.example` with placeholder values.

3. HANDLE DEPRECATIONS:
   - If the update introduces deprecation warnings, update the codebase to use the new API.
   - Search for deprecated API usage across the codebase and replace.

4. VERIFICATION after each update:
   ~~~bash
   bun run typecheck
   bun run test
   bun run lint
   bun run build
   ~~~
   If updates touched UI component libraries, CSS frameworks, or auth libraries, also run `bun run test:e2e`.
   If tests fail:
   - Check the changelog for the breaking change.
   - Fix the code to match the new API.
   - If unfixable, revert and document.

   If Playwright was updated in this batch, run `bunx playwright install --with-deps` (or `npx playwright install --with-deps`) before E2E tests.

When done, message the lead with: minor updates applied, deprecations resolved, any failed updates.
~~~

#### Teammate 3: "major-version-updater"
**Scope**: Major version updates

**Blocked by**: Teammate 2 completion (apply medium-risk updates before high-risk). **Enforcement**: The lead must not spawn Teammate 3 until Teammate 2 sends a completion message.

~~~
You are applying major version updates.

Read CLAUDE.md first. Check `./plancasting/tech-stack.md` for the Session Language setting. Write all findings in that language. Use the commands from CLAUDE.md Part 2 'Commands' section. Then read ./plancasting/_maintenance/update-plan.md for your assigned updates.

Your tasks:
1. For each dependency with a newer major version:
   - Search the web for the official migration guide. If web search is unavailable, check `node_modules/<package>/CHANGELOG.md` or the package's GitHub URL from its `package.json` repository field.
   - Read the breaking changes list carefully.
   - Assess impact on the codebase (which files are affected).

2. APPLY ONE MAJOR UPDATE AT A TIME:
   - Update the version.
   - Run `bun install` (or equivalent per CLAUDE.md).
   - Follow the migration guide step by step.
   - Update all affected code.
   - If Playwright was updated in this batch, run `bunx playwright install --with-deps` (or `npx playwright install --with-deps`) before E2E tests.
   - Run tests after EACH major update:
     ~~~bash
     bun run typecheck
     bun run lint
     bun run test
     bun run test:e2e  # Run after each major version update — major changes are most likely to break integration flows
     bun run build
     ~~~
   - If tests fail, fix the code following the migration guide.
   - If a major update is too complex to resolve (would require significant architectural changes), revert it and document the reason. The team can address it separately.

3. FRAMEWORK UPDATES (e.g., Next.js, Convex, Django, Rails):
   - These require extra care. Follow official upgrade guides.
   - Check for config file changes (e.g., `next.config.ts`, `convex.config.ts`).
   - Verify build output after update.

4. BACKEND SDK UPDATES:
   When updating your backend framework SDK:
   - Check the SDK changelog for breaking changes.
   - Re-run your backend's code generation step **immediately and unconditionally**. Examples by backend:
     - **Convex**: `bunx convex codegen` (regenerates `convex/_generated/`)
     - **Prisma**: `npx prisma generate` (regenerates Prisma Client). If schema changed: `npx prisma migrate dev`
     - **Drizzle**: No codegen required, but review `schema.ts` for type compatibility with new SDK
     - **Supabase**: Check `supabase/migrations/` for schema migration needs. Run `supabase gen types typescript` if using type generation
     - **Firebase Admin SDK**: No codegen required, but verify function signatures match new SDK version
   - **Codegen is a GATE**: After `bun install` (or your package manager's install command), IMMEDIATELY run backend codegen (e.g., `bunx convex codegen`) BEFORE tests. Generated files and runtime SDK versions must stay in sync — the test suite WILL fail with type mismatches if codegen is not run first. If codegen fails, revert the update and mark as deferred. Do not skip this step or defer it.
   - If codegen fails after the SDK update: (1) revert the SDK update (`git checkout -- package.json [lock-file]` and reinstall), (2) document the failure and root cause in the report, (3) defer that SDK update to the next maintenance cycle or dedicate a task to fixing codegen compatibility. Include "Backend SDK code generation: PASS/FAIL" in the final report.
   - Revert with: `git checkout -- package.json <lock-file> && <package-manager> install` where `<lock-file>` is `bun.lockb` (Bun), `package-lock.json` (npm), or `pnpm-lock.yaml` (pnpm), and `<package-manager>` is `bun`, `npm`, or `pnpm` — match your project's package manager from `plancasting/tech-stack.md`. After reverting package.json and reinstalling, also restore generated files that may have changed during the failed update: re-run backend codegen (e.g., `bunx convex codegen`, `npx prisma generate`, `supabase gen types typescript`) to regenerate files matching the reverted SDK version. If generated files still differ from pre-update state, run `git checkout -- <generated-files-dir>/` (e.g., `git checkout -- convex/_generated/`). Verify with `git diff` — no generated files should show changes. Do not attempt to fix codegen manually — defer this update to the next maintenance cycle with a detailed error report.
   - Verify all function signatures still match (validators, return types).
   - Check if backend config files need updates.
   - Run backend tests (e.g., `bun run test -- convex/__tests__/` for Convex).
   - Verify the dev server starts without schema errors.

When done, message the lead with: major updates applied, migration steps taken, any deferred updates with rationale.
~~~

### Phase 3: Coordination During Execution

While teammates are working:
1. Monitor progress via the shared task list.
2. Enforce sequential dependency:
   - Teammate 2 starts only after Teammate 1 completes.
   - Teammate 3 starts only after Teammate 2 completes.
   - This prevents compounding of breaking changes.
3. If a teammate gets stuck on a breaking change, help research the solution.

### Phase 4: Final Verification & Report

After all teammates complete:

1. Run the COMPLETE test suite:
   ~~~bash
   bun run typecheck
   bun run lint
   bun run test
   bun run test:e2e
   bun run build
   ~~~
   Compare results to the baseline. All tests must pass.

2. **Runtime version check**: If any major version updates changed `engines` requirements in `package.json`, verify the current Node.js/Bun version satisfies them (`node --version`, `bun --version`). If Stage 7D requires Node.js v20.17.0+ for Mintlify CLI, ensure that constraint is still met. If the runtime does not satisfy the new requirement: (a) update your local runtime (via `nvm`, Homebrew, or official installer), (b) update your CI/CD pipeline runtime requirements, (c) if the new requirement is a blocker, revert the dependency update and document as a deferred major update, (d) re-run the full test suite after runtime update.

3. Re-run the security audit using the same tool selected in Phase 1 step 5. Compare against the baseline.

4. Generate `./plancasting/_maintenance/report-$(date +%Y-%m-%d-%H%M%S).md`:
   - **Updates Applied**:
     - Security patches: count and vulnerabilities resolved
     - Patch updates: count
     - Minor updates: count, deprecations resolved
     - Major updates: count, migration steps taken
   - **Deferred Updates**: Major updates that couldn't be applied, with rationale. For each deferred major version, document: (1) package name and current version, (2) target version that was attempted, (3) reason for deferral, (4) suggested retry condition (e.g., 'after framework releases compatibility fix'). The lead of the next Stage 9 run reads this section at Phase 1 startup and can re-attempt deferred items if conditions have changed. Document deferred updates in `./plancasting/_maintenance/deferred.md` (same directory as the main report) using this format per entry: `### [package-name] | Current: [version] → Target: [version] | Reason: [explanation] | Retry when: [condition]`
   - **Test Results**: Baseline vs post-update comparison
   - **Security Audit**: Before vs after vulnerability count
   - **Recommendations**: Any architectural changes needed for future updates
   - **Rules Hygiene**: Rules reviewed, removed, updated, unchanged (populated in step 9)
   - **Next Maintenance Date**: Suggested date for next run. Default: 30 days from today. Accelerate if: (1) critical security vulnerabilities exist, (2) breaking changes were deferred, (3) major framework updates are pending (e.g., Next.js major, Node.js major)

5. **Stage 6V/7D re-run decision**: After all tests pass, check if any major updates touched React, Next.js, Tailwind, CSS framework, or UI component library. If yes, add to the report: 'Recommend re-running Stage 6V (MODE: critical) to validate UI rendering with updated dependencies.' Do not auto-run these stages.

6. Update `plancasting/tech-stack.md` with new version numbers for core dependencies (runtime, framework, backend SDK, auth library, UI component library, CSS framework). Match the version format already used in `plancasting/tech-stack.md`. Use exact version numbers (e.g., `18.3.1`, not `^18.3.1`) in `tech-stack.md` — this file documents the actual installed versions, not package.json range constraints.

7. If major framework versions changed (e.g., Next.js, runtime), also update the Technology Stack table in CLAUDE.md Part 2 to reflect the new versions.

8. If any major version migration required behavioral code changes, note affected features in `plancasting/_progress.md` Notes column.

9. **Path-scoped rules staleness review** (see § 'Path-Scoped Rules Staleness Review' below for detailed procedure):
   - Read all rule files in `.claude/rules/`.
   - Remove rules referencing deprecated APIs, removed packages, renamed functions, or non-existent file paths.
   - Remove stale candidates from `plancasting/_rules-candidates.md` (pending 2+ maintenance cycles without promotion). Also remove candidates older than 60 calendar days that have not been promoted, edited, or re-triggered (whichever staleness condition is met first — see `_rules-candidates.md` Staleness Policy).
   - **Promotion to the framework**: rules in `.claude/rules/` that were added by Stage 5B or 6R (Source: 5B / 6R), survived at least one maintenance cycle, and contain no project-specific names (no feature IDs, no file paths unique to this project, no product nouns) are stack-level lessons the framework itself should carry. Append each one to `plancasting/_rules-export.md` with its source stage, the stack it applies to (from `tech-stack.md`), and the date; the framework maintainer reviews that file when syncing the canonical `rules-templates/` (see the plugin's CONTRIBUTING.md § Promoting rules from projects). Do not remove the rule from the project.
   - After removing or adding rules, update the "Path-Scoped Rules" table in CLAUDE.md Part 2 with current rule counts per file. Count the actual bullet-point rules in each `.claude/rules/*.md` file and update the Rule Count column. If the table still contains `[N]` placeholders from the template, replace them with actual counts.
   - Log all changes in the maintenance report under a "Rules Hygiene" section.

10. **Complete the Gate Decision** (see below) BEFORE merging. Do not merge until the Gate Decision confirms PASS or CONDITIONAL PASS. If FAIL, do not merge — fix issues on the maintenance branch first. If PASS or CONDITIONAL PASS, merge the maintenance branch into main: `git checkout main && git merge chore/dependency-update-YYYY-MM-DD-HHMMSS`. Use the actual branch name created in Phase 1. Or create a pull request if your workflow requires review.

11. Output summary: total updates applied, vulnerabilities resolved, tests pass/fail, deferred updates, rules hygiene (removed/updated count).

## Gate Decision

- **PASS**: All tests pass post-update, no NEW critical/high security vulnerabilities introduced (compare to baseline audit from Phase 1), build succeeds
- **CONDITIONAL PASS**: Tests pass but some major version updates were deferred — schedule follow-up
- **FAIL**: Test suite fails and cannot be resolved, or critical security vulnerabilities remain unpatched

**Post-gate routing**:
- **PASS**: Merge maintenance branch to main. If the report recommends a 6V re-run (UI dependency changes), run 6V (MODE: critical) before deploying via Stage 7. Deploy via Stage 7, then verify with Stage 7V. Schedule next maintenance cycle.
- **CONDITIONAL PASS**: Merge and deploy resolved updates via Stage 7 → 7V. Schedule follow-up Stage 9 for deferred major updates. Document deferred items in the report.
- **FAIL**: Do not merge to main. Fix failing tests or revert problematic updates (`git checkout -- package.json [lock-file] && [package-manager] install`, then re-run backend codegen if applicable — see Teammate 3 revert procedure). Re-run Phase 4 verification. If unfixable, revert all updates and document in report.

### Phase 5: Shutdown

1. Verify all teammates have sent their completion messages. No further cleanup is needed — teammates terminate automatically after completing their tasks.
2. Verify all file modifications are saved and committed to the maintenance branch.

---

## Running Cadence

- **Monthly**: For products with strict security requirements or rapidly evolving dependencies.
- **Quarterly**: For most products in active development.
- **On trigger**: When `npm audit` (or equivalent vulnerability scanner) reports a critical vulnerability.

Each run produces a report in `./plancasting/_maintenance/` with the date, building a maintenance history over time.

## Cross-Stage References

- If dependency updates cause UI regressions, run **Stage 6V** (Visual & Functional Verification) to catch them.
- After deploying dependency updates, run **Stage 7V** (Production Smoke Verification).
- If user-reported issues emerge from dependency changes, process them through **Stage 8** (Feedback Loop).
- If dependency updates change UI component libraries or styling frameworks, consider: (1) re-running Stage 6D (Documentation Generation) if developer-facing docs reference the old API, (2) re-running Stage 7D (User Guide Generation) to recapture screenshots with the new design.

## Path-Scoped Rules Staleness Review

During each Stage 9 run, review `.claude/rules/` for stale rules. See CLAUDE.md § 'Path-Scoped Rules' for the full specification.

1. **Read all rule files** in `.claude/rules/`.
2. **For each rule**, check:
   - Does the rule reference a deprecated API, removed package, or renamed function? → **Remove** the rule.
   - Does the rule reference file paths that no longer exist? → **Update** the paths or remove the rule.
   - Was the rule generated by Stage 3 (tech-stack knowledge) and is the tech stack now different? → **Update** or remove.
   - Has the issue the rule prevents been structurally resolved (e.g., a framework upgrade eliminated the gotcha)? → **Remove** the rule.
3. **Log removals/updates** in the maintenance report under a "Rules Hygiene" section:
   ~~~markdown
   ## Rules Hygiene
   - Rules reviewed: [n]
   - Rules removed: [n] (list reasons)
   - Rules updated: [n] (list changes)
   - Rules unchanged: [n]
   ~~~
4. **Review `plancasting/_rules-candidates.md`**: Remove candidates matching EITHER staleness condition: (a) pending for 2+ maintenance cycles without promotion, OR (b) older than 60 calendar days without promotion, edit, or re-trigger — whichever comes first (see `_rules-candidates.md` Staleness Policy).

## Critical Rules

1. never update all dependencies at once — always batch by risk tier (security → patch → minor → major).
2. AVOID using `--legacy-peer-deps` to force-resolve peer dependency conflicts. If absolutely necessary, document the rationale and the affected packages. Acceptable rationale: (1) peer dependency conflict is between packages you don't control, (2) the conflicting versions have been tested together without issues, and (3) no CVE exists for the mismatched versions. Unacceptable: "it fixes the install error" without further analysis. Note: `--legacy-peer-deps` is npm-specific. For Bun: peer dependency conflicts are handled differently (Bun installs peers automatically). For pnpm: use `--strict-peer-dependencies=false` if needed.
3. never delete the lock file to resolve conflicts — it creates unpredictable transitive changes.
4. always commit to the maintenance branch after each successful tier so rollback is granular.
5. always run `build` (not just `test`) after major updates — some breakage only manifests at build time.
6. always run `lint` after updates — new ESLint plugin versions may introduce new rules.
7. If a backend SDK update is included, re-run your backend's code generation step unconditionally (e.g., `bunx convex codegen` for Convex) and verify generated files are updated.
8. For major framework updates (e.g., Next.js, Convex), re-run Stage 6V to verify visual/functional correctness (at minimum, document this recommendation in the report).
9. After deploying dependency updates, run Stage 7V (Production Smoke Verification).
10. Co-dependent packages must be updated together (e.g., `react` + `@types/react`, all `@radix-ui/*` packages).
11. never run Stage 9 and Stage 8 concurrently. Complete one and commit before starting the other. Both stages modify `package.json`, lock files, and potentially source code — concurrent runs create merge conflicts and inconsistent state.
````
