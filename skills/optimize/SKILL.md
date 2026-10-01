---
name: optimize
description: >-
  Audits and optimizes frontend, backend, and perceived performance against PRD budgets.
  This skill should be used when the user asks to "optimize performance",
  "run a performance audit", "improve page speed", "check Lighthouse scores",
  "fix Core Web Vitals", "reduce bundle size", "optimize queries",
  or "improve loading time",
  or when the transmute-pipeline agent reaches Stage 6C of the pipeline.
metadata:
  version: 1.0.0
effort: medium
---

# Performance Optimization — Stage 6C

Read the detailed guide at `${CLAUDE_SKILL_DIR}/references/optimize-detailed-guide.md` for the complete optimization procedures, teammate spawn prompts, benchmark patterns, and report templates.

Lead a multi-agent performance optimization project. Audit the complete product against PRD performance budgets, identify bottlenecks, and implement optimizations.

**Stage Sequence** (recommended ordering): Stage 5B → (6A ‖ 6B ‖ **6C (this stage)**) → 6E → 6F → 6G → 6D → 6H → 6V → 6R → 6P/6P-R → 7 (Deploy). Note: 6A, 6B, and 6C run **in parallel** (each in a separate session). If running in parallel, commit 6A changes as soon as 6A completes to avoid config file conflicts — see CLAUDE.md § "Stage 6 ordering".

## Prerequisite Checks

Before any optimization work, verify:

1. Check that `./plancasting/_audits/implementation-completeness/report.md` exists and shows PASS or CONDITIONAL PASS. If missing, STOP: "Stage 5B report not found — run Stage 5B before starting Stage 6 audits." (Override: if the operator explicitly confirms 5B was intentionally skipped, proceed with a WARN.)
2. If `./plancasting/_audits/security/report.md` (6A) exists, read it to understand security changes that must not be undone during optimization (validation, CSP headers, rate limiting).
3. If `./plancasting/_audits/accessibility/report.md` (6B) exists, read it to understand accessibility patterns (focus ring styles, semantic HTML, `prefers-reduced-motion`) that should not be regressed.
4. If 5B shows FAIL, STOP. If CONDITIONAL PASS, read documented Category C issues and skip optimization for those incomplete features.
5. Read `./CLAUDE.md` and `./plancasting/tech-stack.md` for project conventions.
6. Read relevant PRD sections for implementation context.

## Inputs

- **Codebase**: Backend directory and `./src/` (adapt paths per tech stack)
- **Tech Stack**: `./plancasting/tech-stack.md`
- **PRD Performance Specs**: `./plancasting/prd/15-non-functional-specifications.md`
- **PRD Screen Specs**: `./plancasting/prd/08-screen-specifications.md` (loading states, skeletons)
- **Schema**: Your schema file (e.g., `./convex/schema.ts`)
- **Project Rules**: `./CLAUDE.md`

Check `./plancasting/tech-stack.md` for the `Session Language` setting. Generate reports in that language. Keep code and file names in English.

## Stack Adaptation

Adapt all references to your actual stack per `plancasting/tech-stack.md`:
- `convex/` becomes your backend directory
- `convex/schema.ts` becomes your schema/migration files
- `src/app/` becomes your frontend pages directory
- Convex functions become your backend functions/endpoints

Read `CLAUDE.md` Part 2 for project-specific conventions.

**Package Manager**: Use the package manager specified in `plancasting/tech-stack.md` (default: `bun`).

## Known Failure Patterns

1. **Lighthouse in dev mode**: Always measure against production build, never dev server. never measure against `localhost:3000` in development.
2. **Premature React.memo**: Do not add to every component. Only use where expensive re-renders with unchanged props are measured.
3. **Lazy loading above-the-fold content**: Do not defer critical content visible on initial render — this hurts LCP.
4. **Over-aggressive .take(N)**: Do not truncate queries below the feature's actual data volume.
5. **Breaking Server Components to Client Components**: Do not convert SSR components to client-side solely for optimization hooks. Net negative for performance.
6. **Adding pagination to small lists**: Do not add pagination to lists that will never exceed 50 items.
7. **INP vs FID confusion**: Agent optimizes for First Input Delay (FID) which was deprecated in March 2024 and replaced by Interaction to Next Paint (INP). Lighthouse cannot measure INP directly — use Total Blocking Time (TBT) as a lab proxy. TBT < 200ms generally correlates with good INP.

