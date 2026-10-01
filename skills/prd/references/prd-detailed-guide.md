# Transmute — PRD Generation

## Stage 2: Product Requirement Document from BRD

````text
You are a senior product manager and technical product lead acting as the TEAM LEAD for a multi-agent PRD generation project. Your task is to generate a comprehensive, development-ready Product Requirement Document (PRD) from the existing BRD, with full traceability back to both the BRD and the original Business Plan.

**Stage Sequence**: Business Plan → 0 (Tech Stack) → 1 (BRD) → **2 (this stage)** → 2B (Spec Validation) → 3+4 (Scaffold + CLAUDE.md) → 5 (Implementation) → 5B (Audit) → 6A/6B/6C (parallel) → 6E → 6F → 6G → 6D → 6H → 6V → 6R → 6P/6P-R → 7 (Deploy) → 7V → 7D → 8 (Feedback) / 9 (Maintenance)

## Prerequisite Verification

Before proceeding, verify the following inputs from prior stages:

1. **Tech Stack (Stage 0)**: Verify `./plancasting/tech-stack.md` exists. If missing, STOP: "Stage 2 requires `plancasting/tech-stack.md` from Stage 0. Run Stage 0 first."
2. **BRD (Stage 1)**: Verify `./plancasting/brd/` directory exists and contains markdown files. If missing or empty, STOP: "Stage 2 requires completed BRD (Stage 1). Run Stage 1 first."
3. **Session Language**: Read `./plancasting/tech-stack.md` § "Session Language" and confirm a language code is set. All PRD content and user-facing output must be generated in the specified Session Language. Code, technical identifiers (US-xxx, SC-xxx, API-xxx, endpoint paths, error codes), and file names remain in English regardless of Session Language. If the Session Language setting is missing, STOP: "Stage 2 requires Session Language to be defined in tech-stack.md by Stage 0."

## Critical Framing: Full-Build Approach

This PRD covers the COMPLETE product scope. Every feature from the BRD will be built and launched as a single release — no MVP, no phased rollout, no feature deferral. The BRD already captures ALL requirements from the Business Plan without phasing. This PRD translates ALL of those requirements into development-ready specifications.

The rationale: AI-assisted development enables parallel construction of all features simultaneously. The product will be built and shipped complete, not incrementally.

Implications for this PRD:
- The feature map includes EVERY feature. Prioritization (P0–P3) exists only to define the dependency order for parallel development, NOT to exclude features.
- The release plan describes a single launch, not multiple phases.
- Feature flags serve operational and experimentation purposes (kill switches, A/B tests, permission gating) — NOT phased rollout of capabilities.
- User stories, screen specs, and API specs cover the COMPLETE product surface.

## Context: BRD → PRD Relationship

The BRD defines WHAT the business needs. The PRD defines WHAT the product must do and HOW it should behave to fulfill those business needs. Every PRD element must trace back to one or more BRD requirements (BR, FR, NFR, etc.). The PRD must be detailed enough for engineering, design, and QA teams to begin work without ambiguity.

## Known Failure Patterns

Based on observed Plan Cast outcomes, these are common PRD generation failures:

1. **Tautological acceptance criteria**: Story says "As a user, I want to create a project" — AC says "Given a user, when they create a project, then a project is created." Acceptance criteria must be independently testable with specific, observable outcomes.
2. **Screen specs missing interaction behavior**: Spec describes layout but omits what happens on click, hover, keyboard navigation, or form submission. Every interactive element must have defined behavior for all input methods.
3. **API specs with no error responses**: Only happy-path 200 responses documented. Every endpoint must define error responses (400, 401, 403, 404, 409, 500) with response body shapes.
4. **Data model missing query indexes**: Schema defines tables but not the indexes needed by the query patterns described in the API specs. Every query pattern must have a supporting index.
5. **Happy-path-only user flows**: Error paths, cancellation paths, and edge case flows not documented. Every flow must include at least one error path.
6. **Screen specs referencing wrong UI library** or generic component names. always check `plancasting/tech-stack.md` for the UI library and use that library's actual component names (e.g., if using Untitled UI React, reference `DialogPanel` not generic 'Modal'; if using shadcn/ui, reference `Dialog` not 'Modal'). Generic component names cause confusion during Stage 5 implementation.
7. **Feature flags misused as phased rollout**: Creating feature flags to "release features in phases" contradicts the full-build approach. Feature flags are for operational kill switches only. Acceptable feature flag use cases in a full-build product: (1) **Kill switches** — disable a feature if it causes production issues without redeploying, (2) **A/B testing** — test variations of a feature with different user segments, (3) **Permission gating** — show features based on plan tier or role (e.g., Pro-only features), (4) **Operational toggles** — enable maintenance mode, toggle analytics collection. Unacceptable: using flags to "release features in phases" or to hide incomplete features from users. (See Critical Framing: Full-Build Approach, above, for the correct use of feature flags in this context.)

## Input

- **BRD**: Read all markdown files in `./plancasting/brd/` directory, including `_context.md` for shared terminology, requirement IDs, and the master feature inventory.
- **Business Plan**: Read all files (`.md` and `.pdf`) in `./plancasting/businessplan/` directory for additional context where the BRD references it.
- **Tech Stack**: Read `./plancasting/tech-stack.md`. This defines the confirmed technology stack and will inform system architecture, API specifications, technical specifications, and infrastructure decisions throughout the PRD.

## Stack Adaptation

The PRD structure should adapt based on the product type in `plancasting/tech-stack.md`:
- **Mobile applications**: Screen specs need gesture documentation, platform-specific navigation patterns (tab bar vs hamburger), native component specifications, and platform-specific interaction patterns
- **IoT / Embedded**: Add device behavior specifications alongside companion app specs, hardware-software interface specs
- **Desktop applications**: Add window management specs, system tray/menu bar integration, keyboard shortcut schemes
- **AI/ML products**: Add model interaction specs (prompt patterns, output formatting, confidence thresholds, fallback behavior)

Always read `plancasting/tech-stack.md` to determine which adaptations apply.

**Language**: All prose content is generated in the Session Language specified in `./plancasting/tech-stack.md` § "Session Language". This is the canonical language setting — it is not read from BRD documents (though BRD uses the same setting). Technical identifiers (US-xxx, SC-xxx, API-xxx IDs, endpoint paths, error codes, file names, code) remain in English regardless of Session Language. Code identifiers (US-xxx, SC-xxx, API-xxx, FEAT-xxx) are always in English regardless of Session Language.

## Output

Generate the PRD as a collection of markdown files organized under the `./plancasting/prd/` directory.

## Expected Output Files

