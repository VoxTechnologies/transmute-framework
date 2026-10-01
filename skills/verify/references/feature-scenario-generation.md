# Transmute — Feature Scenario Generation Guide

## Shared Reference for Stages 6V and 7V

> **WARNING**:
> - **Do not paste this FILE'S CONTENTS INTO CLAUDE CODE AS A PROMPT.** This file is read by the 6V and 7V agents during their scenario generation phases (Phase 1 for 6V, Phase 0 for 7V). They read it as a reference file using their file-reading tools — it is not pasted as a prompt. See `prompt_visual_functional_verification.md` or `prompt_production_smoke_verification.md` for the actual prompts to paste.
> - **Do not modify this FILE** in project copies. It is project-agnostic and shared across all Transmute projects. Updates should only be made in the Transmute Framework Template repository.
>
> **Scenario Generation**: Stage 6V reads this file during Phase 1 (Lead Analysis); Stage 7V reads it during Phase 0 (Scenario Generation). The agent generates scenarios dynamically by reading the PRD, codebase, and this guide. Do not create scenarios manually. This file must be copied to `./plancasting/transmute-framework/` in the project directory before running 6V or 7V (see execution-guide.md § "Pre-6V Setup" for copy instructions).

This file is a **reference guide** for agents running 6V/7V. Agents read it to understand scenario types and generation algorithms, then dynamically generate the actual scenario matrix from the PRD and codebase. This file itself is not modified during execution; the generated matrix is saved to the audits directory.

This document defines how to dynamically generate comprehensive test scenarios from PRD specifications and codebase analysis. It is referenced by:
- **Stage 6V** (Visual & Functional Verification) — generates FULL scenario matrix
- **Stage 7V** (Production Smoke Verification) — generates SMOKE scenario matrix (P0/P1 only)

Note: Stage 6R (Runtime Remediation) uses the 6V scenario matrix output (`./plancasting/_audits/visual-verification/feature-scenario-matrix.md`) to verify fixes. 6R does not re-generate the scenario matrix — it reuses the 6V matrix to re-test fixed issues.

**Stage usage summary**:
- **Stage 6V**: Reads this file during Phase 1 to generate the FULL scenario matrix (all 5 scenario types, P0-P3)
- **Stage 7V**: Reads this file during Phase 0 to generate the SMOKE scenario matrix (FS + AS types only, P0-P1, max 15 scenarios)
- **Stage 6R**: Does not read this file — it uses the 6V scenario matrix output at `./plancasting/_audits/visual-verification/feature-scenario-matrix.md` to verify fixes

## Abbreviation Glossary

| Abbreviation | Meaning | Source |
|---|---|---|
| FS-NNN | Feature Scenario | Generated from User Flows (this guide, Step 4) |
| AS-NNN | Auth Context Scenario | Generated from middleware analysis (this guide, Step 5) |
| ES-NNN | Entity State Scenario | Generated from schema analysis (this guide, Step 6) |
| RS-NNN | Role Permission Scenario | Generated from auth helpers (this guide, Step 7) |
| NS-NNN | Negative Scenario | Generated from acceptance criteria (this guide, Step 8) |
| SS-NNN | Smoke Scenario | Re-numbered FS-NNN for Stage 7V (Production Smoke Verification) scope (see Generation Algorithm Step 9) |
| SC-NNN | Screen Specification | From PRD `prd/08-screen-specifications.md` |
| US-NNN | User Story | From PRD `prd/04-epics-and-user-stories.md` |
| UF-NNN | User Flow | From PRD `prd/06-user-flows.md` |
| FEAT-NNN | Feature | From PRD `prd/02-feature-map-and-prioritization.md` |
| FR-NNN | Functional Requirement | From BRD `brd/07-functional-requirements.md` |

## Why Dynamic Scenarios Instead of Static Page Lists

Static page lists ("check /dashboard loads, check /settings loads") miss:
- **Multi-step workflows**: A project creation flow spans 5 pages and 12 button clicks — testing each page in isolation doesn't verify the flow works end-to-end
- **Entity state dependencies**: The Deploy page only works when a project is in `ready_to_deploy` status — a page-load test with a `draft` project passes trivially but misses the real functionality
- **Role-based access variations**: An admin sees different buttons than a viewer on the same page — testing with one role misses permission issues
- **Auth context transitions**: The signup flow transitions from unauthenticated to authenticated — testing only authenticated pages misses the transition

Dynamic scenarios solve this by generating test **sequences** that mirror real user journeys, with explicit auth context, entity prerequisites, and expected outcomes at each step.

## Scenario Types

