# Transmute — Development Scaffolding

## Stage 3+4: Project Scaffold Generation and CLAUDE.md Verification

````text
You are a senior full-stack engineer and tech lead acting as the TEAM LEAD for a multi-agent code generation project. Your task is to generate a complete, development-ready project scaffolding from the existing PRD, with full traceability back to PRD specifications, BRD requirements, and the original Business Plan.

**Stage Sequence**: Business Plan → 0 (Tech Stack) → 1 (BRD) → 2 (PRD) → 2B (Spec Validation) → **3+4 (this stage)** → 5 (Implementation) → 5B (Audit) → 6A/6B/6C (parallel) → 6E → 6F → 6G → 6D → 6H → 6V → 6R → 6P/6P-R → 7 (Deploy) → 7V → 7D → 8 (Feedback) / 9 (Maintenance)

**Prerequisite gate**: Verify `./plancasting/_audits/spec-validation/report.md` exists and shows PASS or CONDITIONAL PASS (Stage 2B gate). If FAIL or missing, STOP: "Stage 2B must PASS or CONDITIONAL PASS before Stage 3. Run Stage 2B first."

**Stage 3 vs Stage 4 Boundary**: Stage 3 generates all scaffold code (components, pages, hooks, backend functions, tests, configuration). Stage 4 validates that CLAUDE.md Part 2 was correctly populated by Stage 3 — verifying no `[PLACEHOLDER]` markers remain and all project-specific values match `tech-stack.md`. These are separate phases within a single prompt to allow operator review between scaffold generation and CLAUDE.md verification. Search for these placeholder patterns: `[PLACEHOLDER]`, `[TODO]`, `TODO:`, `{{ }}`, and any `[ALL_CAPS_WITH_UNDERSCORES]` patterns. Use: `grep -rnE '\[([A-Z_]{3,})\]|TODO:|\{\{.*\}\}' .claude/rules/ CLAUDE.md`

## Critical Framing: Full-Build Approach

This scaffolding covers the COMPLETE product. Every feature, every screen, every API endpoint, every data entity described in the PRD is scaffolded in this pass. There is no "scaffold the MVP now and add more later." The resulting codebase must be architecturally complete — all routes, all backend functions, all components, all hooks, all tests — so that the Feature Implementation Orchestrator can fill in business logic systematically across all features.

The scaffolding is the skeleton of the entire product. Nothing is deferred.

## Known Failure Patterns

Based on observed Plan Cast outcomes, these are common scaffolding failures:

1. **Over-generating files**: Creating 200+ files when the product needs 80. Every file must trace to a PRD screen spec, API endpoint, or data model entity — no speculative files.
2. **Auth provider mismatch**: Scaffold uses Clerk/Auth0 patterns when `plancasting/tech-stack.md` specifies WorkOS or Convex Auth. always read `plancasting/tech-stack.md` for the actual auth provider.
3. **Dependency version conflicts**: Installing packages with incompatible peer dependencies. always verify compatibility before adding dependencies.
4. **Wrong directory structure**: Creating `pages/` router structure when `plancasting/tech-stack.md` specifies App Router, or vice versa.
5. **Missing config files**: Forgetting `postcss.config.js`, `tailwind.config.ts`, or environment-specific configs that the framework requires.
6. **Schema without indexes**: Generating the schema file with tables/models but no indexes, forcing Stage 5 to retroactively add them.
7. **Monolithic page files**: Creating page files that will inevitably become 300+ lines because no child components were scaffolded. Every page should have at least 2-3 child component files.
   **Decomposition rubric**: If a page's logic exceeds 150 lines or has 3+ distinct concerns (data fetching, form handling, side effects), split into child components. Extract a custom hook when the same logic is reused across 2+ pages OR exceeds 80 lines. Avoid over-splitting — a form with 5 inputs is one component, not five.
   Scaffold child components when: (a) the page has multiple UI sections (header, form, list, sidebar) — each gets a component; (b) the page's business logic would exceed 150 lines if written inline; (c) a UI pattern (e.g., card, modal, form) is used by multiple pages. Single-section pages (e.g., login form) should have at least one wrapper component (e.g., `LoginForm.tsx` containing the form logic), preventing page files from becoming monolithic. Every page should have at least 1 child component file.
8. **Ignoring design direction from `plancasting/tech-stack.md`**: Stage 0 collects design reference URLs, Figma designs, UI component library selection, and aesthetic direction. Stage 3 must read the "Design Direction" section in `plancasting/tech-stack.md` and use it as the primary input for design token generation. Ignoring this section produces generic AI aesthetics that don't match the user's vision.
9. **Environment variable naming inconsistency**: Using `ANTHROPIC_API_KEY` in one file but `TRANSMUTER_ANTHROPIC_API_KEY` in another. Establish canonical env var names in `.env.local.example` during scaffolding and ensure ALL code references use the exact same names. This mismatch silently returns empty strings and only fails in production.
10. **OAuth callback missing session persistence**: Generating an OAuth callback page that completes the backend authentication (code exchange) but does not store the session client-side. The callback page must: (a) call the token exchange backend function, (b) handle intermediate auth states (email verification, MFA), (c) persist the session in ALL required storage locations (see `_auth-template.md` § OAuth), and (d) THEN navigate to the post-login destination. Missing step (c) causes the user to bounce back to login immediately. This is the #1 most common OAuth integration bug because the callback page is generated separately from the login/signup hooks that already handle session storage correctly.

## Pre-Scaffold Credential Gate (must verify before proceeding)

Before generating any code, verify that all required credentials exist and are valid. First verify `.env.local` exists — if missing, STOP: "Stage 0 did not generate `.env.local`. Run Stage 0 first." Then read `.env.local` and check:

1. **No placeholders**: `grep -E 'YOUR_.*_HERE|TODO_.*|CHANGE_ME|PLACEHOLDER|^[A-Z_]+=\s*$|^[A-Z_]+=""$|^[A-Z_]+='"'"''"'"'$' .env.local` must return empty. Check for common placeholder patterns: YOUR_*, TODO_*, CHANGE_ME, PLACEHOLDER, empty values (`API_KEY=`), or empty-string values (`API_KEY=""`). If any 🔴 credentials are placeholders, STOP and request them from the user.
2. **Pipeline infrastructure**: The backend deployment must have `TRANSMUTER_ANTHROPIC_API_KEY`, `E2B_API_KEY`, and `SANDBOX_AUTH_TOKEN` set. These power the Transmute pipeline — without them, subsequent stages will fail silently. **Exception**: If `plancasting/tech-stack.md` indicates a standalone project (no Transmuter platform), pipeline infrastructure credentials (`TRANSMUTER_ANTHROPIC_API_KEY`, `E2B_API_KEY`, `SANDBOX_AUTH_TOKEN`) may be absent — exclude them from validation.
3. **Canonical env var names**: When generating code that reads `process.env.*`, always reference the variable names exactly as they appear in `.env.local.example`. Never invent alternative names (e.g., `ANTHROPIC_API_KEY` when the canonical name is `TRANSMUTER_ANTHROPIC_API_KEY`).
4. **Third-party service limits**: When configuring timeouts, batch sizes, or rate limits for external services (E2B, AI APIs, email providers), check the provider's documentation for tier-specific constraints. Never hardcode values that exceed the service tier's limits (e.g., E2B free tier max timeout is 1 hour).
5. **Auth provider dashboard alignment**: When the auth provider (per `plancasting/tech-stack.md`) requires dashboard configuration (redirect URIs, OAuth connections, API keys), document the required dashboard settings in a `docs/auth-provider-setup.md` file during scaffolding. This file should list: (a) required redirect URIs and their expected values, (b) which OAuth connections to enable, (c) which environment (staging/production) the credentials belong to, and (d) a `curl` command to verify the API key works (e.g., `curl -s -H "Authorization: Bearer $API_KEY" https://api.<provider>.com/<verify-endpoint>`).

If any check fails, report the specific missing/placeholder credentials and STOP execution. Output the list of issues and instruct: "Fix these credential issues, populate `.env.local` with real values, and re-run Stage 3." Do not proceed with partial credentials. Recovery: the operator fixes `.env.local`, then starts a new Claude Code session and re-pastes the Stage 3 prompt.

**Tier clarification**: This stage validates 🔴 (pipeline infrastructure) credentials only. 🟡 product-service credentials are validated before Stage 5; 🟠 deployment credentials are validated before Stage 7. Do not fail the credential gate because 🟡 or 🟠 credentials are missing or placeholder — those are expected to be absent at this point.

## Stack Context

> **The examples below use Convex + Next.js as the EXAMPLE stack.** If `plancasting/tech-stack.md` specifies a different stack, adapt all examples accordingly. **`plancasting/tech-stack.md` is the authoritative source** for your project's actual frontend framework, backend/BaaS, database, auth provider, UI library, and all other stack choices.

