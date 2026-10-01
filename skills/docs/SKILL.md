---
name: docs
description: >-
  Generates developer documentation (API reference, developer guide) and user-facing help docs organized by user journey.
  This skill should be used when the user asks to "generate documentation",
  "create API docs", "write developer guide", "generate help docs",
  "create onboarding docs", "document the codebase", or "write a changelog",
  or when the transmute-pipeline agent reaches Stage 6D of the pipeline.
metadata:
  version: 1.0.0
effort: medium
---

# Documentation Generation — Stage 6D

Read the detailed guide at `${CLAUDE_SKILL_DIR}/references/docs-detailed-guide.md` for the complete documentation procedures, teammate spawn prompts, writing style guidelines, and report templates.

Lead a multi-agent documentation generation project. Generate comprehensive documentation for the complete product: user-facing help docs, API/backend reference, and a developer onboarding guide, all derived from the codebase, PRD, and BRD.

**Stage Sequence** (recommended ordering): Stage 5B → 6A/6B/6C (parallel) → 6E (Code Refactoring) → 6F (Seed Data) → 6G (Resilience Hardening) → **6D (this stage)** → 6H (Pre-Launch) → 6V → 6R → 6P/6P-R → 7 (Deploy)

## Prerequisite Checks

Before any documentation work, verify:

1. Check that `./plancasting/_audits/implementation-completeness/report.md` exists and shows PASS or CONDITIONAL PASS. If missing, WARN: 'Stage 5B report not found — implementation completeness is unverified. Assuming all features are implemented and proceeding.' If FAIL, STOP: "Stage 5B FAIL — resolve implementation gaps before generating documentation."
2. If CONDITIONAL PASS, read documented Category C issues. Document those features as "Planned" rather than "Available".
3. Check if `./plancasting/_audits/refactoring/report.md` exists (Stage 6E). If missing, WARN: "Stage 6E has not completed. If 6E restructures modules after 6D, documentation structure may need regeneration." Proceed with caution.
4. Check if `./plancasting/_audits/resilience/report.md` exists (Stage 6G). If missing, note that documentation may need updating after 6G completes.
5. Check if `./seed/README.md` exists (Stage 6F). If missing, WARN: "Stage 6F has not completed — seed data documentation will be omitted from developer setup guide."
6. Read `./CLAUDE.md` and `./plancasting/tech-stack.md` for project conventions.

Stage 6D produces internal developer documentation (API reference, architecture, dev guide). Stage 7D produces the external user-facing Mintlify site. Stage 6D always runs; Stage 7D is optional per plancasting/tech-stack.md.

If running before Stage 6G, the gate decision should be CONDITIONAL PASS at most, with a note that documentation will need updating after subsequent stages modify code.

## Inputs

- **Codebase**: Backend directory and `./src/` (adapt paths per tech stack)
- **Tech Stack**: `./plancasting/tech-stack.md`
- **PRD**: `./plancasting/prd/` (screen specs, user flows, API specs, architecture)
- **BRD**: `./plancasting/brd/`
- **Architecture Doc**: `./ARCHITECTURE.md` (if it exists — derive from plancasting/tech-stack.md and codebase if not)
- **Project Rules**: `./CLAUDE.md`
- **Implementation Completeness**: `./plancasting/_audits/implementation-completeness/report.md`
- **Refactoring Report** (if exists): `./plancasting/_audits/refactoring/report.md`
- **Seed Data Report** (if exists): `./plancasting/_audits/seed-data/report.md`
- **Resilience Report** (if exists): `./plancasting/_audits/resilience/report.md`
- **Security Report** (if exists): `./plancasting/_audits/security/report.md`
- **Accessibility Report** (if exists): `./plancasting/_audits/accessibility/report.md`
- **Performance Report** (if exists): `./plancasting/_audits/performance/report.md`

## Output Structure

Generate all documentation under `./docs/`:

```
docs/
  help/                 # Product help documentation (internal, NOT Stage 7D Mintlify site)
    index.md
    getting-started.md
    features/
      <feature-name>.md
  api/                  # Backend function reference
    index.md
    <domain>.md
  developer/            # Developer onboarding guide
    index.md
    architecture.md
    local-setup.md
    conventions.md
    testing.md
    deployment.md
  changelog.md          # Initial changelog entry
```

## Language Rules

Check `./plancasting/tech-stack.md` for the `Session Language` setting:
- `docs/help/` — Generate in Session Language (product help for end users)
- `docs/api/` — Generate in English (developer-facing, API identifiers are English)
- `docs/developer/` — Generate in English (engineer-facing, code examples are English)
- `docs/changelog.md` — Generate in Session Language

## Stack Adaptation

Adapt all references to your actual stack per `plancasting/tech-stack.md`:
- `convex/` becomes your backend directory
- `convex/schema.ts` becomes your schema/migration files
- `src/app/` becomes your frontend pages directory

