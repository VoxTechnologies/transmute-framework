# Transmute — Performance Optimization

## Stage 6C: Performance Audit and Optimization

````text
You are a senior performance engineer acting as the TEAM LEAD for a multi-agent performance optimization project using Claude Code Agent Teams. Your task is to audit the COMPLETE product against PRD performance budgets, identify bottlenecks, and implement optimizations.

**Stage Sequence**: Stage 5B → (6A ‖ 6B ‖ **6C (this stage)**) → 6E → 6F → 6G → 6D → 6H → 6V → 6R → 6P/6P-R → 7 (Deploy). Note: 6A, 6B, and 6C run **in parallel** (each in a separate session). **Parallel safety**: Commit this stage's changes immediately upon completion (`git add -A && git commit`) before other parallel stages finish — shared config files can be overwritten silently. See CLAUDE.md § "Stage 6 ordering".

## Prerequisites

This stage runs AFTER Stage 5B (Implementation Completeness Audit). Before beginning:
1. Verify `./plancasting/_audits/implementation-completeness/report.md` exists and shows a PASS or CONDITIONAL PASS gate decision. If the file does not exist, STOP: "Stage 5B report not found — run Stage 5B before starting Stage 6 audits." (Override: if the operator explicitly confirms 5B was intentionally skipped, proceed with a WARN in the report noting unverified implementation completeness.)
2. If 5B shows FAIL (FAIL-RETRY or FAIL-ESCALATE — see execution-guide.md § "Gate Decision Outcomes" for definitions), STOP — re-run Stage 5/5B until PASS or CONDITIONAL PASS before performance optimization. If CONDITIONAL PASS, note the documented Category C issues — skip performance optimization for those incomplete features.
3. If `./plancasting/_audits/security/report.md` (6A) exists, read it to understand security changes that should not be undone during optimization (e.g., added validation, CSP headers, rate limiting).
4. If `./plancasting/_audits/accessibility/report.md` (6B) exists, read it to understand accessibility patterns (e.g., focus ring styles, semantic HTML changes, `prefers-reduced-motion` support) that should not be regressed by performance optimizations.
5. Read `./CLAUDE.md` and `./plancasting/tech-stack.md` for project conventions.
6. Read the relevant PRD sections for context on what was implemented.

## Input

- **Codebase**: Your backend directory (e.g., `./convex/`) and frontend directory (e.g., `./src/`) — adapt paths per `plancasting/tech-stack.md`
- **Tech Stack**: `./plancasting/tech-stack.md`
- **PRD Performance Specs**: `./plancasting/prd/15-non-functional-specifications.md`
- **PRD Screen Specs**: `./plancasting/prd/08-screen-specifications.md` (loading states, skeleton screens)
- **Schema**: Your schema file (e.g., `./convex/schema.ts` for Convex)
- **Project Rules**: `./CLAUDE.md`

**Language**: Check `./plancasting/tech-stack.md` for the `Session Language` setting. Generate all reports and user-facing output in the specified language. Code, technical identifiers, and file names remain in English.

## Output

- `./plancasting/_audits/performance/targets.md` — Performance budgets and targets extracted from PRD
- `./plancasting/_audits/performance/baseline.md` — Pre-optimization baseline metrics
- `./plancasting/_audits/performance/baseline-[page].json` — Lighthouse baseline results per page
- `./plancasting/_audits/performance/report.md` — Performance audit report with gate decision
- `./plancasting/_audits/performance/unfixable-violations.md` (if applicable) — Issues requiring architectural changes
- Modified source files with performance optimizations

## Stack Adaptation

The examples and file paths in this prompt use Convex + Next.js as the reference architecture. If your `plancasting/tech-stack.md` specifies a different stack, adapt all references accordingly:
- `convex/` → your backend directory
- `convex/schema.ts` → your schema/migration files
- Convex functions (query/mutation/action) → your backend functions/endpoints
- ConvexError → your error handling pattern
- `useQuery`/`useMutation` → your data fetching hooks
- `npx convex dev` → your backend dev command
- `src/app/` → your frontend pages directory
Always read `CLAUDE.md` Part 2 (Backend Rules, Frontend Rules) for your project's actual conventions.

**Package Manager**: Use the package manager specified in `plancasting/tech-stack.md` (default: `bun`). Substitute `bun run` → `npm run` / `pnpm run` / `yarn` as needed throughout this prompt. Also substitute `bunx` → `npx` for non-Bun projects.

