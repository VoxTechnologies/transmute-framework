---
name: scaffold
description: >-
  Generates a complete project code skeleton from the PRD with full traceability to specifications.
  This skill should be used when the user asks to "generate project scaffolding",
  "scaffold the codebase", "create the code skeleton", "generate the project structure",
  "run Stage 3", or "scaffold from PRD",
  or when the transmute-pipeline agent reaches Stage 3 of the pipeline.
metadata:
  version: 1.0.0
effort: high
---

# Transmute Scaffold — Stage 3: Project Code Skeleton Generation

Lead a multi-agent code generation project to produce a complete, development-ready project scaffolding from the existing PRD, with full traceability back to PRD specifications, BRD requirements, and the original Business Plan.

Read the detailed guide at `${CLAUDE_SKILL_DIR}/references/scaffold-detailed-guide.md` for the complete teammate instructions, code generation guidelines, rules-templates processing, and coordination protocol.

## Critical Framing: Full-Build Approach

This scaffolding covers the COMPLETE product. Every feature, every screen, every API endpoint, every data entity described in the PRD is scaffolded in this pass. There is no "scaffold the MVP now and add more later." The resulting codebase must be architecturally complete so that the Feature Implementation Orchestrator (Stage 5) can fill in business logic systematically across all features.

## Prerequisite Checks

Before proceeding, verify ALL of these conditions. Stop with a clear error message if any fail.

1. Verify `./plancasting/prd/` directory exists and contains markdown files. If missing: STOP — "Stage 3 requires completed PRD. Run Stages 1-2 first."
2. Verify `./plancasting/brd/` directory exists and contains markdown files. If missing: STOP — "Stage 3 requires completed BRD. Run Stage 1 first."
3. Verify `./plancasting/tech-stack.md` exists. If missing: STOP — "Stage 3 requires plancasting/tech-stack.md. Run Stage 0 first."
4. Verify spec validation passed: check `plancasting/_audits/spec-validation/report.md` for PASS or CONDITIONAL PASS. If FAIL or missing: STOP — "Stage 3 requires spec validation. Run Stage 2B first."
5. Verify credentials: `grep -E 'YOUR_.*_HERE|TODO_.*|CHANGE_ME|PLACEHOLDER|^[A-Z_]+=\s*$' .env.local` must return no matches.
6. Validate credential tiers from `plancasting/tech-stack.md`:
   - Red tier pipeline infrastructure credentials (TRANSMUTER_ANTHROPIC_API_KEY, E2B_API_KEY, SANDBOX_AUTH_TOKEN) must be present. **Exception**: If `plancasting/tech-stack.md` indicates a standalone project (no Transmuter platform), pipeline infrastructure credentials (`TRANSMUTER_ANTHROPIC_API_KEY`, `E2B_API_KEY`, `SANDBOX_AUTH_TOKEN`) may be absent — exclude them from validation.
   - Yellow tier product service credentials should be present (WARN if missing — can be added before Stage 5)

## Known Failure Patterns

Avoid these common scaffolding failures:

1. **Over-generating files**: Creating 200+ files when the product needs 80. Every file must trace to a PRD screen spec, API endpoint, or data model entity — no speculative files.
2. **Auth provider mismatch**: always read `plancasting/tech-stack.md` for the actual auth provider.
3. **Dependency version conflicts**: always verify compatibility before adding dependencies.
4. **Wrong directory structure**: Creating `pages/` router when `plancasting/tech-stack.md` specifies App Router, or vice versa.
5. **Missing cross-feature references**: Hooks or functions that reference data from multiple features must be wired correctly from the start.
6. **OAuth callback missing session persistence**: Callback page completes token exchange but never stores the session client-side — user bounces back to login. The callback must: (a) exchange code, (b) handle intermediate auth states, (c) persist session in ALL storage locations, (d) THEN navigate away.

## Execution Phases

### Phase 1: Analysis & Planning (Lead Only)

1. Read and internalize the full context:
   - `./plancasting/tech-stack.md` — technology stack, auth provider, design direction
   - `./plancasting/prd/` — all 18 files, focusing on feature map, screen specs, API specs, data model
   - `./plancasting/brd/` — business rules, security requirements, compliance
   - `./CLAUDE.md` — if it exists, read Part 1 rules carefully; never modify Part 1

2. Generate `plancasting/_codegen-context.md` containing:
   - Naming conventions for backend functions, components, hooks, pages, types
   - Directory structure decisions
   - Cross-feature data flow map
   - Auth check patterns
   - Error handling patterns
   - Feature flag architecture decisions

3. Create the scaffold manifest template (`plancasting/_scaffold-manifest.md`) with the expected file structure. Teammates will append their generated files as they work.

### Phase 2: Spawn 5 Teammates in Parallel

Spawn all teammates simultaneously. Each has a distinct domain. See the detailed guide for complete teammate instructions.

**Teammate 1: "backend-schema-and-functions"**
- Backend schema (complete — every table/model for every feature)
- All backend function files (queries, mutations, actions) organized by domain
- Cron/scheduled job definitions
- HTTP endpoints for webhooks
- Auth helper functions