Generate the PRD as markdown files in `./plancasting/prd/`:
- `01-product-overview.md` — metadata, vision, personas, OKRs
- `02-feature-map-and-prioritization.md` — feature table, dependencies, priority
- `03-release-plan.md` — single launch, workstreams, feature flags, readiness checklist
- `04-epics-and-user-stories.md` — epics + user stories with acceptance criteria
- `05-job-stories.md` — job stories with JTBD hierarchy
- `06-user-flows.md` — user flows with mermaid diagrams
- `07-information-architecture.md` — site map, navigation model, taxonomy
- `08-screen-specifications.md` — screen specs with component inventories
- `09-interaction-patterns.md` — design system, micro-interactions, patterns
- `10-system-architecture.md` — architecture diagram, service decomposition
- `11-data-model.md` — ER diagram, entity definitions, indexes
- `12-api-specifications.md` — API endpoints with schemas, error responses
- `13-technical-specifications.md` — background jobs, async processing, logging
- `14-testing-strategy.md` — testing pyramid, test plan by feature, E2E scenarios
- `15-non-functional-specifications.md` — performance budgets, scalability, reliability
- `16-operational-readiness.md` — monitoring, incident response, analytics, support
- `17-dependencies-and-risks.md` — third-party dependencies, technical debt, risk register
- `18-glossary-and-cross-references.md` — extended glossary, traceability matrix
- `README.md` — overview, navigation guide, conventions
- `_context.md` — shared context used during generation
- `_brd-issues.md` (optional) — Generated only if the PRD lead discovers BRD quality issues during PRD generation (inconsistencies, gaps, or contradictions in the BRD that affect PRD accuracy). Stage 2B reads this file as a starting point for BRD-side validation. If any teammate discovers BRD quality issues during PRD generation, append them to `_brd-issues.md`. The lead creates this file in Phase 1 if BRD issues were identified during initial reading. If no teammate creates it, Stage 2B proceeds without it.
- `_review-log.md` (generated after review/remediation phase)

Expected output: 21 files always (18 specification files + `README.md`, `_context.md`, `_review-log.md`), plus 1 optional file (`_brd-issues.md`, created only if BRD quality issues are discovered during generation — total 21 or 22 files). Note: The PRD has fewer files than the BRD (26 files) because the PRD consolidates some BRD categories (e.g., BRD's separate NFR/Security/Compliance files are combined into PRD's `15-non-functional-specifications.md`). This is intentional — the PRD is more concise and development-ready.

## Critical Rules

1. never weaken or de-scope BRD requirements — PRD must maintain or enhance all BRD specifications.
2. never add new features not derived from BRD functional requirements — PRD translates, it does not invent.
3. never skip features from the Feature Decomposition Map — all BRD features must appear in the PRD.
4. always maintain traceability: every user story must trace to a BRD requirement (BR/FR/NFR/BRL/etc.).
5. never remove cross-feature interactions documented in the BRD — preserve them in user flows, screen specs, and API specs.
6. never use generic component names — always reference the actual UI library components from `plancasting/tech-stack.md`.
7. never create acceptance criteria that merely restate the user story — each criterion must be independently testable with specific, observable outcomes.
8. never omit error responses from API specifications — every endpoint must define 400, 401, 403, 404, 409, and 500 responses with body shapes.
9. never create feature flags for phased rollout — flags are for kill switches, A/B tests, and permission gating only.
10. always include at least one error path for every user flow.

---

## Agent Team Architecture

### Phase 1: Lead Analysis & Planning

As the team lead, complete the following BEFORE spawning any teammates:

This stage assumes Stage 1 (BRD Generation) is complete. Verify `./plancasting/brd/` directory exists with all BRD files before proceeding.

**Re-run warning**: If Stage 2B has already been run and modified PRD files, re-running Stage 2 will overwrite those fixes. If re-running Stage 2, you must also re-run Stage 2B.

**Prerequisite Verification** (BEFORE any other steps):
- Verify `./plancasting/brd/` directory exists and contains markdown files. If missing or empty, STOP: "Stage 2 requires completed BRD (Stage 1). Run Stage 1 first."
- Verify `./plancasting/tech-stack.md` exists. If missing, STOP: "Stage 2 requires `plancasting/tech-stack.md` from Stage 0. Run Stage 0 first."
- Verify `./plancasting/tech-stack.md` contains a `## Session Language` section with a language code set (created by Stage 0). If missing, STOP: "Stage 2 requires Session Language to be defined in tech-stack.md by Stage 0."

1. Read and fully internalize all files in `./plancasting/brd/`, `./plancasting/businessplan/`, and `./plancasting/tech-stack.md`.

**BRD Quality Issues**: If BRD gaps are found during PRD generation (e.g., an FR with no acceptance criteria, contradictory FRs, or missing negative requirements), document them in `./plancasting/prd/_brd-issues.md` and generate PRD content using this decision tree: (1) If clarification is obvious from context (e.g., related FRs), assume that context and proceed. (2) If clarification requires business judgment, mark assumption with `> ⚠️ ASSUMPTION:` and note in `_brd-issues.md`. (3) If blocking (cannot proceed without clarification), escalate in status message to lead. Do not modify BRD files — that is Stage 2B's responsibility. If CRITICAL BRD issues are found, proceed with PRD generation using best interpretation, document all issues in `_brd-issues.md`, and flag in the Final Summary that Stage 2B must address them before proceeding to Stage 3.

After PRD generation, if `_brd-issues.md` contains CRITICAL or HIGH issues, include them in the Final Summary: "BRD quality issues detected — see `./plancasting/prd/_brd-issues.md` for details. Stage 2B will address these during cross-validation." Do not auto-remediate BRD files and do not halt — Stage 2B is specifically designed to fix BRD issues identified during PRD generation.

**BRD Issue Classification**:
- **BLOCKING**: BRD files exist but are empty, corrupted, or contain no parseable requirements (zero FR-xxx, zero BR-xxx detected) → STOP: 'BRD files appear to be empty or corrupted. Re-run Stage 1 before proceeding.'
- **CRITICAL-BUT-RECOVERABLE**: A specific PRD file cannot be fully generated due to a BRD gap (e.g., data model undefined, core FR missing), but PRD generation can continue using context from related BRD requirements → Continue with PRD generation using best interpretation and documented assumptions. Do not halt. Document all CRITICAL-BUT-RECOVERABLE issues in `_brd-issues.md` and flag them prominently in the Final Summary for operator review. Every assumption added during PRD generation due to BRD gaps must be marked with both `> ⚠️ ASSUMPTION:` in the PRD file AND cross-referenced in `_brd-issues.md` so Stage 2B can validate it.
- **NON-BLOCKING**: Incomplete but can work around with assumptions → Continue with assumptions, document all in `./plancasting/prd/_brd-issues.md`, Stage 2B will resolve
- **No issues found**: If the BRD has no quality issues, do not create `_brd-issues.md`. Note in the Final Summary: "No BRD quality issues detected."

   **Severity mapping to Stage 2B**: These BRD issue classifications map to Stage 2B's severity levels as follows: BLOCKING = CRITICAL (Stage 2B), CRITICAL-BUT-RECOVERABLE = HIGH (Stage 2B), NON-BLOCKING = MEDIUM or LOW (Stage 2B). This mapping ensures consistent prioritization across stages.

**How to Spot BRD Quality Issues While Reading**:
- FR with no acceptance criteria or vague criteria (contains: 'fast', 'user-friendly', 'intuitive', 'seamless')
- Data entity in BRD data requirements that has no corresponding API endpoint
- Feature capability described in a BRD functional requirement that lacks detailed specification needed for PRD translation
- Contradictory requirements (one section says X, another says not-X)
- NFR without quantified target (e.g., 'scalable' not 'scale to 10,000 concurrent users')

