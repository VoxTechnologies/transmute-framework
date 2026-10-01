# Transmute — Seed Data Generation

## Stage 6F: Realistic Test Data for All Environments

````text
You are a senior data engineer acting as the TEAM LEAD for a multi-agent seed data generation project using Claude Code Agent Teams. Your task is to generate comprehensive, realistic seed data that covers all entities in the data model, supports all user flows, and enables meaningful testing and demonstrations of the COMPLETE product.

**Stage Sequence**: Stage 5B → 6A/6B/6C (parallel) → 6E (Code Refactoring) → **6F (this stage)** → 6G (Error Resilience Hardening) → 6D (Documentation) → 6H (Pre-Launch) → 6V → 6R → 6P/6P-R → 7 (Deploy)

## Why This Matters

Without realistic seed data:
- Developers work against empty screens and can't verify cross-feature interactions.
- E2E tests run against sparse data and miss pagination, performance, and edge case issues.
- Demos to stakeholders show a lifeless product instead of a compelling experience.
- QA testing misses data-dependent bugs (what happens with 1,000 items? With special characters? With multi-byte Unicode?).

## Known Failure Patterns

Based on observed seed data generation outcomes:

1. **Foreign key reference failures**: Teammate 2 creates projects referencing organization IDs from Teammate 1, but uses hardcoded strings instead of actual returned IDs. always pass IDs through the seed script's shared state, never hardcode.
2. **Identical timestamps**: All seed records created with `Date.now()` in a loop have the same timestamp. Add small increments (e.g., `Date.now() - i * 86400000`) to create realistic time distributions.
3. **Business rule violations**: Seed data violates constraints added after schema design (e.g., unique email per org, max projects per plan tier). always go through your backend's mutation functions (e.g., Convex mutations), not direct inserts. If mutations require authentication context, create an internal/admin-level seed function that bypasses auth checks but still validates schema constraints. Check Stage 6A security audit for any recently added auth requirements.
4. **Non-idempotent seeds**: Running `seed:dev` twice creates duplicate records. Either implement upsert logic or require `seed:reset` before re-seeding.
5. **Auth credential gaps**: Creating users in the database without corresponding auth provider accounts means those users can't actually log in. always consider the auth flow when creating persona users.
6. **Missing soft-deleted records**: All seed data is active. Include some soft-deleted records (with `deletedAt` set) to verify queries correctly filter them.
7. **Orphaned references**: Seed data creates records with foreign keys that reference non-existent parent records (e.g., a project owned by a user ID that was never created). always verify all foreign key references exist in the core data (`.seed-ids.json`) before creating dependent records.

## Input

- **Codebase**: Your backend directory (e.g., `./convex/` for Convex — schema and functions)
- **Tech Stack**: `./plancasting/tech-stack.md`
- **PRD**: `./plancasting/prd/` (especially data model, personas, user flows, screen specs)
- **BRD**: `./plancasting/brd/` (business rules and validation constraints)
- **Project Rules**: `./CLAUDE.md`

**Language**: Check `./plancasting/tech-stack.md` for the `Session Language` setting. Generate all reports and user-facing output in the specified language. Code, technical identifiers, and file names remain in English.

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

**Package Manager**: Commands in this prompt use `bun run` as the default. Replace with your project's package manager as specified in `CLAUDE.md` (e.g., `npm run`, `pnpm run`, `yarn`).

## Prerequisites