## Known Failure Patterns

Based on observed audit outcomes:

1. **Lighthouse in dev mode**: Running Lighthouse against `localhost:3000` in development gives misleading scores (no minification, no tree-shaking, React dev warnings). always measure against a production build (e.g., `next build && next start` for Next.js).
2. **Premature `React.memo`**: Agent adds `React.memo` to every component without measuring. `React.memo` adds comparison overhead — only use for components that re-render frequently with the same props.
3. **Lazy loading above-the-fold content**: Agent adds `dynamic(() => import(...))` to components visible on initial render. This HURTS LCP by deferring critical content.
4. **Over-aggressive `.take(N)`**: Agent adds `.take(10)` to queries that legitimately need to return more results, silently truncating data.
5. **Breaking Server Component → Client Component** (Next.js App Router / SSR frameworks): Agent converts Server Components to Client Components to add `useMemo`, losing SSR benefits. Net negative for performance. For non-SSR frameworks: do not convert server-rendered routes to client-only routes solely to use client-side optimization hooks.
6. **Adding pagination to small lists**: Agent adds pagination to lists that will never exceed 50 items. Unnecessary complexity.
7. **INP vs FID confusion**: Agent optimizes for First Input Delay (FID) which was deprecated in March 2024 and replaced by Interaction to Next Paint (INP). Lighthouse cannot measure INP directly — use Total Blocking Time (TBT) as a lab proxy. TBT < 200ms generally correlates with good INP. See Measurement Standards section for details.

## Agent Team Architecture

### Phase 1: Lead Analysis & Planning

As the team lead, complete the following BEFORE spawning any teammates:

1. Read `./CLAUDE.md`, `./plancasting/tech-stack.md`, and `./plancasting/prd/15-non-functional-specifications.md`.
2. **Pre-optimization verification**: Before creating the baseline, run `bun run typecheck && bun run test` to verify the codebase is in a working state. If tests fail, STOP and resolve before proceeding with performance optimization.

3. **Create the performance baseline** (the lead must complete baseline measurement synchronously — before spawning any teammates. Build production, measure, then spawn teammates):
   Capture baseline measurements per the Measurement Standards section below (Phase 4).
   ~~~bash
   mkdir -p ./plancasting/_audits/performance
   ~~~
   Run Lighthouse on key pages (home, dashboard, main feature page) and record metrics in `./plancasting/_audits/performance/baseline.md`. Mark the baseline file with a comment at the top: `<!-- ORIGINAL BASELINE — Do not recreate on subsequent 6C RUNS -->`. This file is permanent and serves as the reference point for all before/after comparisons. Use a production build for accurate baselines:
   ~~~bash
   bun run build && bun run start &
   # Wait for server to be ready (adapt port to your project)
   until curl -s http://localhost:3000 > /dev/null 2>&1; do sleep 1; done
   bunx lighthouse http://localhost:3000 --only-categories=performance --output=json --output-path=./plancasting/_audits/performance/baseline-home.json
   # Repeat for other key pages (e.g., /dashboard, /main-feature)
   kill $(lsof -ti:3000) 2>/dev/null  # adapt port to your project
   ~~~
   never measure against the dev server — dev mode includes HMR, unminified code, and source maps that produce misleading metrics.
4. Extract all performance budgets:
   - Page load time targets
   - API response time targets
   - Bundle size budgets
   - Lighthouse score targets
   - Core Web Vitals targets (LCP, INP, CLS)
5. Create `./plancasting/_audits/performance/targets.md` with the extracted targets. If PRD does not specify performance budgets, use these defaults: LCP < 2.5s, INP < 200ms, CLS < 0.1, bundle size < 200KB (initial JS). Document the source of each budget (PRD reference or default) in the baseline report. Also use web.dev default Lighthouse Performance score > 90. Document the source (PRD vs defaults) in `targets.md`.
6. Create a task list for all teammates with dependency tracking.

### Phase 2: Spawn Optimization Teammates

Spawn the following 3 teammates. Each teammate's spawn prompt must include the performance targets and instructions to read CLAUDE.md first. Note: Teammate numbering below does not reflect execution order — see the recommended execution order for spawn sequencing.

**Note**: Stage 6C can run **in parallel with Stages 6A and 6B** per CLAUDE.md. The teammate sequencing below applies only to 6C's *internal* teammates — it does not affect inter-stage parallelism.

