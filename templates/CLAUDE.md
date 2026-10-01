# CLAUDE.md — Transmute Project Conventions & Rules

<!-- Pipeline Execution Guide | Part 1: Immutable Rules | Part 2: Project Config (extend only) -->

> **Plan Casting**: The end-to-end process of using Transmute to autonomously transform a Business Plan into a production-ready product through the stages below (0–9 plus sub-stages).

## Pipeline Execution Guide

<!-- This section is for pipeline execution only. After all stages complete,
     it can be removed or collapsed — it is not needed for day-to-day development. -->

> **Canonical source**: `plancasting/transmute-framework/execution-guide.md` owns all definitions, prerequisites, credentials, per-stage warnings, gate thresholds, and recovery procedures. This section provides orientation and safety-critical rules only.

### Pipeline Overview

```
Business Plan → Tech Stack → BRD → PRD → Spec Validation → Scaffold + Verify → Implementation → Completeness Audit → Quality Assurance → Pre-Launch → Live Verification → Remediation → Visual Polish or Redesign → Deploy → Production Smoke → User Guide → Feedback / Maintenance
   [Input]        [0]       [1]   [2]      [2B]              [3+4]             [5]                [5B]              [6A–6G]         [6H]           [6V]               [6R]              [6P / 6P-R]          [7]        [7V]              [7D]        [8] / [9]
```

> **Notation**: `+` = sequential in one session. `/` between alternatives (6P / 6P-R) = run exactly one, never both. `/` between sequential stages (8 / 9) = run both, but one at a time, never concurrently. `[6A–6G]` is simplified (includes security, accessibility, performance, refactoring, seed data, resilience, and documentation sub-stages — excludes 6H, 6V, 6R, and 6P/6P-R which are shown separately). See Stage 6 ordering below for the mandatory execution order within this block.

All stages follow the **Transmute Full-Build Approach**: every feature in the Business Plan is built (P0 → P3 priority order). No MVP, no phased delivery. Priority levels defined in `plancasting/prd/02-feature-map-and-prioritization.md`.