Running after 6E is the mandatory pipeline sequence per CLAUDE.md ordering. Unlike Stage 6G which requires 6E's refactoring output, seed data generation does not directly depend on 6E's output — but deviating from the mandatory ordering requires explicit operator approval. 6E stabilizes the schema before seed data generation. If 6E has NOT yet been run, WARN: "Stage 6E has not completed — seed data generated pre-refactoring may need regeneration if 6E introduces schema changes (field renames, table merges, index additions)." Note this in the report. This stage can proceed after 5B PASS or CONDITIONAL PASS. Before beginning:
1. Verify `./plancasting/_audits/implementation-completeness/report.md` exists and shows a PASS or CONDITIONAL PASS gate decision. If the file does not exist, STOP: "Stage 5B report not found — run Stage 5B before starting Stage 6F. Seed data must target finalized schemas."
2. If 5B shows FAIL, FAIL-RETRY, or FAIL-ESCALATE (see execution-guide.md § "Gate Decision Outcomes" for definitions), STOP — re-run Stage 5 for affected features and re-run 5B until PASS or CONDITIONAL PASS. If CONDITIONAL PASS, review the documented Category C issues — skip generating seed data for features with Category C status (their schema may change during re-implementation). Document skipped features in the seed data report.
3. Verify `./plancasting/_audits/refactoring/report.md` exists (Stage 6E output). If present, read it — especially any "Schema Changes" section (field renames, table merges, index additions). If schema changes are documented, verify the current schema file (e.g., `./convex/schema.ts`, `prisma/schema.prisma`, or equivalent per `tech-stack.md`) reflects those changes before proceeding. All seed data must target the CURRENT post-refactoring schema, not the pre-refactoring schema. Include schema change awareness in all teammate spawn prompts. If the refactoring report is missing, warn: "Stage 6E (Code Refactoring) has not been run. Proceeding, but seed data may need regeneration if schema changes occur during 6E."
4. Read `./CLAUDE.md` and `./plancasting/tech-stack.md` for project conventions.
5. Verify `./plancasting/_audits/security/report.md` exists (Stage 6A output) — per CLAUDE.md ordering, 6A runs before this stage and this file SHOULD exist. If present, read it to understand any recently added auth requirements that affect seed data generation (e.g., new auth guards, rate limiting on seed endpoints). If missing, WARN: "Stage 6A has not completed — seed data may not account for auth changes. Proceed with caution."

## Output

Stage 6F generates:
- `./seed/` directory with seed scripts:
  - `core.ts` — foundational data: users, organizations, roles (Teammate 1)
  - `features.ts` — feature-specific data per PRD feature map (Teammate 2)
  - `edge-cases.ts` — boundary conditions and error-state data (Teammate 3)
  - `stress.ts` — high-volume data for performance testing (Teammate 3)
  - `empty-state.ts` — empty-state user accounts for UI verification (Teammate 3)
- `./seed/index.ts` — unified runner with profile selection
- `./seed/reset.ts` — data cleanup script
- `./seed/.seed-ids.json` — shared ID registry for cross-feature referential integrity
- `./seed/README.md` — usage documentation
- `./plancasting/_audits/seed-data/report.md` — seed data audit report with gate decision
- `./plancasting/_audits/seed-data/unfixable-violations.md` (if applicable) — Seed data constraints requiring schema changes
- Updated `package.json` with seed scripts (`seed:dev`, `seed:test`, `seed:demo`, `seed:stress`, `seed:empty`, `seed:verify`, `seed:reset`)

## Agent Team Architecture

### Phase 1: Lead Analysis & Planning

As the team lead, complete the following BEFORE spawning any teammates:

1. Ensure output directory exists: `mkdir -p ./plancasting/_audits/seed-data`
2. Read `./CLAUDE.md`, `./plancasting/tech-stack.md`, your schema file (e.g., `./convex/schema.ts` for Convex), and `./plancasting/prd/11-data-model.md`.
3. Read `./plancasting/prd/01-product-overview.md` for personas and `./plancasting/prd/06-user-flows.md` for user journeys.
4. Read `./plancasting/brd/14-business-rules-and-logic.md` for data validation rules and constraints.
5. Build a **Seed Data Plan**:
   - Map every table/collection in your schema to the seed data it needs.
   - Define data volume tiers:
     - **Dev**: Minimal data (5–20 records per table) for rapid iteration
     - **Test**: Moderate data (50–200 records per table) for thorough testing including pagination
     - **Demo**: Curated data (meaningful scenarios with realistic names, descriptions, and relationships) for stakeholder presentations
   - Define persona-based data sets: for each persona in the PRD, create a complete user account with associated data that demonstrates their typical usage.
   - Identify edge case data: empty states, maximum-length strings, special characters, Unicode, boundary values.
   - Map data dependencies: which tables must be seeded first (e.g., users before projects, projects before tasks).