### Type 1: Feature Scenarios (FS-NNN)
Complete end-to-end workflows that test a feature from start to finish.
- **Source**: User Flows (`prd/06-user-flows.md`) + User Stories (`prd/04-epics-and-user-stories.md`)
- **Structure**: Multi-step sequence following a user flow's happy path
- **Example**: "First-Time Signup → Onboarding → Dashboard" (UF-001)

### Type 2: Auth Context Scenarios (AS-NNN)
Test the same routes/features from different authentication states.
- **Source**: Information Architecture (`prd/07-information-architecture.md`) + Middleware analysis
- **Structure**: Matrix of routes × auth states (unauthenticated, each role)
- **Example**: "Visit /dashboard as unauthenticated → expect redirect; as starter → expect dashboard; as admin → expect admin features visible"

### Type 3: Entity State Scenarios (ES-NNN)
Test features that behave differently based on entity lifecycle state.
- **Source**: Feature Map (`prd/02-feature-map-and-prioritization.md`) + Schema analysis
- **Structure**: Matrix of features × entity states
- **Example**: "Project tabs at each status: draft (3 tabs enabled), configuring (4 tabs), casting (5 tabs), ..., deployed (9 tabs)"

### Type 4: Role Permission Scenarios (RS-NNN)
Test that RBAC rules are enforced correctly.
- **Source**: User Stories with role-specific criteria + Backend auth helpers
- **Structure**: Matrix of actions × roles (owner, admin, member, viewer)
- **Example**: "Delete project: owner=allowed, admin=allowed, member=denied, viewer=denied"

### Type 5: Negative Scenarios (NS-NNN)
Test error handling, validation, and edge cases.
- **Source**: Acceptance criteria error cases + Screen spec error states
- **Structure**: Trigger → expected error behavior
- **Example**: "Submit empty business plan → validation error shown; Upload 20MB file → file size error shown"

**Note**: SS-NNN (Smoke Scenario) is not a separate type — it is a re-numbered FS-NNN used in Stage 7V's smoke scope. See Step 9 below.

## Generation Algorithm

### Step 0: Filter by Implementation Status

Before generating scenarios, read `./plancasting/_progress.md` (if it exists) and identify which features are marked `✅ Done`. Only generate scenarios for completed features. Features marked `⬜ Not Started`, `🔧 In Progress`, `🔄 Needs Re-implementation`, or `⏸ Blocked` are EXCLUDED from the scenario matrix — do not generate scenarios for them. If `_progress.md` does not exist (pre-Stage 5 scenario generation for planning purposes), assume all features in the PRD are in scope.

### Step 1: Read All PRD Sources

Read these files and extract structured data:

| File | Extract |
|------|---------|
| `prd/02-feature-map-and-prioritization.md` | All FEAT-NNN with priority (P0-P3), dependencies, effort |
| `prd/04-epics-and-user-stories.md` | All US-NNN with acceptance criteria (Given/When/Then), persona, role requirements |
| `prd/06-user-flows.md` | All UF-NNN with entry/exit points, happy path steps, alternative paths, error cases |
| `prd/07-information-architecture.md` | All routes with auth requirements, navigation contexts, entity state prerequisites |
| `prd/08-screen-specifications.md` | All SC-NNN with component inventories, states, responsive behavior |

### Step 2: Read Codebase Sources

Supplement PRD data with actual implementation:

> **Prerequisite**: Before following Step 2, read your project's `plancasting/tech-stack.md` for the directory structure and adapt the paths below to your actual framework paths.

**Stack Adaptation**: The paths below use Next.js + Convex conventions. Replace with your project's equivalent paths per `plancasting/tech-stack.md` (e.g., `[backend-dir]/auth.*` instead of `convex/auth.ts`).

| Source | Extract |
|--------|---------|
| Route constants (e.g., `src/lib/constants.ts`) | All defined routes — may include routes not in PRD |
| Page files (`[PAGE_DIR]/**/page.*` (e.g., `src/app/**/page.tsx` for Next.js)) | All implemented pages — may differ from PRD routes |
| Middleware (`[MIDDLEWARE_PATH]` (e.g., `src/middleware.ts` for Next.js)) | PUBLIC_ROUTES array, auth redirect logic |
| Auth helpers (`[BACKEND_DIR]/auth.*` (e.g., `convex/auth.ts` for Convex)) | Role definitions, permission checks |
| Schema (`[SCHEMA_DIR]/schema.*` (e.g., `convex/schema.ts` for Convex)) | Entity status enums, role enums |
| Layout components | Navigation links, conditional tab logic |
| Hooks directory (`[HOOKS_DIR]/` (e.g., `src/hooks/` for Next.js)) | Available data operations per domain |
| E2E tests (`[TEST_DIR]/` (e.g., `e2e/` for Playwright)) | Existing test scenarios — avoid duplicating existing E2E coverage |