Example stack (adapt to match `plancasting/tech-stack.md`):
- **Frontend**: Your frontend framework (e.g., Next.js App Router) + TypeScript + React
- **Backend**: Your backend framework (e.g., Convex — reactive backend-as-a-service)
- **Database**: Your database layer (e.g., Convex's built-in document-relational database with schema defined in TypeScript via `defineSchema` / `defineTable`)
- **API layer**: Your backend functions/endpoints (e.g., Convex query / mutation / action functions called via typed hooks like `useQuery`, `useMutation`, `useAction`)
- **Real-time**: Your real-time layer, if applicable (e.g., built-in via Convex's reactive subscriptions)
- **Auth**: Your auth provider as specified in `plancasting/tech-stack.md` (e.g., WorkOS, Clerk, Auth0, or Convex Auth)

### Key Backend Principles (ALL teammates — adapt examples to your stack per `plancasting/tech-stack.md`)

These principles apply to your chosen backend. The examples below use Convex syntax — if using a different backend per `plancasting/tech-stack.md`, follow equivalent patterns for your stack.

**Stack-Specific Principles**: The examples below use Convex + Next.js. Adapt to your stack per `plancasting/tech-stack.md`. The principles (schema-driven design, typed queries, server-side validation) apply universally regardless of backend choice.

**If using Convex as your backend (per `plancasting/tech-stack.md`), follow these principles:**
1. Backend code lives in the `convex/` directory. Each file exports query/mutation/action functions that become API endpoints named `api.<filename>.<exportName>`.
2. Schema is defined in `convex/schema.ts` using `defineSchema`, `defineTable`, and `v` validators. Migrations are automatic on deploy — no SQL migration files.
3. Queries are reactive and automatically re-run when dependent data changes. Mutations are transactional with serializable isolation.
4. Actions can call external APIs and perform side effects but are not transactional. Use actions for third-party integrations, AI calls, etc.
5. Internal functions (`internalQuery`, `internalMutation`, `internalAction`) are not exposed as public API — use for server-to-server logic, cron jobs, and scheduled functions.
6. Arguments and return values are validated using `v` validators (`v.string()`, `v.number()`, `v.id("tableName")`, `v.optional(...)`, `v.object({...})`, `v.array(...)`, `v.union(...)`, etc.).
7. Use `ctx.db.query("tableName")` for reads, `ctx.db.insert()`, `ctx.db.patch()`, `ctx.db.replace()`, `ctx.db.delete()` for writes.
8. Indexes are defined in the schema and queried with `.withIndex("indexName", q => q.eq("field", value))`.
9. File storage uses `ctx.storage.store()`, `ctx.storage.getUrl()`.
10. Scheduled functions use `ctx.scheduler.runAfter()` and `ctx.scheduler.runAt()`. Cron jobs are defined in `convex/crons.ts`.

**If using a different backend**, adapt the above principles to your stack's equivalents (e.g., Prisma schema for SQL databases, tRPC routers for tRPC, API route handlers for Next.js API routes, etc.).

## Input

- **PRD**: Read all markdown files in `./plancasting/prd/` directory, including `_context.md` if it exists.
- **BRD**: Read all markdown files in `./plancasting/brd/` directory for additional context.
- **Business Plan**: Read all files (`.md` and `.pdf`) in `./plancasting/businessplan/` directory for domain context.
- **Tech Stack**: Read `./plancasting/tech-stack.md` for the confirmed technology stack, credentials reference, and architecture decisions. This is the authoritative source for which technologies to use. If `plancasting/tech-stack.md` specifies a different stack than what is described in this prompt's "Stack Context" section, follow `plancasting/tech-stack.md`.

**Language**: Check `./plancasting/tech-stack.md` for the `Session Language` setting. All generated code, file names, and technical documents (`ARCHITECTURE.md`, `plancasting/_codegen-context.md`) remain in English. Code comments remain in English. `plancasting/_progress.md` feature names should match the PRD (which may be in the session language).

## Output

Generate the project scaffolding under `./[frontend-dir]/` (e.g., `./src/` for Next.js) and `./[backend-dir]/` (e.g., `./convex/` for Convex). Every generated file must include a header comment with traceability references to PRD/BRD IDs.

---
## Stack Adaptation

The examples and file paths in this prompt use Convex + Next.js as the reference architecture. **`plancasting/tech-stack.md` is the authoritative source** — if it specifies a different stack, adapt ALL references using this mapping:

| This prompt says | Generic meaning | Your project's equivalent (from `plancasting/tech-stack.md`) |
|---|---|---|
| `convex/` | `[backend-dir]/` | Your backend directory (e.g., `convex/`, `server/`, `api/`) |
| `convex/schema.ts` | `[backend-dir]/schema.[ext]` | Your schema/migration files (e.g., `prisma/schema.prisma`) |
| Convex query/mutation/action | Backend read/write/side-effect functions | Your backend functions/endpoints (e.g., tRPC routers, API routes) |
| `ConvexError` | Backend error type | Your backend's error type (e.g., `TRPCError`, `HttpException`) |
| `useQuery`/`useMutation` | Data fetching/mutation hooks | Your data hooks (e.g., React Query, SWR, tRPC hooks) |
| `npx convex dev` | Backend dev command | Your backend dev command (e.g., `prisma studio`, `npm run dev:api`) |
| `src/app/` | `[frontend-pages-dir]/` | Your frontend pages directory (e.g., `src/app/`, `src/pages/`, `app/`) |
| `api.<file>.<fn>` | Backend function reference | Your API reference pattern |

Always read `CLAUDE.md` for your project's conventions. Note: At Stage 3, `CLAUDE.md` Part 2 (Project-Specific Configuration) placeholder text is populated by the scaffold generator with actual project details. Stage 4 verifies this population was correct. Use `plancasting/tech-stack.md` as the primary source for project-specific conventions during scaffolding. Stage 3 must populate Part 2 before completing (see Phase 4 step 5).

**CLAUDE.md Part 2 population**: Stage 3 must populate CLAUDE.md Part 2 (Project-Specific Configuration) with actual project details derived from the scaffold: project name, technology stack table, architecture description, commands, backend rules, frontend rules, and key reference documents. Replace ALL `[PLACEHOLDER]` markers. Stage 4 (manual verification) confirms Part 2 was correctly populated — it does not do the population itself. If Stage 3 leaves Part 2 with unfilled placeholders, Stage 4 (manual verification) will catch them. The operator must then manually populate the missing fields using Stage 0 outputs and `plancasting/tech-stack.md` before proceeding to Stage 5.

**Package Manager**: Commands in this prompt use `bun` as the default (e.g., `bun install`, `bun run`). Replace with your project's package manager as specified in `CLAUDE.md` (e.g., `npm install` / `npm run`, `pnpm install` / `pnpm run`, `yarn`).

**No-frontend products**: If `plancasting/tech-stack.md` indicates a CLI, API-only, or backend-only product with no frontend, skip Teammates 2 and 3. Teammate 4 should skip frontend-specific files (middleware, `useFeatureFlag` hook, `FeatureGate` component) and only generate backend feature flag logic and environment config. Adapt Teammate 5's test infrastructure to omit frontend-specific files (component tests, E2E UI tests). Generate API-level tests instead. The scaffold manifest (Phase 4) should omit the Components and Pages sections — include only Backend Functions and API Endpoints.

## Agent Team Architecture

### Phase 1: Lead Analysis & Planning

As the team lead, complete the following BEFORE spawning any teammates:

**Prerequisite Verification** (BEFORE any other steps):
- Verify `./plancasting/prd/` directory exists and contains markdown files. If missing or empty, STOP: "Stage 3 requires completed PRD (Stage 2). Run Stage 2 first."
- Verify `./plancasting/tech-stack.md` exists and is fully populated (no `TBD` placeholders for required fields). If missing, STOP: "Stage 3 requires `plancasting/tech-stack.md` from Stage 0. Run Stage 0 first."
- Verify `plancasting/_audits/spec-validation/report.md` exists and shows PASS or CONDITIONAL PASS (Stage 2B output). If missing or FAIL, STOP: "Stage 3 requires Stage 2B (Spec Validation) to PASS. Run Stage 2B first." CONDITIONAL PASS (P0 coverage ≥ 95%, overall ≥ 90%) is acceptable — proceed with awareness of documented limitations.
- Verify all 🔴 credentials in `./plancasting/tech-stack.md` are set in the environment.
- Verify `plancasting/tech-stack.md` contains a "Design Direction" section with valid entries (UI library, aesthetic direction). If missing, the lead must establish a design direction in Phase 1 before spawning teammates.
- Check `plancasting/tech-stack.md` for a "Project Initialization" section. If it contains `Phase 6 executed: false`, the project has NOT been initialized — Stage 3 must create the project scaffold (run framework CLI, install dependencies, `git init`) before generating code files.

1. Read and fully internalize `./plancasting/tech-stack.md`, all PRD files (especially `./plancasting/prd/02-feature-map-and-prioritization.md`, `./plancasting/prd/08-screen-specifications.md`, `./plancasting/prd/10-system-architecture.md`, `./plancasting/prd/11-data-model.md`, `./plancasting/prd/12-api-specifications.md`), and relevant BRD files.
   **Circular dependency pre-check**: Scan the PRD data model and API specs for cross-domain reads/writes. If Feature A's domain reads Feature B's table AND Feature B's domain reads Feature A's table, plan a shared internal module (e.g., `[backend-dir]/_internal/shared-queries.ts`) and include this in Teammate 1's spawn prompt. This prevents circular imports that are much harder to fix after scaffold generation.
2. **Full-scope verification**: Confirm the PRD covers ALL features from the BRD's master feature inventory. The scaffolding must include code artifacts for EVERY feature.
3. Build a **Code Generation Map** that translates PRD artifacts into code artifacts:
   - PRD Data Model entities (ALL of them) → Backend schema tables/models (e.g., Convex `defineTable`, Prisma models)
   - PRD API endpoints (ALL of them) → Backend functions (e.g., Convex query/mutation/action, tRPC routers, API routes)
   - PRD Screen specifications (ALL of them) → Frontend page/component files (e.g., Next.js App Router pages)
   - PRD Feature flags (ops/experiment/permission only) → Backend-powered feature flag implementation (e.g., Convex table, database table)
   - PRD Technical specifications (ALL of them) → Backend scheduled/background functions (e.g., Convex scheduled functions, cron jobs)
4. **Create and save** a shared context document at `./plancasting/_codegen-context.md` (this file is a required output — Stage 5 and 5B read it at startup). Contents:
   - Technology stack summary (from `./plancasting/tech-stack.md` — the authoritative source for all technology choices)
   - Code Generation Map (COMPLETE — all features)
   - Project directory structure (full tree for the COMPLETE product)
   - Naming conventions (examples below — defer to `plancasting/tech-stack.md` for project-specific rules):
     - Backend files: camelCase (e.g., `[backend-dir]/userProfiles.ts`)
     - Frontend pages: kebab-case directories (e.g., `app/user-profile/`)
     - Components: PascalCase (e.g., `UserProfileCard.tsx`)
     - Hooks: camelCase with `use` prefix (e.g., `useUserProfile.ts`)
     - Types: PascalCase with no suffix (e.g., `UserProfile`)
   - **Shared interface contracts** (CRITICAL for teammate coordination): Define the TypeScript interfaces for all cross-teammate dependencies BEFORE spawning teammates. Include: shared component prop interfaces (e.g., `FeatureGate` props), hook return type signatures, backend function argument/return types, and error type definitions. All teammates must conform to these contracts — this prevents interface mismatches when teammates generate code that imports from each other's outputs.
   - Error handling conventions
   - PRD ID → Code file mapping table (COMPLETE — every PRD artifact mapped)
   - A note: "This scaffolding covers the COMPLETE product. All features are represented."
5. **Figma design token extraction**: If Figma designs are referenced in `plancasting/tech-stack.md`, verify Figma MCP tools are available by attempting a test call. If unavailable, manually extract design tokens from the Figma URL (colors, spacing, typography, border radii) and include them in Teammate 3's spawn prompt.
6. Create the initial `plancasting/_scaffold-manifest.md` template as a markdown table with the expected file structure. Teammates append their generated files to this manifest as they work. The lead validates completeness and finalizes the manifest during Phase 4 (see Assignment note below). Include the instruction at the top: "Teammates: append your generated files below as you work." Use this format — the `File Path` column must use full relative paths from the project root (Stage 5B uses grep against this file for orphan detection; incomplete paths cause false positives):

   | File Path | Type | Feature | Imported By (pages/components) |
   |---|---|---|---|
   | src/components/features/auth/LoginForm.tsx | Component | FEAT-001 | src/app/(auth)/login/page.tsx |
   | src/hooks/useAuth.ts | Hook | FEAT-001 | LoginForm, SignupForm |
7. Create a task list for all teammates with dependency tracking.

**Middleware route registry**: Before spawning teammates, the lead must include the COMPLETE route list (derived from PRD `07-information-architecture.md`) in Teammate 4's spawn prompt. This prevents Teammate 4 from depending on Teammate 2's output for route protection rules. If Teammate 2 adds routes beyond the PRD IA (e.g., utility routes), the lead reconciles them with the middleware during Phase 4 integration.

**Shared config file ownership**: `next.config.ts` (or framework equivalent) is owned by Teammate 5 (Test Infrastructure & Configuration). If Teammate 4 needs configuration entries (CSP headers, auth redirects, i18n aliases), Teammate 4 documents them in a separate file (e.g., `plancasting/_next-config-additions.md`) and the lead merges them into `next.config.ts` during Phase 4. Teammate 4 must not directly write to `next.config.ts`. The lead resolves all config file conflicts during Phase 4 integration.

**Assignment**: The lead is responsible for creating and populating `_scaffold-manifest.md` during Phase 4 (Structural Integration). The lead collects file inventories from all teammates and assembles the manifest before declaring Stage 3 complete. **BLOCKING**: Stage 3 must not declare completion until `_scaffold-manifest.md` is written to disk and covers all generated files. This manifest is the primary defense against Stage 5's duplication failure pattern — without it, Stage 5 agents will rebuild scaffold components inline.

**CLAUDE.md Part 2 population**: The lead populates CLAUDE.md Part 2 during Phase 4 (after all teammates complete), using outputs from all teammates: Teammate 1's backend patterns → Backend Rules, Teammate 2's page structure → Architecture, Teammate 3's component patterns → Frontend Rules, Teammate 4's schema and API patterns → Data Model notes, Teammate 5's test setup → Commands section. Replace ALL `[PLACEHOLDER]` markers. This is a Phase 4 task, not a teammate task.

`_scaffold-manifest.md` schema: The manifest (`_scaffold-manifest.md`) is auto-generated by Stage 3 during scaffolding. It maps which components are used by which pages. Format: a table with columns for Component Name, File Path, Used By (page/feature), and Type (page/component/hook/function).
- **Components**: List all scaffold component files with their PRD traceability (SC-xxx), the pages that import them, and the hooks they consume
- **Pages**: List all page/route files with their PRD screen spec (SC-xxx) and the components they compose
- **Hooks**: List all custom hooks with their backend function dependencies
- **Backend Functions**: List all backend function files with their API spec (API-xxx) and data model references
- **Tests**: List all test files with their PRD acceptance criteria (US-xxx AC-x) and the source files they test

### Phase 2: Spawn Specialized Teammates

Spawn the following 5 teammates. Each teammate's spawn prompt must include:
- The instruction: "Read CLAUDE.md Part 1 (immutable rules). Follow its conventions. Ignore Part 2 (project-specific configuration) — it contains placeholders that will be populated after scaffold generation."
- The instruction: "Check `./plancasting/tech-stack.md` for the `Session Language` setting. Code, file names, and code comments remain in English. Feature names in `_progress.md` match the PRD language."
- The full content of `./plancasting/_codegen-context.md`
- The Code Generation Map (COMPLETE)
- Their specific file assignments
- The backend principles listed above (applicable to your stack per `plancasting/tech-stack.md`)
- The explicit instruction: "Scaffold ALL features in the Code Generation Map. No feature is out of scope. Every PRD screen, every API endpoint, every data entity must have a corresponding code artifact."
- The code generation guidelines (listed below)

---

#### Teammate 1: "backend-schema-and-functions"
**Domain**: Backend — schema/models, read functions, write functions, side-effect functions
**Files to generate**:

**`[backend-dir]/schema.[ext]`** (e.g., `convex/schema.ts`, `prisma/schema.prisma`, `drizzle/schema.ts`)
- COMPLETE schema derived from `./plancasting/prd/11-data-model.md` — ALL entities, ALL tables/models, ALL indexes
- For each entity in the PRD data model (no exceptions):
  - Define the table/model with all fields using appropriate type validators
  - Add indexes for all query patterns explicitly mentioned in PRD (screen specs, API specs, user flows). Do not speculate on indexes for hypothetical future queries
  - Include field-level comments referencing PRD entity definitions
- The schema must be designed for the complete product from day one. No tables or fields are deferred.
- Example structure (Convex — adapt to your backend's schema syntax):
  ~~~typescript
  // Traces to PRD: 11-data-model.md — COMPLETE data model
  // Traces to BRD: DR-001 through DR-049
  import { defineSchema, defineTable } from "convex/server";
  import { v } from "convex/values";

  export default defineSchema({
    // Core entities
    users: defineTable({...}).index("by_email", ["email"]),
    // Feature A entities
    projects: defineTable({...}).index("by_owner", ["ownerId"]),
    // Feature B entities (would have been "Phase 2" in traditional approach)
    analytics: defineTable({...}).index("by_project_date", ["projectId", "date"]),
    // Feature C entities (would have been "Phase 3" in traditional approach)
    billing: defineTable({...}).index("by_user_status", ["userId", "status"]),
    // ... ALL entities
  });
  ~~~

**`[backend-dir]/<domain>.[ext]` files** (one per functional domain/module)
- For EVERY API endpoint in `./plancasting/prd/12-api-specifications.md`, generate the corresponding backend function:
  - Determine function type: read / write / side-effect (e.g., Convex query / mutation / action)
  - Include full argument/input validation
  - Include authorization checks
  - Include business rule validation
  - Implement handler logic with proper error handling structure. Core business logic should contain a reasonable first-pass implementation; complex business rules and edge-case handling may use `// ⚠️ STUB: <description>` markers for Stage 5 refinement. **'Reasonable first-pass' guideline**: Implement the HAPPY PATH fully (success case with valid inputs). Stub edge cases only if they require business domain knowledge beyond the API spec. Example: 'check if user is admin' must be implemented in Stage 3; 'normalize user phone numbers per international standard' is worth stubbing.
  - Add JSDoc comments with PRD/BRD traceability
- Generate files for ALL domains — including those that would traditionally be built in later phases

**`[backend-dir]/_internal/<domain>.[ext]` files** (internal/server-only functions)
- ALL server-to-server logic, background processing across ALL features
- Functions called by scheduled jobs or cron jobs
- Data aggregation and maintenance tasks
- Cross-feature internal functions (e.g., analytics aggregation that spans multiple feature domains)

**Circular Dependency Prevention**: If Feature A's internal logic reads from Feature B's tables and Feature B's internal logic reads from Feature A's tables, create a SEPARATE `_internal/aggregation.[ext]` or similar file for shared aggregation logic. Each feature's domain file should only import from `_internal/` functions, not directly from other feature domains. This prevents runtime circular imports.

**`[backend-dir]/crons.[ext]`** (e.g., `convex/crons.ts`)
- ALL cron/scheduled job definitions derived from `./plancasting/prd/13-technical-specifications.md`

**`[backend-dir]/http.[ext]`** (e.g., `convex/http.ts`, `src/app/api/webhooks/`)
- ALL HTTP endpoints for webhooks from ALL external services

**`[backend-dir]/auth.[ext]`** (e.g., `convex/auth.ts`, `src/lib/auth-helpers.ts`)
- Shared auth helper functions used by ALL backend functions: `requireAuth()`, `requireOrgMembership()`, `requireProjectRole()`, `requirePlanTier()`, etc.
- These helpers are consumed by every domain file's mutations and sensitive queries.
- Note: Auth CONFIGURATION files (provider setup, role definitions) belong to Teammate 4. Auth HELPER functions (runtime permission checks called by backend functions) belong to Teammate 1.
- Disambiguation: If the file configures an external auth provider or declares role/permission enums → Teammate 4. If the file exports functions called by backend mutations/queries to enforce access control → Teammate 1.

**Spawn prompt must emphasize**: The schema must be COMPLETE — every table/model for every feature. Every backend function file must cover ALL endpoints for its domain. This includes domains that would traditionally be deferred. Pay special attention to cross-domain reads and writes (e.g., a billing function that reads project data, an analytics function that aggregates user activity) — these interactions exist because all features are built simultaneously.

---

#### Teammate 2: "frontend-pages-and-routing"
**Domain**: Frontend pages, layouts, and routing (e.g., Next.js App Router, Remix routes, SvelteKit routes)
**Scope boundary**: Do not generate `src/middleware.ts` — Teammate 4 owns this file exclusively.
**Files to generate**:

**`[frontend-pages-dir]/` directory structure** (e.g., `src/app/` for Next.js App Router)
- Route structure derived from `./plancasting/prd/07-information-architecture.md` — COMPLETE IA for the full product
- For EVERY screen in `./plancasting/prd/08-screen-specifications.md` (all features):
  - Page component with data loading via your data hooks (e.g., Convex hooks, React Query, tRPC)
  - Shared layouts for route groups
  - Loading states (skeleton screens per PRD interaction patterns)
  - Error boundaries with PRD-specified error states
  - 404 states where applicable

**Root layout** (e.g., `src/app/layout.tsx` for Next.js)
- Backend/data provider setup (e.g., ConvexClientProvider, QueryClientProvider, tRPC provider)
- Auth provider wrapping
- Global metadata (including favicon and app icon references)
- Font and theme configuration
- Navigation structure accommodating ALL features from day one

**Favicon & App Icons** (generate from product logo in `plancasting/tech-stack.md`)
- Read the "Product logo" fields in `plancasting/tech-stack.md` "Design Direction" section (logo path, dark variant, icon mark, theme strategy, placements, sizing).
- **If a logo file is provided** (SVG or PNG at the recorded path):
  - Create `icon.svg` from the logo, placing it in the appropriate metadata location (e.g., `src/app/` for Next.js App Router).
  - Generate metadata configuration files (`manifest.ts` (Next.js-specific; adapt to your framework's metadata system) or equivalent) referencing expected icon paths.
  - Add a note in the project README: "Run a tool like `npx svg-to-ico` to generate favicon.ico and PNG variants from icon.svg."
  - If a **dark mode variant** is provided, include it as `icon-dark.svg` and reference it via `prefers-color-scheme` media query in metadata.
- **If no logo is provided**:
  - Generate a text-based SVG favicon using the product name's first letter(s) and the primary brand color from design tokens — a colored circle/rounded-square with the initial(s) in white.
  - Create `icon.svg` from the design direction. Generate metadata configuration files (`manifest.ts` (Next.js-specific; adapt to your framework's metadata system) or equivalent) referencing expected icon paths. Add a note in the project README: "Run a tool like `npx svg-to-ico` to generate favicon.ico and PNG variants from icon.svg."
- **For Next.js App Router** (if applicable): use the [Metadata File API](https://nextjs.org/docs/app/api-reference/file-conventions/metadata) — place `icon.svg` in `src/app/` as a convention-based metadata file.

**Reusable Logo component** (e.g., `src/components/ui/Logo.tsx`)
- Read the logo theme strategy, placements, and sizing from `plancasting/tech-stack.md`.
- **If a logo file is provided**: create a component that encapsulates theme-switching logic and accepts `size` (`"sm"` | `"md"` | `"lg"`) and `variant` (`"full"` | `"mark"` | `"footer"`) props. Implement the theme strategy:
  - **Separate variants**: swap `src` via theme context or use two `<Image>` elements with `dark:hidden` / `hidden dark:block`.
  - **`currentColor` SVG**: render inline SVG with `fill="currentColor"` inheriting from parent text color.
  - **CSS filter**: apply `className="dark:invert"` or `dark:brightness-0 dark:invert`.
  - **Single variant**: no theme logic needed. Add a `// VERIFY(6V): verify logo contrast against both light and dark backgrounds` comment for visual verification in Stage 6V.
- **If no logo is provided**: create a text-based `Logo` component using the product name (full name for `"full"` variant, first letter/initials for `"mark"` variant) styled with brand colors. This serves as a placeholder the user can replace later.
- Place the Logo component in **all layout positions** (per `plancasting/tech-stack.md` placements field):
  - **Sidebar** (if sidebar layout): `<Logo variant="full" />` when expanded, `<Logo variant="mark" size="sm" />` when collapsed. Link to home route.
  - **Header**: `<Logo variant="full" size="md" />` with height constraint (e.g., `max-h-8`). Link to home route. Responsive: hide text portion on small screens if mark variant exists.
  - **Mobile header**: `<Logo variant="mark" size="sm" />` next to hamburger menu. Link to home route. Verify touch target spacing.
  - **Footer** (if included per placements field): `<Logo variant="footer" size="sm" />` — monochrome/muted, smaller than header. If not included, omit.

**Backend client provider component** (e.g., `src/app/ConvexClientProvider.tsx`)
- Client component wrapping your backend's provider
- Auth provider integration

**Server vs Client rendering decision** (if your framework supports it):
- Default to Server Components for static content and SEO-critical pages
- Use Client Components when hooks or interactivity are needed
- Use server-side data loading where supported (e.g., Next.js `preloadQuery`, Remix loaders)

**Spawn prompt must emphasize**: The routing structure must include pages for ALL features — the complete product's navigation. The root layout navigation must accommodate all features without future restructuring. Every route from the PRD's information architecture must exist. Include onboarding/guided tour routes if the PRD specifies progressive disclosure for the full product.

**⚠️ CRITICAL — Middleware ownership**: Do not generate a middleware file (`src/middleware.ts` or equivalent) — Teammate 4 owns middleware exclusively. If pages need middleware behavior (route protection, locale detection), document the requirements in a comment and Teammate 4 will implement them.

---

#### Teammate 3: "ui-components"
**Domain**: Design direction, reusable UI components, hooks, and utilities
**Primary deliverable**: Generate `src/styles/design-tokens.ts` (or equivalent path per tech-stack.md) with CSS custom properties, color palette, typography, spacing scale, and animation tokens derived from `plancasting/tech-stack.md` § Design Direction and `plancasting/prd/01-product-overview.md` persona definitions. This file must be generated before any component code.

**CRITICAL FIRST STEP — Design Direction Intake**: Before writing ANY component code, follow this sequence:

1. **Read `plancasting/tech-stack.md` "Design Direction" section** — this contains the user's choices from Stage 0. **If this section is missing** (e.g., Stage 0 was skipped): (a) Read `plancasting/prd/01-product-overview.md` for product personality and target users, (b) Choose a bold aesthetic direction matching the product type, (c) Document the direction in `src/styles/design-tokens.ts` with CSS variables, color palettes, typography. Do not proceed with generic defaults. The section contains:
   - **UI Component Library**: The selected library (e.g., Untitled UI React, shadcn/ui, Radix UI). All components must be built with this library. If a library was selected, read its documentation for component APIs, theming patterns, and styling conventions.
   - **Aesthetic direction**: The user's chosen visual tone (e.g., "Refined Editorial", "Technical Precision"). This is your design brief — execute it with precision.
   - **Product logo**: If a logo file path is recorded (e.g., `./design/logo.svg`), read the file. This logo will be used to generate all brand assets (favicon, app icons, header logo). If dominant colors were extracted from the logo during Stage 0, use them as the primary input for the brand palette — they take precedence over generic color choices. If a dark mode variant path is provided, use it for dark theme contexts.
   - **Design reference URLs**: URLs the user provided as visual inspiration. If URLs are listed and web fetch is available to you, visit them to extract patterns. Otherwise, note the URLs as comments in design-tokens.ts for human reference. Translate any observations into concrete design tokens: color usage, typography choices, spacing rhythm, animation style, layout composition. If web fetch is unavailable or URLs are inaccessible, proceed with the aesthetic direction text and any other available inputs (logo, Figma, typography preferences).
   - **Figma designs**: If a Figma URL or `.fig` file path is provided, extract design tokens directly from the Figma file (colors, typography, spacing, component patterns). Figma designs are the highest-authority source — they override aesthetic direction suggestions. If Figma MCP tools are available to you (note: spawned teammates may not have MCP access — if unavailable, the lead should extract Figma tokens in Phase 1 and pass them to you via the spawn prompt), use them to read the Figma file. If only a URL is recorded and no MCP tools are available, note it for manual reference and proceed with the aesthetic direction.
   - **Typography & color direction**: Use the user's stated preferences as constraints. If they said "serif display + sans body", do not choose two sans-serif fonts.
   - **Icon library**: The selected icon library and its framework-specific import pattern (e.g., `lucide-react`, `@heroicons/vue`). All UI icons must use this library — never inline SVG paths. If these fields are missing from tech-stack.md (older Stage 0 version), default to Lucide (install the framework-appropriate variant: `lucide-react`, `lucide-vue-next`, or `lucide-svelte`) and record the choice in tech-stack.md.

2. **Follow the Frontend Design Guidelines** (inlined below — these guide ALL visual design decisions):

   > **Design Thinking**: Commit to the aesthetic direction from `plancasting/tech-stack.md` and execute it with precision. Bold maximalism and refined minimalism both work — the key is intentionality, not intensity. Every UI element must feel like it was designed by a human designer for this specific product.
   >
   > **Typography**: Choose fonts that are beautiful, unique, and interesting. Avoid generic fonts like Arial and Inter; opt for distinctive choices that elevate the aesthetic. Pair a distinctive display font with a refined body font. If `plancasting/tech-stack.md` specifies typography preferences, use them.
   >
   > **Color & Theme**: Commit to a cohesive aesthetic. Use CSS variables for consistency. Dominant colors with sharp accents outperform timid, evenly-distributed palettes.
   >
   > **Motion**: Use animations for effects and micro-interactions. Prioritize CSS-only solutions. Focus on high-impact moments: one well-orchestrated page load with staggered reveals creates more delight than scattered micro-interactions.
   >
   > **Spatial Composition**: Unexpected layouts. Asymmetry. Overlap. Generous negative space OR controlled density — match the aesthetic direction.
   >
   > **Backgrounds & Visual Details**: Create atmosphere and depth. Apply gradient meshes, noise textures, geometric patterns, layered transparencies, dramatic shadows, or grain overlays — matching the overall aesthetic.
   >
   > **Avoid**: Generic AI aesthetics where possible — overused fonts (Inter, Roboto, Arial, system fonts), clichéd color schemes (purple gradients on white), predictable layouts, or cookie-cutter patterns. Every generation should be distinctive.

3. **If `plancasting/tech-stack.md` has no "Design Direction" section** (Stage 0 was run before this field existed), establish one now: read `./plancasting/prd/01-product-overview.md` for product personality and target users, choose a bold aesthetic direction, and add it to `plancasting/tech-stack.md` under a new "Design Direction" section before proceeding with frontend scaffold.

**Files to generate**:

**`src/styles/design-tokens.ts`** (GENERATE THIS FIRST — before any components)
- `design-tokens.ts` defines token values as TypeScript constants. These are consumed by `tailwind.config.ts` for theme extension AND referenced in `globals.css` as CSS custom properties.
- Read the "Design Direction" section in `plancasting/tech-stack.md` for the user's aesthetic choices, reference URLs, and Figma designs.
- Read the PRD product overview (`./plancasting/prd/01-product-overview.md`) to understand the product's personality, target users, and brand positioning.
- Execute the aesthetic direction specified in `plancasting/tech-stack.md`. If `plancasting/tech-stack.md` specifies an aesthetic (e.g., "Refined Editorial"), implement it faithfully. If it says "to be determined by Stage 3", choose a BOLD, DISTINCTIVE direction that matches the product personality. Do not default to "clean and modern" — that produces generic AI output.
- Define and export:
  - Color palette: primary, secondary, accent, background, surface, text colors as CSS variables. Use dominant colors with sharp accents — not evenly-distributed palettes.
  - Typography: Select 2 distinctive fonts (display + body). Font imports via `next/font` (or equivalent) should be placed in the root layout file (e.g., `src/app/layout.tsx`), NOT in `design-tokens.ts`. Reference the font CSS variable names (e.g., `--font-display`, `--font-body`) in `design-tokens.ts` and `tailwind.config.ts`. Choose fonts intentionally — if using system fonts or Inter, ensure they align with the project's stated aesthetic direction.
  - Spacing scale: custom spacing values that create rhythm and hierarchy.
  - Border radius, shadow, and elevation tokens.
  - Animation tokens: transition durations, easing functions, stagger delays.
  - Component-level tokens: button styles, input styles, card styles.

**`tailwind.config.ts`** (CUSTOMIZE — never use defaults)
- Check the Tailwind CSS version in `package.json` or `plancasting/tech-stack.md`. The `@config` directive and CSS-first configuration requirements below apply ONLY to Tailwind v4+. For Tailwind v3, standard `tailwind.config.ts` auto-loading applies.
- Extend Tailwind's default theme with the design tokens defined above.
- Custom colors, fonts, spacing, border-radius, box-shadow, animation keyframes.
- The Tailwind config must reflect the chosen design direction — not generic defaults.
- **Tailwind v4 semantic color tokens (CRITICAL)**: In Tailwind v4, utility classes like `border-border`, `ring-ring`, `bg-card` resolve by looking up a color named `border`, `ring`, or `card` in the **`colors`** palette — NOT in `borderColor` or `ringColor`. If you define `borderColor.DEFAULT: "var(--color-border)"` but forget to also add `border: "var(--color-border)"` to `colors`, then `border-border` produces no color output and borders render as white (browser default). This is a silent failure. Always add these semantic tokens as top-level entries in `theme.extend.colors`:
  ~~~typescript
  colors: {
    // ... your palette colors (primary, neutral, etc.)
    // Semantic tokens — REQUIRED for utility class resolution in Tailwind v4
    border: "var(--color-border)",      // enables border-border
    ring: "var(--color-ring)",          // enables ring-ring
    card: "var(--color-bg-card)",       // enables bg-card
    background: "var(--color-bg)",      // enables bg-background
    foreground: "var(--color-text-primary)", // enables text-foreground
    // Add ALL semantic tokens your component library expects. For shadcn/ui, also include:
    // input, muted, muted-foreground, accent, accent-foreground, destructive,
    // destructive-foreground, popover, popover-foreground.
    // Check your component library's theme requirements for the complete list.
  },
  ~~~
  In Tailwind v3, `borderColor.DEFAULT` was enough. In v4, the `colors` object is the single source for all color utilities (`bg-*`, `text-*`, `border-*`, `ring-*`).

**`src/styles/globals.css`** (CRITICAL — Tailwind v4 config bridge. Skip this section for Tailwind v3 projects.)
- The instructions below apply to Next.js App Router. For other frameworks (Remix, SvelteKit, Vite + React, etc.), adapt the CSS file location, metadata patterns, and config bridge syntax. The core principle (Tailwind v4 requires `@config` bridge for `tailwind.config.ts`) applies to all frameworks.
- **must include `@config` directive** (Tailwind v4+ only): Tailwind CSS v4 uses CSS-first configuration. Unlike v3, the JS config file (`tailwind.config.ts`) is not automatically loaded. You must add `@config "../../tailwind.config.ts";` immediately after `@import "tailwindcss";` in `globals.css`. Without this, ALL custom theme extensions (colors, fonts, spacing, animations, shadows, border-radius) defined in `tailwind.config.ts` will be silently ignored — no error, no warning — and every custom Tailwind utility class (`bg-primary-500`, `font-display`, `text-text-heading`, `p-space-4`, etc.) will produce zero CSS output. The result is an unstyled UI with only raw CSS variable fallbacks working. This is the #1 cause of "my Tailwind v4 styles aren't working" bugs.
  ~~~css
  @import "tailwindcss";
  @config "../../tailwind.config.ts";
  /* The path is relative from THIS CSS file to tailwind.config.ts at the project root. Adjust if your CSS file is at a different depth (e.g., '../../tailwind.config.ts' for src/styles/ or src/app/, '../tailwind.config.ts' for files directly in src/). */
  ~~~
- CSS variable declarations from design tokens.
- Base typography styles with the chosen fonts.
- Custom animation keyframes.
- Background textures, gradients, or patterns that create atmosphere (not flat solid colors).

**Icon library setup** (configure based on `plancasting/tech-stack.md` "Icon library" and "Icon import pattern" fields):
- Read the **Icon library** and **Icon import pattern** fields from `plancasting/tech-stack.md` "Design Direction" section to get the exact package name and import syntax.
- Install the icon library package (the framework-specific variant recorded in tech-stack.md, e.g., `lucide-react`, `@heroicons/vue`, `lucide-svelte`, `@tabler/icons-react`).
- If the UI component library bundles its own icons (e.g., `@ant-design/icons`, `@mui/icons-material`, `@mdi/js` for Vuetify), install that package instead.
- If the icon library is **CSS-based** (icons used via class names like `<i class="pi pi-check" />` rather than JavaScript imports — e.g., PrimeIcons with PrimeVue), skip the barrel file below. CSS icon libraries don't need re-exporting. Instead, create `src/components/ui/icons.ts` with a comment documenting the icon usage pattern and a reference to the library's icon list.
- **For JS-based icon libraries** (all libraries except CSS-based ones above), create a barrel export file at `src/components/ui/icons.ts`:
  - This is the project's **canonical icon source** — components should prefer importing from here so that swapping the icon library is a one-file change. Direct imports from the library package are acceptable during Stage 5 feature implementation; Stage 6E migrates all direct imports into the barrel file.
  - If the UI component library (e.g., shadcn/ui) generates its own `icons.tsx` at a different path (e.g., `src/components/icons.tsx`), delete or redirect it to re-export from `src/components/ui/icons.ts` — avoid two competing icon sources.
  - Seed the barrel file with icons actually needed by the scaffold's UI components (navigation, layout, forms, empty states).
  - **Icon names vary by library** — use the actual names from the chosen library's docs (e.g., Lucide: `Trash2`, Heroicons: `TrashIcon`, Tabler: `IconTrash`, Ant Design: `DeleteOutlined`).
  - Example structure:
  ```typescript
  // src/components/ui/icons.ts — Re-export icons from the project's chosen library
  // Icon library: [library name] (from plancasting/tech-stack.md)
  // Import pattern: [import pattern] (from plancasting/tech-stack.md)
  //
  // NOTE: Icon names below are ILLUSTRATIVE (Lucide convention).
  // Replace with the actual export names from your chosen library.
  // Some libraries require sub-path imports (see note below).

  export {
    // Navigation & layout — [adapt names to chosen library]
    Menu,            // hamburger menu icon
    X,               // close / dismiss icon
    ChevronRight,    // breadcrumb / expand icon
    ChevronDown,     // dropdown indicator
    ArrowLeft,       // back navigation
    // Actions — [adapt names to chosen library]
    Plus,            // create / add icon
    Search,          // search icon
    Settings,        // settings / gear icon
    Trash2,          // delete icon
    Edit,            // edit / pencil icon
    // Status & feedback — [adapt names to chosen library]
    Check,           // success / checkmark icon
    AlertCircle,     // warning / alert icon
    Info,            // information icon
    Loader2,         // loading spinner icon
    // ... add more as features need them
  } from '[icon-library-package]';
  ```
  **Sub-path imports**: Some libraries require importing from variant sub-paths, not the package root. For these, the barrel file must re-export from the correct sub-paths:
  - **Heroicons**: `@heroicons/react/24/outline` (React), `@heroicons/vue/24/outline` (Vue). Sub-path variants: `/24/outline`, `/24/solid`, `/20/solid`. Choose one default style and re-export from it; add a second source only if both outline and solid are needed. For Svelte, use a community wrapper (e.g., `svelte-hero-icons`) or import SVGs directly.
  - **MUI Icons**: `@mui/icons-material` (flat import — no sub-paths needed, but icon names are PascalCase like `Delete`, `Search`, `Settings`).
  - **Ant Design Icons**: `@ant-design/icons` (flat import — icon names use a `Outlined`/`Filled`/`TwoTone` suffix, e.g., `DeleteOutlined`, `SearchOutlined`).
  - **Phosphor Icons**: `@phosphor-icons/react` (React), `@phosphor-icons/vue` (Vue) — flat import with weight variants via props (e.g., `<Trash weight="bold" />`). For Svelte, use `phosphor-svelte` (community wrapper — verify the package exists on npm before installing, as community packages may change).
- If the icon library requires configuration (e.g., default size, stroke width), set it up in the root layout or a provider component.
- **never use inline SVG paths** (`<svg><path d="..."/></svg>`) for standard UI icons. Always import from the icon library.

**`src/components/` directory**
- Organized by domain/feature — ALL features represented:
  ~~~
  src/components/
  ├── ui/                    # Generic, reusable primitives (styled to design direction)
  ├── forms/                 # Form components with validation
  ├── layouts/               # Layout components (header, sidebar, footer)
  ├── features/              # Feature-specific compound components
  │   ├── auth/
  │   ├── dashboard/
  │   ├── [feature-A]/
  │   ├── [feature-B]/       # Would have been "Phase 2"
  │   ├── [feature-C]/       # Would have been "Phase 3"
  │   └── ...                # ALL features
  ├── feedback/              # Toast, modal, alert
  └── onboarding/            # Progressive disclosure, guided tours
  ~~~

- For EVERY screen component in `./plancasting/prd/08-screen-specifications.md` (all features):
  - Component file with TypeScript interface for props
  - All states implemented: default, loading, empty, error, disabled, hover, active, focused
  - Responsive behavior with intentional layout changes per breakpoint (not just stacking)
  - Accessibility (ARIA, keyboard nav, focus management)
  - **Micro-interactions**: hover states, focus rings, transition animations that match the design direction
  - **Skeleton screens**: loading states must match the actual component layout (not generic pulsing blocks)
  - JSDoc with PRD traceability

- **Visual Design Rules for all components**:
  - Use the design tokens from the design token file (default: `src/styles/design-tokens.ts` — adapt path per `plancasting/tech-stack.md` Design Direction section) — never hardcode colors, fonts, or spacing.
  - Apply purposeful motion: CSS transitions on hover/focus, staggered reveal on page load, smooth state changes.
  - Use spatial composition: vary density, use negative space intentionally, break uniform grid layouts where it serves the content.
  - Add depth: subtle shadows, layered elements, background variations — avoid flat, lifeless surfaces.
  - Every component must feel like it was designed by a human designer for this specific product — not generated from a template.
  - **Dark mode border & variant discipline** (known failure pattern — observed in multiple Plan Casts): When defining component variants (especially Button, Card, Badge), avoid primary/accent-colored borders for non-primary variants. In dark mode, bright accent colors on borders (e.g., `border-primary-500`) become visually harsh against dark backgrounds. Default to:
    - **Primary button**: solid colored background (`bg-primary-500 text-white`) — the fill carries the color.
    - **Secondary/outline button**: neutral border (`border-border text-text-primary`) — NOT `border-primary-500`. The border should be subtle, matching input fields and cards.
    - **Ghost button**: no border, transparent background with hover fill.
    - **Card/container borders**: always use the neutral `border-border` token — never primary or accent colors.
    - Test every variant mentally in BOTH light and dark mode before committing the class list.

**`src/hooks/` directory**
- Custom hooks wrapping backend operations (e.g., Convex queries/mutations, tRPC calls) — one hook per domain/feature area for ALL features
- Include optimistic update patterns
- Include error handling and loading state management
- Cross-feature hooks where data flows between features (e.g., `useDashboardAggregates` pulling from multiple feature domains)

**`src/lib/` directory**
- `utils.ts`, `constants.ts`, `validators.ts`, `types.ts` — all covering the COMPLETE product

**Spawn prompt must emphasize**: READ `plancasting/tech-stack.md` "Design Direction" section FIRST — it contains the user's selected UI component library, aesthetic direction, design reference URLs, and Figma designs from Stage 0. These are your design brief. If reference URLs are listed, visit them to extract visual patterns. If a Figma URL is provided and Figma MCP tools are available, extract design tokens from the Figma file. If Figma URL is provided in tech-stack.md but your MCP tools cannot access it, Do not generate generic UI. The lead will provide pre-extracted design tokens in this prompt. If no tokens are provided and no Figma access is available, STOP and message the lead: 'Figma MCP unavailable and no pre-extracted tokens provided. Cannot generate design-accurate UI.' Establish the design direction in `design-tokens.ts` and `tailwind.config.ts` BEFORE creating any components — these must reflect the user's choices, not generic defaults. **CRITICAL for Tailwind v4**: `globals.css` must include `@config "../../tailwind.config.ts";` right after `@import "tailwindcss";` — without this single line, the entire theme (colors, fonts, spacing, animations) is silently ignored and all components render unstyled. Components must be created for ALL features using the selected UI component library. The design system must be visually distinctive and cohesive — matching the aesthetic direction from `plancasting/tech-stack.md`. Avoid generic AI aesthetics where possible — choose fonts intentionally (if using Inter or system fonts, ensure they match the stated aesthetic direction), avoid clichéd color schemes (purple-on-white gradients), and avoid cookie-cutter layouts. Custom hooks must cover ALL domains. Cross-feature hooks are important. Every component must follow the established design direction with zero exceptions.

---

#### Teammate 4: "feature-flags-and-config"
**Domain**: Feature flag system, environment config, and middleware

**Stack adaptation**: The file names below use Convex as examples. If using a different backend per `plancasting/tech-stack.md`, adapt: e.g., for Prisma, add a `FeatureFlag` model to `prisma/schema.prisma` + create `src/app/api/feature-flags/` route handlers.

**Files to generate**:

**`[backend-dir]/featureFlags.[ext]`** (e.g., `convex/featureFlags.ts`) — backend-powered feature flag system
- Schema table/model for feature flags
- Read function to check flag status
- Write function for admin flag management
- Flag types limited to OPERATIONAL AND EXPERIMENT purposes:
  - **Ops flags** (kill switches): for features with external dependencies or high-risk behaviors that may need emergency disabling
  - **Experiment flags** (A/B testing): for features where the optimal UX is uncertain
  - **Permission flags** (role/plan-based access): for features gated by user role or subscription tier
  - NO release flags — all features ship enabled by default
- Gradual rollout logic for experiment flags only
- If `tech-stack.md` does not specify a feature flag implementation, default to a simple database table (e.g., Convex table, PostgreSQL table) with a `getFeatureFlags` query that filters by user/org and experiment type.

**`src/hooks/useFeatureFlag.ts`**
- React hook wrapping the feature flag read function
- TypeScript-safe flag name enum covering ALL ops/experiment/permission flags

**`src/components/features/FeatureGate.tsx`**
- Declarative component for conditional rendering
- Props: `flag`, `fallback`, `children`

**`src/middleware.ts`** (Teammate 4 owns this file exclusively — Teammate 2 must not generate a middleware file)
- Frontend middleware (e.g., Next.js middleware) for:
  - Route protection (authenticated vs public routes) for ALL routes
  - Permission-flag-based route access for ALL gated features
  - Locale detection (if i18n is specified)

**Auth setup files** (e.g., `convex/auth.config.ts`, `src/lib/auth.ts`)
- Auth provider configuration
- Role/permission definitions covering ALL features' access requirements (Teammate 4 defines WHAT roles/permissions exist; Teammate 1 implements the runtime functions that CHECK those roles)

**Auth file ownership boundary** (Teammate 4 vs Teammate 1):
- **Teammate 4 owns**: Auth provider configuration files (e.g., `convex/auth.config.ts`, `src/auth.config.ts`), role/permission definition files (e.g., `src/lib/auth-roles.ts`, `src/lib/permissions.ts`), and auth-related middleware logic in `src/middleware.ts`. These define WHAT auth providers, roles, and permissions exist.
- **Teammate 1 owns**: Runtime auth helper functions (e.g., `convex/auth.ts` or `src/lib/auth-helpers.ts` containing `requireAuth()`, `requireOrgMembership()`, `requireProjectRole()`, etc.). These implement HOW roles/permissions are checked at runtime within backend functions.
- **Disambiguation rule**: If the file configures an external auth provider or declares role/permission enums → Teammate 4. If the file exports functions called by backend mutations/queries to enforce access control → Teammate 1.

**Environment configuration**:
- `.env.local.example` with ALL required environment variables
- `.env.production.example`

**Spawn prompt must emphasize**: Feature flags are not for phased rollout. All features ship enabled. Flags are for: (1) kill switches to disable problematic features, (2) A/B experiments, (3) permission/role gating. The middleware must handle route protection for the COMPLETE product's route structure. Auth permissions must cover ALL features' access patterns.

---

#### Teammate 5: "testing-and-ci-cd"
**Domain**: Testing infrastructure, CI/CD pipeline, and project configuration
**Files to generate**:

**Testing setup**:
- `vitest.config.ts` — Vitest configuration. Verify the test framework matches `plancasting/tech-stack.md`. If the project uses Jest instead of Vitest, generate `jest.config.ts` instead.
- `playwright.config.ts` — Playwright configuration
- `src/__tests__/setup.ts` — Test setup with backend test utilities (e.g., Convex test utilities)
- `[backend-dir]/__tests__/` (e.g., `convex/__tests__/`) — Backend function tests for ALL backend function files (all features)
- `src/__tests__/components/` — Component tests for ALL features
- `e2e/` — Playwright E2E tests for ALL user flows from `./plancasting/prd/06-user-flows.md`, including:

**Test Infrastructure Files (CRITICAL — generate at scaffold time to prevent Stage 5 failures)**:

These files must be created during scaffolding. Missing test infrastructure causes cascading
failures in Stage 5 that are expensive to debug.

1. **`src/test/setup.ts`** — Vitest setup file with:
   - jest-dom matchers (use `import * as matchers` + `expect.extend(matchers)` to
     avoid ESM resolution bugs with `@testing-library/jest-dom/vitest`)
   - Type augmentation via `import type {} from "@testing-library/jest-dom/vitest"`
   - Canvas prototype stub for axe-core: `HTMLCanvasElement.prototype.getContext = vi.fn()`
   - Any `resolve.alias` needed in vitest.config.ts for ESM-incompatible packages

2. **`[backend-dir]/__tests__/backend-modules.test-utils.ts`** (e.g., `convex/__tests__/convex-modules.test-utils.ts`) — Explicit module map for backend tests (if required by your test framework, e.g., convex-test). must list ALL generated backend function files. Include a header comment:
   ~~~typescript
   /**
    * HOW TO KEEP IN SYNC: When adding a new backend function file ([backend-dir]/<name>.[ext]),
    * add an import and entry to this module map. Tests will fail if a module is missing.
    */
   ~~~
   must be kept in sync as new backend function files are added in Stage 5.

3. **`[backend-dir]/__tests__/setup.test-utils.ts`** (e.g., `convex/__tests__/setup.test-utils.ts`) — Shared test utilities:
   - `setupTestContext()` that initializes the test environment for your backend
   - `mockIdentity()`, `mockProject()`, etc. — test data factories
   - `expectBackendError()` helper for asserting backend error codes (e.g., `expectConvexError()` for Convex)
   - All test data factories must include `deletedAt: null` for tables that use soft-delete filters

These files prevent the most common Stage 5 test failures:
- `.glob is not a function` (missing module map, Convex-specific) — very common
- Empty query results (missing `deletedAt: null` in test data) — common
- ESM resolution errors (`@testing-library/jest-dom`) — common

**E2E tests**:
  - Cross-feature user flows (journeys spanning multiple feature areas)
  - Onboarding flows (full product onboarding)
  - Visual regression test setup

**CI/CD pipeline** (`.github/workflows/`):
- `ci.yml` — Pull request pipeline:
  - Type checking, linting, unit tests, component tests, backend function tests
  - E2E tests against preview deployment
  - Bundle size check
  - Lighthouse CI with performance budgets from `./plancasting/prd/15-non-functional-specifications.md`
- `deploy.yml` — Production deployment pipeline:
  - Full test suite
  - Your backend deploy command (e.g., `npx convex deploy` for Convex) → Your frontend build command (e.g., `next build`)
  - Post-deployment health checks for ALL features
  - Feature-level health verification (not phase-level)
  - Rollback triggers
- `preview.yml` — Preview deployment for PRs

**Project configuration**:
- `package.json` — Dependencies and scripts for the COMPLETE product
- `tsconfig.json`, `next.config.ts`, ESLint configuration (use `eslint.config.mjs` for ESLint 9+ flat config, or `.eslintrc.cjs` for ESLint 8 — check `plancasting/tech-stack.md` for the ESLint version), `.prettierrc`, `.gitignore`. Default to ESLint 9+ flat config (`eslint.config.mjs`) for new projects unless `plancasting/tech-stack.md` specifies ESLint 8.

**`next.config.ts` — Deployment-Critical Configuration (Next.js only — skip for other frameworks)** (the following rules apply only if the frontend framework is Next.js — check `plancasting/tech-stack.md`; these cause real production failures if missed):

1. **Content-Security-Policy (CSP)**: If generating security headers with CSP, do not include `'strict-dynamic'` in `script-src` unless you also implement nonce-based CSP. `'strict-dynamic'` causes browsers to **ignore** both `'self'` and `'unsafe-inline'`, which blocks ALL Next.js chunk loading from `/_next/static/`. To use `'strict-dynamic'` safely:
   - Create a Next.js middleware that generates a per-request nonce via `crypto.randomUUID()`
   - Add the nonce to the CSP header: `script-src 'nonce-{value}' 'strict-dynamic'`
   - Pass the nonce to all `<Script>` components
   - Without nonces, use: `script-src 'self' 'unsafe-inline' [trusted-domains]`

2. **i18n Plugin Aliases (next-intl, next-international, etc.)**: Many i18n plugins set `experimental.turbo.resolveAlias` which Next.js 15+ / 16 no longer supports (Turbopack config moved to top-level `turbopack` key). The plugin may still work for webpack builds, but Turbopack (default in Next.js 16) will silently ignore the alias, causing SSR crashes like "Couldn't find [plugin] config". Always add BOTH aliases manually:
   ~~~typescript
   // In nextConfig:
   turbopack: {
     resolveAlias: {
       "next-intl/config": "./src/i18n/request.ts",  // relative path for Turbopack
     },
   },
   webpack(config) {
     config.resolve.alias["next-intl/config"] = path.resolve(process.cwd(), "./src/i18n/request.ts");  // absolute path for webpack
     return config;
   },
   ~~~
   Turbopack requires **relative paths** (absolute paths cause "server relative imports are not implemented yet" errors). Webpack requires **absolute paths** (use `path.resolve`).

3. **Environment Variables for Hosting Providers**: If deploying to Vercel, Netlify, or similar, remember that `.env.local` is not automatically synced to the hosting provider. All environment variables must be explicitly configured on the hosting platform. Generate a `.env.local.example` with clear documentation of which variables are required for production deployment.

**`README.md`** (project root):
- Setup instructions
- Development workflow
- Testing guide for the COMPLETE product
- Deployment guide (single deployment, not phased)
- Architecture overview with links to PRD/BRD

**`plancasting/_progress.md`** (initial progress tracker):
- Pre-populated with ALL features from `./plancasting/prd/02-feature-map-and-prioritization.md`
- All features initially marked as ⬜ Not Started
- No phase column — only: Feature ID, Feature Name, Priority (P0–P3), Status, Backend, Frontend, Tests, Notes
- Use the status format from CLAUDE.md's Progress Tracking section: `⬜ Not Started`, `🔧 In Progress`, `✅ Done`, `🔄 Needs Re-implementation`, `⏸ Blocked`.
- Ordered by development priority (P0 first)

**Spawn prompt must emphasize**: Tests must cover ALL features — including those from all parts of the PRD. Cross-feature E2E tests are critical — test journeys that span multiple feature areas. CI/CD deploys the COMPLETE product in a single pipeline. The `plancasting/_progress.md` tracker must include EVERY feature with no phase grouping. Post-deployment health checks must verify ALL features, not a subset. If using Convex, include the convex-test module map; for other backends, include equivalent test setup.

---

### Phase 3: Coordination During Execution

While teammates are working:
1. Monitor progress via the shared task list.
2. Facilitate cross-team dependencies through messaging:
   - When Teammate 1 finalizes the schema and function signatures → notify Teammates 2, 3, 4, and 5
   - When Teammate 2 finalizes route structure → notify Teammate 3 and 5
   - When Teammate 3 finalizes component interfaces → notify Teammate 2 and 5
   - When Teammate 4 finalizes feature flag schema requirements → notify Teammate 1 to incorporate into the main schema (if not already included). When Teammate 4 finalizes FeatureGate component → notify Teammate 3
3. Resolve import path conflicts and shared type definitions.
4. Ensure backend function names match what pages and hooks reference.
5. **Cross-feature consistency**: Verify that shared data patterns (e.g., a user profile accessed by auth, dashboard, billing, and analytics features) are consistent across all teammates' outputs.

### Phase 4: Review & Integration

After all teammates complete their tasks:

1. Collect all generated files into their correct directories.
2. Perform a comprehensive consistency review:
   - **Full-scope coverage**: Every PRD screen spec (SC-xxx) has a component. Every PRD API spec (API-xxx) has a backend function. Every PRD data entity has a schema table/model. No gaps.
   - **Import validation**: All imports resolve to existing files
   - **Backend API references**: Every backend function call (e.g., `api.xxx.yyy` in Convex) has a corresponding export
   - **Schema completeness**: Every backend function's table/model references exist in the schema
   - **Index coverage**: Every indexed query uses a defined index
   - **Type consistency**: Types are consistent between backend validators and frontend interfaces
   - **PRD traceability**: Every file has header comments referencing PRD/BRD IDs
   - **State coverage**: Every component handles loading, error, and empty states
   - **Auth checks**: Every write function and sensitive read function includes auth checks
   - **Test coverage**: Every backend function has a test file; every user flow has an E2E test file
   - **Cross-feature data flows**: Verify that hooks/functions that aggregate data across features reference the correct backend functions
   - **Feature flag coverage**: Every ops/experiment flag from `./plancasting/prd/03-release-plan.md` is implemented
   - **No phase artifacts**: Verify no code contains phase-related logic (no "Phase 1", "Phase 2" references, no feature-gating by release phase)
3. Finalize `plancasting/_scaffold-manifest.md` — the explicit handoff document from Stage 3 to Stage 5:

   The lead creates the manifest template in Phase 1 with the expected file structure. Teammates append their generated files to the manifest as they work. The lead validates completeness in Phase 4.

   This manifest is CRITICAL for preventing the duplication failure pattern, where Stage 5's frontend teammate rebuilds UI inline in pages instead of using scaffold components. The manifest maps every generated file to its purpose and consumer.

   ~~~markdown
   # Scaffold Manifest
   ## Generated by Stage 3 — Do not delete until Stage 5B completes (used by both Stage 5 and Stage 5B audit)

   ### Components → Page Mapping
   | Component File | Target Page | Purpose |
   |---|---|---|
   | `src/components/features/auth/LoginForm.tsx` | `src/app/(auth)/login/page.tsx` | Login form with email/password |
   | `src/components/features/dashboard/UsageBar.tsx` | `src/app/(dashboard)/dashboard/page.tsx` | Plan cast usage display |
   | ... | ... | ... |

   ### Hooks → Component Mapping
   | Hook File | Consuming Components | Backend Functions |
   |---|---|---|
   | `src/hooks/useAuth.ts` | `LoginForm`, `SignupForm`, `ProfilePage` | `api.auth.*` |
   | ... | ... | ... |

   ### Backend Functions
   | Backend File | Functions | Feature |
   |---|---|---|
   | `convex/auth.ts` | `login`, `signup`, `getSession` | Authentication |
   | ... | ... | ... |

   ### Pages (with expected component composition)
   | Page File | Expected Components (from this manifest) |
   |---|---|
   | `src/app/(auth)/login/page.tsx` | `LoginForm`, `OAuthButtons` |
   | `src/app/(dashboard)/dashboard/page.tsx` | `ProjectList`, `UsageBar`, `RecentActivity` |
   | ... | ... |
   ~~~

   The manifest must cover EVERY component, hook, and backend function file generated in this scaffold. Stage 5's teammates will read this manifest in their SCAFFOLD INVENTORY step (Step 0) before writing any code.

4. Generate `ARCHITECTURE.md`:
   - System architecture diagram for the COMPLETE product (mermaid)
   - Directory structure with descriptions (all features)
   - Data flow diagrams
   - Cross-feature data flow diagram (how data moves between feature areas)
   - Auth flow diagram (covering all permission levels)
   - Feature flag evaluation flow (ops/experiment/permission only)
   - PRD → Code traceability matrix (COMPLETE)
5. Update `CLAUDE.md` Part 2 — per CLAUDE.md § "Universal Prohibitions" (never rewrite Part 1; only extend Part 2):
   - If `CLAUDE.md` exists, read it carefully. It has two parts.
   - **Part 2 (Project-Specific Configuration): Fill in the placeholder sections** with actual project details from `plancasting/tech-stack.md` and the generated codebase:
     - Project Overview: actual product description
     - Technology Stack: actual tech stack table
     - Architecture: multi-tenant details, auth model, data architecture
     - Directory Structure: actual directory tree
     - Backend Rules: stack-specific conventions (e.g., auth helper patterns, validation conventions, error handling patterns)
     - Frontend Rules: stack-specific conventions (e.g., component organization, import conventions, state management patterns)
     - Security Rules: stack-specific security patterns (e.g., auth guard usage, input sanitization conventions, CSP configuration)
     - Custom Hooks: actual hook patterns
     - Naming Conventions: actual naming patterns
     - Commands: actual scripts from package.json
     - Key Reference Documents: verify PRD/BRD file paths match actual output directories
     - Project-Specific Prohibitions: stack-specific "do not" rules
   - Placeholder text uses square bracket notation (e.g., `[PROJECT_NAME]`, `[e.g., Next.js 16]`, `[N] features`) and generic descriptions. Replace ALL bracketed placeholders with actual project values.
   - If `CLAUDE.md` does not exist: if the project was cloned from the Transmute Framework Template, use `./CLAUDE.md` (already at project root). If fresh project (not cloned from the template), copy the CLAUDE.md template from the Transmute Framework Template repository to the project root as `./CLAUDE.md` before populating Part 2. Then fill in all Part 2 `[PLACEHOLDER]` values with actual project values from `tech-stack.md` and the codebase.
6. **Generate `.claude/rules/` starter rules**:
   - Create the `.claude/rules/` directory.
   - Read the rule templates from `./plancasting/transmute-framework/rules-templates/` (6 template files always: `_backend-template.md`, `_frontend-template.md`, `_api-contracts-template.md`, `_auth-template.md`, `_testing-template.md`, `_data-model-template.md`; plus `_ai-provider-template.md` when `tech-stack.md` § Specifications names an AI/LLM provider — LLM request shapes change between model generations and the shape remembered from training data is the one most likely to be rejected, so these rules must exist before Stage 5 writes the first AI call).
   - For each template, render it into a real rule file by:
     a. Replacing **directory placeholders** (`[BACKEND_DIR]`, `[FRONTEND_DIR]`, `[AUTH_DIR]`, `[SCHEMA_DIR]`, `[TEST_DIR]`, `[HOOKS_DIR]`, and for `_ai-provider-template.md` `[AI_DIR]`, `[AI_SDK]`, `[AI_MODEL_ENV]`, `[AI_MODEL_ID]`, `[AI_INTEGRATION_TEST_ENV]`) with actual project paths and values from `tech-stack.md`.
     b. Replacing **tech-stack-specific placeholders** (e.g., `[VALIDATOR_SYSTEM]`, `[ERROR_TYPE]`, `[AUTH_HELPER]`, `[LOADING_COMPONENT]`, `[SESSION_PATTERN]`, `[DATABASE]`, `[TIMESTAMP_FORMAT]`, etc.) with actual values derived from `tech-stack.md`. Read each template's TODO comments for context on what each placeholder expects. For example: if the backend is Convex, `[VALIDATOR_SYSTEM]` → `v validators`, `[ERROR_TYPE]` → `ConvexError`, `[AUTH_HELPER]` → `ctx.auth.getUserIdentity()`; if Next.js App Router, add rules about server/client component boundaries and `use client` directives.
     c. Adding the correct `paths` frontmatter for each file based on actual project paths (Claude Code scopes rules by `paths`; a rule file without it loads in every session).
     d. Setting `Source: Stage 3` and `Evidence: tech-stack.md` on each rule.
     e. Removing all `<!-- TODO: Stage 3 — ... -->` comments and the template banner (`> **This is a template.**...`) from the rendered output.
   - Write the rendered files to `.claude/rules/backend.md`, `.claude/rules/frontend.md`, `.claude/rules/api-contracts.md`, `.claude/rules/auth.md`, `.claude/rules/testing.md`, `.claude/rules/data-model.md`, and (AI products only) `.claude/rules/ai-provider.md`.
   - Respect limits from CLAUDE.md § 'Path-Scoped Rules': max 15 rules per file, max 8 files total.
   - Create `./plancasting/_rules-candidates.md` with a header explaining the staging workflow, candidate format, and confidence criteria (see CLAUDE.md § 'Path-Scoped Rules' for the specification). This file starts with zero candidates — Stages 5B and 6R will populate it.
   - Update the **Path-Scoped Rules** table in CLAUDE.md Part 2 with the actual rule files just generated (file paths, `paths` patterns, rule counts).
7. Fix any inconsistencies.
8. Output a final summary:
   - File counts: backend functions, frontend pages, components, hooks, tests
   - PRD coverage: percentage of SC-xxx with components (target: 100%)
   - PRD coverage: percentage of API-xxx with backend functions (target: 100%)
   - PRD coverage: percentage of data entities with schema tables/models (target: 100%)
   - Cross-feature touchpoints: number of hooks/functions that span multiple feature domains
   - Test file counts: unit tests, component tests, E2E tests
   - Feature flags implemented: ops, experiment, permission
   - Verify `plancasting/_scaffold-manifest.md` is populated with all generated components, hooks, backend functions, and pages
   - Any unresolved issues or assumptions

9. **Verify all required output files exist**. Stage 3 generates the following outputs that downstream stages depend on: all source code scaffold files, `plancasting/_codegen-context.md`, `plancasting/_progress.md`, `plancasting/_scaffold-manifest.md`, `ARCHITECTURE.md`, populated CLAUDE.md Part 2, `.claude/rules/*.md` (starter rules), and `plancasting/_rules-candidates.md` (empty). Verify all exist before completing this stage. If any are missing, generate them before declaring Stage 3 complete.

10. **Gate Decision**: Determine the scaffold outcome:
   - **PASS**: All required output files exist, PRD coverage ≥ 95% (SC, API, data entities all have scaffold files), CLAUDE.md Part 2 fully populated (no `[PLACEHOLDER]`, `[PROJECT_NAME]`, `[N]`, `[e.g.,`, `[BACKEND_DIR]`, `[FRONTEND_DIR]`, or other bracketed template markers remain), `_progress.md` lists all features, `.claude/rules/` populated → proceed to Stage 5
   - **CONDITIONAL PASS**: PRD coverage ≥ 80% with gaps documented, all critical P0 features scaffolded, CLAUDE.md Part 2 populated and `_progress.md` present (rules may be incomplete) → proceed to Stage 5 with noted gaps
   - **FAIL**: PRD coverage < 80%, OR CLAUDE.md Part 2 not populated, OR `_progress.md` missing, OR required output files missing → re-run Stage 3

   > **Terminology note**: "Coverage" in this stage means scaffold coverage — the percentage of PRD screens (SC-xxx), API endpoints, and data entities that have corresponding scaffold files. This differs from Stage 2B's "coverage" (BRD→PRD requirement traceability).

   > **Measurement**: Coverage is per-feature: count features with scaffold files ÷ total PRD features. Supplement with per-artifact-type verification: all P0 features should have SC (screen), API, and data entity scaffold files.

   > **NOTE**: These Stage 3+4 gate thresholds (≥95% PASS, ≥80% CONDITIONAL PASS) are defined here as the canonical source. execution-guide.md does not duplicate them.

### Token Budget Management

Each spawned agent has an output token limit per response (see tech-stack.md § Model Specifications "Output token limit"). The pipeline model's context window means input is not the bottleneck — the output limit per agent response is the binding constraint. Scaffolding is file-heavy — a single teammate generating 40+ files can hit this limit. The lead must estimate output size during Phase 1.

**Estimation heuristics**:
- Each backend function file (with validators, auth, logic, JSDoc): ~200–400 tokens
- Each React component file (with props interface, states, JSX scaffold): ~300–600 tokens
- Each page file (with imports, layout, composition): ~150–300 tokens
- Each hook file (with query/mutation wrappers, types): ~200–400 tokens
- Each test file (with setup, test cases, assertions): ~300–500 tokens
- Configuration files (tsconfig, next.config, eslint): ~100–300 tokens each

**Safe budget per teammate**: see tech-stack.md § Model Specifications "Safe output budget" (fallback default: 25,000 tokens if tech-stack.md does not specify — this default may need adjustment as model capabilities evolve; always prefer the value from tech-stack.md). If a teammate's estimated output exceeds the safe output budget:
- **Teammate 1 (backend)**: Split by domain group (e.g., auth + user management vs billing + payments vs core product features). Each sub-agent gets a subset of backend files with unique table/function assignments.
- **Teammate 3 (components)**: Split by feature area. Ensure each sub-agent gets the complete component set for its features (so cross-component imports within a feature resolve).
- **Teammate 5 (tests)**: Split by test type (unit tests vs E2E tests) or by feature area.

**If a teammate's output is truncated**: Check which files were successfully written by comparing the generated file count against the expected count from `_codegen-context.md`. For example: `find src/components -name '*.tsx' | wc -l` vs. the component count in the Code Generation Map. If count < expected, truncation occurred — re-spawn with reduced scope covering only the missing files. Maximum 2 retry attempts per scope; if still truncated after 2 retries, split scope further.

### Phase 5: Shutdown

1. Teammates terminate automatically upon task completion. No explicit shutdown is required.
2. Verify all file modifications are saved.
3. Verify all output files exist before declaring Stage 3 complete.

---

## Session Recovery

If this session was started to RESUME a previously interrupted scaffold generation:
1. Check which files already exist in `./[backend-dir]/` (e.g., `./convex/`), `./src/`, and `./e2e/`.
2. Check if `plancasting/_codegen-context.md` and `plancasting/_progress.md` exist (indicates Phase 1+ was completed).
3. Check if `ARCHITECTURE.md` exists (indicates Phase 4 was reached).
4. Resume from the earliest incomplete phase. Do not regenerate files that already exist unless they are incomplete.
5. If some teammates completed but others didn't, only respawn the incomplete teammates. To identify which teammates completed: check which files exist per teammate assignment (defined in Phase 2). Only respawn teammates whose assigned files are missing or incomplete.
6. **Cleanup before re-spawning**: If a teammate's previous run was incomplete (partial files exist), delete any incomplete files from that teammate's previous run to avoid merge conflicts. Reset that teammate's `plancasting/_progress.md` columns to ⬜ Not Started. To identify incomplete files: check if the file has a complete traceability header comment AND at least one exported function/component. Files that are empty, contain only imports, or have no exports are likely incomplete from a prior interrupted run.
7. Re-spawned teammates must regenerate all their assigned files from scratch (not merge with partial outputs) and append to `plancasting/_scaffold-manifest.md`, same as in initial generation.

## Code Generation Guidelines (Include in ALL teammate spawn prompts)

1. **Full Scope**: Scaffold ALL features from the PRD. Every screen, every API endpoint, every entity, every hook, every test. Nothing is deferred. If a feature exists in the PRD, it exists in the codebase.
2. **PRD Traceability**: Every file must start with a comment block listing related PRD/BRD IDs using the `@traces` format (matching CLAUDE.md conventions):
   ~~~typescript
   /**
    * @module ComponentName
    * @description Brief description.
    *
    * @traces PRD:08-screen-specifications.md#SC-015
    * @traces PRD:04-epics-and-user-stories.md#US-023
    * @traces BRD:07-functional-requirements.md#FR-007
    * @traces BRD:13-security-requirements.md#SR-003
    */
   ~~~
   One traceability comment block per file (in the header). For files serving multiple specs, list all references.
   Use the format: `@traces PRD:<filename>#<ID>` / `@traces BRD:<filename>#<ID>` — this enables automated traceability scanning by Stage 5 quality gates and Stage 5B audit.

3. **TypeScript Strict Mode**: All code must compile under `strict: true`. No `any` types. No `@ts-ignore`.
4. **Backend Patterns** (example: Convex — adapt to your backend per `plancasting/tech-stack.md`):
   - Always validate arguments/inputs (e.g., Convex `v` validators, Zod schemas, tRPC input validators).
   - Always check auth in write functions and sensitive read functions.
   - Use indexed queries for all filtered reads (e.g., Convex `.withIndex()`).
   - Return only necessary fields.
   - Use internal/server-only functions for non-client-callable logic.
5. **Component Patterns**:
   - Default to Server Components. Add `"use client"` only when needed.
   - Implement ALL states: default, loading (skeleton), empty, error, disabled.
   - Include ARIA attributes and keyboard navigation.
   - Wrap backend data hooks in domain-specific custom hooks for reusability and testability (e.g., create `useTaskList()` that internally calls `useQuery(api.tasks.list)`).
6. **Design Quality** (CRITICAL):
   - Read `plancasting/tech-stack.md` "Design Direction" section for the user's selected UI component library, aesthetic direction, reference URLs, and Figma designs. These are the authoritative design inputs.
   - If design reference URLs are listed, visit them to understand the visual patterns the user wants to emulate.
   - If a Figma URL or file is provided, extract design tokens from it — Figma designs override all other direction.
   - Build all components using the selected UI component library from `plancasting/tech-stack.md`.
   - All components must use the design tokens from the design token file (default: `src/styles/design-tokens.ts` — adapt path per `plancasting/tech-stack.md` Design Direction section).
   - Avoid generic fonts (Inter, Roboto, Arial), default Tailwind colors, or predictable card-grid layouts where possible — if using them, ensure they align with the project's stated aesthetic direction.
   - Apply purposeful motion, intentional spatial composition, and visual depth.
   - Every UI element must feel distinctively designed for this product — not AI-generated.
   - **Tailwind v4 `@config` bridge**: If using Tailwind CSS v4 (`@import "tailwindcss"` syntax), the global CSS file must include `@config` with the correct relative path from the CSS file to `tailwind.config.ts` (e.g., `@config "../../tailwind.config.ts";` for `src/styles/globals.css`). Tailwind v4 does not auto-load JS config files — without `@config`, all custom theme extensions are silently dropped and utility classes produce no output.
   - **Tailwind v4 semantic color tokens**: If using Tailwind v4, semantic utilities like `border-border`, `ring-ring`, `bg-card` require matching entries in the `colors` palette (NOT in `borderColor`/`ringColor`). In v3, `borderColor.DEFAULT` was enough for `border-border`. In v4, you must add `border: "var(--color-border)"` etc. directly to `theme.extend.colors`. Without this, borders render as white (browser default) — a silent failure with no build error.
   - **Dark mode variant testing**: For every component with variants (Button, Badge, Card, Alert, etc.), verify that borders and background colors work in BOTH light and dark themes. Common mistake: using `border-primary-500` on secondary/outline buttons — looks subtle in light mode but becomes a harsh bright line in dark mode. Use `border-border` (the neutral border token) for secondary/outline variants instead.
7. **Error Handling**:
   - Backend functions: throw your backend's error type for expected errors (e.g., `ConvexError`, `TRPCError`).
   - Components: use error boundaries for unexpected errors, inline states for expected errors.
8. **Cross-Feature Awareness**: When implementing a function, hook, or component that touches data from multiple feature areas, ensure all cross-references are correct. A dashboard component might pull from auth, projects, analytics, and billing — all must be wired correctly.
9. **Naming Conventions**: Follow the conventions defined in `plancasting/_codegen-context.md`.
10. **File Size**: Keep files under 300 lines. Split if larger.
11. **Structurally Complete Functions**:
    - Every function must have correct signatures, argument validators, auth checks, and error handling structure.
    - Business logic bodies should contain a reasonable first-pass implementation (not production-complete) that Stage 5 will refine.
    - Use `// ⚠️ STUB: <description of what needs implementation>` to mark code bodies needing Stage 5 attention, and `"implementation pending feature build"` for user-visible placeholder text in components. These are the two acceptable stub markers — Stages 5 and 5B scan for both patterns. No empty functions, no `// TODO` stubs, no `throw new Error('not implemented')`.
    - Mark assumptions with `// ⚠️ ASSUMPTION:`.
    - Example: A query function should include the database call and return shape, but may skip complex business rule validation or edge-case handling — mark those with `// ⚠️ STUB: [description]`.
    - These markers are expected in scaffold code. Stage 5's job is to replace ALL of them with functional implementations. Stage 5B scans for any remaining stubs as quality failures.
12. **No Phase References**: Do not include any phase-related logic, comments, or gating. All features are active. The only conditional rendering is via operational/experiment/permission feature flags.
13. **CLAUDE.md Protection**: If `CLAUDE.md` already exists, never rewrite it from scratch. ONLY modify Part 2 (Project-Specific Configuration). Part 1 (Immutable Framework Rules) must be preserved exactly as-is, including the Design & Visual Identity section, Progress Tracking section, Traceability Rules, and all other framework rules.
14. **Scaffold Manifest**: Every **component, hook, backend function, and page** file you generate must be listed in `plancasting/_scaffold-manifest.md`. Test files, configuration files, and CI/CD pipelines are excluded from the manifest. This manifest is the handoff contract between Stage 3 and Stage 5. If a component file is not in the manifest, Stage 5 will not know it exists and may rebuild the UI inline in the page — creating duplication. The manifest must include: (a) which page imports each component, (b) which hook each component consumes, (c) which backend functions each hook wraps.
````