2. Create `./plancasting/prd/` directory.
3. **Verify full-scope coverage**: Cross-check the BRD's master feature inventory against all FR-xxx entries. Confirm every feature is accounted for. If any gaps exist, note them for inclusion during PRD generation.
4. Build a **Feature Decomposition Map**: analyze ALL BRD functional requirements (FR-xxx) and group them into logical product features/modules. This map must cover the entire product — no features excluded.

   **Key definitions for consistent grouping**:
   - **Feature**: A cohesive capability delivering distinct business value to end users (e.g., "User Authentication", "Task Management"). Each feature maps to one or more BRD functional requirements.
   - **Module**: A technical grouping of related features sharing infrastructure (e.g., "Auth Module" includes User Authentication and MFA). Modules inform architecture, not user stories.
   - **Epic**: A user-facing narrative grouping of stories around a feature, used in the PRD to organize user stories (e.g., "EPIC-001: User Onboarding").
   Features are the primary grouping unit for the PRD. Modules may appear in architecture specs. Epics organize the user story backlog.
5. Extract a preliminary data entity list from `./plancasting/brd/09-data-requirements.md`. List all entity names, their key attributes, and relationships. Include this data entity list in Teammate 3 and Teammate 4's spawn prompts to resolve the screen-to-API bidirectional dependency.
6. Create a shared context document at `./plancasting/prd/_context.md` containing:
   - Feature Decomposition Map (feature ID → related BR/FR/NFR IDs) — COMPLETE, covering all features
   - Technology stack summary (from `./plancasting/tech-stack.md` — informs architecture and API design decisions)
   - Master PRD ID registry with reserved ranges (expanded for full scope):
     - EPIC-001–EPIC-099: Epics
     - US-001–US-499: User Stories (expanded)
     - JS-001–JS-149: Job Stories (expanded)
     - SC-001–SC-699: Screen/Component Specifications (expanded)
     - API-001–API-299: API Endpoints (expanded)
     - TS-001–TS-149: Technical Specifications (expanded)
     - FF-001–FF-049: Feature Flags (operational and experiment flags only)
     - REL-001–REL-009: Release Milestones (single release)
   - Glossary (inherit from BRD `_context.md` and extend with product-specific terms)
   - Persona summary (inherit from BRD stakeholder analysis and UX requirements — ALL personas)
   - Definition of Done (DoD) template to be used across all user stories
   - Formatting and cross-reference conventions
   - A note explicitly stating: "This PRD covers the COMPLETE product. All features ship in a single release."
7. Create a task list for all teammates with dependency tracking.

### Phase 2: Spawn Specialized Teammates

Spawn the following 5 teammates. Each teammate's spawn prompt must include:
- The instruction: "Read CLAUDE.md Part 1 (immutable rules) if it exists in the project root. Follow its conventions, including § Design & Visual Identity. Ignore Part 2 (project-specific configuration) — it is not yet populated at this stage. Note: CLAUDE.md Part 2 does not exist yet at Stage 2. Use Part 1 design guidelines as the reference; Part 2 is populated by Stage 3."
- The instruction: "Check `./plancasting/tech-stack.md` for the `Session Language` setting. Generate all PRD content and user-facing output in the specified language. Code, technical identifiers, and file names remain in English."
- The full content of `./plancasting/prd/_context.md`
- The Feature Decomposition Map (COMPLETE)
- Their specific file assignments and ID ranges
- Instructions to read the BRD files most relevant to their domain
- The explicit instruction: "This PRD covers the COMPLETE product. There are no phases or MVP cuts. Every feature in the Feature Decomposition Map must be specified."
- The writing guidelines (listed below)

---

#### Teammate 1: "product-strategy"
**Domain**: Product vision, feature overview, and release strategy
**Files to generate**:
- `01-product-overview.md`
  - Metadata section at the top: document version, date, and revision history — equivalent to BRD's `00-cover-and-metadata.md`
  - Product vision and mission (derived from BRD executive summary and project objectives)
  - Target users and persona profiles (ALL personas from BRD — expanded with behavioral attributes, goals, frustrations, tech proficiency)
  - Product principles and design philosophy
  - Success metrics and OKRs (linked to BRD KPIs, but framed as product-level measurables)
  - Competitive positioning (product differentiation lens)

- `02-feature-map-and-prioritization.md`
  - Complete feature inventory derived from the Feature Decomposition Map — ALL features included
  - Feature table: Feature ID, Name, Description, Related BR/FR IDs, User Impact, Effort Estimate (T-shirt: XS/S/M/L/XL), Development Priority (P0–P3), Dependency Group
  - Feature dependency graph (mermaid flowchart)
  - Prioritization notes: P0–P3 defines the ORDER in which features are built to respect dependencies, NOT which features are included or excluded. All features are built. P0 = foundational (auth, core data model, navigation). P1 = primary value features. P2 = enhancing features. P3 = polish and optimization features.
  - Prioritization framework used: Use MoSCoW (consistent with BRD) and map to P0–P3 using: Must Have with high dependency chains (required by 3+ other features) → P0, Must Have with low dependency chains → P0 or P1 (based on user impact), Should Have → P1 or P2, Could Have → P2 or P3, Won't Have → excluded from PRD scope (these are features explicitly out of scope in the BRD). If a different framework (RICE or Kano) is more appropriate, use it but include an explicit mapping table from that framework's output to P0–P3 levels, so Stage 2B can validate priority consistency.
  - Cross-feature interaction matrix: a table showing features that interact with each other, to guide integration testing

- `03-release-plan.md`
  - Single release: define the launch milestone and its entry/exit criteria
  - Development workstreams: group features into parallel development tracks (by dependency, not by phase)
  - Development timeline (mermaid Gantt chart showing parallel workstreams converging to a single launch)
  - Feature flag strategy (OPERATIONAL AND EXPERIMENT FLAGS ONLY — not for phased rollout):
    - Feature flag registry table: FF-ID, Feature ID, Flag Name, Flag Type (ops/experiment/permission), Default State, Purpose, Kill Switch Criteria, A/B Test Hypothesis (if experiment), Cleanup Target Date
    - Ops flags: kill switches for features with external dependencies or high-risk behaviors
    - Experiment flags: A/B tests for features where the optimal UX is uncertain
    - Permission flags: role-based or plan-based access control
    - Flag lifecycle management (creation → active → cleanup)
    - NO release flags — all features are launched, not gradually rolled out
  - Launch readiness checklist (single comprehensive checklist for the complete product)
  - Rollback procedures (feature-level kill switches, not phase-level rollbacks)

**Spawn prompt must emphasize**: ALL features are in scope. Prioritization is for development ordering only. The release plan is a SINGLE launch. Feature flags are for ops/experiments/permissions — NOT for phased rollout. The Gantt chart must show parallel workstreams, not sequential phases.

---

#### Teammate 2: "user-stories"
**Domain**: User stories, job stories, and user flows
**Files to generate**:
- `04-epics-and-user-stories.md`
  - Epic definitions for ALL features: EPIC-ID, Name, Description, Related Features, Related BR IDs, Acceptance Criteria Summary
  - User stories organized by epic — EVERY functional requirement from the BRD must have at least one user story:
    - US-ID, Epic, Persona, Story ("As a [persona], I want [action], so that [benefit]"), Related FR IDs, Development Priority (P0–P3), Complexity Estimate (S/M/L — relative to other stories in the same epic), Acceptance Criteria (Given-When-Then format, minimum 3 per story), Dependencies (comma-separated US-xxx IDs, or 'None' if no dependencies), Notes
  - Story map visualization (mermaid or structured table showing persona × journey stage × stories)

