---
name: seed-data
description: >-
  Generates comprehensive, realistic seed data for all environments (dev, test, demo, stress).
  This skill should be used when the user asks to "generate seed data",
  "create test data", "populate the database", "create demo data",
  "generate edge case data", or "set up seed scripts"
  — or when the transmute-pipeline agent reaches Stage 6F of the pipeline.
metadata:
  version: 1.0.0
effort: medium
---

# Stage 6F: Realistic Test Data for All Environments

Read the detailed guide at `${CLAUDE_SKILL_DIR}/references/seed-data-detailed-guide.md` for the complete generation procedures, teammate spawn prompts, data profile patterns, and report templates.

Lead a multi-agent seed data generation project. Generate comprehensive, realistic seed data covering all entities in the data model, supporting all user flows, and enabling meaningful testing and demonstrations of the COMPLETE product.

**Stage Sequence** (recommended ordering): Stage 5B → 6A/6B/6C (parallel) → 6E (Code Refactoring) → **6F (this stage)** → 6G (Resilience Hardening) → 6D (Documentation) → 6H (Pre-Launch) → 6V → 6R → 6P/6P-R → 7 (Deploy)

## Prerequisites

Verify before starting:

1. `./plancasting/_audits/implementation-completeness/report.md` exists with PASS or CONDITIONAL PASS. If missing, STOP: "Stage 5B report not found — run Stage 5B before starting. Seed data must target finalized schemas."
2. If 5B shows FAIL, STOP. If CONDITIONAL PASS, review Category C issues — proceed with awareness of known gaps.
3. `./plancasting/_audits/refactoring/report.md` (6E) exists. If missing, WARN: "Stage 6E has not been run. Seed data may need regeneration if 6E introduces schema changes." If present, read to understand schema changes (field renames, table merges, index additions).
4. Read `./CLAUDE.md` and `./plancasting/tech-stack.md` for project conventions.
5. If `./plancasting/_audits/security/report.md` (6A) exists, read for auth requirements affecting seed data (e.g., new auth guards, rate limiting on seed endpoints).

Check `./plancasting/tech-stack.md` for the `Session Language` setting. Generate all reports in that language. Code and file names remain in English. Replace all command references with the project's package manager from `CLAUDE.md`.

## Stack Adaptation

Source examples use Convex + Next.js. Adapt all paths and patterns to your actual tech stack: `convex/` becomes your backend directory, Convex mutations become your backend mutation functions, etc.

## Known Failure Patterns

1. **Foreign key reference failures**: Use actual returned IDs through shared state, never hardcode.
2. **Identical timestamps**: Add increments (`Date.now() - i * 86400000`) for realistic distributions.
3. **Business rule violations**: Always go through backend mutation functions, not direct inserts. Create internal/admin seed functions if auth is required. Check Stage 6A for recently added auth requirements.
4. **Non-idempotent seeds**: Implement upsert logic or require `seed:reset` before re-seeding.
5. **Auth credential gaps**: Consider the full auth flow when creating persona users.
6. **Missing soft-deleted records**: Include some records with `deletedAt` set to verify query filtering.
7. **Orphaned references**: Child records referencing non-existent parents — verify all foreign key references exist in `.seed-ids.json` before creating dependent records.

## Output

Stage 6F generates:
- `./seed/` directory with seed scripts: `core.ts`, `features.ts`, `edge-cases.ts`, `stress.ts`, `empty-state.ts`
- `./seed/index.ts` — unified runner with profile selection
- `./seed/reset.ts` — data cleanup script
- `./seed/.seed-ids.json` — shared ID registry for cross-feature referential integrity
- `./seed/README.md` — usage documentation
- `./seed/verify-integrity.ts` — referential integrity verification
- `./plancasting/_audits/seed-data/report.md` — seed data audit report with gate decision
- Updated `package.json` with seed scripts (`seed:dev`, `seed:test`, `seed:demo`, `seed:stress`, `seed:empty`, `seed:verify`, `seed:reset`)

## Phase 1: Lead Analysis and Planning

Complete BEFORE spawning teammates:

1. Read `./CLAUDE.md`, `./plancasting/tech-stack.md`, your schema file, and PRD `11-data-model.md`.
2. Read PRD `01-product-overview.md` for personas and `06-user-flows.md` for journeys.
3. Read BRD `14-business-rules-and-logic.md` for validation rules.
4. Build a **Seed Data Plan** mapping every table to needed seed data:
   - **Dev tier**: 5-20 records per table for rapid iteration.
   - **Test tier**: 50-200 records per table for thorough testing including pagination.
   - **Demo tier**: Curated scenarios with realistic names and relationships.
   - **Stress tier**: 500-1,000 records per major table for performance testing. Use batch sizes of 10-50 records per call, adjusted to backend rate limits.
   - **Empty-state tier**: Users with NO associated data for empty state UI verification.
   - Persona-based data sets for each PRD persona.
   - Edge case data: empty states, max-length strings, special characters, Unicode, boundary values.
   - Dependency map: which tables must be seeded first.
   - **Mutation function emphasis**: ALL data insertion must use backend mutation functions, not direct database inserts.
5. Decide the seed data auth strategy (direct database insertion vs. API-based user creation). Communicate to all teammates.
6. Verify the schema's soft-delete field name (common: `deletedAt`, `deleted_at`, `isDeleted`). Document the exact field name and communicate to all teammates.
7. Verify `seed/.seed-ids.json` is in `.gitignore`. If not, add it.
8. Create `./seed/README.md` with the seed data plan.
9. Create a task list for all teammates with dependency tracking.

## Phase 2: Spawn Seed Data Teammates

Spawn Teammate 1 first. Wait for completion and validate `.seed-ids.json` per the Synchronization Protocol. Only after validation, spawn Teammates 2 and 3 in parallel.

### Teammate 1: "core-data-seeder"

Scope: Foundational entities (users, organizations, roles, settings).

Tasks:
- Create `./seed/core.ts` with production environment safety check at the top of all seed functions. Adapt the check to your backend's environment detection (`process.env.NODE_ENV`, `CONVEX_DEPLOYMENT`, etc.). Place production check in the Node.js seed runner script, not inside query/mutation functions for serverless backends.
- Use backend mutation functions to insert data respecting all schema validators.
- Create persona user accounts with realistic names, emails, complete profiles, appropriate roles.
- Include at least one admin user and one user per distinct role.
- Handle auth provider integration: implement programmatic creation if SDK available, or document manual steps in `./seed/MANUAL_SETUP.md`. Decision tree: (1) auth provider has user management API? Use it. (2) Backend has CLI for auth layer? Document steps. (3) Neither? Document manual steps and alternative test credentials.
- Generate three tiers: `seedCoreDev()` (2-3 users, 1 org), `seedCoreTest()` (10-15 users, 3 orgs), `seedCoreDemo()` (5-8 personas, 2 orgs).
- Include edge case users (max-length name, Unicode/emoji, minimal fields, deactivated).
- Include 2-3 soft-deleted records per entity type (set the soft-delete field to a timestamp 7-30 days ago).
- Write created IDs to `./seed/.seed-ids.json`. Store only DATABASE IDs (primary keys), NOT auth provider IDs.

### Teammate 2: "feature-data-seeder"

Scope: Feature-specific entities. Blocked by Teammate 1.

Tasks:
- Read `./seed/.seed-ids.json` for core entity IDs.
- Create `./seed/features.ts` for EVERY feature-specific table.
- Cover happy paths of every user flow. Include various states (draft/active/completed/archived). Use realistic content, not "Test Item 1". Respect business rules. Create proper relationships via backend IDs. Include realistic timestamp distributions (not all at the same millisecond).
- Three tiers: `seedFeaturesDev()` (3-5 items per feature per user), `seedFeaturesTest()` (20-50 items, enough for pagination), `seedFeaturesDemo()` (hand-crafted showcase scenarios).
- Demo data must include a completed end-to-end scenario, compelling dashboard data, cross-feature data.
- Include 2-3 soft-deleted items per feature.

### Teammate 3: "edge-case-seeder"

Scope: Edge case and stress test data. Blocked by Teammate 1.

Tasks:
- Read `./seed/.seed-ids.json` for core entity IDs.
- Create `./seed/edge-cases.ts` with boundary records: empty/minimal, maximum-length, special characters (Unicode, emoji, RTL, HTML entities, SQL injection strings as data), boundary values, all state combinations, soft-deleted edge cases.
- Create `./seed/stress.ts` with `seedStress()`: 500-1,000 records per major table. Use batch operations for rate-limited backends (batch sizes 10-50). Realistic distributions (80/20 ownership for stress, even spread for demo). Realistic timestamp distributions.
- Create `./seed/empty-state.ts` with `seedEmptyState()`: users with NO associated data for empty state UI verification.

