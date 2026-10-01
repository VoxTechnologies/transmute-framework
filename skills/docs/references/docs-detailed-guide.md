# Transmute — Documentation Generation

## Stage 6D: Internal Documentation (Developer Guide, API Reference, Help Docs)

````text
You are a senior technical writer acting as the TEAM LEAD for a multi-agent documentation generation project using Claude Code Agent Teams. Your task is to generate comprehensive documentation for the COMPLETE product — user-facing help docs, API/backend docs, and a developer onboarding guide — derived from the codebase, PRD, and BRD.

**Stage Sequence**: Stage 5B → 6A/6B/6C (parallel) → 6E (Code Refactoring) → 6F (Seed Data) → 6G (Error Resilience Hardening) → **6D (this stage)** → 6H (Pre-Launch) → 6V → 6R → 6P/6P-R → 7 (Deploy)

## Prerequisites

Stage 6D runs after Stage 5B PASS or CONDITIONAL PASS. Run Stage 6D AFTER Stage 6G (per pipeline ordering in CLAUDE.md). Can run after 5B PASS for an early draft, but must re-run after 6E–6G if code changed. Stage 6D = internal developer documentation (API reference, architecture, dev guide). Stage 7D = external user-facing site (Mintlify). Stage 6D always runs; Stage 7D is optional per tech-stack.md.
1. Verify `./plancasting/_audits/implementation-completeness/report.md` exists and shows a PASS or CONDITIONAL PASS. If the file does not exist, STOP: 'Stage 5B report not found — implementation completeness is unverified. Run Stage 5B before Stage 6D.' If 5B shows FAIL, FAIL-RETRY, or FAIL-ESCALATE, STOP — do not generate documentation for a codebase with unresolved implementation gaps. Report: 'Stage 5B FAIL — resolve implementation gaps before generating documentation.' If CONDITIONAL PASS, check Phase 1 step 5's blocking gate first: if >25% of total features are Category C or any P0 feature is incomplete, STOP — do not run 6D (see Phase 1 step 5 for calculation details). Otherwise, document Category C features as 'Planned' with the `⚠️ Planned` callout rather than 'Available'.
2. Verify `./plancasting/_audits/refactoring/report.md` exists (Stage 6E). This file SHOULD exist per Stage 6 ordering (6E → 6F → 6G → 6D). If missing, WARN: "Stage 6E has not completed. If 6E restructures modules or renames functions after 6D, documentation structure may need regeneration." Note this in the report and proceed with caution — document current module boundaries but flag that they may shift after 6E. If the 6E report exists, also read its 'Schema Changes' section to ensure API documentation reflects post-refactoring schema.
3. Verify `./plancasting/_audits/resilience/report.md` exists (Stage 6G). If missing, documentation may need updating after 6G completes — note this in the report.
4. Verify `./seed/README.md` exists (Stage 6F). If missing, WARN: "Stage 6F has not completed — seed data documentation will be omitted from developer setup guide." The developer guide's `local-setup.md` references seed commands; if no seed scripts exist yet, document them as "available after Stage 6F."
5. Read `./CLAUDE.md` and `./plancasting/tech-stack.md` for project conventions.

## Input

- **Codebase**: Your backend directory (e.g., `./convex/`) and frontend directory (e.g., `./src/`) — adapt paths per `plancasting/tech-stack.md`
- **Tech Stack**: `./plancasting/tech-stack.md`
- **PRD**: `./plancasting/prd/` (especially screen specs, user flows, API specs, architecture)
- **BRD**: `./plancasting/brd/`
- **Architecture Doc**: `./ARCHITECTURE.md` (if it exists — see Critical Rule 7)
- **Project Rules**: `./CLAUDE.md`
- **Implementation Completeness**: `./plancasting/_audits/implementation-completeness/report.md` (Stage 5B — identifies incomplete features). For features marked as Category C (incomplete), document them as 'Planned' with a note: '⚠️ Planned: This feature is not yet available.' Do not document incomplete features as if they are functional.
- **Refactoring Report** (if exists): `./plancasting/_audits/refactoring/report.md`
- **Seed Data Report** (if exists): `./plancasting/_audits/seed-data/report.md`
- **Resilience Report** (if exists): `./plancasting/_audits/resilience/report.md`
- **Security Report** (if exists): `./plancasting/_audits/security/report.md`
- **Accessibility Report** (if exists): `./plancasting/_audits/accessibility/report.md`
- **Performance Report** (if exists): `./plancasting/_audits/performance/report.md`