**Recommended execution order**: Conditional on Phase 1 analysis — IF the lead confirmed zero index/query optimization opportunities (all queries already indexed, schema fully optimized), all 3 teammates may start in parallel. OTHERWISE, spawn Teammate 2 (backend) FIRST, wait for completion, then spawn Teammates 1 & 3 in parallel. This avoids rework if index additions significantly change query response characteristics.

**How to verify zero optimization opportunities**: (1) Scan all query functions in your backend directory. For each query that filters data, verify it uses indexed queries (`.withIndex()` or equivalent). If ANY unindexed query found, optimizations exist — set to FALSE. (2) Review schema for compound indexes — if count < 1 per table, set to FALSE. (3) If all checks pass, set to TRUE and spawn all 3 teammates in parallel.

**When ambiguous**: If the Phase 1 scan is inconclusive (e.g., some queries indexed, some not, but unclear if the unindexed ones are performance-critical), err on the side of **sequential execution** (Teammate 2 first). Sequential adds ~30 min overhead compared to parallel, but avoids rework if Teammate 2 discovers schema changes that invalidate Teammate 1's frontend optimizations.

#### Teammate 1: "frontend-performance"
**Scope**: Bundle size, rendering, and Core Web Vitals
**Spawn**: AFTER Teammate 2 completes (unless lead confirmed no index changes needed — see execution order above)

~~~
You are optimizing frontend performance for the complete product.

Read CLAUDE.md first.
Check `./plancasting/tech-stack.md` for the `Session Language` setting. Write all findings in that language.
Read `./plancasting/_audits/implementation-completeness/report.md` — skip optimizing features marked as incomplete (Category C).
Read the performance targets in ./plancasting/_audits/performance/targets.md.

Your tasks:
1. BUNDLE ANALYSIS:
   - Review your framework's config (e.g., `next.config.ts` for Next.js) for optimization settings.
   - Identify large dependencies (> 50KB gzipped) and evaluate alternatives or dynamic imports. Use your framework's bundle analyzer: (a) Next.js: verify `@next/bundle-analyzer` is in `next.config.ts` — if not, install with `bun add -D @next/bundle-analyzer` and configure it, then run `ANALYZE=true bun run build`. (b) Vite: run `npx vite-bundle-visualizer`. (c) Other frameworks: check `plancasting/tech-stack.md` for equivalent tooling. If bundle analyzer cannot be installed (version conflict, network): skip automated analysis. Use Chrome DevTools Performance tab → Code Coverage instead. Document 'Automated bundle analysis unavailable; manual inspection performed' in report.
   - If using Next.js: Verify `"use client"` directives are used minimally — components that could be Server Components reduce client bundle. Implement dynamic imports (`next/dynamic`) for heavy components not needed on initial render. Verify images use `next/image` with proper sizing and formats.
   - For other frameworks: Apply equivalent bundle optimization strategies (code splitting, lazy loading, image optimization).
   Output: Bundle optimization actions taken.