## Phase 1: Analysis and Baseline

Complete these steps synchronously before spawning any teammates:

1. Read `./CLAUDE.md`, `./plancasting/tech-stack.md`, and `./plancasting/prd/15-non-functional-specifications.md`.
2. **Create the performance baseline** (must complete before spawning teammates — build production, measure, then spawn):
   ```bash
   mkdir -p ./plancasting/_audits/performance
   bun run build && bun run start &
   until curl -s http://localhost:3000 > /dev/null 2>&1; do sleep 1; done
   bunx lighthouse http://localhost:3000 --only-categories=performance --output=json --output-path=./plancasting/_audits/performance/baseline-home.json
   # Repeat for other key pages
   kill $(lsof -ti:3000) 2>/dev/null
   ```
   Record metrics in `./plancasting/_audits/performance/baseline.md`. Mark with: `<!-- ORIGINAL BASELINE — Do not recreate on subsequent 6C RUNS -->`. This file is permanent. never measure against the dev server.
3. Extract all performance budgets from the PRD: page load targets, API response targets, bundle size budgets, Lighthouse score targets, Core Web Vitals targets (LCP, INP, CLS). If the PRD does not specify, use web.dev defaults: LCP < 2.5s, INP < 200ms, CLS < 0.1, Lighthouse Performance > 90.
4. Write `./plancasting/_audits/performance/targets.md` with extracted targets. Document the source (PRD vs defaults).
5. Create a task list for all teammates with dependency tracking.

## Phase 2: Spawn Optimization Teammates

Spawn Teammate 2 (backend) FIRST. After Teammate 2 completes, spawn Teammates 1 and 3 in parallel. Exception: all 3 may start in parallel only if zero index/query optimization opportunities exist and the schema is fully indexed. When ambiguous, err on sequential (Teammate 2 first).

### Teammate 1: frontend-performance

Scope: Bundle size, rendering, Core Web Vitals. Spawn AFTER Teammate 2 completes.

- **Bundle analysis**: Review framework config for optimization settings. Identify large dependencies (>50KB gzipped) and evaluate alternatives or dynamic imports. Use your framework's bundle analyzer (Next.js: `@next/bundle-analyzer` with `ANALYZE=true bun run build`; Vite: `npx vite-bundle-visualizer`). If bundle analyzer cannot be installed: skip automated analysis, use Chrome DevTools Code Coverage instead, document limitation. If Next.js: verify minimal `"use client"` directives, implement `next/dynamic` for heavy non-initial components, verify images use `next/image`.
- **Rendering optimization**: Identify pages benefiting from SSR data loading. Verify loading skeleton screens exist for all routes. Check for unnecessary re-renders from unneeded data subscriptions. Apply `React.memo`/`useMemo` only where expensive computations or frequent re-renders occur — do not blanket-apply. Check for layout shift sources (images without dimensions, dynamically injected content).
- **Asset optimization**: Verify font loading strategy (e.g., `next/font` with `display: swap`). Verify CSS is not importing unused utilities. Check for render-blocking resources.

### Teammate 2: backend-query-performance

Scope: Backend function performance, index utilization, data access patterns. Spawn FIRST.

- **Index audit**: Verify every filtered query uses indexed query methods instead of unindexed filtering. Identify queries benefiting from compound indexes. Add missing indexes to the schema file.
- **Query efficiency**: Flag `.collect()` where `.first()`/`.unique()` suffices. Flag queries fetching more data than needed. Identify N+1 patterns and refactor to batch. Verify pagination for large result sets.
- **Mutation efficiency**: Verify mutations don't read-then-write when direct `.patch()` works. Check for unnecessary database reads. Identify opportunities to combine mutations.
- **Scheduled functions/crons**: Verify cron frequencies match data change rates (cleanup: daily/weekly; aggregation: daily; notifications: hourly/per SLA). Check background job efficiency.

### Teammate 3: perceived-performance

Scope: Perceived performance, loading states, optimistic updates. Spawn AFTER Teammate 2 completes.