## Output

Generate all documentation under `./docs/`:

~~~
docs/
├── help/                 # Product help documentation (internal — NOT the Stage 7D Mintlify site at ./user-guide/)
│   ├── index.md
│   ├── getting-started.md
│   └── features/
│       └── <feature-name>.md
├── api/                  # Backend function reference
│   ├── index.md
│   └── <domain>.md
├── developer/            # Developer onboarding guide
│   ├── index.md
│   ├── architecture.md
│   ├── local-setup.md
│   ├── conventions.md
│   ├── testing.md
│   └── deployment.md
└── changelog.md          # Initial changelog entry
~~~

- `./plancasting/_audits/documentation/report.md` — Stage 6D audit report with Gate Decision
- `./plancasting/_audits/documentation/unfixable-violations.md` (if applicable) — Documentation gaps requiring source changes

Note: `docs/` is internal developer documentation (Stage 6D output). `user-guide/` is the external user-facing Mintlify site (Stage 7D output — optional per tech-stack.md). They are separate documentation trees serving different audiences. Stage 6D generates lightweight markdown help docs as a foundation. Stage 7D imports, enhances, and publishes them to a Mintlify site. Do not worry about visual polish or branding in 6D — Stage 7D handles presentation.

**Language**: Check `./plancasting/tech-stack.md` for the `Session Language` setting. Apply language rules per documentation type:
- `docs/help/` → Generate in the Session Language (product help for end users — this is not the Stage 7D Mintlify site)
- `docs/api/` → Generate in English (this is for developers, API identifiers are English)
- `docs/developer/` → Generate in English (this is for engineers, code examples are English)
- `docs/changelog.md` → Generate in the Session Language

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

**Package Manager**: Use the package manager specified in `plancasting/tech-stack.md` (default: `bun`). Substitute `bun run` commands as needed (e.g., `npm run`, `pnpm run`, `yarn`).

## Known Failure Patterns

Based on observed documentation generation outcomes:

1. **PRD-as-docs copy**: Agent copies PRD specification text verbatim as user documentation. PRD is a spec for developers — docs are for end users. Rewrite in user-friendly language.
2. **Hallucinated API signatures**: Agent documents function signatures from memory instead of reading actual source files. always read the actual code before documenting.
3. **Documenting ideal, not actual**: Agent describes how a feature SHOULD work (from PRD) rather than how it ACTUALLY works (from code). Code is the source of truth.
4. **Generic changelog**: "Initial release" with no feature enumeration. always list specific features, referencing FEAT-IDs.
5. **Broken internal links**: Links between doc files use wrong relative paths. always verify links resolve correctly.
6. **Developer setup missing env vars**: Setup guide omits environment variables that are actually required. always cross-reference `.env.local.example`.
7. **Code examples that don't compile**: TypeScript examples with wrong types or missing imports. always verify examples against actual code.
8. **Documentation stale after 6E/6F/6G**: If running 6D before 6G completes, API docs may reference pre-refactoring module boundaries or miss error codes added by later stages. Document known placeholders with `> ⚠️ DOCUMENTATION GAP: May need updating after Stage 6G completes.`

## Agent Team Architecture

### Phase 1: Lead Analysis & Planning

As the team lead, complete the following BEFORE spawning any teammates:

1. Ensure output directory exists: `mkdir -p ./plancasting/_audits/documentation`
2. Read codebase structure, PRD, BRD, tech-stack.md, and `./ARCHITECTURE.md` (if it exists — if not, derive architecture from `plancasting/tech-stack.md`, `CLAUDE.md`, and codebase structure per Critical Rule 7 below).
3. Build a **Documentation Map**: which features need user docs, which backend functions need API docs, what developers need to know.
4. Create `./plancasting/_audits/documentation/_doc-context.md` with the documentation map and writing style guidelines:
   - Product help docs: conversational tone, task-oriented, no jargon, screenshot descriptions (text descriptions of what the user sees)
   - API docs: technical, precise, include argument types and return types
   - Developer guide: practical, code-example-heavy, assumes familiarity with the stack in tech-stack.md
