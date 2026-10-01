---
name: prd
description: >-
  Generates a development-ready Product Requirement Document (PRD) from the BRD using parallel agent teams.
  This skill should be used when the user asks to "generate PRD",
  "create product requirements document", "run Stage 2",
  "generate product requirements", "create PRD from BRD",
  "translate BRD to PRD", or when the transmute-pipeline agent
  reaches Stage 2 of the pipeline.
metadata:
  version: 1.0.0
effort: high
---

# Transmute — PRD Generation (Stage 2)

Read the detailed guide at `${CLAUDE_SKILL_DIR}/references/prd-detailed-guide.md` for the complete agent team architecture, teammate spawn prompts, token budget management, review agent checklists, story grouping examples, and writing guidelines.

## Prerequisites

Before starting, verify:
1. `./plancasting/brd/` directory exists and contains markdown files. If missing or empty, STOP: "Stage 2 requires completed BRD (Stage 1). Run Stage 1 first."
2. `./plancasting/tech-stack.md` exists. If missing, STOP: "Stage 2 requires `plancasting/tech-stack.md` from Stage 0. Run Stage 0 first."

## Critical Framing

This PRD uses the **Full-Build Approach**: the COMPLETE product is built and launched as a single release. No MVP, no phased rollout, no feature deferral. P0-P3 priorities define dependency order for parallel development, NOT which features to include or exclude. ALL features ship.

## BRD → PRD Relationship

The BRD defines WHAT the business needs. The PRD defines WHAT the product must do and HOW it should behave. Every PRD element must trace back to one or more BRD requirements. The PRD must be detailed enough for engineering, design, and QA teams to begin work without ambiguity.

## Execution Flow

### Step 1: Read and Analyze Inputs

Read and fully internalize:
- All files in `./plancasting/brd/`, including `_context.md`
- All files in `./plancasting/businessplan/` for additional context
- `./plancasting/tech-stack.md` for stack-informed architecture and API design

Check `Session Language` in `./plancasting/tech-stack.md`. Generate ALL PRD documents in the specified language, matching the BRD's language. Technical identifiers remain in English.

Adapt PRD structure based on product type:
- **Mobile**: Gesture documentation, platform-specific navigation, native component specs
- **IoT/Embedded**: Device behavior specs alongside companion app specs
- **Desktop**: Window management, system tray, keyboard shortcuts
- **AI/ML**: Model interaction specs (prompts, output formatting, confidence thresholds, fallback)

### Step 2: Handle BRD Quality Issues

If BRD gaps are found during PRD generation, use this decision tree:
1. **Obvious from context**: Assume and proceed
2. **Requires business judgment**: Mark with `> ⚠️ ASSUMPTION:` and note in `_brd-issues.md`
3. **Blocking**: Escalate in status message

Do not modify BRD files. Document issues in `./plancasting/prd/_brd-issues.md` with classification:
- **BLOCKING**: Empty/corrupted BRD files → STOP
- **CRITICAL-BUT-RECOVERABLE**: BRD gap but can continue with best interpretation → Continue, document, flag
- **NON-BLOCKING**: Incomplete but workable with assumptions → Continue

If no BRD issues found, do not create this file. Stage 2B reads `_brd-issues.md` (if it exists) and maps classifications: BLOCKING → CRITICAL, CRITICAL-BUT-RECOVERABLE → HIGH, NON-BLOCKING → MEDIUM/LOW.

### Step 3: Build Feature Decomposition Map

1. Verify full-scope coverage: cross-check BRD's master feature inventory against all FR-xxx entries. Every feature must have at least one FR.
2. Group ALL BRD functional requirements into logical product features/modules
3. Create `./plancasting/prd/_context.md` containing:
   - **Feature Decomposition Map** (feature ID → related BR/FR/NFR IDs) — COMPLETE. This map is the authoritative source for which BRD requirements belong to which product feature. It is referenced by Stage 2B for P0 coverage calculations and by Stage 3 for scaffold organization.
   - Technology stack summary
   - Master PRD ID registry with expanded ranges:
     - EPIC-001–EPIC-099, US-001–US-499, JS-001–JS-149, SC-001–SC-699
     - API-001–API-299, TS-001–TS-149, FF-001–FF-049, REL-001–REL-009
   - Glossary (inherited from BRD + product-specific terms)
   - Persona summary (ALL personas), DoD template, formatting conventions
   - Note: "This PRD covers the COMPLETE product."