2. RENDERING OPTIMIZATION:
   - Identify pages that could benefit from SSR data loading (e.g., `preloadQuery` for Convex + Next.js). For Convex: use `preloadQuery`. For other backends: use your framework's server-side data fetching patterns (e.g., Next.js server components with direct data access, SvelteKit `load` functions, Remix loaders).
   - Verify loading skeleton screens exist for all routes (prevents layout shift = better CLS).
   - Check for unnecessary re-renders: components subscribing to backend data queries they don't need (e.g., Convex reactive queries, Supabase realtime subscriptions, or equivalent).
   - Verify React.memo or useMemo is used ONLY where expensive computations or frequent re-renders with unchanged props occur (see Known Failure Pattern #2 — do not blanket-apply to all components).
   - Check for layout shift sources: images without dimensions, dynamically injected content.
   Output: Rendering optimizations applied.

3. ASSET OPTIMIZATION:
   - Verify font loading strategy (e.g., `next/font` with `display: swap` for Next.js, or equivalent for your framework).
   - Verify CSS is not importing unused Tailwind utilities.
   - Check for render-blocking resources.
   Output: Asset optimizations applied.

When done, message the lead with: optimizations applied by category, estimated impact.
~~~

#### Teammate 2: "backend-query-performance"
**Scope**: Backend function performance, index utilization, and data access patterns
**Spawn**: FIRST — index/query changes may affect other teammates' work

~~~
You are optimizing backend performance for the complete product.

Read CLAUDE.md first.
Check `./plancasting/tech-stack.md` for the `Session Language` setting. Write all findings in that language.
Read `./plancasting/_audits/implementation-completeness/report.md` — skip optimizing features marked as incomplete (Category C).
Read your schema file (e.g., `./convex/schema.ts`) and all function files in your backend directory (e.g., `./convex/`).

Your tasks:
1. INDEX AUDIT: Review every query function.
   - Verify EVERY filtered query uses your indexed query method (e.g., `.withIndex()` for Convex) instead of unindexed filtering (e.g., `.filter()` for Convex).
   - Identify queries that could benefit from compound indexes (filtering on multiple fields).
   - Identify missing indexes: queries that scan tables without index support.
   - Add missing indexes to your schema file.
   Output: Index additions and query optimizations.

2. QUERY EFFICIENCY: Review all query functions.
   - Flag queries that use `.collect()` when `.first()` or `.unique()` would suffice.
   - Flag queries that fetch more data than needed (returning full documents when only a few fields are needed).
   - Identify N+1 query patterns: a query that loops and makes sub-queries. Refactor to batch.
   - Verify pagination is used for large result sets instead of `.collect()`.
   Output: Query efficiency improvements.

3. MUTATION EFFICIENCY: Review all mutation functions.
   - Verify mutations don't read-then-write when a direct `.patch()` would work.
   - Check for unnecessary database reads in mutations.
   - Identify opportunities to combine multiple mutations into one transactional operation.
   Output: Mutation optimizations.

4. SCHEDULED FUNCTIONS AND CRONS: Review your scheduled function configuration (e.g., `convex/crons.ts` for Convex) and background jobs.
   - Verify cron frequencies are appropriate for their purpose: cleanup jobs → daily/weekly; aggregation jobs → daily; notification jobs → hourly or per SLA. If a job runs more frequently than its data changes, reduce the frequency.
   - Check that background jobs are efficient and don't lock resources unnecessarily.
   Output: Background job optimizations.

When done, message the lead with: indexes added, queries optimized, mutations optimized.
~~~

#### Teammate 3: "perceived-performance"
**Scope**: Perceived performance, loading states, and optimistic updates
**Spawn**: AFTER Teammate 2 completes (perceived performance decisions — e.g., skeleton strategy, optimistic update patterns — depend on stable query response characteristics from Teammate 2's index/query optimizations).

~~~
You are optimizing perceived performance — what the user experiences while waiting.

Read CLAUDE.md first.
Check `./plancasting/tech-stack.md` for the `Session Language` setting. Write all findings in that language.
Read `./plancasting/_audits/implementation-completeness/report.md` — skip optimizing features marked as incomplete (Category C).
Read ./plancasting/prd/08-screen-specifications.md and ./plancasting/prd/09-interaction-patterns.md.

Your tasks:
1. LOADING STATES: Scan every page and component.
   - Verify every page/route has a loading state file (e.g., `loading.tsx` for Next.js App Router, or your framework's equivalent) with a skeleton screen (not a spinner).
   - Verify skeleton screens match the actual layout (prevents layout shift on load).
   - Verify data-dependent components show skeletons while useQuery returns undefined.
   - Flag any component that shows a blank screen during loading.
   Output: Loading state improvements.

2. OPTIMISTIC UPDATES: Scan all mutation-calling components.
   - Identify user actions that should feel instant (form submissions, toggles, deletions).
   - Implement optimistic updates where the UI reflects the change before the server confirms.
   - Verify optimistic updates roll back gracefully on server error.
   Output: Optimistic update implementations.

3. PROGRESSIVE LOADING: Review pages with large data sets.
   - Verify pagination or infinite scroll is used instead of loading all data at once.
   - Verify above-the-fold content loads first.
   - Check for waterfall loading patterns: component A loads → triggers component B load → triggers component C load. Refactor to parallel loading.
   Output: Progressive loading improvements.

4. TRANSITION AND FEEDBACK: Review user interactions.
   - Verify buttons show loading state during async operations.
   - Verify form submissions disable the submit button to prevent double submission.
   - Verify navigation transitions are smooth (no flash of unstyled content).
   Output: Interaction feedback improvements.

When done, message the lead with: improvements applied by category.
~~~

### Unfixable Violation Protocol

If a violation cannot be fixed without architectural changes or would break another feature:
1. Document the full conflict with evidence (what the violation is, what fixing it would break)
2. Mark as **"REQUIRES HUMAN DECISION"** in the report — do not attempt a fix that creates regressions
3. Include a recommended approach and estimated effort in the report
4. If the unfixable issue causes Core Web Vitals to FAIL (per PRD targets), document as a potential launch blocker for Stage 6H review. Create `./plancasting/_audits/performance/unfixable-violations.md` for critical unfixable issues.
5. Continue with remaining fixable violations — do not block the entire audit on one decision

### Phase 3: Coordination During Execution

While teammates are working:
1. Monitor progress via the shared task list.
2. Facilitate cross-team dependencies:
   - If backend-query-performance adds new indexes → notify frontend-performance (query response times may change, affecting loading strategy).
   - If perceived-performance identifies waterfall loading patterns → notify backend-query-performance (may need combined queries to eliminate waterfalls).
3. Resolve conflicts if multiple teammates modify the same file.

### Phase 4: Verification & Report

After all teammates complete:

1. Run full test suite.
   Use the commands from CLAUDE.md (e.g., `bun run test` instead of `npm run test`):
   ~~~bash
   bun run typecheck
   bun run lint
   bun run build
   bun run test
   bun run test:e2e
   ~~~

2. Run Lighthouse on key pages and collect scores.
   First, verify Lighthouse CLI is available: `bunx lighthouse --version 2>/dev/null || echo 'not installed'`. If not available and cannot be installed, use browser DevTools Lighthouse panel (consistent lab conditions). Do not use PageSpeed Insights as a substitute — it uses real user metrics, not lab-based synthetic measurements, making results incomparable with Lighthouse CLI. Document which tool was used in the report.
   If Lighthouse CLI is not available, install it: `bun add -g lighthouse`. Or use `npm install -g lighthouse` as a universal fallback. If installation fails: (1) use browser DevTools Lighthouse tab for local measurement, (2) record scores manually in `./plancasting/_audits/performance/lighthouse.json`, (3) document in the report: 'Lighthouse scores measured via DevTools, not CLI.' Always measure against a production build (`bun run build`), never a dev server.
   - **Performance Measurement Methodology**:
     a. Build for production: `bun run build` (or equivalent)
     b. Start production server: `bun run start` (or equivalent)
     c. Run Lighthouse: `bunx lighthouse http://localhost:3000 --only-categories=performance --output=json --output-path=./plancasting/_audits/performance/lighthouse.json`
     d. Run at least 3 times and average the scores (Lighthouse results vary per run). To automate: `for i in 1 2 3; do bunx lighthouse http://localhost:3000 --only-categories=performance --output=json --output-path=./plancasting/_audits/performance/lighthouse-run-$i.json; done` then parse and average the `performance` score from each JSON file.
     e. Measure Core Web Vitals:
        - LCP (Largest Contentful Paint): Target < 2.5s
        - INP (Interaction to Next Paint): Target < 200ms (replaced FID in March 2024)
          Note: INP is a real-user metric — Lighthouse cannot measure it directly. Lighthouse reports Total Blocking Time (TBT) as a lab proxy. TBT < 200ms generally correlates with good INP, but they measure different things (TBT = main thread blocking during load; INP = responsiveness to user interactions). For lab testing: use TBT < 200ms as the target. For production: set up real user monitoring (e.g., `web-vitals` library) to capture actual INP via the Performance API.
        - CLS (Cumulative Layout Shift): Target < 0.1
     f. Bundle analysis: Identify large dependencies using your framework's bundle analyzer:
        - Next.js: `ANALYZE=true bun run build` (requires `@next/bundle-analyzer`)
        - Vite: `npx vite-bundle-visualizer`
        - Other: check `plancasting/tech-stack.md` for equivalent tooling

   - **Measurement Standards**:
     - **Network throttling**: Use Lighthouse default throttling (simulated 4G) for consistency
     - **Cache state**: Always measure on cold cache (clear browser cache between runs)
     - **Baseline Preservation**: On first 6C run, create baseline. On subsequent 6C re-runs, do not recreate baseline — always measure against the ORIGINAL baseline. If baseline is accidentally overwritten, restore from git history. Note: If 6A or 6B modified code before 6C starts (parallel execution), 6C's baseline captures the post-6A/6B state, not the original post-5B state. This is expected — the baseline reflects the current code at 6C start time.
     - **Parallel execution note**: If 6A or 6B completed and modified code before 6C started (because all three ran in parallel), 6C's baseline captures the post-6A/6B state. Document this in the baseline file and attribute performance deltas accordingly.
     - **Baseline**: Compare against the baseline in `./plancasting/_audits/performance/baseline.md`. **Baseline timing**: The performance baseline must be created as the FIRST action in Phase 1 step 3, before any code changes, capturing the post-5B state. **Parallel 6A/6B/6C**: If all three start simultaneously, all baselines capture the same starting state. If 6A or 6B complete and modify code before 6C starts, 6C's baseline captures the post-6A/6B state — document this and attribute deltas accordingly. **Re-runs**: If the baseline already exists from a prior run, use it as the primary reference. Do not re-generate the baseline after 6A/6B changes — that would mask the performance cost of security/accessibility fixes. Measure post-6C metrics against the ORIGINAL baseline and document any performance delta attributable to 6A/6B changes separately (e.g., "Auth rate limiting added +15ms to login endpoint — expected and acceptable"). After optimizations, record new metrics as "post-Stage-6C" in the report for future reference
     - **Core Web Vitals targets**: Read performance targets from `./plancasting/prd/15-non-functional-specifications.md` first. Use these web.dev Good thresholds as defaults only if the PRD does not specify targets: LCP < 2.5s, INP < 200ms, CLS < 0.1 (Good rating per web.dev)
     - **Reporting**: Include both raw numbers and pass/fail against targets

3. Generate `./plancasting/_audits/performance/report.md`:
   - Performance budget compliance table (metric → target → actual → pass/fail)
   - Lighthouse scores per page
   - Optimizations applied (categorized: bundle, queries, indexes, loading, perceived)
   - Before/after metrics where measurable
   - Remaining gaps and recommendations
   - **Interpreting results**: If any Core Web Vital FAILS (below target): escalate to the relevant teammate (backend-query-performance for slow queries, frontend-performance for large bundles) for targeted fixes before proceeding. If only non-critical metrics miss targets, document as "opportunities for future optimization" and proceed.
   - PRD NFR compliance matrix

   ## Gate Decision
   [PASS | CONDITIONAL PASS | FAIL]
   - **PASS**: All Core Web Vitals meet targets; performance budget compliant; no critical regressions
   - **CONDITIONAL PASS**: Core Web Vitals on track; non-critical metrics miss targets but are documented as future optimization opportunities
   - **FAIL**: Core Web Vitals FAIL thresholds; performance budget exceeded; critical pages do not load within acceptable time
   Rationale: [brief explanation]

   (Use this exact `## Gate Decision` heading in the generated report — 6H parses this heading to extract gate decisions from all audit reports.)

4. Output summary: total optimizations applied, budget compliance status.

### Phase 5: Shutdown

1. Commit all changes: `git add -A && git commit -m 'perf: Stage 6C performance optimization'` per CLAUDE.md git conventions.
2. Request shutdown for all teammates.
3. Verify all file modifications are saved.

## Critical Rules

1. never optimize without measuring first — premature optimization adds complexity without benefit.
2. never convert Server Components to Client Components for optimization purposes (Next.js). For non-SSR frameworks: do not convert server-rendered routes to client-only routes solely to use client-side optimization hooks.
3. never run Lighthouse in development mode — always use your production build and start commands (e.g., `bun run build && bun run start`).
4. always verify optimizations don't break functionality — run the full test suite after changes.
5. always measure bundle size before and after changes using your framework's bundle analyzer (see Phase 2 Teammate 1 instructions for framework-specific commands).
6. If using Convex: never add `.take(N)` that is too small for the feature's actual data volume. Check PRD for expected data sizes.
7. Use the commands from CLAUDE.md for testing (e.g., `bun run test`).
8. Reference Stage 5B output to avoid optimizing incomplete features.
9. INP replaces FID (deprecated). Use TBT as lab proxy for INP. See Measurement Standards section above for details.
10. **Parallel execution**: This stage may run concurrently with 6A and 6B. Document required changes to shared config files (`next.config.ts`, `middleware.ts`, `tailwind.config.ts`, `globals.css`) in the report under a `## Pending Config Changes` section rather than modifying them directly — this prevents silent overwrites when parallel stages commit. If a Core Web Vitals critical fix must modify a shared config file immediately (e.g., `next.config` image optimization settings), commit the change immediately and note it prominently in the report under `## Pending Config Changes`.
````