- **Loading states**: Verify every page/route has a loading state with a skeleton screen (not a spinner). Verify skeletons match actual layout. Verify data-dependent components show skeletons while query returns undefined. Flag blank-screen loading.
- **Optimistic updates**: Identify user actions that should feel instant (form submissions, toggles, deletions). Implement optimistic updates with graceful rollback on error.
- **Progressive loading**: Verify pagination or infinite scroll for large datasets. Verify above-the-fold loads first. Identify and refactor waterfall loading patterns to parallel.
- **Transition and feedback**: Verify buttons show loading state during async operations. Verify form submit buttons disable to prevent double submission. Verify smooth navigation transitions.

## Unfixable Violation Protocol

When an issue cannot be fixed without architectural changes:

1. Document the full conflict with evidence.
2. Mark as **REQUIRES HUMAN DECISION**.
3. Include recommended approach and estimated effort.
4. If Core Web Vitals FAIL per PRD targets, document as a potential launch blocker for Stage 6H review. Create `./plancasting/_audits/performance/unfixable-violations.md`.
5. Continue with remaining fixable items.

## Phase 3: Coordination

- If backend adds new indexes, notify frontend (query response times may change).
- If perceived-performance finds waterfall patterns, notify backend (may need combined queries).
- Resolve conflicts when multiple teammates modify the same file.

## Phase 4: Verification and Report

1. Run the full test suite: `bun run typecheck`, `bun run lint`, `bun run build`, `bun run test`, `bun run test:e2e`.
2. Run Lighthouse on key pages against a production build. Methodology:
   a. Build for production: `bun run build`
   b. Start production server: `bun run start`
   c. Run at least 3 times and average scores: `for i in 1 2 3; do bunx lighthouse http://localhost:3000 --only-categories=performance --output=json --output-path=./plancasting/_audits/performance/lighthouse-run-$i.json; done`
   d. Measure Core Web Vitals:
      - LCP (Largest Contentful Paint): Target < 2.5s
      - INP (Interaction to Next Paint): Target < 200ms. Note: INP is a real-user metric — Lighthouse cannot measure it directly. Use TBT (Total Blocking Time) < 200ms as lab proxy. TBT = main thread blocking during load; INP = responsiveness to user interactions.
      - CLS (Cumulative Layout Shift): Target < 0.1
   e. Use Lighthouse default throttling (simulated 4G), cold cache.
   f. **Baseline Preservation**: On first 6C run, create baseline. On subsequent re-runs, do not recreate — always measure against the ORIGINAL baseline.
   g. Read PRD targets first; use web.dev Good thresholds only as defaults.
3. Generate `./plancasting/_audits/performance/report.md` containing:
   - Performance budget compliance table (metric, target, actual, pass/fail)
   - Lighthouse scores per page
   - Optimizations applied by category (bundle, queries, indexes, loading, perceived)
   - Before/after metrics
   - Remaining gaps and recommendations
   - PRD NFR compliance matrix
4. Include a **Gate Decision** under a `## Gate Decision` heading (6H parses this heading):
   - **PASS**: All Core Web Vitals meet targets; performance budget compliant; no critical regressions
   - **CONDITIONAL PASS**: Core Web Vitals on track; non-critical metrics miss targets but are documented as future optimization opportunities
   - **FAIL**: Core Web Vitals FAIL thresholds; performance budget exceeded; critical pages do not load within acceptable time
5. Output summary: total optimizations applied, budget compliance status.

## Phase 5: Shutdown

1. Request shutdown for all teammates.
2. Verify all file modifications are saved and committed.

## Critical Rules

1. never optimize without measuring first — premature optimization adds complexity without benefit.
2. never convert Server Components to Client Components for optimization (Next.js). For non-SSR frameworks: do not convert server-rendered routes to client-only.
3. never run Lighthouse in development mode — always use production build and start commands.
4. always verify optimizations don't break functionality — run the full test suite.
5. always measure bundle size before and after changes using your framework's bundle analyzer.
6. never add `.take(N)` that is too small for the feature's actual data volume.
7. Use commands from CLAUDE.md for testing.
8. Reference Stage 5B output to avoid optimizing incomplete features.
9. INP replaces FID (deprecated March 2024). Use TBT as lab proxy for INP. See Measurement Standards above.