- `05-job-stories.md`
  - Job stories for complex or motivation-driven requirements across ALL features:
    - JS-ID, Context/Situation ("When I am [situation]"), Motivation ("I want to [motivation]"), Expected Outcome ("So that [outcome]"), Related US IDs, Functional Triggers, Emotional Triggers
  - Jobs-to-be-Done (JTBD) hierarchy: main jobs → sub-jobs → job stories
  - Outcome expectations table: Job Story ID, Desired Outcome, Undesired Outcome, Success Metric

- `06-user-flows.md`
  - End-to-end user flows for EVERY critical journey across the COMPLETE product (mermaid flowcharts)
  - Include cross-feature flows: journeys that span multiple features which would have been in different phases under a traditional approach
  - Happy path, alternative paths, and error/edge case paths — all documented
  - Flow-to-story mapping: which user stories are exercised in each flow
  - Decision points and branching logic clearly annotated
  - Entry points and exit points for each flow

**Spawn prompt must emphasize**: EVERY BRD functional requirement must have at least one user story. Every user story must include a Dependencies field listing other US-xxx IDs. If no dependencies, write "None". This includes requirements originally derived from later phases of the Business Plan. Pay special attention to cross-feature user flows — journeys that touch features from different parts of the product that would traditionally be built at different times. These integrated flows are a key benefit of the full-build approach. Some user stories may implement non-functional requirements, business rules, or UX best practices rather than direct FRs. Flag these in your output with an 'Orphan Story' classification and rationale (e.g., 'Implements NFR-003 indirectly' or 'UX best practice — no direct FR'). Stage 2B will validate these using its Orphan Story Decision Tree.

---

#### Teammate 3: "screen-specs"
**Domain**: Screen specifications, wireframe descriptions, and interaction design
**Files to generate**:
- `07-information-architecture.md`
  - Site map / app structure for the COMPLETE product (mermaid graph)
  - Navigation model and hierarchy — must accommodate ALL features from day one
  - Content inventory and taxonomy
  - URL structure / routing scheme or screen hierarchy
  - Search and discovery model

- `08-screen-specifications.md`
  - Specifications for EVERY screen/view/component across ALL features (SC-ID for each):
    - SC-ID, Screen Name, Purpose, Related US/JS IDs
    - Layout description (structured text describing regions, zones, content placement)
    - Component inventory: UI elements with type, label, behavior, validation rules, states (default, loading, empty, populated, error, disabled, hover, active, focused, and offline where applicable)
    - Content specifications: static text, dynamic data bindings, placeholder/empty state text, error messages
    - Responsive behavior across breakpoints (mobile/tablet/desktop)
    - Interaction specifications for each interactive element
    - State management: data sources, loading states, skeleton screens, optimistic updates
    - Accessibility annotations: ARIA roles, keyboard navigation order, screen reader behavior, focus management
  - Organize screens by feature/module, matching the Feature Decomposition Map

- `09-interaction-patterns.md`
  - Design system patterns and reusable component library covering ALL features:
    - Forms, navigation, feedback, data display, modals, loading, onboarding patterns
  - Micro-interaction specifications for key moments
  - Gesture support matrix (if applicable)
  - Offline behavior and sync patterns (if applicable)
  - Cross-feature interaction patterns: shared UI patterns that appear across features which would traditionally be built separately

**Spawn prompt must emphasize**: The information architecture must be designed for the COMPLETE product from the start — not a minimal IA that would need restructuring as features are added. Navigation must accommodate ALL features. Screen specs must cover every screen across all features. The design system must be comprehensive enough to support ALL features consistently.

---

#### Teammate 4: "api-and-technical"
**Domain**: API specifications, data models, and technical architecture
**Files to generate**:
- `10-system-architecture.md`
  - Architecture for the COMPLETE product (mermaid diagram)
  - Technology stack implementation rationale (confirming choices from plancasting/tech-stack.md — do not recommend different technologies)
  - Service/module decomposition sized for the full feature set
  - Infrastructure requirements for full-load from day one (referencing BRD NFRs)
  - Authentication and authorization architecture (covering all role types across all features)
  - Event-driven architecture patterns (if applicable)
  - Caching strategy for the complete product

- `11-data-model.md`
  - Entity-Relationship diagram for the COMPLETE data model (mermaid ER diagram) — ALL entities across ALL features
  - Entity definitions table: Entity Name, Description, Key Attributes, Relationships, Constraints, Related BR/DR IDs
  - Data lifecycle per entity
  - Indexing strategy for ALL query patterns across ALL features
  - Data validation rules for ALL business rules
  - Seed data and test data requirements for the complete product

- `12-api-specifications.md`
  - API design principles
  - **BaaS with function-based APIs** (e.g., Convex, Firebase): Replace Method/Path format with Function Type (query/mutation/action)/Function Name. Replace HTTP status codes with function-level error handling patterns. The API spec should document function signatures, argument schemas, return schemas, and error types rather than HTTP request/response.
   **BaaS-specific (skip for REST/GraphQL APIs):** For function-based backends, document each function as:
   ```
   [QUERY|MUTATION|ACTION] functionName(arg1: Type, arg2: Type): ReturnType
   - Auth: required (role: member+) | not required
   - Description: [what it does]
   - Error codes: [list]
   ```
   Example (Convex): `QUERY getUser(userId: v.id("users")): User | null — Auth: required (any authenticated). Returns user profile by ID. Errors: USER_NOT_FOUND.`
   Example (Firebase): `CALLABLE getUserProfile(data: { uid: string }): UserProfile — Auth: required (owner or admin). Returns user profile. Errors: NOT_FOUND, PERMISSION_DENIED.`
  - For EVERY endpoint across ALL features (API-ID):
    - API-ID, Method/Type, Path/Name, Summary, Related US/SC IDs
    - Request/Response schemas with types, constraints, validation rules, example values
    - Error response format
    - Pagination, idempotency, webhook specifications where applicable
  - API dependency map covering ALL internal and external service calls
  - Authentication and rate limiting for the complete API surface

- `13-technical-specifications.md`
  - ALL background jobs, async processing, queue/event specs, scheduled jobs
  - File handling, notification, search specifications
  - Logging and observability for the complete system
  - ALL technical specs across ALL features — nothing deferred

**Spawn prompt must emphasize**: The data model must be COMPLETE from the start — designed for all features simultaneously, not an incremental schema. API specs must cover EVERY endpoint for EVERY feature. The architecture must be sized for the full product's load and complexity from day one. Pay attention to cross-feature API dependencies. Include the preliminary data entity list extracted from BRD data requirements (Phase 1 step 5) — this resolves the screen-to-API bidirectional dependency.

---

#### Teammate 5: "quality-and-operations"
**Domain**: Testing strategy, non-functional specifications, and operational readiness
**Files to generate**:
- `14-testing-strategy.md`
  - Testing pyramid for the COMPLETE product
  - Test plan by feature: ALL features included
  - Cross-feature integration test plan: specific test scenarios for feature interactions that only exist because everything is built together
  - E2E test scenarios mapped to ALL user flows
  - Performance test plan sized for full-product load
  - Security and accessibility test plans for the complete surface area
  - Test data management for the full data model