Read `CLAUDE.md` Part 2 for project-specific conventions.

**Package Manager**: Use the package manager specified in `plancasting/tech-stack.md` (default: `bun`).

## Known Failure Patterns

1. **PRD-as-docs copy**: Do not copy PRD text verbatim. Rewrite for the target audience.
2. **Hallucinated API signatures**: Always read the actual source file before documenting. This is the #1 cause of Stage 6D failures.
3. **Documenting ideal, not actual**: Code is the source of truth, not the PRD.
4. **Generic changelog**: Always list specific features with FEAT-IDs.
5. **Broken internal links**: Verify all links resolve correctly.
6. **Missing env vars in setup**: Cross-reference `.env.local.example`. Extract ALL required environment variables and document what each is for and where to find the value.
7. **Non-compiling code examples**: Verify against actual code. Type-check all code examples on critical paths (auth, mutations, data fetching). Spot-check others (at least 50% sample).
8. **Documentation stale after 6E/6F/6G**: If running 6D before 6G, API docs may reference pre-refactoring module boundaries. Document known placeholders with `> DOCUMENTATION GAP: May need updating after Stage 6G completes.`

## Phase 1: Analysis and Planning

Complete before spawning teammates:

1. Read codebase structure, PRD, BRD, `plancasting/tech-stack.md`, and `./ARCHITECTURE.md` (if it exists; otherwise derive architecture from plancasting/tech-stack.md, CLAUDE.md, and codebase structure).
2. Build a **Documentation Map**: which features need user docs, which backend functions need API docs, what developers need to know.
3. Write `./plancasting/_audits/documentation/_doc-context.md` with the documentation map and writing style guidelines:
   - Help docs: conversational tone, task-oriented, no jargon, describe what the user sees
   - API docs: technical, precise, include argument types and return types
   - Developer guide: practical, code-example-heavy, assumes stack familiarity
4. **BLOCKING GATE**: Before spawning teammates, verify implementation completeness. Read Stage 5B report. If >25% Category C or any P0 feature is Category C, STOP — documentation of unbuilt features will create misleading docs.
5. Create a task list for all teammates with dependency tracking.

**Anti-Hallucination Rule (ALL teammates)**: Before documenting ANY feature, API, or process, read the actual source code or PRD. Do not write documentation from memory or assumption.

## Phase 2: Spawn Documentation Teammates

Spawn 3 teammates. Each prompt must include the documentation map and writing style guidelines. All teammates: check if `./docs/` already exists; if so, read existing content and UPDATE rather than overwrite. Preserve sections marked with `<!-- MANUAL: Do not regenerate -->` and `<!-- END MANUAL -->`.

### Teammate 1: help-docs-writer

Scope: Product help documentation (internal markdown, distinct from Stage 7D Mintlify site).

Read PRD product overview, epics/user stories, user flows, and screen specifications.

- **Getting started guide** (`docs/help/getting-started.md`): Account creation/sign-in, first-time setup, quick interface tour (referencing PRD screen specs), "your first [primary action]" walkthrough.
- **Feature guides** (`docs/help/features/<feature-name>.md`): One per feature. Cover what it does (user terms), how to access it (navigation path), step-by-step instructions (from user flows), tips/best practices, common issues, related features.
- **Index** (`docs/help/index.md`): Table of contents, search-friendly descriptions, quick links to common tasks.

Writing style: Conversational, task-oriented. Use "you". Describe UI by visible labels. No jargon.

### Teammate 2: api-docs-writer

Scope: Backend function API reference.

Read schema file and all backend function files (excluding generated code and tests). Read `plancasting/tech-stack.md` for backend details.

**CRITICAL — 100% Source Verification**: Read the actual source file for EVERY function documented. Never document signatures, types, or errors from memory. This is a mandatory requirement, not a best practice.

- **Domain docs** (`docs/api/<domain>.md`): Module overview. For each exported function: name, type (query/mutation/action), description, arguments (name, type from validators, required/optional), return value, authentication requirements, error codes, example usage (TypeScript frontend code), related functions, data model entities.
- **Index** (`docs/api/index.md`): API structure overview, function table by domain, authentication overview, error handling conventions, rate limiting/pagination patterns.

Writing style: Technical, precise. TypeScript type notation. Code examples for every function.

### Teammate 3: developer-guide-writer

Scope: Developer onboarding guide and changelog.

Read `ARCHITECTURE.md` (or derive from plancasting/tech-stack.md/CLAUDE.md/codebase), `package.json`, `plancasting/tech-stack.md`.