**Stage 6 ordering** (mandatory — not merely recommended): First, parallel: 6A + 6B + 6C (commit each before proceeding). Then sequential: 6E → 6F → 6G → 6D → 6H → 6V → 6R → 6P or 6P-R. Then proceed to Stage 7 → 7V → 7D (see execution-guide.md). Note: 6D (Documentation) runs AFTER 6G (Resilience) despite its lower letter — all code-modifying stages (6A–6C, 6E–6G) must complete before documentation so docs reflect final code. 6H is a static pre-deployment gate (binary READY/NOT READY outcome, distinct from 6A–6G's PASS/CONDITIONAL PASS/FAIL) that runs BEFORE 6V (live verification). **Parallel safety**: When running 6A+6B+6C in parallel, shared config files can be overwritten silently — commit each stage's changes immediately, or run 6A first (most config changes), commit, then 6B+6C in parallel.

### Safety-Critical Rules

- **Teammate spawn refused**: When a teammate cannot be started — the Agent tool refuses the spawn because of a concurrency cap, a rate limit, a usage limit, or a hook — do not stop to ask the operator. Run the teammates you could not start in smaller waves, starting each wave as the previous one finishes, down to one at a time. Keep each teammate's scope and its separate context, since the stage's review steps depend on them; writing a teammate's files yourself is the last resort, used only when not even one teammate can be started, and recorded in the stage report.
- **Never skip** 5B, 5V, 6V, 6P/6P-R, or 7V. Always run exactly one of 6P or 6P-R (default: 6P). (5V is the 6V prompt in `MODE: critical`, run right after 5B so a product that does not start is sent back to Stage 5 before the Stage 6 audits.) (5B catches the #1 cause of Stage 6 failures — frontend stubs and duplication that slip through late-queue quality gates.) Note: 5B uses four outcomes (PASS, CONDITIONAL PASS, FAIL-RETRY, FAIL-ESCALATE) — see execution-guide.md § "Gate Decision Outcomes" for thresholds and recovery actions.
- **6P / 6P-R mutual exclusivity**: Run exactly one, never both. To switch: commit 6P work, `git revert` the 6P commit, then run 6P-R in a new session.
- **6R skip conditions**: Skip 6R only if 6V returns PASS (zero issues) or CONDITIONAL PASS with only 6V-C issues (human-judgment items — architectural decisions, design trade-offs — that 6R cannot auto-fix). If 6V returns FAIL, resolve critical blocking issues (manually or by re-running relevant Stage 5/6 steps) and re-run 6V until it achieves PASS or CONDITIONAL PASS before proceeding to 6R. If skipped, 6P/6P-R uses the 6V report as input.
- **Stage 3 prerequisite**: Stage 2B must PASS or CONDITIONAL PASS before Stage 3. Stage 4 (CLAUDE.md Part 2 populated, `.claude/rules/*.md` present) is an automated check performed by the pipeline agent and repeated by the gate hook before Stage 5; it is not an operator stop.
- **Stage 1 stop condition**: if the BRD's assumption volume is ≥ 30% and `Operator reviewed: YES` is not set in `plancasting/brd/_review-log.md`, the pipeline stops after Stage 1 for the operator to revise the business plan or review the assumptions.
- **Stage 7 prerequisites**: 6H READY + 6V PASS or CONDITIONAL PASS + 6R PASS/CONDITIONAL PASS (if run) + 6P or 6P-R PASS/CONDITIONAL PASS (one of 6P/6P-R always runs) + 6D complete (mandatory for software products; its output serves as Stage 7's deployment reference; skip 6D only if `tech-stack.md` has `developer-docs-needed: false` or the product is non-software). Note: 6D = developer/deployment docs (Stage 6); 7D = user guide (runs after Stage 7 deployment, optional). If 6D was skipped, refer to your hosting provider's documentation for deployment steps; no earlier stages need re-running.
- **Stage 8 prerequisite**: Stage 7V must achieve PASS or CONDITIONAL PASS before starting Stage 8 (Feedback Loop). If Stage 7D was run, it must be PASS or WARN (non-blocking issues documented but not gate-failing; FAIL blocks Stage 8 until resolved). Note: Stage 7D uses PASS/WARN/FAIL instead of the universal PASS/CONDITIONAL PASS/FAIL because it produces documentation, not code — WARN indicates quality gaps that do not block proceeding to Stage 8.
- **Stages 8 + 9**: **never concurrent** — both modify `package.json`, lock files, and source code. Run one, commit, then the other.
- **Stage 9 prerequisite**: Stage 9 does not formally require 7V PASS — it can update dependencies at any point after Stage 5. However, if the product is deployed, re-run 7V after deploying updated dependencies.

### Cross-References

| Topic | Location |
|---|---|
| Full stage table (prompts, inputs, outputs, durations) | execution-guide.md § "Transmute Pipeline Overview" |
| Prerequisites, credentials, `.env.local` timing | execution-guide.md § "Prerequisites" |
| CLI workflow, per-stage setup | execution-guide.md § per-stage sections |
| Per-stage warnings (0–9) | execution-guide.md § per-stage sections |
| Gate definitions, thresholds, routing | execution-guide.md § "Gate Decision Outcomes (Universal)" |
| Recovery procedures | execution-guide.md § per-stage sections (e.g., "5B.5 If FAIL: Recovery Actions", "7.1.2 Deployment Failure Recovery") and § "Troubleshooting" |
| Stage skip conditions | execution-guide.md § "Stage Skip Logic" |
| Tips, troubleshooting, project structure | execution-guide.md § "Tips for Successful Plan Casting", "Safety Rules", "Troubleshooting" |

---

## Part 1: Immutable Transmute Framework Rules

<!-- ⛔ Do not modify or delete anything in Part 1 ⛔ -->
<!-- These rules are core to the Transmute framework and must be preserved -->
<!-- across all projects. Stage 3/4 may ADD project-specific rules in Part 2, -->
<!-- but must never remove, replace, or weaken any rule in Part 1. -->

### Reference Documents

Always read the relevant PRD/BRD files BEFORE implementing any feature:

| What you need | Where to find it |
|---|---|
| Product overview & personas | `./plancasting/prd/01-product-overview.md` |
| Feature list & priorities | `./plancasting/prd/02-feature-map-and-prioritization.md` |
| Release plan & feature flags | `./plancasting/prd/03-release-plan.md` |
| User stories & acceptance criteria | `./plancasting/prd/04-epics-and-user-stories.md` |
| Job stories | `./plancasting/prd/05-job-stories.md` |
| User flows | `./plancasting/prd/06-user-flows.md` |
| Information architecture | `./plancasting/prd/07-information-architecture.md` |
| Screen specifications | `./plancasting/prd/08-screen-specifications.md` |
| Interaction patterns | `./plancasting/prd/09-interaction-patterns.md` |
| System architecture | `./plancasting/prd/10-system-architecture.md` |
| Data model | `./plancasting/prd/11-data-model.md` |
| API specifications | `./plancasting/prd/12-api-specifications.md` |
| Technical specifications | `./plancasting/prd/13-technical-specifications.md` |
| Testing strategy | `./plancasting/prd/14-testing-strategy.md` |
| Non-functional specs | `./plancasting/prd/15-non-functional-specifications.md` |
| Operational readiness | `./plancasting/prd/16-operational-readiness.md` |
| Dependencies & risks | `./plancasting/prd/17-dependencies-and-risks.md` |
| Glossary & cross-references | `./plancasting/prd/18-glossary-and-cross-references.md` |
| Business requirements | `./plancasting/brd/06-business-requirements.md` |
| Functional requirements | `./plancasting/brd/07-functional-requirements.md` |
| Business rules | `./plancasting/brd/14-business-rules-and-logic.md` |
| Security requirements | `./plancasting/brd/13-security-requirements.md` |
| Compliance requirements | `./plancasting/brd/12-regulatory-and-compliance-requirements.md` |

### Component Rules (All Frameworks)

1. always implement all states: default, loading, empty, error, disabled.
2. always include ARIA attributes for interactive elements.
3. always support keyboard navigation.
4. never use inline styles. Use the project's CSS framework (Tailwind, etc.). Exception: dynamic runtime values that cannot be expressed as utility classes (e.g., `style={{ width: \`${progress}%\` }}`).
5. Props interfaces must be explicitly typed and exported.
6. never use inline SVG `<path>` elements for standard UI icons. Use the project's icon library (see `plancasting/tech-stack.md` "Icon library" field and the project's icon registry file). If the project defines an icon registry (see Technology Stack table, 'Icon Registry' row), import all standard icons from that registry file. Inline SVGs are permitted ONLY for product logos, brand marks, or custom illustrations unavailable in any icon library.

### Design & Visual Identity

<!-- ⛔ Do not delete this section — it is critical for design quality ⛔ -->

Before writing ANY frontend code, use the design direction in the project's design token file (path defined in Part 2 Technology Stack table or `plancasting/tech-stack.md`) and the guidelines below as the primary design authority. If running in Anthropic's hosted cloud environment, also check `/mnt/skills/public/frontend-design/SKILL.md` for supplementary patterns (the local design token file remains the primary authority).

**Design Direction**: This project has a defined design direction stored in the design token file (see Part 2 Technology Stack table for path; common locations: `src/styles/design-tokens.ts`, `src/lib/tokens.css`, `app/styles/tokens.ts`) and referenced in `plancasting/tech-stack.md` (Design Direction section from Stage 0). All UI code must follow this direction consistently. If the design direction does not yet exist, establish one before building components by:
1. Reading the PRD product overview and persona definitions.
2. Choosing a distinctive, opinionated aesthetic direction (not generic or safe) that matches the product's personality and target users.
3. Documenting the direction in the design token file with CSS variables, color palettes, typography choices, spacing scales, and animation patterns. The format (TypeScript module, CSS file, or both) depends on the tech stack — see `plancasting/tech-stack.md` for the chosen approach.

**Anti-Patterns — avoid these**. A general "no generic AI look" instruction only swaps one default style for another; the model responds to patterns named concretely, so this list is the design authority's exclusion list. Extend it with whatever default the first generated screens fall back on:
- Named default patterns: cream or off-white page backgrounds as the default surface; italic accent words inside headlines; numbered "01 / 02 / 03" section labels; monospace labels or eyebrows on non-technical products; pill-shaped buttons and pill badges everywhere; purple-on-white or indigo-to-violet gradients; three-column feature-card grids with an icon, a bold title and two lines of copy; identical card radii, shadows and padding on every surface; emoji as icons; centered hero + three cards + testimonial + CTA page skeletons.
- Fonts chosen by default rather than for the product: Inter, Roboto, Arial or system-ui when the design direction did not ask for them. Choose fonts that match the product's personality — even widely-used fonts can work if deliberately chosen for a reason.
- Default Tailwind without customization. Always configure the Tailwind theme (via `tailwind.config.ts` or `@theme` directive in CSS, per your Tailwind version) with custom colors, fonts, and spacing that match the design direction.
- Uniform spacing and sizing everywhere. Use intentional variation — generous whitespace in some areas, controlled density in others.
- Bland, evenly-distributed color palettes. Use dominant colors with sharp accents.

**Must-Have Design Qualities**:
- **Typography**: Choose distinctive, characterful fonts. Pair a display font with a body font. Import via the framework's font optimization (e.g., `next/font` for Next.js, `@fontsource` for Vite/Remix) for performance. Never default to system fonts unless the design direction explicitly specifies a system font stack for strategic reasons (e.g., developer tools, CLI dashboards).
- **Color & Theme**: Define a cohesive palette in CSS variables. Commit to it across all components. Use light/dark mode if specified in PRD.
- **Motion & Micro-interactions**: Use CSS transitions for hover states, focus rings, and state changes. Use staggered reveal animations on page load. Keep animations purposeful — enhance understanding, don't decorate.
- **Spatial Composition**: Break predictable grid layouts where appropriate. Use asymmetry, overlap, generous negative space. Every page should feel intentionally composed, not auto-generated.
- **Backgrounds & Depth**: Avoid flat solid-color backgrounds. Add subtle textures, gradient meshes, shadows, or layered transparencies that create atmosphere.

**Consistency**: Once the design direction is established, EVERY component must follow it. A single off-brand component breaks the entire experience.

### API Contract Alignment

<!-- ⛔ Do not delete this section — prevents production type mismatch bugs ⛔ -->

- Frontend types must match the ACTUAL backend response shape — NOT the database schema.
- Create SEPARATE types for projections (e.g., `OrganizationSummary` for list view, `Organization` for detail view).
- never use `as unknown as Type` casts to force type compatibility — use explicit field mapping.
- When backend returns renamed or computed fields, frontend hooks must map them explicitly.
- If the backend returns `orgId` but the frontend expects `_id`, the hook must transform — never cast.

### Scaffold Inventory

<!-- ⛔ Do not delete this section — prevents the duplication pattern ⛔ -->

Before writing ANY code for a feature, the implementing agent must:
1. List ALL existing scaffold files for the feature (backend functions, components, pages, hooks).
2. Read `plancasting/_scaffold-manifest.md` if it exists — it maps which components are used by which pages.
3. EXTEND existing scaffold files. never create duplicate files alongside them.
4. If a page already imports `ComponentX` from the scaffold, do not create a new `ComponentXInline` inside the page.

This prevents the "duplication pattern" where Stage 5 agents rebuild UI inline instead of using scaffold components, creating orphan files and bloated pages.

### TypeScript Rules

- Strict mode (`strict: true`). No exceptions.
- No `any` types in project code. If a third-party library forces `any` in its type definitions, wrap it with an explicit project type at the boundary. No `@ts-ignore`. Avoid `@ts-expect-error`; when unavoidable, always include an explanation comment justifying the suppression.
- Explicit return types for all exported functions.
- Use `type` for object shapes. Use `interface` only when extension is intended.

### Testing Rules

#### Backend Function Tests
- One test file per backend function file.
- Test cases derived from PRD acceptance criteria (Given-When-Then).
- Must cover: argument validation, auth checks, happy path, error cases, edge cases, business rules.

#### Component Tests
- Test all component states (default, loading, empty, error, disabled).
- Include accessibility checks (axe-core).
- Mock backend hooks, not the API directly.

#### E2E Tests
- One test file per user flow from PRD `plancasting/prd/06-user-flows.md`.
- Cover happy path, key alternative paths, and critical error paths.
- Prefer `getByRole`/`getByText`/`getByLabel` selectors. Use `getByTestId` as fallback when no semantic selector is available. Never use CSS class or ID selectors.
- For eventually-consistent backends (e.g., Convex): use `expect.poll()` or `expect.toPass()`.

#### Test Count Preservation
- The number of tested behaviors must never decrease during refactoring. Test files may be consolidated, but every previously-tested behavior must remain covered. If a refactoring reduces behavior coverage, it is a regression.

### Traceability Rules

Every feature implementation file (backend functions, pages, components, hooks) must include a header comment block with PRD/BRD traceability. Utility files, type definitions, config files, and test helpers that do not trace to specific PRD/BRD items are exempt:

```typescript
/**
 * @module TaskList
 * @description Displays the user's task list with filtering and sorting.
 *
 * @traces PRD:08-screen-specifications.md#SC-012
 * @traces PRD:08-screen-specifications.md#SC-013
 * @traces PRD:04-epics-and-user-stories.md#US-003
 * @traces PRD:04-epics-and-user-stories.md#US-004
 * @traces BRD:07-functional-requirements.md#FR-007
 */
```

When the PRD does not provide enough detail for an implementation decision, document the assumption inline:

```typescript
// ⚠️ ASSUMPTION: Default sort order is by creation date descending.
// PRD SC-012 specifies sorting but does not define the default.
```

### Progress Tracking

<!-- ⛔ Do not delete this section — the Feature Orchestrator depends on it ⛔ -->

Implementation progress is tracked in `./plancasting/_progress.md`. Update this file after completing each feature:

```markdown
| Feature ID | Feature Name | Priority | Status | Backend | Frontend | Tests | Notes |
|---|---|---|---|---|---|---|---|
| FEAT-001 | User Authentication | P0 | ✅ Done | ✅ | ✅ | ✅ | — |
| FEAT-002 | Task Management | P0 | 🔧 In Progress | ✅ | 🔧 | ⬜ | Frontend pending |
| FEAT-003 | Dashboard | P1 | ⬜ Not Started | ⬜ | ⬜ | ⬜ | Depends on FEAT-002 |
```

Valid status values: `⬜ Not Started`, `🔧 In Progress`, `✅ Done`, `🔄 Needs Re-implementation` (set by Stage 5B audit for Category C features, or by operator after reviewing 5B report, to trigger re-build in next Stage 5 session), `⏸ Blocked` (feature blocked by dependency or external issue — document blocker in Notes column). File location: `plancasting/_progress.md`.

**Valid state transitions**: `⬜` → `🔧` (Stage 5 starts feature) → `✅` (Stage 5 completes feature) → `🔄` (Stage 5B audit or operator sets after 5B FAIL) → `🔧` (Stage 5 re-run picks up feature) → `✅`. Also: `⬜`/`🔧`/`🔄` → `⏸` (blocked) → `🔧` (unblocked). When transitioning `🔧`/`🔄` → `⏸`, preserve sub-status columns (Backend/Frontend/Tests) as-is and record the pre-block status in the Notes column (e.g., "Blocked: was 🔄") — they indicate which layers were completed before the blocker. When unblocked (`⏸` → `🔧`), Stage 5 resumes from the first incomplete layer; if the feature was `🔄` before being blocked (check Notes column), unblocking restores it to `🔄` (rebuild from scratch, not resume).

```
⬜ → 🔧 → ✅ → 🔄 → 🔧 → ✅
     ↓              ↓
    ⏸ ←────────────⏸
     ↓
    🔧 (unblocked)
```

**Stage 5 resumption**: The Feature Orchestrator (Stage 5) reads this file at startup and performs a **positional scan** (top-to-bottom, not status-prioritized) to resume from the first `🔧 In Progress`, `⬜ Not Started`, or `🔄 Needs Re-implementation` feature, skipping all `✅ Done` and `⏸ Blocked` features. Features marked `🔧 In Progress` from a crashed session are inspected for sub-status (backend/frontend/tests completeness) and resumed from the first incomplete layer — see `plancasting/transmute-framework/prompt_feature_orchestrator.md` § "Session Recovery" and execution-guide.md § "Stage 5" for details. (`⏸ Blocked` features are treated like `✅ Done` for resumption purposes but retain their `⏸` status so the operator can unblock and re-run later.) This enables multi-session execution when the feature count exceeds the session limit.

### Path-Scoped Rules (`.claude/rules/`)

<!-- ⛔ Do not delete this section — enables self-evolving development knowledge ⛔ -->

Claude Code natively reads `.claude/rules/` files and applies matching rules based on `paths` frontmatter (a rule file without `paths` loads for every session, so always scope rules). This section defines how the Transmute pipeline uses path-scoped rules to accumulate implementation knowledge across sessions.

**What rules are**: Concise, actionable directives scoped to specific file paths. They complement CLAUDE.md (which holds universal project rules) with targeted, tech-stack-specific guidance that evolves as implementation proceeds.

**Generation points**:
- **Stage 3** (Scaffold): Generates **starter rules** from `tech-stack.md` using the templates in `plancasting/transmute-framework/rules-templates/` — known patterns, gotchas, and best practices for the selected stack. These are tech-stack knowledge (theoretical). Templates: `_backend-template.md`, `_frontend-template.md`, `_api-contracts-template.md`, `_auth-template.md`, `_data-model-template.md`, `_testing-template.md`, and `_ai-provider-template.md` (rendered only when the stack includes an AI/LLM provider).
- **Stage 5B** (Audit): Extracts **implementation lessons** from recurring audit findings — patterns that caused stubs, duplication, or gaps across 2+ features. These are observed patterns (empirical).
- **Stage 6R** (Remediation): Captures **verified fix patterns** from successful 6V-A/B fixes — confirmed working solutions to runtime issues. These have the highest confidence (battle-tested).
- **Stage 9** (Maintenance): Reviews existing rules for **staleness** — removes rules referencing deprecated APIs or resolved issues, updates rules with changed file paths, and prunes old candidates from `_rules-candidates.md`. Does not generate new rules but maintains rule quality.

**Confidence hierarchy**: Rules generated later in the pipeline carry higher inherent confidence — Stage 3 rules are theoretical (tech-stack knowledge), Stage 5B rules are empirical (observed across features), and Stage 6R rules are battle-tested (verified working fixes). When rules from different stages conflict, prefer the later stage's rule.

**Quality gate**: Every rule requires:
- **Evidence**: Issue ID (e.g., `SC-012`), commit hash, or PRD reference
- **Confidence**: HIGH (auto-promoted to `.claude/rules/`), MEDIUM/LOW (staged to `plancasting/_rules-candidates.md` for operator review)
- HIGH confidence threshold: 2+ distinct features (separate FEAT-IDs from `plancasting/prd/02-feature-map-and-prioritization.md`) affected with a clear, repeatable pattern. Two occurrences within the same feature count as 1 feature.

**Candidate staging**: Rules that don't meet the HIGH confidence threshold are staged in `plancasting/_rules-candidates.md` for operator review. Operator can promote (move to `.claude/rules/`), edit, or discard candidates. Maximum 30 candidates at any time — if exceeded, discard the oldest LOW-confidence candidates first.

**Limits**:
- Maximum **15 rules per file** — split into a new file if exceeded
- Maximum **8 rule files** total — consolidate related rules if exceeded
- Each individual rule (bullet point) must be ≤ 3 sentences (directive, not explanation). A section may contain multiple rules as separate bullets.

**Staleness review**: During Stage 9 (Dependency Maintenance), review all rules for staleness. Remove rules that reference deprecated APIs, outdated patterns, or resolved issues. Update rules that reference changed file paths or renamed functions. Also review `plancasting/_rules-candidates.md` for stale candidates (see the file's Staleness Policy: 60 calendar days without promotion or re-trigger, or 2+ maintenance cycles without promotion — whichever comes first).

**Rule file format** (`.claude/rules/*.md`):
```markdown
---
description: Brief description of what these rules cover
paths: ["src/backend/**", "convex/**"]
---

# Backend Rules

## [Rule Title]
<!-- Source: Stage [3/5B/6R] | Evidence: [ref] | Confidence: HIGH -->
- [Rule text — concise, actionable directive]
- [Additional rule in same section, if any]
```

### Git Conventions

#### Branch Naming
- `feat/<feature-id>-<short-description>` (e.g., `feat/US-003-task-list`)
- `fix/<issue-description>`
- `refactor/<scope>`
- `chore/<scope>` (e.g., `chore/dependency-update-2026-03-16` — used by Stage 9)
- `feedback/<scope>` (e.g., `feedback/batch-2026-03-16` — used by Stage 8)
- `docs/<scope>` (e.g., `docs/api-reference` — for documentation changes outside the pipeline)
- `redesign/<scope>` (e.g., `redesign/frontend-elevation` — used by Stage 6P-R)

#### Commit Messages
Format: `<type>(<scope>): <description> [PRD-ID]`

Examples:
- `feat(tasks): implement task list query [US-003]`
- `fix(auth): handle expired token in middleware [SR-003]`
- `test(tasks): add E2E test for task creation flow [US-005]`

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`, `style`

### Universal Prohibitions

- Do not omit required component states (default, loading, empty, error, disabled) — see Component Rules #1.
- Do not implement a feature without first reading the corresponding PRD section.
- Do not store secrets in code. Use environment variables.
- Do not remove or weaken any rule in Part 1 of this file.
- Do not rewrite this file from scratch. ONLY extend Part 2.
- Do not log, commit, or share test credentials in reports — reference by name only (e.g., "the basic-tier test user from `e2e/constants.ts`").
- Do not write credential values into any file other than `.env.local` (includes markdown, reports, code comments, commits). Reference by variable name only (e.g., `STRIPE_SECRET_KEY`).
- Do not display, echo, log, or repeat credential values in output. Use non-revealing checks (e.g., `wc -c`) to verify presence without exposing values.
- Do not copy credential values between files — each service reads from `.env.local` or the hosting platform's environment variable configuration.
- Do not use `console.log(process.env)` or log entire config/env objects in application code — log only specific non-sensitive fields. Error handlers must sanitize connection strings and tokens before logging.
- For implementation patterns on credential handling, see `.claude/rules/backend.md` § Environment Variables and `.claude/rules/auth.md` § Auth Error Handling (available after Stage 3).

---

## Part 1 vs Part 2 Lifecycle

- **Part 1** (above): Immutable Transmute Framework rules. Never modified after initial template placement. These are universal rules that apply to all Transmute projects regardless of tech stack.
- **Part 2** (below): Project-specific configuration. Stage 3 (Scaffold) populates this section with actual project details. The operator may customize after Stage 4 verification.
- **Pipeline Execution Guide** (top of file): Orientation and safety-critical rules for the pipeline. Can be removed or collapsed after all stages complete.

---

## Part 2: Project-Specific Configuration

<!-- ⚠️ TEMPLATE: Bracketed values below ([PROJECT_NAME], [N], [e.g., ...]) are placeholders.
     Stage 3 must fill ALL bracketed placeholders in Part 2, including those inside code blocks
     and table cells. Stage 4 will grep for remaining brackets (`grep -nE '\[[A-Z_]+\]'`).
     If reading this in a project and placeholders are still present, run Stage 4 verification. -->

### Project Overview

**[PROJECT_NAME]** — [One-sentence project description].

- **Full tech stack reference**: `./plancasting/tech-stack.md`
- **Business plan files**: `./plancasting/businessplan/`
- **PRD**: [N] features, [N] API endpoints, ~[N] screens
- **BRD**: [N] business rules
- **Data model**: [N] tables

### Technology Stack

| Category | Technology | Purpose |
|---|---|---|
| Runtime | [e.g., Bun / Node.js] | JS/TS runtime + package manager |
| Frontend | [e.g., Next.js (App Router)] | SSR/RSC React framework |
| UI Components | [e.g., Untitled UI React / shadcn/ui] | Component library |
| Icons | [e.g., Lucide / Heroicons / Tabler / framework default] | Icon library |
| Icon Registry | [e.g., src/components/icons/index.ts] | Central icon export file (see Component Rules #6) |
| Design Tokens | [e.g., src/styles/design-tokens.ts] | Design direction file (see Design & Visual Identity) |
| CSS | [e.g., Tailwind CSS v4.1] | Styling |
| Backend | [e.g., Convex / Supabase / Firebase] | Backend-as-a-Service |
| Database | [e.g., Convex (built-in) / PostgreSQL / SQLite] | Data storage (see `.claude/rules/data-model.md` for reserved words) |
| Auth | [e.g., WorkOS / Clerk / NextAuth] | Authentication |
| AI | [e.g., Claude Agent SDK / OpenAI SDK] | AI integration |
| Payments | [e.g., Stripe] | Billing |
| E2E Testing | [e.g., Playwright] | End-to-end testing |
| Hosting | [e.g., Vercel / Cloudflare] | Deployment |

Rows for AI, Payments, and other integrations are optional — include only categories relevant to your product.

### Architecture

**Multi-tenant**: [Describe tenant boundary — org-based, user-based, workspace-based, etc.]

**Auth helpers**: [List the actual auth helper functions and their locations]

**Soft delete**: [Describe the soft-delete pattern if applicable, including field name, retention period, and child entity strategy (cascade soft-delete vs. orphan)] (See `.claude/rules/data-model.md` § Soft Delete for the canonical pattern definition once Stage 3 generates it.)

**Deployment**: [Describe deployment order and production URLs]

**Testing**: [Describe test runner config, workspace setup, E2E tags]

### Commands

> Commands below use `bun run` as default. Adapt to your package manager per `plancasting/tech-stack.md`.

```bash
# Development
bun run dev              # [describe what this starts]
bun run dev:backend      # Backend only (if separate; adapt command name to your stack)

# Testing
bun run test             # Unit + integration tests
bun run test:e2e         # E2E tests (Playwright)
bun run test:e2e:critical # Critical path E2E only (if applicable)

# Quality
bun run lint             # Linter
bun run typecheck        # TypeScript type checking

# Deployment
bun run build            # Production build
bun run deploy           # Full deployment

# Seed Data (after Stage 6F — omit if 6F was not run)
bun run seed:dev         # Minimal data for development
bun run seed:test        # Moderate data for testing
bun run seed:demo        # Curated data for demonstrations
bun run seed:stress      # High-volume data for performance testing
bun run seed:empty       # Empty-state users (no data) for UI verification
bun run seed:verify      # Referential integrity check on seeded data
bun run seed:reset       # Clear all data and re-seed
```

### Backend Rules

<!-- Stage 3: Add backend-specific summary rules here as bullet-point directives (max 5 items).
     Detailed rules belong in .claude/rules/backend.md. Example: "- Always validate [field] with [validator] before mutation." -->

### Frontend Rules

<!-- Stage 3: Add frontend-specific summary rules here as bullet-point directives (max 5 items).
     Detailed rules belong in .claude/rules/frontend.md. Example: "- Always use [LoadingComponent] for async states." -->

### Security Rules

<!-- Stage 3: Add security summary patterns here as bullet-point directives (max 5 items).
     Detailed rules belong in .claude/rules/auth.md. Example: "- Always call [authHelper] before accessing user data." -->

### Project-Specific Prohibitions

<!-- Stage 3: Add stack-specific prohibitions extending Part 1 as bullet-point directives.
     Example: "- Do not use [deprecated API] — use [replacement] instead." -->

### Key Reference Documents

See Part 1 § "Reference Documents" for the complete PRD/BRD reference table. Key files for daily development:
- Acceptance criteria — `plancasting/prd/04-epics-and-user-stories.md`
- UI specs — `plancasting/prd/08-screen-specifications.md`
- API specs — `plancasting/prd/12-api-specifications.md`
- Business rules — `plancasting/brd/14-business-rules-and-logic.md`
- Security requirements — `plancasting/brd/13-security-requirements.md`

### Conventions

See `docs/developer/conventions.md` (generated by Stage 6D; not available before that stage) for: design guidelines, TypeScript rules, testing details, traceability format, git conventions, naming conventions, inline style exceptions.
See `plancasting/_progress.md` for feature tracking.

### Path-Scoped Rules

<!-- Stage 3: Populate with actual rule files generated from tech stack -->

Stage 3 replaces all `[PLACEHOLDER]` values below with actual project paths and rule counts.

| Rule File | Paths | Generated By | Rule Count |
|---|---|---|---|
| `.claude/rules/backend.md` | `[BACKEND_DIR]/**` | Stage 3 | [N] |
| `.claude/rules/frontend.md` | `[FRONTEND_DIR]/**` | Stage 3 | [N] |
| `.claude/rules/api-contracts.md` | `[BACKEND_DIR]/**`, `[HOOKS_DIR]/**`, `[FRONTEND_TYPES_DIR]/**` | Stage 3 | [N] |
| `.claude/rules/auth.md` | `[AUTH_DIR]/**`, `[MIDDLEWARE_PATH]` | Stage 3 | [N] |
| `.claude/rules/testing.md` | `[TEST_DIR]/**`, `**/*.test.*`, `**/*.spec.*` | Stage 3 | [N] |
| `.claude/rules/data-model.md` | `[SCHEMA_DIR]/**`, `[MIGRATION_DIR]/**` | Stage 3 | [N] |

**Candidate staging file**: `plancasting/_rules-candidates.md` (MEDIUM/LOW confidence rules awaiting operator review)