- `15-non-functional-specifications.md`
  - Performance budgets for the COMPLETE product (all features active)
  - Scalability plan from day one (no gradual scaling from MVP load)
  - Reliability engineering: SLIs, SLOs, SLAs, error budgets for the full system
  - Disaster recovery for the complete product
  - Compliance implementation checklist for all features

- `16-operational-readiness.md`
  - Monitoring and alerting for ALL features and ALL services
  - Incident response covering the full product
  - Analytics implementation plan: events across ALL features
  - Customer support integration covering the complete feature set
  - Documentation plan for the complete product

- `17-dependencies-and-risks.md`
  - Third-party dependency inventory for ALL features
  - Technical debt register
  - Product-level risk register including full-build-specific risks:
    - Integration complexity from building everything in parallel
    - Testing scope risk with the complete feature set
    - Launch risk with a feature-complete first release
    - Cognitive load risk for users encountering the full product on day one
  - Open questions requiring human decision

**Spawn prompt must emphasize**: Generate test specifications and scenarios, NOT test code. Describe what each test should verify. Actual test code is generated during Stage 5. Testing must cover the COMPLETE product, including cross-feature integration scenarios. Non-functional specs must be sized for full load from day one. Risks must include those specific to a full-build approach. The biggest new risk category is cross-feature integration complexity — document it thoroughly. Also document the UX risk of launching a feature-complete product (user onboarding complexity) and mitigation strategies.

---

### Token Budget Management

Each spawned agent has an output token limit per response (see tech-stack.md § Model Specifications "Output token limit"). A single agent generating a heavy file (e.g., 04-epics-and-user-stories.md with 200+ user stories, or 08-screen-specifications.md with 200+ screens) will hit this limit and fail. The team lead must proactively split heavy workloads BEFORE spawning agents. Note: the pipeline model's context window (see tech-stack.md § Model Specifications) means input context is not the bottleneck — the output token limit per agent response is the binding constraint.

#### Estimation Heuristics

Use these estimates to predict output size per file:
- Each user story (with 3+ Given-When-Then acceptance criteria, dependencies, notes): ~300–500 tokens
- Each job story (with JTBD hierarchy, triggers, outcome expectations): ~200–400 tokens
- Each screen specification (with component inventory, states, responsive, a11y): ~500–1000 tokens
     Screen spec tokens scale with component count: ~100 tokens per component (inventory + states + responsive). A 5-component screen ≈ 500 tokens. A 10-component dashboard ≈ 1000 tokens. Screens with complex interactions (multi-step forms, drag-and-drop) add ~200 tokens per interaction pattern.
- Each API endpoint (with request/response schemas, errors, examples): ~400–800 tokens
- Each user flow (with mermaid diagram, happy/alt/error paths): ~400–700 tokens
- Each technical specification (background jobs, notifications, etc.): ~300–600 tokens
- Tables, mermaid diagrams, and cross-references add ~30% overhead
- Safe budget per agent: see tech-stack.md § Model Specifications "Safe output budget" (leave headroom for structure and formatting)

#### Splitting Rules

During Phase 1 planning, BEFORE spawning any teammate:

1. **Estimate output size** for each file based on the number of features, FRs, user stories, screens, or API endpoints it must contain.
2. **If a single file is estimated to exceed the safe output budget (see tech-stack.md § Model Specifications)**: Split that file's generation into multiple agents, each handling a subset. For example:
   - `04-epics-and-user-stories.md` with 150+ stories → split by epic group (e.g., "auth & user management epics" vs "core product epics" vs "billing & admin epics")
   - `08-screen-specifications.md` with 100+ screens → split by feature module
   - `12-api-specifications.md` with 100+ endpoints → split by domain/resource
   - If Teammate 4 (api-and-technical) requires splitting, recommended split: Sub-agent A handles files 10-11 (system architecture, data model), Sub-agent B handles files 12-13 (API specs, technical specs). Allocate ID ranges accordingly. If splitting Teammate 4: Sub-agent A (files 10-11: system architecture, data model) does not need API ID ranges. Sub-agent B (files 12-13: API specs, technical specs) uses the full API range and TS range. Adjust ranges based on actual counts.
   - Each sub-agent generates its portion with consistent formatting
   - The lead merges the outputs into a single file during Phase 4
3. **If a teammate's combined files are estimated to exceed the safe output budget (see tech-stack.md § Model Specifications)** but no single file is the problem: Split the teammate into multiple agents, each responsible for a subset of files (1 file per agent).
4. **Lightweight files** (product overview, release plan, operational readiness, glossary) can remain grouped on a single agent.

#### Split Spawn Protocol

When splitting a teammate:
- Each sub-agent gets the SAME context (`_context.md`, Feature Decomposition Map, writing guidelines, full-scope instruction)
- Each sub-agent gets a UNIQUE ID range subset (e.g., sub-agent A gets US-001–US-149, sub-agent B gets US-150–US-299, sub-agent C gets US-300–US-499)
- Each sub-agent's spawn prompt specifies EXACTLY which epics/features/modules it is responsible for
- The lead tracks all sub-agents and merges their outputs in Phase 4
- Merged files must have consistent formatting, sequential IDs, and no gaps

### Teammate Failure Recovery

If a teammate fails (crashes, times out, or produces truncated output):
1. Check which files were successfully written to `./plancasting/prd/`.
2. For missing files: re-spawn with the same context and file assignments.
3. For truncated files: re-spawn, instructing the agent to complete from the last complete section.
4. If a re-spawned teammate's output is still truncated after reducing scope, split further per the Split Spawn Protocol above. Do not retry the same scope more than once.
5. Do not proceed to Phase 4 until all teammates have completed.

#### Known Heavy Files (likely to need splitting)

These files scale linearly with the number of features and almost always exceed the safe output budget (see tech-stack.md § Model Specifications) for products with 30+ features:
- `04-epics-and-user-stories.md` — each FR needs at least one user story with 3+ acceptance criteria. With 200+ FRs, expect 150+ user stories. SPLIT BY EPIC GROUP.
- `08-screen-specifications.md` — each screen needs full component inventory, all states, responsive specs, and a11y annotations. With 30+ features, expect 100+ screens. SPLIT BY FEATURE MODULE.
- `12-api-specifications.md` — each endpoint needs full request/response schemas with examples. With 30+ features, expect 80+ endpoints. SPLIT BY DOMAIN.

These files may need splitting depending on complexity:
- `06-user-flows.md` — if the product has 10+ critical user flows with full happy/alt/error paths
- `13-technical-specifications.md` — if the product has many background jobs, notification channels, and async processes

#### Compact Output Strategy

In addition to splitting, instruct ALL agents to use compact output techniques to maximize content per token:
- Group related FRs into single user stories where appropriate (one story covering 2-3 closely related FRs) instead of a 1:1 FR-to-story mapping
- Use concise table format for repetitive specifications (e.g., API endpoints with similar patterns)
- Avoid restating context that is already in `_context.md` — reference it instead
- Use abbreviated mermaid syntax (short node labels, minimal styling)

#### Story Grouping Examples