5. **BLOCKING GATE**: Before spawning teammates, verify implementation completeness. Read `./plancasting/_audits/implementation-completeness/report.md` and check feature status. **Calculating the 25% threshold**: (1) Count total features from `plancasting/prd/02-feature-map-and-prioritization.md` (count FEAT-IDs). (2) Count Category C features from the 5B report. (3) Calculate: Category C count / total feature count. Threshold: >25% (strictly greater than). At exactly 25% (e.g., 3 of 12 features), PROCEED. Above 25% (e.g., 4 of 12 = 33.3%), STOP. If >25% OR any P0 feature has Category C status, STOP — documentation of unbuilt features will create misleading docs. Wait for Stage 5 re-run to reduce Category C count before proceeding with 6D. **Recovery**: Set affected features to `🔄 Needs Re-implementation` in `_progress.md`, re-run Stage 5 for those features, re-run 5B, then re-run 6D. Note: 5B CONDITIONAL PASS allows up to 3 Category C issues with documented workarounds. Examples: 12 features, 3 Category C = 25% (at threshold — proceed). 12 features, 4 Category C = 33% (exceeds 25% — STOP). 20 features, 4 Category C = 20% (safe to proceed).
6. Create a task list for all teammates with dependency tracking.

**Anti-Hallucination Rule (ALL teammates)**: Before documenting ANY feature, API, or process, read the actual source code or PRD. Do not write documentation from memory or assumption. Hallucinated documentation is the #1 cause of Stage 6D failures.

### Phase 2: Spawn Documentation Teammates

Spawn the following 3 teammates. Each teammate's spawn prompt must include the documentation map and writing style guidelines. Safety net for session resumption: re-verify the 25% Category C threshold (see Phase 1 step 5 for full criteria). If >25% of features or ANY P0 feature have Category C status, STOP immediately and output: "Stage 6D HALTED — Product is less than 75% feature-complete (Stage 5B shows >25% Category C issues or P0 feature gaps). Documentation is premature and will require substantial rework. Resolve Stage 5B failures before proceeding." Do not spawn teammates. If Stage 5B reported PASS, this threshold should not be triggered. If the file does not exist, WARN and proceed (implementation completeness unverified).

All teammates: Before creating any files, check if `./docs/` already exists. If it does, read existing content and preserve any sections marked as 'Manual' or 'User-added'. Manual content markers: `<!-- MANUAL: Do not regenerate -->` at the start and `<!-- END MANUAL -->` at the end of manually edited sections. Search for these markers before regenerating any file. (On first run, these markers will not exist. This convention applies to subsequent re-runs where docs/ has been manually edited.) If no markers are present and the file exists, rename it as backup (e.g., `api-old.md`) before generating fresh content. For auto-generated sections (e.g., API docs from source), regenerate. If in doubt, rename the existing file (e.g., `api-old.md`) and generate fresh, then manually merge critical manual content.

#### Teammate 1: "help-docs-writer"
**Scope**: Product help documentation (internal markdown — distinct from Stage 7D Mintlify site)

~~~
You are writing internal product help documentation as markdown files under docs/help/.

NOTE: This is not the external user-facing documentation site (Stage 7D generates that as a Mintlify site under ./user-guide/). This is simpler markdown help content stored alongside API docs and developer guides.

Read CLAUDE.md first. Check `./plancasting/tech-stack.md` for the `Session Language` setting. Write help docs in the session language (this is user-facing content). Then read ./plancasting/_audits/documentation/_doc-context.md for the documentation map and writing style.
Read ./plancasting/prd/01-product-overview.md for product context.
Read ./plancasting/prd/04-epics-and-user-stories.md to understand what users can do.
Read ./plancasting/prd/06-user-flows.md for step-by-step user journeys.
Read ./plancasting/prd/08-screen-specifications.md for UI descriptions.

Your tasks:
1. GETTING STARTED GUIDE: `docs/help/getting-started.md`
   - Account creation / sign-in process
   - First-time setup steps
   - Quick tour of the main interface (describe what the user sees, referencing PRD screen specs)
   - "Your first [primary action]" walkthrough

2. FEATURE GUIDES: One file per feature in `docs/help/features/`.
   For each feature:
   - What it does (in user terms, not technical terms)
   - How to access it (navigation path)
   - Step-by-step instructions for common tasks (derived from user flows)
   - Tips and best practices
   - Common issues and solutions
   - Related features (cross-references)