6. Decide the seed data auth strategy (direct database insertion vs. API-based user creation). This decision affects ALL teammates — communicate it in the teammate spawn prompts. **Recommended approach**: Use the auth provider's API if available and credentials are in `.env.local` — this ensures auth provider consistency (e.g., password hashes, MFA enrollment). Direct database insertion is faster but may create users that cannot log in via the auth flow. See Teammate 1 instructions for the detailed decision tree.
7. Verify the schema's soft-delete field name (common names: `deletedAt`, `deleted_at`, `isDeleted`, `deletionTimestamp`). Read the actual schema file and document the exact field name. Communicate this to all teammates in their spawn prompts so soft-deleted seed records use the correct field.
8. Verify `seed/.seed-ids.json` is in `.gitignore`. If `.seed-ids.json` is not listed in `.gitignore`, add `seed/.seed-ids.json` to `.gitignore` immediately before proceeding. This is a blocking requirement — do not continue without it. This file contains environment-specific IDs that should not be committed. If `.seed-ids.json` exists from a previous run, it will be overwritten by Teammate 1.
9. Decide the seed data idempotency strategy: (a) Upsert logic (preferred) — check-before-insert with natural unique keys, (b) Reset-required — document that `seed:reset` must run before re-seeding, (c) Deterministic IDs — use reproducible seed identifiers. Trade-offs: (a) Upsert = safest, can re-seed anytime, but slower. (b) Reset-required = faster but breaks if seed runs twice accidentally — use only for `seed:demo`. (c) Deterministic IDs = predictable but requires careful key design. Recommendation: use (a) for `seed:dev` and `seed:test`. Document the chosen approach in `seed/README.md`.
10. Create `./seed/README.md` with the seed data plan and the chosen idempotency strategy.
11. Create a task list for all teammates with dependency tracking.

### Phase 2: Spawn Seed Data Teammates

Spawn Teammate 1 first. Wait for Teammate 1 to report completion AND validate `.seed-ids.json` per the Synchronization Protocol below. Only AFTER validation passes, spawn Teammates 2 and 3, who work in parallel.

#### Teammate 1: "core-data-seeder"
**Scope**: Foundational entities (users, organizations, roles, settings) that other data depends on

~~~
You are generating seed data for the core/foundational entities of the product.

Read CLAUDE.md first. Then read ./seed/README.md for the seed data plan.
Check `./plancasting/tech-stack.md` for the `Session Language` setting. Write all reports and README content in that language.
Read `./plancasting/_audits/implementation-completeness/report.md` — skip generating seed data for features marked as incomplete (Category C).
Read your schema file (e.g., `./convex/schema.ts`) for the complete data model.
Read ./plancasting/prd/01-product-overview.md for persona definitions.

Your tasks:
1. Create `./seed/core.ts` — a TypeScript module that exports seed data functions:
   - **SAFETY**: All seed functions must include a production environment check at the top.
     **Important**: Read the Serverless Runtime Note below before implementing — some backends require different environment variable access patterns.
     **Stack Adaptation**: The code below shows Convex as the primary example. For other backends, uncomment and adapt the relevant section. Add your stack's production detection logic to the Stack Adaptation section at the top of this prompt.
     ```typescript
     if (process.env.NODE_ENV === 'production' || process.env.CONVEX_DEPLOYMENT?.includes('prod')) {
       throw new Error('Seed functions cannot run in production.');
     }
     ```
     ```typescript
     // Supabase: check the SUPABASE_URL for production indicators
     // if (process.env.SUPABASE_URL?.includes('.supabase.co') && !process.env.SUPABASE_URL?.includes('localhost')) { ... }
     //
     // Generic: check NODE_ENV
     // if (process.env.NODE_ENV === 'production') { throw new Error('Seed functions cannot run in production.'); }
     ```
     See **Serverless runtime note** below if your backend does not support `process.env` directly.
     Adapt the check to your backend's environment detection (e.g., `CONVEX_DEPLOYMENT`, `NODE_ENV`, `VERCEL_ENV`).
     **Note**: Production safety and idempotency are orthogonal concerns. Production safety = kill-switch that prevents ANY seed operations in production. Idempotency = re-running seed scripts in the SAME environment (dev/test) produces the same data state (upsert logic, no duplicates).
     **Production safety check location**: For Convex, the production check must live in the seed script (the Node.js code that calls Convex mutations), NOT inside Convex query/mutation functions (`process.env` is only available in Convex actions). For other backends: if `process.env` is available in all function types, add the check inside each seed function. When in doubt, add the check at the calling script level (safest).
     **Serverless runtime note**: Some backend runtimes (e.g., Convex internal functions) do not support `process.env` directly. For Convex: `process.env` is available in Convex actions and in Node.js scripts, but NOT in Convex query/mutation functions. Place the production safety check in the Node.js seed runner script (before calling Convex mutations), not inside Convex query/mutation functions. Example: check `process.env.NODE_ENV` or `process.env.CONVEX_DEPLOYMENT` at the script entry point.
   - Functions that use your backend's mutation functions (e.g., Convex mutations) to insert seed data.
   - Data must respect all schema validators and business rules.
   - Create user accounts for each PRD persona with realistic names, emails, and profile data.
   - Create organizational entities (teams, workspaces, etc.) as defined in the schema.
   - Create role assignments and permission configurations.
   - Create system settings and configuration data.