### Step 3: Build the Feature Dependency Graph

Create a directed graph of features and their dependencies. Dependencies are extracted from:
1. **Explicit dependency fields** in `prd/02-feature-map-and-prioritization.md` (if present — look for "Depends on" or "Prerequisites" columns)
2. **User story prerequisites**: If US-005 requires data from FEAT-002, then features behind US-005 depend on FEAT-002
3. **Implicit dependencies**: If FEAT-010 (Deploy) requires FEAT-005 (Implementation) to have run, infer the edge. **Inference algorithm**: (1) Read each feature's prerequisites in PRD 02-feature-map. (2) For each prerequisite, add an edge in the graph. (3) Read user stories — if a story for FEAT-A references data created by FEAT-B, add edge FEAT-B → FEAT-A (keyword detection: look for "created by", "requires", "depends on" in story text). (4) For features with lifecycle states, add edges based on state transitions (if FEAT-X produces state S and FEAT-Y is only valid in state S, add edge FEAT-X → FEAT-Y).

**Cycle detection**: After building the graph, topologically sort all features. If a cycle is detected (e.g., FEAT-A → FEAT-B → FEAT-C → FEAT-A):
1. Report as ERROR with the full cycle description (list all edges in the cycle and their evidence source — explicit PRD dependency, user story reference, or inferred from state transitions).
2. Attempt to resolve by checking if any inferred (non-explicit) edges in the cycle are false positives — if an edge was added by the inference algorithm (Step 3, item 3/4) but has weak evidence, remove it and re-attempt topological sort. Document the removal in the scenario matrix with a WARNING.
3. If all edges in the cycle have strong evidence (explicit in PRD dependency fields or user story prerequisites), halt and ask the operator: the cycle indicates a PRD inconsistency requiring human review. Do not silently break strongly-evidenced edges — removing a real dependency distorts the scenario execution order and may mask integration failures. If a cycle is detected, the operator has three options: (a) reorder features to break the cycle (preferred), (b) merge the cyclic features into a single combined scenario, or (c) accept the cycle and test in declared order with a documented note.

**Transitive reduction** (recommended): If FEAT-A → FEAT-B → FEAT-C and also FEAT-A → FEAT-C, the direct FEAT-A → FEAT-C edge is redundant (implied by transitivity). Remove it to simplify the graph. This reduces complexity for scenario ordering without losing coverage, and prevents unnecessary blocking cascades during execution (an early failure blocks fewer downstream scenarios).

The following is an illustrative example from a hypothetical project — your product's feature graph should be derived from the PRD feature map (`prd/02-feature-map-and-prioritization.md`).

```
FEAT-001 (Auth, P0)
  ↓ enables
FEAT-002 (Org Management, P0) + FEAT-003 (Project Management, P0)
  ↓ enables
FEAT-004 (Business Plan Input, P0) + FEAT-014 (Billing, P1)
  ↓ enables
FEAT-005 (Tech Discovery, P1) → FEAT-006 (Cloud Setup, P1) → FEAT-007 (Pipeline, P1)
  ↓ enables
FEAT-009 (Review, P1) → FEAT-010 (Code Browser, P2) → FEAT-011 (Audits, P1)
  ↓ enables
FEAT-012 (Deploy, P1) → FEAT-013 (Post-Launch, P2)
```