### Step 4: Spawn Agent Teams (Phase 2)

Spawn 5 specialized teammates. Each spawn prompt must include: CLAUDE.md Part 1 instructions, full `_context.md` content, the COMPLETE Feature Decomposition Map, file assignments with ID ranges, relevant BRD files, full-scope instruction ("This PRD covers the COMPLETE product. Every feature in the Feature Decomposition Map must be specified."), and the writing guidelines from the detailed guide.

**Teammate 1 — "product-strategy"**
Files: `01-product-overview.md`, `02-feature-map-and-prioritization.md`, `03-release-plan.md`
Emphasize: ALL features in scope. P0-P3 defines development ORDER (dependency-based), not inclusion. Release plan is a SINGLE launch. Feature flags for ops/experiments/permissions only — NOT phased rollout. Gantt chart must show parallel workstreams, not sequential phases. Feature flag registry includes: FF-ID, Feature ID, Flag Name, Flag Type (ops/experiment/permission), Default State, Purpose, Kill Switch Criteria.

**Teammate 2 — "user-stories"**
Files: `04-epics-and-user-stories.md`, `05-job-stories.md`, `06-user-flows.md`
Emphasize: EVERY BRD FR must have at least one user story. Every US must include a Dependencies field (comma-separated US-xxx IDs, or "None"). Minimum 3 Given-When-Then acceptance criteria per story. Cross-feature user flows are critical — journeys that touch features from different parts of the product. Story map visualization showing persona x journey stage x stories.

**Teammate 3 — "screen-specs"**
Files: `07-information-architecture.md`, `08-screen-specifications.md`, `09-interaction-patterns.md`
Emphasize: IA designed for COMPLETE product from the start — navigation must accommodate ALL features. Per-screen spec includes: component inventory (type, label, behavior, validation, states), content specifications (static text, dynamic bindings, empty/error text), responsive behavior across breakpoints, interaction specifications per element, state management, accessibility annotations (ARIA roles, keyboard nav, focus management).

**Teammate 4 — "api-and-technical"**
Files: `10-system-architecture.md`, `11-data-model.md`, `12-api-specifications.md`, `13-technical-specifications.md`
Emphasize: Complete data model from start — designed for all features simultaneously. For BaaS architectures (Convex, Firebase): replace Method/Path with Function Type/Function Name, document function signatures instead of HTTP request/response. API specs for EVERY endpoint across ALL features with request/response schemas, error responses, pagination, idempotency. Architecture sized for full product load from day one.

**Teammate 5 — "quality-and-operations"**
Files: `14-testing-strategy.md`, `15-non-functional-specifications.md`, `16-operational-readiness.md`, `17-dependencies-and-risks.md`
Emphasize: Generate test specifications and scenarios, NOT test code. Cross-feature integration test plan critical. Non-functional specs sized for full load from day one. Full-build-specific risks: integration complexity from parallel construction, testing scope with complete feature set, launch risk with feature-complete first release, cognitive load for users encountering full product on day one.

### Step 5: Token Budget Management

Safe budget: output token limit minus 7K headroom per agent (see tech-stack.md § Model Specifications). Estimate output sizes before spawning.

**Known heavy files** (likely need splitting for 30+ feature products):
- `04-epics-and-user-stories.md` — split by epic group
- `08-screen-specifications.md` — split by feature module
- `12-api-specifications.md` — split by domain

**Story grouping rules**: Group FRs that share the same screen, same user action trigger, AND same error/success states. Never group FRs from different epics or with different failure modes.

### Step 6: Structural Integration (Phase 4)