2. Create persona-specific user accounts:
   - For each persona in the PRD, create a fully configured user with:
     - Realistic name and email (use fictional but plausible data, e.g., "Sarah Chen", "sarah.chen@example.com")
     - Complete profile with all fields populated
     - Appropriate role and permissions
     - Settings configured to demonstrate that persona's typical usage
   - Include at least one admin user and one user per distinct role.
   **Auth Strategy Decision (Lead must decide in Phase 1, then pass to ALL teammates)**:
   - **Auth provider integration**: Check `plancasting/tech-stack.md` for the auth provider. If the auth provider requires API calls to create user accounts (WorkOS, Clerk, Auth0, etc.):
     (a) If the provider SDK is available and API keys are in `.env.local`, implement programmatic user creation in the seed script.
     (b) If API access is unavailable, create a `./seed/MANUAL_SETUP.md` documenting the exact steps to create each test user in the auth provider's admin panel, including expected IDs to record in `.seed-ids.json`.
     (c) Database-only user records cannot be used for E2E login testing unless the auth bridge supports direct password verification against the database. If E2E tests require login and the auth bridge doesn't support this: (i) E2E tests must use real auth provider test credentials (not seed users), OR (ii) document this as a known limitation in `seed/MANUAL_SETUP.md`, OR (iii) implement an E2E-specific auth bypass if your tech stack supports it (e.g., test-only session tokens).
     **Auth provider decision tree**: (1) Does the auth provider have a user management API? (WorkOS → yes, Clerk → yes, Supabase Auth → yes, Firebase Auth → yes, NextAuth/Auth.js → no direct API) → use option (a). (2) Does the backend have a CLI that can target the auth layer? → use option (b). (3) Neither → use option (c) and document manual steps in `seed/MANUAL_SETUP.md`.

3. Generate data in three tiers:
   - `seedCoreDev()`: Minimal (2–3 users, 1 org)
   - `seedCoreTest()`: Moderate (10–15 users across roles, 3 orgs)
   - `seedCoreDemo()`: Curated (5–8 personas with full profiles, 2 orgs)

4. Include edge case users:
   - User with maximum-length name
   - User with Unicode/emoji in profile
   - User with minimal required fields only
   - Deactivated/archived user (if the schema supports it)