## Synchronization Protocol

IDs are shared via `./seed/.seed-ids.json`. Only Teammate 1 writes this file. Teammates 2 and 3 read but do not modify it — they run in parallel and must not create write conflicts.

**Lead validation after Teammate 1 completes** (timeline: Teammate 1 creates entities -> writes file -> reports completion -> lead validates -> spawns Teammates 2/3):
- File exists at `./seed/.seed-ids.json`
- Parses as valid JSON
- Contains expected top-level keys (`users`, `organizations`, etc.)
- Each key maps to a non-empty object of `{ label: id }` pairs
- IDs are database IDs (for foreign keys), not auth-provider IDs

If ANY check fails, do not spawn Teammates 2/3 — re-spawn Teammate 1 with fix instructions. Fallback: extract IDs from completion message and write the file manually.

## Phase 3: Integration and Seed Script

After all teammates complete:

1. Create `./seed/index.ts` — master orchestrator for all seed tiers (dev, test, demo, stress, empty, reset).
2. Create `./seed/reset.ts` — clear all tables with confirmation parameter and production safety check.
3. Add seed commands to `package.json`: `seed:dev`, `seed:test`, `seed:demo`, `seed:stress`, `seed:empty`, `seed:verify`, `seed:reset`.
4. Test each seed tier and verify no schema validation errors. Reset between tiers if testing in isolation.
5. Run `bun run typecheck && bun run lint && bun run build && bun run test` to verify no regressions.
6. Run E2E tests against test seed data if test credentials are configured.
7. **Data Integrity Verification**: Create `./seed/verify-integrity.ts` checking: (a) referential integrity — every foreign key points to existing record, (b) no orphaned records, (c) soft-delete filtering — queries exclude soft-deleted records, (d) enum/status values are valid per schema. Add as `seed:verify` command.

### Integrity Check Failure Recovery

- **Minor constraint violation**: Document as known limitation. Proceed.
- **Referential integrity failure**: Reset and re-execute the failing seed script. If repeated, escalate for manual fix.
- **Schema mismatch**: BLOCKING. Pause all teammates. Verify schema against current codebase. Check if 6E changed schema. Fix seed script to match current schema.

8. Run `bun run seed:verify` and verify all checks pass.
9. Update `./seed/README.md` with run instructions, persona credentials, data volumes, reset procedure.

## Report and Gate Decision

Generate `./plancasting/_audits/seed-data/report.md` containing:
- Data volume summary per tier (dev, test, demo, stress, empty)
- Persona accounts with credentials
- Integrity verification results
- Edge cases covered
- Constraints or manual steps required

Gate: PASS / CONDITIONAL PASS / FAIL — see prompt for criteria.

Include under a `## Gate Decision` heading (6H parses this heading):
- **PASS**: All tiers generated successfully, referential integrity verified, seed data renders correctly in UI.
- **CONDITIONAL PASS**: Generated with documented constraints (e.g., auth users need manual creation, deferred features have no seed data). Document alternative test credentials.
- **FAIL**: Schema mismatches, missing core entities, or referential integrity failures.

### Unfixable Violation Protocol

If a seed data issue cannot be resolved without schema changes or architectural modifications:
1. Document in `./plancasting/_audits/seed-data/unfixable-violations.md` with issue description, root cause, affected entities, and recommended resolution.
2. Continue with remaining seed data generation.
3. Reference in the final report under "Seed Data Constraints".

## Critical Rules

1. never use real personal data in seed data.
2. never bypass schema validators — all data goes through backend mutation functions. Create internal/admin seed functions if auth is required.
3. never hardcode document IDs — use IDs returned from insert operations.
4. Seed scripts must be idempotent (upsert logic preferred). Use natural unique keys for deduplication. If upsert not feasible, provide `seed:reset` and document the requirement.
5. always include soft-deleted records to verify query filtering.
6. always verify seed data renders correctly in the UI, not just that it inserts.
7. always include realistic timestamps with proper chronological ordering. Demo data dates should be relative to "now" (calculated at runtime) so demos always look current.
8. If auth provider requires API calls to create users, document as manual step or implement in seed script.
9. never hard-code API keys, secrets, or real credentials in seed scripts. Use environment variables or placeholder values.
10. If Stage 6A or 6G has added rate limiting, seed scripts must either use internal/admin functions that bypass rate limiting or add delays between batch operations.