After all teammates complete:
1. Collect all files into `./plancasting/prd/`
2. Run structural consistency checks:
   - **Full-scope traceability audit**: Every FR-xxx covered by at least one US-xxx
   - **Cross-feature integration audit**: Interactions have user flows, screen specs, and test scenarios
   - ID uniqueness, cross-references, terminology, assumptions, mermaid validation
   - **Screen coverage**: Every user story maps to a screen specification
   - **API coverage**: Every data-displaying/mutating screen has API endpoints
   - **Test coverage**: Every user flow has E2E test scenarios
3. **Cross-story dependency validation**:
   - Build directed dependency graph from US Dependencies fields
   - **Verify acyclic** (no circular dependencies) — if cycles found, document and break by removing the weakest dependency link
   - Verify no P0 story depends on P1/P2/P3
   - Verify no story depends on lower-priority epic's story
4. Generate `18-glossary-and-cross-references.md` with BRD traceability matrix and cross-feature interaction matrix
5. Generate `README.md` with role-specific reading order (PM, Designer, Engineer, QA)
6. Fix structural inconsistencies

### Step 7: Deep Quality Review (Phase 5)

Spawn 3 review agents reading ALL PRD files, BRD files, and Business Plan.

**completeness-reviewer**: FR → US coverage (target ≥95%), acceptance criteria quality (measurable Given-When-Then), all states documented, API completeness (schemas + errors), user flow coverage, onboarding flows.

**consistency-reviewer**: No contradictions across files, no duplicate stories, consistent terminology/priorities/complexity, screen-flow alignment, API-screen data shape alignment, navigation accommodates all features, valid BRD traceability, test coverage.

**technical-reviewer**: Tech stack feasibility, data model implementation, API design conventions, auth model, performance budgets, real-time specs, background jobs, valid mermaid diagrams, infrastructure sizing, third-party dependencies current.

### Step 8: Remediation (Phase 6)

1. Consolidate reports, remove duplicates
2. CRITICAL and HIGH: mandatory remediation
3. Fix root causes. Preserve BRD traceability. Generate complete specs for coverage gaps, not stubs.
4. If >15 CRITICAL+HIGH fixes, targeted re-review of modified files
5. Create `./plancasting/prd/_review-log.md`
6. Output Final Summary: Epics, User Stories, Job Stories, Screens, API Endpoints, Technical Specs, Feature Flags counts. BRD coverage percentage (target: 100%). Cross-feature interactions. Quality metrics.

## Known Failure Patterns to Avoid

1. **Tautological acceptance criteria**: "When they create a project, then a project is created" — must be independently testable.
2. **Screen specs missing interaction behavior**: Define behavior for click, hover, keyboard, form submission.
3. **API specs with no error responses**: Define 400, 401, 403, 404, 409, 500 with response bodies.
4. **Data model missing query indexes**: Every query pattern needs a supporting index.
5. **Happy-path-only user flows**: Include at least one error path per flow.
6. **Wrong UI library component names**: Check `plancasting/tech-stack.md` for actual library component names.
7. **Feature flags for phased rollout**: Feature flags are for operational kill switches only.

## Writing Guidelines Summary

- BRD traceability via `[Traces to BR-001](../brd/06-business-requirements.md#br-001)` — lowercase anchors
- Development-ready detail: engineer can implement without questions
- All states documented: default, loading, empty, populated, error, disabled, hover, active, focused, offline
- Edge cases: 0 items, 1 item, 10,000 items, concurrent edits
- Cross-feature interactions explicitly documented
- Given-When-Then acceptance criteria strictly
- JSON schemas for all API request/response bodies
- Onboarding consideration: progressive disclosure for complete product

## Output Specification

| Output | Location | Description |
|---|---|---|
| PRD files | `./plancasting/prd/` | 18 numbered markdown files (01-18) |
| Shared context | `./plancasting/prd/_context.md` | Feature Decomposition Map, ID registry, glossary |
| BRD issues | `./plancasting/prd/_brd-issues.md` | BRD quality issues (only if found) |
| Review log | `./plancasting/prd/_review-log.md` | Quality review findings |
| Navigation hub | `./plancasting/prd/README.md` | File descriptions, role-specific reading order |