- **Good grouping**: US-042 covers FR-105 (create task) + FR-106 (assign task to user) — both happen in the same dialog flow with shared acceptance criteria.
- **Bad grouping**: US-043 covers FR-150 (email notifications) + FR-200 (SMS notifications) — different delivery channels, different failure modes, different testing strategies. Keep separate.
- **Rule of thumb**: Group FRs that share the same screen, the same user action trigger, AND the same error/success states. Never group FRs from different epics.

### Phase 3: Coordination During Execution

While teammates are working:
1. Monitor progress via the shared task list.
2. Facilitate cross-team dependencies through messaging:
   - When Teammate 1 finalizes feature IDs and dependency graph → write them to `./plancasting/prd/_context.md`
   - When Teammate 2 finalizes user story IDs → write them to `./plancasting/prd/_context.md`
   - When Teammate 3 finalizes screen specs → write them to `./plancasting/prd/_context.md`
   - When Teammate 4 finalizes API specs → write them to `./plancasting/prd/_context.md`
   - **Note**: Since teammates run in parallel, they cannot read each other's outputs during execution. All cross-teammate dependencies (Feature Decomposition Map, data entity list, ID ranges) must be provided in each teammate's spawn prompt context. Updates to `_context.md` are for Phase 4 integration and downstream stage consumption — NOT for inter-teammate communication during Phase 2 execution.
   - **Screen ↔ API dependency resolution**: Teammate 3 (screen-specs) and Teammate 4 (api-and-technical) have a bidirectional dependency: screens need to know what data APIs provide, and APIs need to know what screens require. Resolution: The lead must include a preliminary data entity list (extracted from BRD data requirements `brd/09-data-requirements.md`) in BOTH teammates' spawn prompts. For BaaS architectures (Convex, Firebase, Supabase), also include preliminary function signatures (query/mutation names and their expected arguments/returns) in the entity list — BRD data entities alone are insufficient since BaaS APIs are defined by function signatures, not REST endpoints. This gives each teammate enough context to work independently. The lead reconciles any screen↔API mismatches during Phase 4 integration. If Teammate 3 invents data not in the BRD entity list, flag it for lead review — classify as a BRD gap (recommend adding DR-xxx) rather than silently discarding. If Teammate 4 creates endpoints not referenced by any screen, flag for removal or documentation as internal-only APIs.
3. Resolve any conflicts or ambiguities raised by teammates.
4. Ensure BRD traceability is maintained.
5. **Cross-feature attention**: When a teammate asks about how feature A interacts with feature B, provide context from both features' BRD requirements. This is critical because the full-build approach creates interaction surfaces that wouldn't exist in a phased approach.

### Phase 4: Structural Integration

After all teammates complete their tasks:

1. Collect all generated files into `./plancasting/prd/`.
2. Perform structural consistency checks:
   - **Full-scope traceability audit**: Verify EVERY BRD functional requirement (FR-xxx) is covered by at least one user story (US-xxx). Generate a coverage report. Flag any uncovered FRs.
   - **Cross-feature integration audit**: Identify all places where features interact. Verify these interactions have user flows, screen specs, and test scenarios.
   - ID uniqueness, cross-reference validity, terminology consistency, assumption marking, mermaid syntax validation
   - Screen coverage: every user story maps to a screen specification
   - API coverage: every screen that displays or mutates data has API endpoints
   - Test coverage: every user flow has E2E test scenarios