**Teammate 2: "frontend-pages-and-routing"**
- Route structure from PRD information architecture (complete IA for full product)
- Page components with data loading for every screen in PRD
- Layouts, loading states, error boundaries, 404 states
- Root layout with providers, metadata, font/theme config
- Logo, favicon, and app icons from product logo in plancasting/tech-stack.md
- Backend client provider component

**Teammate 3: "ui-components"**
- Design tokens (`src/styles/design-tokens.ts`) — GENERATE FIRST
- Tailwind config customized to design direction
- Global CSS with `@config` bridge for Tailwind v4
- All feature components organized by domain (all features)
- Custom hooks wrapping backend operations (all features)
- Utility files (utils, constants, validators, types)

**Teammate 4: "feature-flags-and-config"**
- Feature flag backend + hook + gate component
- Middleware (route protection, permission gating, locale detection)
- Auth configuration and role/permission definitions
- Environment configuration files

**Teammate 5: "testing-and-ci-cd"**
- Test infrastructure (vitest config, playwright config, setup files, module maps)
- Backend function tests (all features)
- Component tests (all features)
- E2E tests (all user flows from PRD)
- CI/CD pipelines (ci.yml, deploy.yml, preview.yml)
- Project config (package.json, tsconfig, eslint, prettier, gitignore)
- `plancasting/_progress.md` pre-populated with all features
- `README.md`

### Phase 3: Coordination During Execution

While teammates work:
1. Facilitate cross-team dependencies via messaging (schema finalized -> notify pages/components/tests).
2. Resolve import path conflicts and shared type definitions.
3. Ensure backend function names match what pages and hooks reference.
4. Verify cross-feature consistency for shared data patterns.

### Phase 4: Review & Integration

After all teammates complete:

1. Perform comprehensive consistency review:
   - Full-scope coverage: every PRD screen spec has a component, every API spec has a backend function, every data entity has a schema table
   - Import validation, backend API references, schema completeness, index coverage
   - Type consistency, PRD traceability, state coverage, auth checks, test coverage
   - Cross-feature data flows, feature flag coverage
   - No phase artifacts (no "Phase 1", "Phase 2" references)

2. Finalize `plancasting/_scaffold-manifest.md` — the explicit handoff from Stage 3 to Stage 5. Map every component to its target page, every hook to its consuming components and backend functions.

3. **Generate `ARCHITECTURE.md`** with system architecture diagram (mermaid), directory structure, data flow diagrams, cross-feature flows, auth flow, feature flag flow, and PRD-to-code traceability matrix.

4. Update `CLAUDE.md` Part 2 ONLY — fill in placeholder sections with actual project details. never modify Part 1. Replace ALL bracketed placeholders (`[PROJECT_NAME]`, `[e.g., ...]`, `[N]`) with actual values. After verification passes (all Part 1 sections intact, no Part 2 placeholders remain), commit: `git add CLAUDE.md && git commit -m 'chore: complete Stage 4 (CLAUDE.md verification)'`

5. **Generate `.claude/rules/` starter rules**:
   - Create the `.claude/rules/` directory
   - Read the rule templates from `./plancasting/transmute-framework/rules-templates/` (6 template files: `_backend-template.md`, `_frontend-template.md`, `_api-contracts-template.md`, `_auth-template.md`, `_testing-template.md`, `_data-model-template.md`)
   - For each template, render into a real rule file by:
     a. Replacing directory placeholders (`[BACKEND_DIR]`, `[FRONTEND_DIR]`, etc.) with actual project paths from `tech-stack.md`
     b. Replacing tech-stack-specific placeholders (`[VALIDATOR_SYSTEM]`, `[ERROR_TYPE]`, `[AUTH_HELPER]`, etc.) with actual values derived from `tech-stack.md`
     c. Adding correct `paths` frontmatter based on actual project paths (Claude Code scopes rules by `paths`; a rule file without it loads in every session)
     d. Setting `Source: Stage 3` and `Evidence: tech-stack.md` on each rule
     e. Removing all `<!-- TODO: Stage 3 — ... -->` comments and template banners
   - Write rendered files to `.claude/rules/backend.md`, `.claude/rules/frontend.md`, `.claude/rules/api-contracts.md`, `.claude/rules/auth.md`, `.claude/rules/testing.md`, `.claude/rules/data-model.md`
   - Respect limits: max 15 rules per file, max 8 files total

6. **Create `plancasting/_rules-candidates.md`** with a header explaining the staging workflow, candidate format, and confidence criteria (per CLAUDE.md § 'Path-Scoped Rules'). Starts with zero candidates — Stages 5B and 6R will populate it.

7. **Update the Path-Scoped Rules table** in CLAUDE.md Part 2 with actual rule files (file paths, `paths` patterns, rule counts).

8. **Copy framework files into project**: Copy `execution-guide.md` and `feature_scenario_generation.md` from the Transmute Framework Template into `./plancasting/transmute-framework/` so they are available for later stages (6V, 7V) without depending on the template location. Note: The CLAUDE.md template lives at the ROOT of the Transmute Framework Template, not inside `plancasting/transmute-framework/`.

9. Fix any inconsistencies found during review.