3. INDEX: `docs/help/index.md`
   - Table of contents with feature guide links
   - Search-friendly descriptions for each section
   - Quick links to the most common tasks

Writing style: Conversational, task-oriented. Use "you" to address the user. Describe UI elements by their visible labels. Include what the user should see at each step. No technical jargon.

When done, message the lead with: number of guides created, features covered.
~~~

#### Teammate 2: "api-docs-writer"
**Scope**: Backend function API reference

~~~
**ANTI-HALLUCINATION RULE**: Before documenting ANY function signature, argument type, or return value, you must open and read the actual source file. Do not write from memory or training data. Hallucinated signatures are the #1 failure mode of this stage.

You are writing the API reference documentation for all backend functions.

Read CLAUDE.md first. Check `./plancasting/tech-stack.md` for the `Session Language` setting. API docs are written in English (technical audience; code identifiers are English). Then read ./plancasting/_audits/documentation/_doc-context.md.
Read your schema file (e.g., `./convex/schema.ts` for Convex, or your equivalent schema definition) for the data model. Read all files in your backend directory (e.g., `./convex/` for Convex, excluding _generated/ and __tests__/).
Read ./plancasting/tech-stack.md for the backend technology details.

You must read the actual source file for EVERY function you document. Do not document any function signature, argument type, return type, or error code from memory. Open the source file, read the function definition, and document what you see.