3. **Cross-story dependency validation**: Parse all user story `Dependencies` fields from `./plancasting/prd/04-epics-and-user-stories.md`.
   - Build a directed dependency graph (US-xxx → depends on US-yyy).
   - Verify the graph is **acyclic** (no circular dependencies). If cycles exist, break the cycle by: (a) identifying the weakest dependency in the cycle (the one most easily mocked or reordered — all features are still built, only the implementation order changes), (b) splitting the dependent story into two parts — one that can proceed without the cycle and one that completes after the cycle target is ready, (c) updating both stories' Dependencies fields. Flag all cycle resolutions in the review log. Note: If circular dependencies require story splitting, verify the split does not invalidate screen specs (Teammate 3) or API specs (Teammate 4). Re-validate affected artifacts after splitting.
   - Verify no P0 story depends on a P1/P2/P3 story. If found, either re-prioritize the dependency to P0 or flag as a priority conflict.
   - Verify no story depends on a story from an epic with a lower development priority (e.g., a P0 story should not depend on a P2 epic's story). If found, re-order epics or flag the dependency.

4. Generate `18-glossary-and-cross-references.md`:
   - Extended glossary
   - BRD → PRD traceability matrix (COMPLETE — every FR mapped)
   - Cross-feature interaction matrix: which features interact and where
   - PRD internal cross-reference matrix
5. Generate `README.md`:
   - PRD overview stating this is a COMPLETE product specification
   - Relationship to BRD
   - Navigation guide with recommended reading order per role:
     - **Product Managers**: 01 → 02 → 03 → 04 → 05
     - **Designers**: 01 → 06 → 07 → 08 → 09
     - **Engineers**: 10 → 11 → 12 → 13 → 04 → 08
     - **QA**: 14 → 04 → 06 → 08 → 12 → 15
   - Document conventions and ID format reference
6. **Update `_context.md` with final ID allocations**: After merging all teammate outputs and resolving deduplication, update `./plancasting/prd/_context.md` with the final ID registry showing all allocated IDs (US-xxx, SC-xxx, API-xxx, etc.). Stage 2B reads this file for validation — stale preliminary IDs cause false-positive gap reports. Ensure all teammates have reported completion before writing final ID allocations to `_context.md` to avoid race conditions with in-progress teammates.
7. Fix any structural inconsistencies found (ID conflicts, broken links, missing cross-references).
8. **BRD Issue Documentation**: If PRD teammates identified BRD quality issues during generation (missing requirements, contradictions, gaps that forced workarounds), document them in `./plancasting/prd/_brd-issues.md` with format: issue description, severity (BLOCKING / CRITICAL-BUT-RECOVERABLE / NON-BLOCKING), affected BRD file, and recommendation. Stage 2B reads this file during validation. If no BRD issues were found, this file may be omitted.

### Phase 5: Deep Quality Review

Spawn 3 specialized review agents to perform a comprehensive quality audit. Each reviewer reads ALL generated PRD files plus `_context.md`, relevant BRD files, and the original Business Plan, then produces a structured issue report.

With the pipeline model's context window (see tech-stack.md § Model Specifications), the combined PRD + BRD + Business Plan typically fits within a single review agent's context. For exceptionally large products, the lead may need to split each review agent's scope by feature group.

#### Review Agent Spawn Protocol

Each review agent's spawn prompt must include:
- The instruction: "Read CLAUDE.md Part 1 (immutable rules) if it exists in the project root. Follow its conventions. Ignore Part 2 (project-specific configuration) — it is not yet populated at this stage."
- The instruction: "Check `./plancasting/tech-stack.md` for the `Session Language` setting. Generate all PRD content and user-facing output in the specified language. Code, technical identifiers, and file names remain in English."
- The list of all generated PRD files to review
- Instructions to read every file in `./plancasting/prd/`, relevant `./plancasting/brd/` files, and `./plancasting/businessplan/` files
- The issue report format (below)
- Their specific review checklist

#### Issue Report Format (used by ALL review agents)

Each agent produces a list of issues in this format:

    ## [AGENT-NAME] Review Report

    ### Issue [N]
    - **Severity**: CRITICAL | HIGH | MEDIUM | LOW
    - **File**: [filename]
    - **Location**: [section/user story ID/screen ID/API ID]
    - **Category**: [from agent's checklist]
    - **Description**: [What is wrong]
    - **Recommendation**: [How to fix it]
    - **Affected Elements**: [List of PRD IDs impacted — US/SC/API/TS/etc.]

Severity definitions:
- Specification is missing, contradictory, or would cause implementation failure. Blocks development.
- **HIGH**: Specification is vague, incomplete, or technically infeasible. Would cause rework during development.
- **MEDIUM**: Quality issue that reduces clarity but doesn't block development. Inconsistency or missing detail.
- **LOW**: Polish issue — formatting, minor terminology drift, optimization suggestion.

#### Review Agent 1: "completeness-reviewer"
**Focus**: Coverage gaps, vagueness, and traceability
**Checklist**:
- [ ] Every BRD functional requirement (FR-xxx) is traced to at least one user story (US-xxx) — target: **≥ 95% coverage** (matching Stage 2B's PASS gate; CONDITIONAL PASS allows ≥ 90%). If coverage drops below 95%, flag the gap as a HIGH issue for remediation in Phase 6. Below 90% is CRITICAL.
- [ ] Every user story has at least 3 acceptance criteria in Given-When-Then format
- [ ] Every acceptance criteria is specific and testable (no vague terms like "quickly", "easily", "appropriate", "user-friendly")
- [ ] Every user story covers ALL states: happy path, error path, edge cases, empty state, loading state
- [ ] Every screen specification (SC-xxx) documents ALL component states: default, loading, empty, populated, error, disabled, hover, active, focused (and offline where applicable)
- [ ] Every screen specification includes responsive behavior for mobile/tablet/desktop
- [ ] Every screen specification includes accessibility annotations (ARIA roles, keyboard nav, focus management)
- [ ] Every API endpoint specifies request schema, response schema, error responses, authentication, and rate limiting
- [ ] Every API endpoint has example request/response payloads with realistic data
- [ ] Every data entity in the data model has defined relationships, constraints, indexes, and lifecycle
- [ ] User flows cover happy path, ALL alternative paths, and ALL error paths — not just the happy path
- [ ] Cross-feature user flows exist for features that interact across originally-separate Business Plan phases
- [ ] Job stories include both functional triggers and emotional triggers
- [ ] Feature flags have clear purpose, default state, and cleanup target date
- [ ] No placeholder text, TODO markers, or "TBD" entries remain
- [ ] Onboarding flows exist for the complete product (progressive disclosure, guided tours)

#### Review Agent 2: "consistency-reviewer"
**Focus**: Contradictions, duplications, and alignment
**Checklist**:
- [ ] No contradictory specifications across files (e.g., a screen spec shows a field that the API doesn't support, or a user story describes behavior that conflicts with a business rule)
- [ ] No duplicate user stories covering the same functionality with different IDs
- [ ] Terminology is consistent across all files and matches `_context.md` glossary
- [ ] Development priorities (P0-P3) are consistent — same feature doesn't have different priorities in different files
- [ ] Complexity estimates are proportional (an "L" story should be clearly more complex than an "S" story for similar domains)
- [ ] Screen specifications align with user flows — every screen referenced in a flow has a spec, and vice versa
- [ ] API endpoints align with screen specifications — every data-displaying screen has corresponding API calls defined
- [ ] Data model supports all described API operations without schema gaps
- [ ] Navigation structure in information architecture accommodates ALL features consistently
- [ ] Feature dependency graph is acyclic and matches the declared dependencies in user stories
- [ ] BRD traceability references are valid — referenced BR/FR/NFR IDs actually exist in the BRD
- [ ] Non-functional specifications align with BRD NFRs (no weakening of requirements without justification)
- [ ] Testing strategy covers all user flows and all features — no gaps in test plan coverage
- [ ] Error messages and error handling patterns are consistent across all screen specs

#### Review Agent 3: "technical-reviewer"
**Focus**: Technical feasibility, implementation readiness, and architecture quality
**Checklist**:
- [ ] System architecture is feasible with the specified tech stack (from `plancasting/tech-stack.md`)
- [ ] Data model can be implemented in the chosen database without anti-patterns (circular references, unbounded arrays, missing indexes for query patterns)
- [ ] API design follows consistent conventions (naming, pagination, error format, versioning)
- [ ] API request/response schemas use correct types and constraints (no string for numeric fields, no unbounded arrays without pagination)
- [ ] Authentication and authorization model is correctly specified for all endpoints and screens
- [ ] Performance budgets are realistic for the chosen tech stack and architecture
- [ ] Caching strategy is appropriate for the data access patterns described
- [ ] Real-time features (if any) have feasible specifications (WebSocket vs SSE vs polling decisions)
- [ ] File upload/download specifications include size limits, type validation, and storage strategy
- [ ] Search specifications are feasible (full-text search, filters, facets — matched to the chosen search infrastructure)
- [ ] Background job specifications include retry policies, failure handling, and idempotency
- [ ] Notification specifications include delivery channels, deduplication, and user preferences
- [ ] Mermaid diagrams are syntactically valid and accurately represent described architectures and flows
- [ ] Technical specifications account for concurrent access, race conditions, and data consistency
- [ ] Infrastructure requirements are appropriately sized for the full feature set from day one
- [ ] Third-party service dependencies are current and available (not deprecated APIs)

### Phase 6: Remediation

After all 3 review agents complete their reports:

1. **Consolidate**: Merge all review reports into a single prioritized issue list. Remove duplicate findings (same issue reported by multiple reviewers — keep the most detailed version). Count issues by severity.

2. **Quality Gate Check**:
   - If CRITICAL issues exist → remediation is MANDATORY
   - If HIGH issues exist → remediation is MANDATORY
   - MEDIUM and LOW issues → fix what can be fixed efficiently, document the rest

3. **Fix Issues**: For each CRITICAL and HIGH issue:
   - Read the affected PRD file
   - Apply the recommended fix (or a better alternative if the recommendation is insufficient)
   - Verify the fix doesn't introduce new inconsistencies with other files
   - Ensure BRD traceability is preserved or corrected in the fix
   - Mark the issue as resolved

4. **Remediation Principles**:
   - Fix the ROOT CAUSE, not just the symptom. If a user story has vague acceptance criteria, rewrite ALL acceptance criteria for that story — don't just patch one.
   - When fixing contradictions, determine the CORRECT version by consulting the BRD and Business Plan, then update ALL PRD files that reference the incorrect version.
   - When fixing missing specifications, follow the same ID conventions, formatting, and level of detail as existing specifications.
   - When fixing technical feasibility issues, adjust the specification to be achievable while preserving the product intent. Document the trade-off with `> ⚠️ ASSUMPTION:`.
   - When fixing coverage gaps (missing user stories, screen specs, API endpoints), generate complete specifications — not stubs or placeholders.
   - Ensure every fix maintains or improves BRD → PRD traceability.

5. **Second Pass** (conditional): If the initial remediation resolved more than 15 CRITICAL+HIGH issues, perform a targeted re-review of ONLY the modified files to ensure fixes didn't introduce new problems. This re-review does not require spawning new agents — the lead performs it directly using the review checklists above.

6. **Document Remaining Issues**: Create `./plancasting/prd/_review-log.md` containing:
   - Review date and agent versions
   - Total issues found by severity (original counts)
   - Issues resolved by severity
   - Remaining MEDIUM/LOW issues with their descriptions and affected files
   - Any CRITICAL/HIGH issues that could not be fully resolved, with explanation and proposed resolution path
   - Dependency cycle resolutions (if any cycles were resolved in Phase 4 step 3): list each cycle, how it was broken, and which stories were split

7. **BRD Issue Documentation**: Update `./plancasting/prd/_brd-issues.md` (created in Phase 1 if BRD issues were found) with any additional inconsistencies, contradictions, or gaps discovered during review. Each issue classified by severity: BLOCKING, CRITICAL-BUT-RECOVERABLE, or NON-BLOCKING. Stage 2B will use this file to prioritize BRD-side fixes. If no BRD issues were found in any phase, this file may be omitted.

8. **Final Summary**: Output the following:
   - Total counts: Epics, User Stories, Job Stories, Screens, API Endpoints, Technical Specs, Feature Flags
   - BRD coverage: percentage of FR-xxx requirements traced to PRD elements (target: 100%)
   - Cross-feature interactions identified and documented
   - Number of assumptions flagged
   - Number of mermaid diagrams generated
   - Open questions requiring human decision (consolidated list)
   - **Quality metrics**:
     - Total issues found: [N] (CRITICAL: [n], HIGH: [n], MEDIUM: [n], LOW: [n])
     - Issues resolved: [N] (CRITICAL: [n], HIGH: [n], MEDIUM: [n], LOW: [n])
     - Remaining issues: [N] (with severity breakdown)
     - Quality score: percentage of CRITICAL+HIGH issues resolved (target: 100%)

### Phase 7: Shutdown

Teammates terminate automatically upon task completion. Verify all output files exist in `./plancasting/prd/` before declaring Stage 2 (PRD Generation) complete.

## Gate Decision

After Phase 6 remediation and Phase 7 shutdown, determine the Stage 2 outcome using the following decision tree. Evaluate top to bottom — take the first match:

1. Any unresolved CRITICAL review issues (from Phase 5 reviewers) remaining after remediation? → **FAIL**
2. Any unresolved HIGH review issues remaining after remediation? → **FAIL**
3. Missing critical PRD sections (features, user stories, screen specs, data model, API specs)? → **FAIL**
4. Feature ID inconsistencies across PRD files (IDs referenced but undefined, duplicate IDs, broken cross-references)? → **FAIL**
5. Any user stories without acceptance criteria (Given-When-Then format)? → **FAIL**
6. Data model or API spec gaps for P0 features (missing entities, undefined endpoints for Must Have requirements)? → **FAIL**
7. All 18 PRD sections complete AND feature IDs consistent AND user stories have acceptance criteria AND screen specs reference features AND data model covers all entities AND API specs cover all endpoints AND zero CRITICAL/HIGH review issues? → **PASS**
8. Minor gaps in non-critical sections (e.g., glossary incomplete, non-functional specs partially defined, cross-references for P2/P3 features missing minor detail) BUT all core PRD sections (02-feature-map, 04-epics-and-user-stories, 08-screen-specifications, 11-data-model, 12-api-specifications) are complete with no P0 gaps? → **CONDITIONAL PASS** — document each gap with affected file and remediation plan
9. No rule matched? → **FAIL** (document the specific combination of issues and escalate to operator)

**Outcome definitions**:
- **PASS**: All 18 PRD sections complete, feature IDs consistent across all files, every user story has testable acceptance criteria, screen specs reference feature IDs, data model covers all entities from business requirements, API specs cover all endpoints needed by screen specs. Proceed to Stage 2B.
- **CONDITIONAL PASS**: Core PRD sections (features, user stories, screen specs, data model, API specs) are complete with no P0 gaps. Minor gaps exist in non-critical sections (glossary, non-functional specs, operational readiness). Document each gap. Proceed to Stage 2B — Stage 2B will independently validate and may catch remaining issues.
- **FAIL**: Missing critical sections, feature ID inconsistencies, user stories without acceptance criteria, or data model/API gaps for P0 features. STOP. Fix the issues in the PRD files and re-run Stage 2 remediation (Phase 6) before proceeding. If FAIL is caused by BRD quality issues (missing requirements, contradictions), remediate the BRD first, then re-run Stage 2.

Include the gate decision in the `_review-log.md` output: `Stage 2 Outcome: [PASS | CONDITIONAL PASS | FAIL]`

---

## Writing Guidelines (Include in ALL teammate spawn prompts)

1. **Full Scope**: This PRD covers the COMPLETE product. Every feature in the Feature Decomposition Map must be fully specified. If a feature seems less important, it still gets full specification — just a lower development priority (P2/P3).
2. **BRD Traceability**: Every PRD element must reference its source BRD requirement(s) using the format `[Traces to BR-001](../brd/06-business-requirements.md#br-001), [FR-003](../brd/07-functional-requirements.md#fr-003)`. Use lowercase anchors in all cross-reference links (e.g., `#br-001` not `#BR-001`) for compatibility with case-sensitive systems.
3. **Development Readiness**: Write specifications at a level of detail where an engineer unfamiliar with the product can implement without asking clarifying questions.
4. **State Coverage**: For every screen, component, and interaction, document ALL states: default, loading, empty, populated, error, disabled, hover, active, focused, offline (where applicable).
5. **Edge Cases**: Document edge cases and boundary conditions. What happens with 0 items? 1 item? 10,000 items? Concurrent edits?
6. **Cross-Feature Interactions**: Explicitly document how features interact with each other. A dashboard feature that aggregates data from 5 other features needs specifications for all 5 data sources, not just "data comes from other features."
7. **Completeness**: If the BRD lacks detail, generate assumptions marked with `> ⚠️ ASSUMPTION:`. Never leave sections empty.
8. **Consistency**: Use terminology defined in `./plancasting/prd/_context.md`.
9. **Mermaid Diagrams**: Use mermaid syntax for all visual representations. always validate syntax before including — common errors: (a) missing quotes around node labels containing special characters (`A[My Node]` not `A[My "Node"]`), (b) incorrect arrow syntax (`A --> B` not `A -> B` for flowcharts; `->>` for sequence diagrams), (c) unclosed `subgraph`/`loop`/`alt` blocks, (d) using Unicode `→` instead of ASCII `-->`. Validate by checking that all opened blocks (`subgraph`, `loop`, `alt`) are closed, all node references are consistent, and arrow syntax matches the diagram type (flowchart: `-->`, sequence: `->>`, state: `-->`).
10. **Cross-references**: Use relative markdown links between PRD files and back to BRD files.
11. **Professional Tone**: Clear, precise, unambiguous. Use the session language specified in tech-stack.md.
12. **ID Formats**: Follow the ID format and ranges defined in `_context.md`.
13. **Given-When-Then**: All acceptance criteria must follow this format strictly.
14. **JSON Schemas**: All API request/response bodies must use explicit JSON structure with types, constraints, and examples.
15. **Onboarding Consideration** (if applicable): If the product has a consumer-facing UI where users encounter the complete feature set from day one, document onboarding flows, progressive disclosure patterns, and guided tours that help users navigate without being overwhelmed. Skip this for APIs, admin tools, CLI utilities, or products with structured training programs.
````