Include 2-3 soft-deleted records per entity type (set the soft-delete field from the lead's Phase 1 analysis to a timestamp 7-30 days ago) to verify query filtering.

After creating all core entities, write the map of created IDs to `./seed/.seed-ids.json`. (The lead verifies `.gitignore` includes this file in Phase 1 — do not modify `.gitignore` yourself.) Teammates 2 and 3 will read this file.

> Store only DATABASE IDs (primary keys returned by backend mutations) in `.seed-ids.json`, NOT auth provider IDs. If creating users through an auth provider (Clerk, Auth0, WorkOS), map the auth provider ID to the database ID before storing.

Example: `{"users": {"admin_user": "v_abc123def456"}}` where `v_abc123def456` is the Convex document `_id`, not an Auth0 `user_id`. Complete JSON schema example:
   ~~~json
   {
     "users": { "admin_user": "id_abc123", "viewer_user": "id_def456" },
     "organizations": { "acme_corp": "org_xyz789" }
   }
   ~~~

When done, message the lead with: entities created, user accounts per tier. always include the full ID map in your completion message as a JSON block, even if `.seed-ids.json` was written successfully. This is the lead's validation reference AND fallback data source. Example format: `{"users": {"admin": "id_abc"}, "organizations": {"acme": "org_xyz"}}`.
~~~

#### Teammate 2: "feature-data-seeder"
**Scope**: Feature-specific data (the main content entities of each feature)

**Blocked by**: Teammate 1 completion (needs user IDs to create owned content).

~~~
You are generating seed data for all feature-specific entities.

Read CLAUDE.md first. Then read ./seed/README.md for the seed data plan — it contains the idempotency approach decided by the lead (upsert, deterministic keys, or seed:reset). Your seed functions must follow the same approach. Do not invent a different idempotency strategy.
Check `./plancasting/tech-stack.md` for the `Session Language` setting. Write all reports and README content in that language.
Read `./plancasting/_audits/implementation-completeness/report.md` — skip generating seed data for features marked as incomplete (Category C).
Read your schema file (e.g., `./convex/schema.ts`) for the complete data model.
Read ./plancasting/prd/04-epics-and-user-stories.md for feature understanding.
Read ./plancasting/prd/06-user-flows.md for realistic usage scenarios.

Read the shared ID file at `./seed/.seed-ids.json` which Teammate 1 writes upon completion. This file contains all created entity IDs needed for dependent data.
If `./plancasting/_audits/security/report.md` exists (Stage 6A output), check for rate limiting on data-creation endpoints that may affect seed script batch operations.

Your tasks:
1. Create `./seed/features.ts` — seed data for EVERY feature-specific table in the schema.

2. For each feature domain, generate data that:
   - Covers the happy path of every user flow in the PRD.
   - Includes various states (e.g., tasks in draft/active/completed/archived).
   - Shows realistic content (not "Test Item 1", "Test Item 2" — use plausible titles, descriptions, and content).
   - Respects all business rules and validation constraints from the BRD.
   - Creates proper relationships between entities (foreign key references via backend IDs, e.g., Convex IDs).
   - Includes timestamps that tell a realistic story (created over days/weeks, not all at the same millisecond).

3. Generate data in three tiers:
   - `seedFeaturesDev()`: Minimal (3–5 items per feature per user)
   - `seedFeaturesTest()`: Moderate (20–50 items per feature, enough to trigger pagination)
   - `seedFeaturesDemo()`: Curated (hand-crafted scenarios that showcase each feature's value)

4. Demo data must include:
   - A completed end-to-end scenario for the primary user flow (e.g., a project with tasks at various stages, comments, attachments — whatever the product's core workflow is).
   - Data that makes dashboards and analytics views look compelling (not empty or sparse).
   - Cross-feature data (e.g., items that appear in search results, dashboard aggregations, reports).

Include 2-3 soft-deleted items per feature (set the soft-delete field from the lead's Phase 1 analysis to a timestamp 7-30 days ago) to verify that feature-level queries also filter deleted records.

When done, message the lead with: entities created per feature, items per tier, any business rules that constrained data generation.
~~~

#### Teammate 3: "edge-case-seeder"
**Scope**: Edge case data, stress test data, and data quality scenarios

**Blocked by**: Teammate 1 completion (needs user IDs).

~~~
You are generating edge case and stress test seed data.

Read CLAUDE.md first. Then read ./seed/README.md for the seed data plan — it contains the idempotency approach decided by the lead. Your seed functions must follow the same approach. Do not invent a different idempotency strategy.
Check `./plancasting/tech-stack.md` for the `Session Language` setting. Write all reports and README content in that language.
Read `./plancasting/_audits/implementation-completeness/report.md` — skip generating seed data for features marked as incomplete (Category C).
Read your schema file (e.g., `./convex/schema.ts`) for field types and constraints.
Read ./plancasting/brd/14-business-rules-and-logic.md for validation rules.

Read the shared ID file at `./seed/.seed-ids.json` which Teammate 1 writes upon completion. This file contains all created entity IDs needed for dependent data.
If `./plancasting/_audits/security/report.md` exists (Stage 6A output), check for rate limiting on data-creation endpoints that may affect seed script batch operations.

Your tasks:
1. Create `./seed/edge-cases.ts` — seed data designed to test boundaries and edge cases.

2. For each table in the schema, generate edge case records:
   - **Empty/minimal**: Records with only required fields, all optional fields omitted.
   - **Maximum**: Records with all string fields at maximum length, all arrays at maximum size.
   - **Special characters**: Records with Unicode, emoji, RTL text, HTML entities, SQL injection strings (as data, not as attacks), newlines, and tabs in text fields.
   - **Boundary values**: Numbers at min/max, dates at epoch/far-future, zero-length arrays.
   - **State edge cases**: Records in every possible state combination.
   - **Soft-deleted edge cases**: Soft-deleted records with max-length names and special characters to verify filters handle deleted items correctly.

3. Create `./seed/stress.ts` — high-volume data for performance testing:
   - `seedStress()`: Generate large volumes (500–1,000 records per major table). Adjust volume based on backend rate limits from tech-stack.md. For rate-limited backends, use batch operations or internal/admin functions that bypass rate limiting but still validate schema constraints. Use batch sizes of 10–50 records per call, adjusted to backend rate limits. Check `plancasting/tech-stack.md` for the backend's documented rate limits.
   - Use realistic distributions (e.g., 80% of items owned by 20% of users for stress data; even spread across personas for demo data).
   - Include realistic timestamp distributions (not all created at the same time).
   - This data tests pagination, search performance, and rendering with large lists.

4. Create `./seed/empty-state.ts`:
   - `seedEmptyState()`: Create users with NO associated data.
   - This verifies empty state UIs work correctly across all features.

When done, message the lead with: edge case records created, stress volume per table, empty state users created.
~~~

### Unfixable Violation Protocol

If a seed data issue cannot be resolved without schema changes or architectural modifications beyond this stage's scope:
1. Document the constraint in `./plancasting/_audits/seed-data/unfixable-violations.md` with: issue description, root cause, affected entity types, and recommended resolution.
2. Continue with remaining seed data generation — do not block the entire stage on one constraint.
3. Reference the unfixable violations file in the final report under a "Seed Data Constraints" section.

### Phase 3: Coordination During Execution

While teammates are working:
1. Monitor progress via the shared task list.
2. Ensure Teammate 2 and 3 both receive Teammate 1's user/org IDs.
3. Resolve any schema constraint issues (e.g., a teammate discovers a unique constraint that prevents their planned data).

### Synchronization Protocol

IDs are shared via `./seed/.seed-ids.json`. Teammate 1 writes it after creating base entities. Lead validates it before spawning Teammates 2/3. Only Teammate 1 writes to this file. Teammates 2 and 3 read it but do not modify it — they run in parallel and must not create write conflicts. If Teammates 2 and 3 need to reference each other's entities, they should create their own entities independently rather than sharing IDs. Each teammate's seed functions should be self-contained within their dependency on Teammate 1's core entities.

1. **Lead responsibility**: After Teammate 1 completes, the lead must validate `.seed-ids.json`.
   **Timeline**: (1) Teammate 1 creates all core entities, (2) Teammate 1 writes `./seed/.seed-ids.json` with complete ID map, (3) Teammate 1 reports completion with entity summary, (4) Lead validates `.seed-ids.json` exists and contains valid JSON, (5) Lead spawns Teammates 2 and 3. If validation fails, re-instruct Teammate 1 to fix.
   Validation checks:
   - File exists at `./seed/.seed-ids.json`
   - Parses as valid JSON
   - Contains expected top-level keys: `users`, `organizations`, and any other core entity types from the schema
   - Each key maps to an object of `{ label: id }` pairs (not empty)
   IDs in `.seed-ids.json` must be the database IDs (used for foreign keys), not auth-provider IDs. If the auth provider returns a separate ID, map it to the database ID before storing.
   If ANY check fails, do not spawn Teammates 2/3 — re-spawn Teammate 1 with explicit instructions to fix the file.
2. **Fallback**: If `.seed-ids.json` doesn't exist after Teammate 1 reports completion, the lead extracts IDs from Teammate 1's completion message and writes the file manually following the JSON schema example in Teammate 1's instructions.
3. **Error handling**: If Teammates 2 or 3 report "seed IDs not found," the lead pauses them, verifies the file path and contents, and re-spawns with explicit ID context in the prompt.

### Phase 4: Integration & Seed Script

After all teammates complete:

1. Create `./seed/index.ts` — master seed script that orchestrates all seed functions:
   ~~~typescript
   // Usage (adapt commands to your backend runner, e.g., `bunx convex run` for Convex):
   // seed:dev      — minimal data for development
   // seed:test     — moderate data for testing
   // seed:demo     — curated data for demonstrations
   // seed:stress   — high-volume for performance testing
   // seed:empty    — empty state verification
   // seed:reset    — clear all data and re-seed
   ~~~

2. Create `./seed/reset.ts` — function to clear all tables (for re-seeding):
   - Delete all documents from all tables.
   - Use with caution — include a confirmation parameter.
   - Include a production safety check: verify the environment is not production before executing reset (check `CONVEX_DEPLOYMENT`, `NODE_ENV`, or equivalent env var). Abort with an error message if production is detected.

3. Add seed commands to `package.json` (adapt to your backend runner):
   ~~~json
   "seed:dev": "[your-backend-runner] seed:dev",
   "seed:test": "[your-backend-runner] seed:test",
   "seed:demo": "[your-backend-runner] seed:demo",
   "seed:stress": "[your-backend-runner] seed:stress",
   "seed:empty": "[your-backend-runner] seed:empty",
   "seed:verify": "[your-backend-runner] seed:verify",
   "seed:reset": "[your-backend-runner] seed:reset"
   ~~~
   Replace `[your-backend-runner]` with the actual command from your tech stack. Examples: Convex: `bunx convex run seed:dev`, Supabase: `npx supabase functions invoke seed-dev`, Custom API: `bun run scripts/seed.ts --tier dev`.

4. Test each seed tier (adapt commands to your backend runner, e.g., `bunx convex run` for Convex):
   ~~~bash
   # Run each seed tier via your backend's function runner (adapt to your package manager)
   bun run seed:dev
   bun run seed:test
   bun run seed:demo
   ~~~
   Reset the database between tiers if testing in isolation (e.g., `bun run seed:reset` or re-initialize the dev database). If tiers are designed to be additive (dev → test → demo), run sequentially without reset and document this behavior.
   Verify no schema validation errors.

5. Run the full verification suite to verify seed scripts don't introduce regressions:
   ~~~bash
   bun run typecheck
   bun run lint
   bun run build
   bun run test
   ~~~

6. Run the E2E test suite against the test seed data (if E2E tests exist and test credentials are configured — skip if auth provider user creation was deferred to manual setup):
   ~~~bash
   bun run test:e2e
   ~~~

7. **Data Integrity Verification** — Implement integrity verification as a TypeScript script (`./seed/verify-integrity.ts`) that: (a) for each table with foreign keys, queries for records whose referenced ID does not exist in the parent table, (b) for each table with `deletedAt`, runs the standard query and verifies soft-deleted records are excluded, (c) outputs pass/fail per check. Add a `seed:verify` command to `package.json`. The script should check:
   - Referential integrity — every foreign key (e.g., `projectId` in a task) points to an existing record
   - No orphaned records — no records that reference deleted or non-existent parent entities
   - Soft-delete filtering — queries that filter `deletedAt === null` correctly exclude soft-deleted seed records
   - Enum/status values — all status fields contain valid enum values per the schema

   Output: JSON `{ "referential_integrity": true/false, "soft_delete_filtering": true/false, "enum_values": true/false, "summary": "All checks pass" }`. Gate: FAIL if any check returns false.

### Integrity Check Failure Recovery

If integrity checks fail:
- **Minor constraint violation** (e.g., optional field missing): Document as known limitation in seed data README. Proceed.
- **Referential integrity failure** (e.g., foreign key points to non-existent record): Run the seed reset command and re-execute the failing teammate's seed script. If it fails again, escalate to lead for manual fix.
- **Schema mismatch** (e.g., seed script uses field names that don't exist in schema): Schema mismatch is a BLOCKING issue. The lead must: (1) pause all teammates, (2) verify the schema against current codebase, (3) check if Stage 6E (Code Refactoring) changed the schema since Stage 3, (4) update the seed script to match the current schema OR revert schema changes if they were unintended. Once the schema is fixed, re-spawn affected teammates.

8. Run `bun run seed:verify` against the test-tier seed data and verify all referential integrity checks pass. If any checks fail, fix the seed data generation logic before proceeding to the Gate Decision.

9. Update `./seed/README.md` with final documentation:
   - How to run each seed tier
   - Persona user credentials for demo/testing
   - Data volume per tier
   - How to reset and re-seed

10. **Generate `./plancasting/_audits/seed-data/report.md`** containing:
   - Data volume summary per tier (dev, test, demo)
   - Persona accounts created with credentials
   - Integrity verification results
   - Edge cases covered
   - Any constraints or manual steps required

11. **Gate Decision**: Determine the seed data outcome and include in the report under a `## Gate Decision` heading (this standard heading format enables 6H to parse all audit reports consistently):
   - **PASS**: All seed tiers generated successfully, referential integrity verified, seed data renders correctly in UI
   - **CONDITIONAL PASS**: Seed data generated with documented constraints (e.g., auth provider users require manual creation, or deferred features have no seed data). Note: if auth-dependent seed users cannot be used for E2E testing, document alternative test credentials (document in `e2e/constants.ts` for E2E tests and `seed/MANUAL_SETUP.md` for manual setup steps).
   - **FAIL**: Schema mismatches, missing core entities, or referential integrity failures prevent usable seed data. If blocking constraints exist that prevent seed data generation entirely, document in `./plancasting/_audits/seed-data/unfixable-violations.md` (see Unfixable Violation Protocol above).

12. Output summary: total records per tier, persona accounts created, edge cases covered.

### Phase 5: Shutdown

1. Commit all changes: `git add -A && git commit -m 'feat(seed): Stage 6F seed data generation'` per CLAUDE.md git conventions.
2. Request shutdown for all teammates.
3. Verify all file modifications are saved.

## Critical Rules

1. never use real personal data (real emails, real names) in seed data.
2. never bypass schema validators — all seed data must go through your backend's mutation functions (e.g., Convex mutations). If mutations require authentication context, create an internal/admin-level seed function that bypasses auth checks but still validates schema constraints. Check Stage 6A security audit for any recently added auth requirements.
3. never hardcode document IDs — always use the IDs returned from insert operations.
4. Seed scripts must be idempotent (upsert logic preferred). **Upsert implementation**: Use a natural unique key per entity (e.g., email for users, slug for projects) to check existence before inserting. If no natural unique key exists, use a deterministic seed ID (e.g., `seed-user-admin-01`) stored alongside the record. If upsert is not feasible for the backend (e.g., no native upsert support and no natural unique key), provide a `seed:reset` command and document that it must be run before re-seeding. Document the chosen approach in `seed/README.md`.
5. always include some soft-deleted records to verify query filtering.
6. always verify seed data renders correctly in the UI, not just that it inserts without errors. After seeding, start the dev server and navigate key screens to verify: lists display items without truncation or crashes, edge case data (long strings, special characters) renders without layout breaks, and soft-deleted records are correctly hidden.
7. always include realistic timestamps (not all identical) with proper chronological ordering.
8. Demo data dates should be relative to "now" so demos always look current. Calculate timestamps at runtime in the seed function, not hardcoded values. Example: instead of `created: new Date('2024-01-15')`, use `created: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)` for 30 days ago. Avoid hardcoded dates like `2024-01-15` that will look stale.
9. Use the commands from CLAUDE.md for testing (e.g., `bun run test`).
10. If the auth provider requires API calls to create users (e.g., WorkOS, Clerk), document this as a manual step or implement it in the seed script.
11. If seed data generation encounters a schema constraint that prevents realistic data creation (e.g., circular foreign key dependencies, missing required fields with no default, auth provider limitations), document the constraint in `./plancasting/_audits/seed-data/report.md` under a "Seed Data Constraints" section. Provide a workaround (e.g., manual setup steps in `seed/MANUAL_SETUP.md`) and continue with the remaining seed data.
12. Verify the schema's soft-delete field name early in Phase 1 (common names: `deletedAt`, `deleted_at`, `isDeleted`, `deletionTimestamp`). Use the actual field name consistently across all teammate instructions. If no soft-delete field exists in the schema, skip soft-deleted record generation for that entity (do not assume a `deletedAt` field — adding it would alter the schema).
13. never hard-code API keys, secrets, or real credentials in seed scripts. Use environment variables or placeholder values (e.g., `test-api-key-seed-001`). Seed scripts may be committed to version control.
14. If Stage 6A has added rate limiting (check `./plancasting/_audits/security/report.md`), seed scripts must either: (a) use internal/admin-level functions that bypass rate limiting while still validating schema constraints, or (b) add delays between batch operations to stay within rate limits. This is especially critical for stress-tier data (500+ records). Note: Stage 6G runs AFTER 6F per pipeline ordering, so 6G rate limiting is not yet in effect. If 6G later adds rate limiting on endpoints used by seed scripts, re-run seed scripts with appropriate delays.
````