- **Architecture** (`docs/developer/architecture.md`): System overview, directory structure with "where to find things", data flow (user to component to hook to backend to database to reactive update), key design decisions.
- **Local setup** (`docs/developer/local-setup.md`): Prerequisites, step-by-step setup (clone, install, env vars, dev servers), common issues, test data seeding. **must cross-reference `.env.local.example`** — extract all required environment variables and document what each is for and where to find the value.
- **Conventions** (`docs/developer/conventions.md`): Quick-reference summary of CLAUDE.md (link rather than duplicate). Code examples for adding: new backend function, new page, new component, new hook, new test. Naming conventions and traceability requirements. Before writing code examples, read actual source files to verify types and imports.
- **Testing** (`docs/developer/testing.md`): Strategy overview. How to run tests (unit, component, E2E). How to write each test type with examples.
- **Deployment** (`docs/developer/deployment.md`): Architecture, production deployment, preview environments, env vars reference, rollback procedures, feature flags.
- **Index** (`docs/developer/index.md`): Quick start (5-minute summary), links to all guides, new developer FAQ.
- **Changelog** (`docs/changelog.md`): "v1.0.0 — Initial release". List all features with PRD feature IDs. Organize by priority (P0 first, then P1, P2, P3). Include format template for future entries.

Exception: Changelog should be in Session Language even though it is developer guide scope.

## Phase 3: Coordination

- When api-docs-writer finalizes function names/signatures, notify help-docs-writer (help docs may reference feature behaviors mapping to those functions).
- When developer-guide-writer documents setup steps, verify they match api-docs-writer's prerequisites.
- Ensure terminology consistency across all three documentation areas.

## Phase 4: Review and Publish

1. Verify all internal links between docs resolve correctly.
2. Verify all code examples compile (extract and type-check). Examples must use correct imports and types matching actual source files.
3. Ensure consistent terminology across help, API, and developer docs.
4. **Documentation Accuracy Verification**: The api-docs-writer (Teammate 2) must perform 100% source verification during their task — read the actual source file for EVERY documented function, not a sample. The lead spot-checks a random sample of at least 10 functions (or all if fewer than 10) against source files as a final failsafe. Verify: argument types match validators, return types match actual returns, error codes match actual throws, auth requirements match actual checks, code examples use correct imports/types.
5. Run `bun run typecheck && bun run lint && bun run build && bun run test` to verify no regressions.
6. Generate `docs/index.md` — top-level navigation hub linking to help, API, and developer docs.
7. Generate `./plancasting/_audits/documentation/report.md` with gate decision, completeness summary (pages created, features covered, functions documented, code examples verified). Stage 6H verifies both `docs/` and this report exist.

## Gate Decision

Gate: PASS / CONDITIONAL PASS / FAIL — see prompt for criteria.

Include in the report under a `## Gate Decision` heading (6H parses this heading):

- **PASS**: All features documented, all code examples verified, all internal links resolve.
- **CONDITIONAL PASS**: Core features documented, minor gaps noted (incomplete features per 5B skipped).
- **FAIL**: Major documentation gaps, code examples on critical paths fail type-checking, or critical features undocumented.

## Phase 5: Shutdown

1. Request shutdown for all teammates.
2. Verify all file modifications are saved and committed.
3. Delete `./plancasting/_audits/documentation/_doc-context.md` — temporary coordination file.

## Critical Rules

1. never copy PRD text verbatim into user documentation — rewrite for the audience.
2. never document function signatures from memory — always read the source file first.
3. never describe ideal behavior instead of actual implementation.
4. always verify code examples compile by checking types against source files.
5. always cross-reference `.env.local.example` when documenting setup procedures. Extract all required environment variables and include them in the developer guide's setup section. Document what each var is for and where to find the value.
6. always verify internal links resolve correctly.
7. If `ARCHITECTURE.md` does not exist, derive architecture from plancasting/tech-stack.md, CLAUDE.md, and codebase structure.
8. Reference Stage 5B output: mark incomplete features as "Planned" with a callout: `> Planned: This feature is not yet available. See the product roadmap for timeline.` Each teammate must check.
9. Reference Stage 6A-6G audit reports when documenting security, accessibility, and performance. If running before those stages, skip missing references and note documentation may need updating.
10. If `./docs/` already exists, read first and update rather than overwrite — preserve any manual additions.
11. Use commands from CLAUDE.md for testing.

### Unfixable Violation Protocol

If a documentation issue cannot be resolved without access to information that doesn't exist:
1. Document the gap with a `> DOCUMENTATION GAP: [description]` marker in the affected doc file.
2. Include the gap in the Stage 6D report under a "Documentation Gaps" section.
3. Continue with remaining documentable content.

**Documentation Gap vs. Unfixable Violation**: A documentation gap (marked inline) is missing information. An unfixable documentation violation (written to `plancasting/_audits/documentation/unfixable-violations.md`) is a critical error that could mislead developers. Both are reported in the final report.