10. Output final summary: file counts, PRD coverage percentages (target: 100% for screens, APIs, data entities), cross-feature touchpoints, test file counts, feature flags, unresolved issues.

11. **Gate Decision**:
    - **PASS**: All required output files exist, PRD coverage ≥ 95%, CLAUDE.md Part 2 fully populated, `_progress.md` lists all features, `.claude/rules/` populated → proceed to Stage 4
    - **CONDITIONAL PASS**: PRD coverage ≥ 80% with gaps documented, all critical P0 features scaffolded, CLAUDE.md Part 2 populated and `_progress.md` present (rules may be incomplete) → proceed to Stage 4 with noted gaps
    - **FAIL**: PRD coverage < 80%, OR CLAUDE.md Part 2 not populated, OR `_progress.md` missing, OR required output files missing → re-run Stage 3

> **Terminology note**: "Coverage" in this stage means scaffold coverage — the percentage of PRD screens (SC-xxx), API endpoints, and data entities that have corresponding scaffold files. This differs from Stage 2B's "coverage" (BRD→PRD requirement traceability).
>
> **Scaffold Coverage Definition**: Scaffold coverage is the percentage of PRD-specified features that have at least one scaffold file. Coverage ≥95% = PASS, ≥80% = CONDITIONAL PASS, <80% = FAIL. Note: this differs from Stage 2B's requirement traceability coverage.

### Phase 5: Shutdown

Verify all file modifications are saved and all output files exist before declaring Stage 3 complete.

## Session Recovery

If resuming a previously interrupted scaffold generation:
1. Check which files already exist in backend dir, `src/`, and `e2e/`.
2. Check if `plancasting/_codegen-context.md` and `plancasting/_progress.md` exist (Phase 1+ completed).
3. Check if `ARCHITECTURE.md` exists (Phase 4 reached).
4. Resume from the earliest incomplete phase. Do not regenerate existing complete files.
5. Only respawn teammates whose assigned files are missing or incomplete.
6. Clean up incomplete files before re-spawning. Re-spawned teammates regenerate from scratch and append to `plancasting/_scaffold-manifest.md`.

## Code Generation Guidelines (Apply to ALL Teammates)

1. **Full Scope**: Scaffold ALL features from the PRD. Nothing is deferred.
2. **PRD Traceability**: Every file starts with `@traces` comment block referencing PRD/BRD IDs.
3. **TypeScript Strict Mode**: All code compiles under `strict: true`. No `any`, no `@ts-ignore`.
4. **Structurally Complete Functions**: Correct signatures, validators, auth checks, error handling. Business logic bodies contain a reasonable first-pass with `// ⚠️ STUB: <description>` markers for Stage 5 to replace.
5. **Design Quality**: Read `plancasting/tech-stack.md` "Design Direction" section. Use design tokens. Build with the selected UI component library. Avoid generic AI aesthetics.
6. **Tailwind v4 Critical**: `globals.css` must include `@config` directive. Semantic color tokens must be in `colors` palette.
7. **Component Patterns**: Default to Server Components. Implement ALL states. Include ARIA and keyboard nav.
8. **No Phase References**: All features ship enabled. Conditional rendering only via ops/experiment/permission flags.
9. **CLAUDE.md Protection**: Never rewrite from scratch. Only extend Part 2.
10. **Scaffold Manifest**: Every generated file must be listed in `plancasting/_scaffold-manifest.md`.
11. **File Size**: Keep files under 300 lines. Split if larger.

## Output Specification

Upon completion, the following artifacts must exist:

| Artifact | Path | Description |
|---|---|---|
| Code generation context | `plancasting/_codegen-context.md` | Naming conventions, patterns, decisions |
| Scaffold manifest | `plancasting/_scaffold-manifest.md` | Component-to-page and hook-to-component mapping |
| Progress tracker | `plancasting/_progress.md` | All features listed, all marked Not Started |
| Architecture doc | `ARCHITECTURE.md` | System diagrams, directory structure, traceability |
| CLAUDE.md (updated) | `CLAUDE.md` | Part 2 filled with project-specific config |
| Rules (starter) | `.claude/rules/*.md` | 6 rule files rendered from templates |
| Rules candidates | `plancasting/_rules-candidates.md` | Empty staging file for future rule candidates |
| Backend schema + functions | `[backend-dir]/` | Complete schema, all domain function files |
| Frontend pages | `[pages-dir]/` | All routes with layouts, loading, error states |
| UI components | `src/components/` | All feature components, design system |
| Design tokens | `src/styles/design-tokens.ts` | Complete design system tokens |
| Hooks | `src/hooks/` | All custom hooks wrapping backend operations |
| Tests | `[backend-dir]/__tests__/`, `src/__tests__/`, `e2e/` | Full test infrastructure |
| CI/CD | `.github/workflows/` | ci.yml, deploy.yml, preview.yml |
| Project config | Root | package.json, tsconfig, eslint, tailwind, etc. |
| README | `README.md` | Setup, development, testing, deployment guide |
| Framework files | `plancasting/transmute-framework/` | execution-guide.md, feature_scenario_generation.md |