The Feature Dependency Graph (constructed in Step 3) determines:
- **Scenario ordering**: P0 features must be tested before P1 (they're prerequisites)
- **Entity state setup**: To test FEAT-012 (Deploy), you need a project that has passed through FEAT-004→005→006→007→009→011
- **Failure cascade**: If FEAT-001 (Auth) fails, ALL other scenarios are blocked

**Dependency edge definition**: A→B (A enables B) means: (1) B cannot be tested until A is working (prerequisite), (2) B's user flow/feature depends on A's data or state, (3) A must be tested before B in execution order.

### Step 4: Generate Feature Scenarios (FS-NNN)

For each User Flow (UF-NNN):

1. **Map to features**: Which FEAT-NNN does this flow exercise? If a user flow references a FEAT-NNN not found in the feature map, include the scenario but flag the discrepancy in the matrix output as a WARN-level note.
2. **Inherit priority**: Use the highest priority of the mapped features. If the feature is unmapped (FEAT-NNN not found in feature map), use the highest priority from referenced user stories as a fallback.
3. **Extract happy path**: Convert the Mermaid flowchart steps into a linear test sequence
4. **Identify auth context**: Does the flow start unauthenticated? Which role is needed?
5. **Identify entity prerequisites**: What entity states must exist before the flow starts?
6. **Map to screens**: For each step in the user flow, identify the screen specification (SC-NNN) from `prd/08-screen-specifications.md`. If a user flow step does not map to a screen spec (because the PRD does not specify UI for that step), note it as a gap: "UF-NNN step N maps to [business logic] but no SC-NNN available — infer screen structure from codebase analysis (Step 2)." Do not invent screen specs — only reference what exists in the PRD. If a screen spec (SC-NNN) exists in the PRD but is not referenced by any user flow, include it as a standalone page-load scenario to ensure full screen coverage.
7. **Identify buttons/actions**: What buttons are clicked, what forms are filled at each step?
8. **Define expected outcomes**: What should happen after each step? (page transition, data change, toast, redirect)

**Output format for each Feature Scenario**:
```markdown
### FS-NNN: [Scenario Name]
- **Source**: UF-NNN, FEAT-NNN, US-NNN
- **Priority**: P0 / P1 / P2 / P3
- **Auth Context**: unauthenticated → authenticated / role: [role] / admin
- **Prerequisites**: [entity states, data conditions]
- **Test User**: [which test user account to use]

| Step | Page (SC-NNN) | Action | Expected Result |
|------|--------------|--------|-----------------|
| 1 | /signup (SC-003) | Fill email, password, name. Check terms. Click "Create Account". | Redirect to /onboarding (SC-005). |
| 2 | /onboarding (SC-005) | Answer 3 quiz questions. Click "Continue". | Redirect to /dashboard (SC-010). |
| 3 | /dashboard (SC-010) | Verify personal org created. Verify Starter plan badge. | Dashboard loads with empty project list. |
| ... | ... | ... | ... |

**Acceptance Criteria Covered**: US-001 AC-1, AC-2, AC-3; US-005 AC-1
**Buttons Clicked**: "Create Account", "Next" ×3, "Get Started"
**Forms Filled**: Signup form (email, password, name), Onboarding quiz (3 selects)
**Negative Variants**:
- FS-NNN-E1: Submit with invalid email → validation error shown
- FS-NNN-E2: Submit with weak password → password strength error
- FS-NNN-E3: Submit with existing email → duplicate account error

**Negative Variants vs. Standalone Negative Scenarios**: Negative variants (E1–E3) are inline error-path tests within a parent FS scenario — they share the same prerequisite data and auth context. Standalone Negative Scenarios (NS-NNN from Step 8) are independent error tests not tied to a specific FS happy path. **Decision rule**: If the error case occurs during a Feature Scenario's happy path flow (e.g., "submit with invalid email during signup"), make it a variant (FS-NNN-EN). If it's a standalone error condition not tied to any FS flow (e.g., "manually crafted API request with invalid auth token"), make it a Negative Scenario (NS-NNN).

**Counting for Step 9 trimming**: Each negative variant (FS-NNN-EN) counts as a separate scenario. Example: FS-001 + FS-001-E1 + FS-001-E2 = 3 scenarios toward the cap. Each standalone NS-NNN also counts as 1 scenario.
```

### Step 5: Generate Auth Context Scenarios (AS-NNN)

Build an auth matrix from middleware analysis + route list:

```markdown
### Auth Context Matrix

| Route | Unauthenticated | Starter | Pro | Enterprise | Admin |
|-------|----------------|---------|-----|-----------|-------|
| / | 200 (landing) | 200 (landing) | 200 (landing) | 200 (landing) | 200 (landing) |
| /dashboard | 302 → /login | 200 (dashboard) | 200 (dashboard) | 200 (dashboard) | 200 (dashboard) |
| /settings/billing | 302 → /login | 200 (starter limits) | 200 (pro features) | 200 (enterprise) | 200 (all features) |
| /admin/dashboard | 302 → /login | 403 | 403 | 403 | 200 (admin panel) |
| /projects/[id]/deploy | 302 → /login | 200 (if owner) | 200 (if owner) | 200 | 200 |
```

For 6V: Test EVERY cell in the matrix.
For 7V: Test one representative cell per route: the primary role expected to access that route (e.g., /dashboard with 'Starter' role, /admin with 'Admin' role). Also test the unauthenticated column (all routes as unauthenticated user — expect redirect to /login or error page).

### Step 6: Generate Entity State Scenarios (ES-NNN)

For entities with lifecycle states (e.g., project status), generate a scenario per meaningful state:

The following is an illustrative example from a hypothetical project — your product's entity states should be derived from the schema analysis (Step 2).

```markdown
### ES-001: Project Pipeline Tab Availability

| Project Status | Expected Enabled Tabs | Expected Disabled Tabs |
|---------------|----------------------|----------------------|
| draft | Plan, Discovery | Setup, Progress, Review, Code, Audits, Deploy, Hub |
| configuring | Plan, Discovery, Setup | Progress, Review, Code, Audits, Deploy, Hub |
| casting | Plan, Discovery, Setup, Progress | Review, Code, Audits, Deploy, Hub |
| review_needed | Plan, Discovery, Setup, Progress, Review | Code, Audits, Deploy, Hub |
| building | Plan, Discovery, Setup, Progress, Review, Code | Audits, Deploy, Hub |
| quality_check | Plan, Discovery, Setup, Progress, Review, Code, Audits | Deploy, Hub |
| ready_to_deploy | Plan, Discovery, Setup, Progress, Review, Code, Audits, Deploy | Hub |
| deployed | All 9 tabs enabled | None |

**Test method**: Create or use projects in each status. Navigate to the project page. Verify correct tabs are enabled/disabled. Click each enabled tab — verify content loads. Click each disabled tab — verify no navigation occurs.
```

### Step 7: Generate Role Permission Scenarios (RS-NNN)

For each action that has role restrictions:

The following is an illustrative example — your product's roles and actions should be derived from the auth helper analysis (Step 2) and user stories.

```markdown
### RS-001: Project Actions by Role

| Action | Owner | Admin | Member | Viewer |
|--------|-------|-------|--------|--------|
| Create project | ✅ | ✅ | ✅ | ❌ |
| Edit project | ✅ | ✅ | ✅ (own) | ❌ |
| Delete project | ✅ | ✅ | ❌ | ❌ |
| Invite member | ✅ | ✅ | ❌ | ❌ |
| Change member role | ✅ | ✅ (not self) | ❌ | ❌ |
| Deploy | ✅ | ✅ | ❌ | ❌ |
| View project | ✅ | ✅ | ✅ | ✅ |

**Test method**: Log in as each role. Attempt each action. Verify allowed actions succeed and denied actions show appropriate error/disabled state.
```

### Step 8: Generate Negative Scenarios (NS-NNN)

Extract from acceptance criteria error cases and screen spec error states:

The following is an illustrative example — your product's form validations and error cases should be derived from acceptance criteria and screen specifications.

```markdown
### NS-001: Form Validation Errors

| Form | Field | Invalid Input | Expected Error |
|------|-------|--------------|---------------|
| Signup | email | "not-an-email" | "Please enter a valid email" |
| Signup | password | "123" | "Password must be at least 8 characters" |
| Create Project | name | "" (empty) | "Project name is required" |
| Business Plan | file | 20MB PDF | "File size must be under 10MB" |
| Invite Member | email | existing member | "User is already a member" |
```

### Step 9: Prioritize and Filter

**ID convention**: When Stage 7V filters Feature Scenarios for smoke testing, it re-numbers them as SS-NNN (Smoke Scenario) in the smoke scenario matrix. The original FS-NNN source ID is preserved in the 'Source' column for traceability.

Example: If 6V generates FS-001, FS-003, FS-007, FS-012 for P0 features, 7V renumbers them as SS-001, SS-002, SS-003, SS-004 (sequentially) with `Source=FS-NNN` preserved in the matrix.

**For 6V (Full)**:
- Generate ALL scenario types for ALL features (P0-P3)
- Total scenario count typically ranges from 50 to the verification scenario cap (default: 150 for 6V split across teammates at ~2–3 min per scenario; 15 for 7V single agent at ~2 min per scenario). Default cap: 150 scenarios for 6V, 15 for 7V. To override, update the `Verification scenario cap` value in `plancasting/tech-stack.md` § Model Specifications table. If `plancasting/tech-stack.md` § Model Specifications defines a 'Verification scenario cap', use that value instead. **Limit justification**: The scenario cap ÷ 3–4 teammates yields a manageable per-teammate load, at ~2–3 min per scenario, fitting within a single pipeline model session. If count is within the verification scenario cap, proceed to execution without trimming. If count exceeds the verification scenario cap, apply these trimming steps in order (each step removes lower-value scenarios first) until count drops to within the cap. Stop applying further steps as soon as count drops to within the cap.
  > **Note**: Steps 1–4 apply to 6V's full matrix. For 7V, the matrix is already filtered to P0+P1 — steps 1–4 are typically no-ops; start evaluation at step 5 (terminal condition).

  1. Remove P3 scenarios entirely (P3 = "nice-to-have" features; testing them is deferrable to post-launch)
  2. Remove P2 negative variants for non-critical features (error paths are important but less critical than happy paths; keep P0/P1 negative scenarios)
  3. Remove P2 Entity State and Role Permission scenarios, keeping only Feature Scenarios for P2 (ES/RS are detailed behavior tests; FS are end-to-end workflows with higher signal-to-noise ratio)
  4. Consolidate related Feature Scenarios that share the same feature into multi-step test scenarios (reduces redundancy without reducing feature coverage)
  5. **6V only** (does not reduce count — skip to step 6 for 7V): Split the test execution across additional teammates rather than reducing coverage further — parallelism before cutting tests. If teammate capacity is exhausted and count still exceeds the cap, proceed to step 6.
     - **7V note**: 7V is single-agent and cannot split. If the count is already ≤15 after initial P0+P1 filtering (P3 scenarios are never generated for 7V), no further trimming is needed — proceed directly to execution. Otherwise, continue to step 6.
  6. **Terminal condition** (use only if product scope is extremely large and timeline is constrained): If count still exceeds the verification scenario cap after all steps, cap at the limit by keeping ONLY Feature Scenarios (P0+P1+P2) + Auth Context (P0+P1) + Negative Scenarios for P0 features only. Remove all Role Permission and Entity State scenarios entirely. Document in the scenario matrix: "Coverage is intentionally limited due to scope — full E2E test suite recommended post-launch."

Apply trimming steps sequentially — check count after each step. **STOP** applying steps as soon as count is within the cap. This ensures maximal coverage retention.

**6V vs 7V trimming**: For 6V, PREFER splitting scenarios across more teammates (parallelism) over cutting scenarios. For 7V (single-agent), trimming is the only option — apply the steps above.

- Estimated time: 30–60 minutes for ≤50 scenarios; 60–120 minutes for 50–150 scenarios (scenarios split across 3–4 teammates in parallel)

**For 6V MODE: critical (P0+P1 Focus)**:
- Generate Feature Scenarios for P0 and P1 features only (skip P2/P3)
- Generate Auth Context Scenarios for P0 features only
- Generate Entity State Scenarios for P0 features only
- Skip Role Permission and Negative Scenarios entirely
- Reduces matrix size for time-constrained verification runs while retaining coverage of all launch-critical functionality
- Estimated time: 15-30 minutes

**For 7V (Smoke — Quick Production Validation)**:
- Generate Feature Scenarios for P0 features (all scenarios) + P1 features (top 5 by user impact) + any P2 features in the critical path (a P2 feature is "in the critical path" if it is a transitive prerequisite of any P0/P1 feature in the Feature Dependency Graph — e.g., a P2 feature that blocks P0/P1 flows). If a feature has no existing Feature Scenario, create a minimal happy-path scenario. **User impact scoring**: Assign points to each P1 feature and select the top 5 by score:
  - **Personas affected**: +1 per persona that has a user story referencing this feature (cap: 5 points)
  - **Flow frequency**: +1 if the feature appears in ≥3 user flows (UF-NNN), +0 otherwise
  - **Business criticality**: +2 if revenue-impacting (payments, billing, subscriptions), +0 otherwise
  - Total: 0–8 points. Select the top 5 P1 features by score. Ties broken by earlier position in PRD feature map.
  - Example: FEAT-005 (Billing): 3 personas + 4 flows + revenue = 3+1+2 = 6 points. FEAT-008 (Admin Panel): 1 persona + 1 flow + internal = 1+0+0 = 1 point.
- Generate Auth Context Scenarios for unauthenticated + 1 authenticated role only. For Auth Context, test one representative cell per route: the primary role expected to access that route (e.g., admin dashboard with admin, user settings with regular user), rather than testing every route × every role combination. Also test the unauthenticated column (all routes as unauthenticated user — expect redirect to /login or error page).
- Skip Entity State and Role Permission scenarios entirely (too detailed for smoke test).
- **Hard cap: 15 scenarios** (not a recommendation — a limit). This ensures 7V completes within 30–45 minutes total (at ~2 min per scenario + scenario generation + infrastructure checks). If trimming produces >15 scenarios, apply the terminal condition (step 6 in "Prioritize and Filter" above) to reduce to 15. If the product scope is so large that trimming to 15 omits critical P1 functionality, escalate to the operator — they may split verification across two 7V runs or extend the session time budget.
- **Selection criteria**: (1) P0 Feature Scenarios first (typically 5-8), (2) P1 Feature Scenarios if space permits (top 3-5 by user impact), (3) Auth Context: test /login, /dashboard, /settings for unauthenticated and 1 authenticated role. Do not include Negative Scenarios in smoke tests — they're too detailed for production validation.

### Step 10: Save the Scenario Matrix

Save the matrix to the appropriate path based on which stage is running:
- **Stage 6V**: `./plancasting/_audits/visual-verification/feature-scenario-matrix.md`
- **Stage 7V**: `./plancasting/_audits/production-smoke/smoke-scenario-matrix.md`

Validate all Mermaid syntax in the feature dependency graph: verify closed subgraph blocks, consistent arrow syntax, and properly quoted node labels containing special characters.

```markdown
# Feature Scenario Matrix
- **Generated**: [date]
- **Scope**: full / critical / smoke
- **PRD Sources**: [list of files read]
- **Code Sources**: [list of files scanned]

## Summary
- Feature Scenarios (FS): [n]
- Auth Context Scenarios (AS): [n]
- Entity State Scenarios (ES): [n]
- Role Permission Scenarios (RS): [n]
- Negative Scenarios (NS): [n]
- **Total scenarios**: [n]
- **Estimated time**: [n] minutes

## Feature Dependency Graph
[Mermaid diagram or text representation]
<!-- Validate all Mermaid syntax: verify closed subgraph blocks, consistent arrow syntax, and properly quoted node labels containing special characters. -->

## Scenarios by Priority
### P0 (must test)
[FS/AS/ES/RS/NS scenarios]

### P1 (should test)
[scenarios]

### P2 (test if time permits)
[scenarios]

### P3 (skip for now)
[scenarios]

## Scenario Details
[Full scenario definitions]
```

## Test User Account Requirements (Required Before 6V)

Ensure these test accounts exist with the following roles and plan tiers. These accounts are created during Stage 6F (Seed Data) or manually via the UI before running 6V. These are logical account identifiers — map them to actual test credentials (email/password pairs) stored in `.env.test` or equivalent, as configured during Stage 6F.

**Prerequisite**: Test accounts must exist before 6V starts. If Stage 6F created them, verify with `bun run seed:verify`. If 6F was not run or was skipped, create accounts manually via the signup flow or admin panel before starting 6V.

| Account Name | Plan Tier | Role | Purpose |
|---|---|---|---|
| TEST_USER_STARTER | Starter | member | Default for page-load checks (AS, ES) |
| TEST_USER_PRO | Pro | member | Default for feature flow execution (FS, NS) |
| TEST_USER_ENTERPRISE | Enterprise | member | Default for interaction/permission testing (RS) |
| TEST_USER_ADMIN | Any | admin | Admin panel verification |
| TEST_USER_MEMBER | Any | member (no ownership) | Non-owner permission testing |

Plan tiers listed above are illustrative defaults. Map to your project's actual plan tiers as defined in `prd/02-feature-map-and-prioritization.md` or `brd/14-business-rules-and-logic.md`. For products without plan tiers (e.g., desktop apps, IoT, single-tier products), use role-based distinctions instead (admin, editor, viewer, etc.).

## Mapping Scenarios to Teammates (6V Only)

When distributing scenarios to teammates:

**Note**: These teammate names are defaults. If your session uses different names, map scenario categories to teammates by domain (e.g., auth scenarios to the teammate handling authentication), not by name.

| Teammate | Scenario Types | Auth Context |
|----------|---------------|--------------|
| Teammate 1 (automated-page-verifier) | Auth Context (AS), Entity State (ES) — page load and component checks per auth/state | TEST_USER_STARTER |
| Teammate 2 (acceptance-criteria-verifier) | Feature Scenarios (FS), Negative Scenarios (NS) — multi-step flow execution | TEST_USER_PRO |
| Teammate 3 (visual-ai-reviewer) | **Reviewer only** — reviews screenshots from Teammates 1+2; performs visual/accessibility spot-checks (no new scenario execution, no scenarios from the matrix) | TEST_USER_STARTER |
| Teammate 4 (responsive-and-interaction-verifier) | Role Permission (RS), buttons/interactions from all FS — interaction testing | TEST_USER_ENTERPRISE |

Note: This teammate mapping applies to Stage 6V only. Stage 7V is a single-agent stage that executes all scenario types itself. Teammate names reference Stage 6V's default naming. If your 6V session uses different teammate names, map accordingly.

Test user assignments are primary defaults. Teammates testing Auth Context (AS) or Role Permission (RS) scenarios must use multiple test accounts to cover the auth matrix. All teammates should have access to all test user credentials.

**Scenario Ownership Rules**: (1) A scenario belongs to ONE teammate based on its PRIMARY test type. (2) If a Feature Scenario (FS) incidentally tests auth transitions, it still belongs to Teammate 2 (FS owner), not Teammate 1. (3) If a scenario PRIMARILY tests an entity state change, it belongs to Teammate 1 (ES owner). Resolve ambiguities by asking: "What is the failure mode we're most worried about?"

**Key rule**: Feature Scenarios are the PRIMARY test unit. Standalone page-load checks (simple "does this URL render without errors" tests) are SECONDARY — they fill gaps where no Feature Scenario covers a screen. Every screen SHOULD be covered by at least one Feature Scenario. If a screen has no scenario, add a standalone page-load check as a fallback.

## Scenario Execution Rules

1. **Run P0 scenarios first.** If a P0 scenario fails (e.g., Auth fails), mark ALL dependent scenarios as BLOCKED — don't waste time running them. More broadly, if ANY scenario fails, consult the Feature Dependency Graph to identify all transitively dependent scenarios and mark them as BLOCKED.
   - **Exception for 7V (smoke scope)**: For 7V, use the Feature Dependency Graph to identify immediate dependents only. If Auth (FS-001) fails, mark as BLOCKED only scenarios that explicitly list Auth as a direct prerequisite. Do not transitively cascade — 7V's goal is quick validation, not exhaustive dependency tracing (e.g., if Dashboard depends on User Profile which depends on Auth, and Auth fails, mark only User Profile as BLOCKED — Dashboard is not blocked because it has an independent failure mode worth testing).
2. **Use the Feature Dependency Graph** to determine execution order. A scenario for FEAT-012 (Deploy) cannot run before FEAT-003 (Project Management) passes.
3. **Share entity state across scenarios when possible.** If FS-003 creates a project and FS-005 needs a project, use the same project — don't recreate. But ensure scenarios that MODIFY entities use separate instances.
4. **Record button clicks and page transitions.** Every button clicked, every form filled, every page navigated to should be logged. This data feeds the link integrity and button action reports.
5. **Screenshot at each step, not just the final state.** Feature scenarios are multi-step — a failure at step 5 of 8 needs a screenshot at step 5.
6. **Map results back to acceptance criteria.** When a Feature Scenario step corresponds to a US-NNN acceptance criterion, record PASS/FAIL against that criterion.
7. **Execution log format** (per scenario step): `[Step N] [Page SC-NNN] | Action: [button/form] | Expected: [outcome] | Result: PASS/FAIL | Screenshot: [link]`

## Handling Flaky Scenarios

Re-run a failing scenario once. If it passes on re-run, mark as "Flaky — investigate timing" and include in the report's flaky tests section. If both runs fail, mark as failed. Do not retry more than once. **Stage distinction**: For 6V (dev environment), flaky scenarios are informational — flag for investigation but do not block the gate and are EXCLUDED from the pass/fail percentage calculation. They appear in a separate "Flaky Scenarios" section of the report. For 7V (production smoke), a flaky scenario is a FAIL — production instability must be resolved before re-running 7V. Note: Flaky handling differs by stage. In 6V, flaky scenarios are excluded from the pass-rate denominator (informational). In 7V, flaky scenarios count as FAIL (production must be deterministic). This is intentional — see execution-guide.md § Gate Decision Outcomes. Don't exclude flaky scenarios from the matrix, but flag them for developer attention. Flaky scenarios often indicate:
1. Missing waits/polling in the test (add `expect.poll()` or `expect.toPass()` for eventually-consistent backends)
2. Race conditions in the app (add explicit wait states)
3. External service latency (mock external services for consistent timing)

## Scenario De-duplication Rules

Two scenarios should be **consolidated** if: (1) They exercise the exact same steps in the same order, (2) They have the same success criteria, (3) They test the same roles/auth contexts.

Separate scenarios are **justified** if: (1) They test different roles (e.g., owner vs member creating a project), (2) They test different entity states (e.g., project in draft vs in progress), (3) They test different error paths. When in doubt, keep separate scenarios and let the lead consolidate during optimization.

## Scenario Matrix Audit Checklist (Before Passing to Teammates)

Before distributing the matrix, the lead should verify:
1. Every P0 feature has at least one Feature Scenario
2. Every route in Information Architecture is covered by at least one Auth Context Scenario
3. Entity State Scenarios cover all meaningful lifecycle states (e.g., draft, in_progress, done, error)
4. Role Permission Scenarios cover all role combinations mentioned in user stories
5. Total scenario count is within the allocated execution time budget (6V: 30-120 min depending on scenario count, 7V: 15-45 min)
6. All scenario prerequisites (entity states, test accounts) can be set up with existing seed data or UI flows
7. `_progress.md` was checked — always read the LATEST version of `_progress.md` at scenario generation time (Stage 5B may have changed feature statuses after Stage 5 completion). Features marked `⬜ Not Started`, `🔄 Needs Re-implementation`, `🔧 In Progress`, or `⏸ Blocked` are EXCLUDED from the scenario matrix (no scenarios generated for them). Only `✅ Done` features have scenarios generated. If `_progress.md` does not exist (e.g., running before Stage 5), derive the feature list from `plancasting/prd/02-feature-map-and-prioritization.md` instead. Note: 6V should only run after Stage 5B completes. If `_progress.md` does not exist, this likely indicates a pipeline sequence error — verify Stage 5 was run before proceeding.