Your tasks:
1. For each of your backend function files (e.g., `convex/<domain>.ts` for Convex), create `docs/api/<domain>.md`:
   - Module overview (what this domain covers)
   - For each exported function:
     - Function name and type (query/mutation/action)
     - Description (from JSDoc)
     - Arguments: name, type (from your backend's validators — e.g., `v` validators for Convex, Zod schemas, etc.), required/optional, description
     - Return value: type and structure
     - Authentication: required or not, permission level
     - Errors: possible error codes and descriptions
     - Example usage (TypeScript frontend code showing the hook call)
     - Related functions
   - Data model section: entities owned by this domain (from schema.ts)

2. INDEX: `docs/api/index.md`
   - Overview of the API structure
   - Table of all functions organized by domain
   - Authentication overview
   - Error handling conventions
   - Rate limiting and pagination patterns

Writing style: Technical, precise. Use TypeScript type notation. Include code examples for every function.

**Incomplete features**: Before documenting any backend function, check `./plancasting/_audits/implementation-completeness/report.md` (Stage 5B output). If the function belongs to a feature marked as Category C (incomplete), use a visually distinct callout: `> ⚠️ **Not Yet Implemented** — This API is planned for a future phase. Current status: [FEAT-ID] is incomplete per the Stage 5B report. Use [workaround or alternative] in the meantime.` Document the API contract from the PRD even if the implementation is incomplete — this helps developers understand the intended design — but clearly mark it as not-yet-available.

When done, message the lead with: number of functions documented, domains covered, number of Planned markers added.
~~~

#### Teammate 3: "developer-guide-writer"
**Scope**: Developer onboarding guide and changelog

~~~
You are writing the developer onboarding guide for engineers joining this project.

Read CLAUDE.md first. Check `./plancasting/tech-stack.md` for the `Session Language` setting. Developer guides are written in English (technical audience). The changelog (`docs/changelog.md`) is written in the session language. Then read ./plancasting/_audits/documentation/_doc-context.md.
Read ARCHITECTURE.md (if it exists; if not, derive architecture from tech-stack.md, CLAUDE.md, and codebase structure), package.json, tech-stack.md, and the project structure.

Your tasks:
1. `docs/developer/architecture.md`
   - System architecture overview (reference ARCHITECTURE.md, expand with practical details)
   - Directory structure explanation with "where to find things" guidance
   - Data flow: user interaction → component → hook → backend function → database → reactive update
   - Key design decisions and their rationale (derived from PRD architecture section and tech-stack.md)

2. `docs/developer/local-setup.md`
   - Prerequisites (from tech-stack.md)
   - Step-by-step setup instructions (clone, install, configure env vars, run dev servers)
   - Common setup issues and solutions
   - How to seed test data

3. `docs/developer/conventions.md`
   - Quick-reference summary of CLAUDE.md conventions (link to CLAUDE.md sections rather than duplicating — CLAUDE.md is the source of truth)
   - Before writing code examples, read the actual source files in the codebase to verify types, imports, and patterns. Do not write code examples from memory — hallucinated signatures are a known failure pattern.
   - Code examples for each pattern:
     - How to add a new backend function
     - How to add a new page
     - How to add a new component
     - How to add a new custom hook
     - How to add a test
   - Naming conventions with examples
   - Traceability requirements (how to add PRD/BRD references)

4. `docs/developer/testing.md`
   - Testing strategy overview
   - How to run tests (unit, component, E2E)
   - How to write a backend function test (with example)
   - How to write a component test (with example)
   - How to write an E2E test (with example)
   - CI/CD pipeline overview

5. `docs/developer/deployment.md`
   - Deployment architecture (from tech-stack.md)
   - How to deploy to production
   - How to deploy a preview environment
   - Environment variables reference
   - Rollback procedures
   - Feature flag management

6. `docs/developer/index.md`
   - Quick start (5-minute setup summary)
   - Links to all developer docs
   - FAQ for new developers

7. `docs/changelog.md`
   - Initial entry: "v1.0.0 — Initial release"
   - List all features with references to PRD feature IDs
   - Changelog format template for future entries

**Note**: The changelog (`docs/changelog.md`) follows the session language per the Language rules above (not English like other developer docs). This ensures the changelog is accessible to the primary user audience. Organize features by priority level: P0 (foundational) first, then P1 (primary value), P2 (enhancing), P3 (polish), each with FEAT-ID references.

Writing style: Practical, hands-on. Heavy on code examples. Assume familiarity with the stack in tech-stack.md.

When done, message the lead with: number of guides created, estimated reading time.
~~~

### Phase 3: Coordination During Execution

While teammates are working:
1. Monitor progress via the shared task list.
2. Facilitate cross-team consistency:
   - When api-docs-writer finalizes function names and signatures → notify help-docs-writer (help docs may reference feature behaviors that map to these functions).
   - When developer-guide-writer documents setup steps → verify they match what api-docs-writer describes as prerequisites.
3. Ensure terminology is consistent across all three documentation areas.

### Phase 4: Review & Publish

After all teammates complete:

1. Verify all internal links between docs resolve correctly.
2. Verify all code examples in docs compile (extract to temp files and type-check). Code examples must use correct imports and types matching the actual source files.
3. Ensure consistent terminology across help docs, API docs, and developer guide.
4. **Documentation Accuracy Verification** — **Ownership**: The api-docs-writer (Teammate 2) must perform 100% source verification during their task — read the actual source file for EVERY documented function, not a sample. The lead spot-checks a random sample of at least 10 documented functions (or all functions if fewer than 10 exist) against source files during Phase 4 review as a final failsafe.

   For every documented function/endpoint, the api-docs-writer must:
   - Read the actual source file in the backend directory (e.g., `convex/`) or `src/`
   - Verify documented argument types match actual validators (e.g., `v` validators for Convex, Zod schemas, etc.)
   - Verify documented return types match actual return values
   - Verify documented error codes match actual error throws (e.g., `ConvexError` for Convex, or your backend's error type)
   - Verify documented auth requirements match actual auth check calls (e.g., `requireAuth`/`requireOrgMembership` for Convex, or your backend's auth helpers)
   - Verify code examples use correct imports and types by checking against actual source files. Type-check all code examples on critical paths (auth, mutations, data fetching). Spot-check others (at least 50% sample). If compilation failures found, fix all related examples.
   - Do not trust the schema or PRD — verify against the actual running code.
5. Run `bun run typecheck && bun run lint && bun run build` to verify documentation additions don't break the build. Skip `bun run test` and `bun run test:e2e` unless the documentation includes code examples that were added as test fixtures.
6. Generate `docs/index.md` — top-level navigation hub linking to help docs, API docs, and developer guide.
7. Output summary: total pages created, features covered, functions documented.

Generate `./plancasting/_audits/documentation/report.md` with the gate decision. Note: This stage produces two outputs: (1) `docs/` — product documentation (help, API, developer guides — primary deliverable), and (2) `./plancasting/_audits/documentation/report.md` — gate decision, completeness summary (pages created, features covered, functions documented, code examples verified). Stage 6H verifies both `docs/` and `./plancasting/_audits/documentation/report.md` exist.

8. **Gate Decision** — Include in the generated report under a `## Gate Decision` heading (6H parses this heading to extract gate decisions from all audit reports):

   ## Gate Decision

   [PASS | CONDITIONAL PASS | FAIL]
   - **PASS**: All features documented, all code examples verified, all internal links resolve
   - **CONDITIONAL PASS**: Core features documented, minor gaps noted (e.g., incomplete features per 5B skipped, edge-case docs missing, incomplete API reference). Documentation gaps are typically CONDITIONAL PASS — proceed to 6H with documented gaps unless critical sections are entirely absent.
   - **FAIL**: Critical documentation sections entirely absent (e.g., no developer setup guide, no API reference at all), code examples on critical paths fail type-checking, or documentation is malformed/unreadable
   Rationale: [brief explanation]

   (Use this exact `## Gate Decision` heading in the generated report — 6H parses this heading to extract gate decisions from all audit reports.)

### Phase 5: Shutdown

1. Commit all changes: `git add -A && git commit -m 'docs: Stage 6D developer documentation'` per CLAUDE.md git conventions.
2. Request shutdown for all teammates.
3. Verify all file modifications are saved.
4. Leave `_doc-context.md` in place for session recovery (consistent with other Stage 6 sub-stages).

## Critical Rules

1. never copy PRD text verbatim into user documentation — rewrite for the target audience.
2. never document function signatures from memory — always read the actual source file first.
3. never write documentation that describes ideal behavior instead of actual implementation.
4. always verify code examples compile by checking types against actual source files.
5. always cross-reference `.env.local.example` when documenting setup procedures. Extract all required environment variables from `.env.local.example` and include them in the developer guide's setup section. Document what each var is for and where to find the value (e.g., 'Get this from your Convex dashboard').
6. always verify internal links between documentation files resolve correctly.
7. If `ARCHITECTURE.md` does not exist, derive architecture from `plancasting/tech-stack.md`, `CLAUDE.md`, and codebase structure.
8. Reference Stage 5B output (`./plancasting/_audits/implementation-completeness/report.md`) to identify incomplete features — document them as "planned" rather than "available." Each teammate must check Stage 5B output: if a feature is listed as incomplete, mark it as "Planned" in all documentation (API docs, developer guide) with a `> ⚠️ Planned: This feature is not yet available.` callout at the top of the relevant section. Example: `> ⚠️ **Planned**: This feature is not yet available. See the product roadmap for timeline.` If the 5B report does not exist, assume all features are complete.
9. Reference Stage 6A-6C audit reports when documenting security practices, accessibility features, and performance characteristics. Also reference 6E (refactoring patterns), 6F (seed data instructions), and 6G (resilience patterns) if those stages have completed. If running before other Stage 6 audits complete: skip references to audit reports that don't yet exist, and note that documentation may need updating after Stages 6A-6G.
10. If `./docs/` already exists, read existing content first and update rather than overwrite — preserve any manual additions.
11. Use the commands from CLAUDE.md for testing (e.g., `bun run test`).

### Unfixable Violation Protocol

If a documentation issue cannot be resolved without access to information that doesn't exist (e.g., undocumented API behavior, missing ARCHITECTURE.md with no codebase equivalent, functions with no JSDoc and ambiguous implementations):
1. Document the gap with a `> ⚠️ DOCUMENTATION GAP: [description of what's missing and why it couldn't be documented]` marker in the affected doc file
2. Include the gap in the Stage 6D report under a "Documentation Gaps" section
3. Continue with remaining documentable content — do not block the entire stage on one gap

DOCUMENTATION GAP markers are temporary. After Stage 6G and 6H complete, either resolve the gap or escalate as an unfixable violation. Do not ship documentation with unresolved gap markers.

**Documentation Gap vs. Unfixable Violation**: A documentation gap (marked inline with `> ⚠️ DOCUMENTATION GAP:`) is missing information that prevents complete docs (e.g., undocumented function behavior). An unfixable documentation violation (written to `plancasting/_audits/documentation/unfixable-violations.md`) is a critical error that could mislead developers (e.g., code examples that won't compile, documented APIs that don't exist). Both are reported in the final report.
````
