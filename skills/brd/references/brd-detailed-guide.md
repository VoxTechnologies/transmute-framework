# Transmute — BRD Generation

## Stage 1: Business Requirement Document from Business Plan

````text
You are a senior business analyst and solution architect acting as the TEAM LEAD for a multi-agent BRD generation project. Your task is to generate a comprehensive, enterprise-grade Business Requirement Document (BRD) from the provided Business Plan using Claude Code Agent Teams.

**Stage Sequence**: Business Plan → 0 (Tech Stack) → **1 (BRD — this stage)** → 2 (PRD) → 2B (Spec Validation) → 3+4 (Scaffold + CLAUDE.md) → 5 (Implementation) → 5B (Audit) → 6A/6B/6C (parallel) → 6E → 6F → 6G → 6D → 6H → 6V → 6R → 6P/6P-R → 7 (Deploy) → 7V → 7D → 8 (Feedback) / 9 (Maintenance)

## Critical Framing: Full-Build Approach

This BRD covers the COMPLETE product scope. Every feature described in the Business Plan will be built and delivered as a single, complete product — no MVP, no phased rollout, no feature deferral. Every capability mentioned in the Business Plan — regardless of how it was originally sequenced — must be captured as a requirement with the same level of detail and urgency. If the Business Plan describes "Phase 1, Phase 2, Phase 3" or similar staging, IGNORE the phasing and treat all described functionality as part of a single unified scope. Similarly, features labeled "future", "planned", "roadmap", or "long-term" are INCLUDED in this full-build scope and must be captured with equal detail. Only features explicitly marked "out-of-scope" or "explicitly not planned" are excluded.

The rationale: AI-assisted development enables parallel construction of all features simultaneously, eliminating the traditional need for incremental delivery.

Features explicitly labeled "out-of-scope" in the Business Plan are excluded. All other described functionality is treated as in-scope regardless of language like "future" or "potential" — flag ambiguous scope boundaries in the BRD for operator review.

## Known Failure Patterns

Based on observed Plan Cast outcomes, these are common BRD generation failures:

1. **Vague acceptance criteria**: Using unmeasurable adjectives ("fast response time", "intuitive interface", "scalable architecture"). always include specific metrics (e.g., "response time < 200ms", "task completion in < 3 clicks").
2. **Copy-pasting business plan text**: Agent copies business plan sentences verbatim as requirements instead of translating into structured requirement format with IDs, priority, and traceability.
3. **MoSCoW inflation**: All requirements marked "Must Have" because the full-build approach is misinterpreted as "everything is critical." Maintain proper priority distribution — Must/Should/Could/Won't should reflect both criticality and implementation dependency order, ensuring reasonable distribution across tiers. In a full-build approach, all features are in-scope (will be built). However, MoSCoW reflects CRITICALITY AND DEPENDENCY ORDER, not inclusion/exclusion. A healthy distribution: Must 50–65%, Should 20–30%, Could 10–15%, Won't 0–5% (reserved for features explicitly considered and rejected — features NOT described in the Business Plan at all, e.g., features someone might assume exist but the Business Plan intentionally omits; never use Won't Have for Business Plan features marked as 'future' or 'phase 2' — in the full-build approach, those are still in-scope). Exception: Products with mandatory compliance requirements (regulated industries, accessibility-critical systems) may have higher Must Have (up to 70%). See prompt_validate_specs.md gate validation for acceptance thresholds during Stage 2B. Example: Authentication (Must Have) is more critical for day-one than advanced reporting (Could Have), even though both will be built.
4. **Missing negative requirements**: Only specifying what the system must do, never what it must not do (e.g., "the system must not allow users to access other organizations' data").
5. **Circular traceability**: FR traces to BR, but BR just restates the FR in different words. Each requirement level must add specificity.
6. **NFRs without measurement methods**: Specifying "99.9% uptime" without defining how uptime is measured, what counts as downtime, or how it is monitored.
7. **Mermaid syntax errors**: Diagrams with invalid syntax that silently fail to render. always validate mermaid syntax before including. Common errors: (a) missing quotes around node labels containing special characters (`A[My Node]` not `A[My "Node"]`), (b) incorrect arrow syntax (`A --> B` not `A -> B` for flowcharts), (c) unclosed subgraph blocks, (d) using `→` Unicode arrow instead of `-->` ASCII arrow. Validate by checking that all opened blocks (`subgraph`, `loop`, `alt`) are closed, all node references are consistent, and arrow syntax matches the diagram type (flowchart: `-->`, sequence: `->>`, state: `-->`).
8. **Thin business plan extrapolation**: When the business plan is sparse, agent generates assumptions that contradict the business plan's implied intent. If 30% or more of total requirements across all categories must be assumed (not derived from the Business Plan), flag this as CRITICAL in the final summary and recommend the user review assumptions before proceeding to Stage 2.

## Input

Read all files in the `./plancasting/businessplan/` directory. Supported formats: `.md` (markdown) and `.pdf` (read using the PDF reading tool — extract all text content). These files constitute the complete Business Plan. Thoroughly analyze every section — including but not limited to: executive summary, market analysis, competitive landscape, product/service description, revenue model, go-to-market strategy, operational plan, financial projections, risk assessment, and organizational structure. Pay special attention to any features, capabilities, or functionality described across ALL phases, tiers, or future roadmap items — these must ALL be included as current-scope requirements.

## Stack Adaptation

The BRD structure should adapt based on the product type specified in `plancasting/tech-stack.md`:
- **Web applications**: Standard structure as documented below
- **Mobile applications**: Add platform-specific requirement categories (App Store/Play Store guidelines, device permissions, offline capabilities)
- **IoT / Embedded**: Add hardware requirement categories (environmental requirements, power requirements, connectivity protocols, certification requirements)
- **Desktop applications**: Add platform-specific requirements (Windows/macOS/Linux compatibility, installation/update mechanisms, system resource requirements)
- **AI/ML products**: Add model requirement categories (training data requirements, inference latency, accuracy metrics, bias/fairness requirements)

Always read `plancasting/tech-stack.md` first to determine which adaptations apply.

**Language**: If `./plancasting/tech-stack.md` contains a `## Session Language` section, use that language. If Session Language is not specified in `tech-stack.md`, default to English. Technical identifiers (requirement IDs like FR-001, section headers, cross-reference codes) remain in English regardless of the document language.

**Language Inheritance**: Subsequent stages (PRD, audits, reports) will read the `Session Language` section from `plancasting/tech-stack.md` — NOT from BRD documents. The BRD's language serves as a reference, but the canonical language setting is always in `tech-stack.md`.

## Output

Generate the BRD as a collection of markdown files organized under the `./plancasting/brd/` directory. Each file must correspond to a specific BRD category. Every file must be self-contained yet cross-reference related sections where appropriate using relative markdown links. Generate a `README.md` that serves as a navigation hub linking to all BRD files with reading order and document conventions.

## Expected Output Files

Generate the BRD as markdown files in `./plancasting/brd/`:
- `00-cover-and-metadata.md` — Document metadata, version, revision history, approval table, TOC
- `01-executive-summary.md` — Problem statement, proposed solution, KPIs, critical success factors
- `02-project-background-and-objectives.md` — Business context, SMART objectives, strategic alignment, ROI
- `03-current-state-analysis.md` — As-is processes, gap analysis, pain points, process flows
- `04-stakeholder-analysis.md` — Stakeholder table, RACI matrix, communication plan, escalation paths
- `05-scope-definition.md` — In/out scope, change control
- `06-business-requirements.md` — Numbered BRs with rationale, priority (MoSCoW), acceptance criteria, traceability matrix
- `07-functional-requirements.md` — FRs in user story format, traced to BRs, organized by module
- `08-non-functional-requirements.md` — Performance, scalability, availability, accessibility, i18n, disaster recovery
- `09-data-requirements.md` — Data model, data flows, data quality, volume projections, retention, privacy classification
- `10-integration-requirements.md` — Systems list, integration patterns, API specs, third-party dependencies
- `11-user-experience-requirements.md` — Personas, user journeys, UI/UX principles, responsive design, brand adherence
- `12-regulatory-and-compliance-requirements.md` — Applicable laws/regulations, industry standards, audit trails, data residency
- `13-security-requirements.md` — AuthN/AuthZ, encryption, OWASP Top 10, monitoring, incident response
- `14-business-rules-and-logic.md` — Business rule catalog, decision tables, workflow state transitions
- `15-reporting-and-analytics-requirements.md` — Reports/dashboards list, KPI definitions, analytics capabilities
- `16-migration-and-transition-requirements.md` — Migration strategy, data mapping, rollback, training, go-live checklist
- `17-acceptance-criteria.md` — UAT approach, test scenarios, entry/exit criteria, defect classification, sign-off process
- `18-assumptions-constraints-dependencies.md` — Assumptions/constraints/dependencies tables with impact analysis
- `19-risk-analysis-and-mitigation.md` — Risk register, risk heat map, top 10 risks with mitigation, monitoring cadence
- `20-cost-benefit-analysis.md` — Cost breakdown, benefits quantification, NPV, payback period, sensitivity analysis, TCO
- `21-timeline-and-milestones.md` — Milestone table, Gantt chart, critical path, decision gates
- `22-glossary-and-appendices.md` — Consolidated glossary, cross-reference matrix
- `_context.md` — Shared context used during generation (Business Plan summary, feature inventory, ID registry, glossary)
- `_review-log.md` — Review date, issues found/resolved by severity, remaining issues
- `README.md` — BRD overview, navigation guide, file descriptions, reading order, conventions

Expected total: 26 files (23 numbered specification files + 3 supporting files)

---

## Agent Team Architecture

### Phase 1: Lead Analysis & Planning

As the team lead, complete the following BEFORE spawning any teammates:

**Prerequisite Verification** (BEFORE any other steps):
- Verify `./plancasting/businessplan/` directory exists and contains `.md` or `.pdf` files. If missing or empty, STOP: "Stage 1 requires a Business Plan at `./plancasting/businessplan/`. Place your business plan files (.md or .pdf) there before running Stage 1."
- Verify `./plancasting/tech-stack.md` exists (created by Stage 0). If missing, STOP: "Stage 1 requires `plancasting/tech-stack.md` from Stage 0. Run Stage 0 first."
- Read `./plancasting/tech-stack.md` and verify it contains a `## Session Language` section. If missing, STOP: "Session Language not found in tech-stack.md — run Stage 0 first or add a Session Language section manually." Generate all BRD content and user-facing output in the specified language. Technical identifiers (requirement IDs like FR-001, section headers, cross-reference codes) and file names remain in English.

1. Read and fully internalize all files in `./plancasting/businessplan/` and `./plancasting/tech-stack.md`.
2. **Feature Extraction Sweep**: Identify EVERY feature, capability, and function described anywhere in the Business Plan — including those labeled as "future", "Phase 2/3", "nice-to-have", "roadmap", "planned", or "long-term". Compile a master feature inventory. Nothing is out of scope. **Deduplication rule**: If two features are variants of the same capability (e.g., "real-time collaboration" and "live editing" both describe concurrent document interaction), merge them into one feature with multiple acceptance criteria. If they are distinct (e.g., "user invitations" vs "user roles"), keep separate. **Variant test**: Two features are variants if they share the same user goal AND the same core data entity AND the same business logic. Different delivery channels (email notifications vs push notifications) for the same notification entity with the same trigger rules ARE variants — merge them. But if the channels have divergent business logic (e.g., email = daily digest aggregation, push = real-time instant alert), treat as separate features with separate FRs. Different data domains (user management vs billing) are distinct even if they share a UI pattern (e.g., both use list views) — keep separate. When in doubt, keep as separate features — merging is harder to undo than splitting.
3. Create `./plancasting/brd/` directory.
4. Create a shared context document at `./plancasting/brd/_context.md` containing:
   - A summary of the Business Plan's key elements (market, product, revenue model, customers, risks, financials)
   - Technology stack summary (from `./plancasting/tech-stack.md` — informs technical requirements and constraints)
   - The master feature inventory as a markdown table with columns: **Feature ID** (FEAT-001, FEAT-002, etc.), **Feature Name**, **Business Plan Section** (where found), **FR ID(s)** (populated in Phase 4), **Coverage Status** (Assigned to FR / Needs FR / Explicit Exclusion (rare) — note: 'Explicit Exclusion (rare)' applies ONLY to features explicitly excluded by the Business Plan, not to features that seem low-priority. The full-build approach means all Business Plan features are in-scope.). All features extracted from ALL phases/sections of the Business Plan must appear in this table.
   - The master requirement ID registry with reserved ID ranges per category:
     - BR-001–BR-099: Business Requirements
     - FR-001–FR-299: Functional Requirements (expanded range to accommodate full scope)
     - NFR-001–NFR-099: Non-Functional Requirements
     - CR-001–CR-049: Compliance & Regulatory Requirements
     - SR-001–SR-049: Security Requirements
     - BRL-001–BRL-149: Business Rules & Logic (expanded range)
     - DR-001–DR-049: Data Requirements
     - IR-001–IR-049: Integration Requirements
   - Glossary of key terms and acronyms to be used consistently across all files
   - Cross-reference conventions and formatting standards
   - A note explicitly stating: "This BRD covers the COMPLETE product scope. No features have been deferred or phased."
5. Create a task list for all teammates with dependency tracking.

### Phase 2: Spawn Specialized Teammates

Spawn the following 5 teammates. If dependencies between teammates are identified during Phase 1 analysis, the lead MAY delay spawning dependent teammates until their prerequisite teammates complete. **Known dependency**: Teammate 3 (data-and-integration) depends on Teammate 2 (technical-infrastructure) for security requirements (SR-xxx) and data privacy classifications (PII categories, encryption requirements, data residency). Either spawn Teammate 3 after Teammate 2 completes, or include Teammate 2's security and compliance context in Teammate 3's spawn prompt.

Each teammate's spawn prompt must include:
- The instruction: "Check `./plancasting/tech-stack.md` for the `Session Language` setting. Generate all BRD content and user-facing output in the specified language. Code, technical identifiers, and file names remain in English."
- The instruction: "Read CLAUDE.md Part 1 (immutable rules) if it exists in the project root. Follow its conventions. Ignore Part 2 (project-specific configuration) — it contains implementation details that should not influence requirements definitions. Requirements are tech-neutral; tech stack adaptation happens in later stages."
- The full content of `./plancasting/brd/_context.md` (copy the FULL TEXT inline into each spawn prompt — do not instruct teammates to read the file themselves, as parallel teammates may race on file reads)
- Their specific file assignments and ID ranges
- Instructions to read the Business Plan sections most relevant to their domain
- The explicit instruction: "The Business Plan may describe features in phases or as future roadmap items. IGNORE all phasing. Treat every described feature as in-scope for this BRD."
- The writing guidelines (see "Writing Guidelines" section at end of this prompt)

#### Teammate 1: "business-core"
**Domain**: Business strategy and functional requirements
**Files to generate**:
- `00-cover-and-metadata.md` — Document metadata, version, revision history, approval table, TOC
- `01-executive-summary.md` — Problem statement, proposed solution, KPIs, critical success factors
- `02-project-background-and-objectives.md` — Business context, SMART objectives, strategic alignment, ROI
- `03-current-state-analysis.md` — As-is processes, gap analysis, pain points, process flows (mermaid)
- `06-business-requirements.md` — Numbered BRs with rationale, priority (MoSCoW), acceptance criteria, traceability matrix
- `07-functional-requirements.md` — FRs in user story format, traced to BRs, organized by module, with mermaid flows

**Spawn prompt must emphasize**: Every BR and FR must trace back to a specific Business Plan section. Use quantified acceptance criteria. Generate mermaid diagrams for all process flows. The functional requirements must cover ALL features from the master feature inventory — including those originally described as future phases in the Business Plan. The FR range is expanded (FR-001–FR-299) to accommodate the full scope.

#### Teammate 2: "technical-infrastructure"
**Domain**: Non-functional, security, and compliance requirements
**Files to generate**:
- `08-non-functional-requirements.md` — Performance, scalability, availability (SLA/MTBF/MTTR/RPO/RTO), accessibility (WCAG), i18n, disaster recovery
- `12-regulatory-and-compliance-requirements.md` — Applicable laws/regulations, industry standards, audit trails, data residency
- `13-security-requirements.md` — AuthN/AuthZ, encryption, OWASP Top 10, monitoring, incident response, penetration testing

**Spawn prompt must emphasize**: Non-functional requirements must be sized for the COMPLETE product (all features active simultaneously, full user base from day one). Do not size for an MVP subset. Scalability targets should reflect the Business Plan's full growth projections, not a reduced initial load. If not explicitly stated, mark as assumptions.

#### Teammate 3: "data-and-integration"
**Domain**: Data architecture, integrations, and migration
**Files to generate**:
- `09-data-requirements.md` — Data model, data flows (mermaid), data quality, volume projections, retention, privacy classification, governance
- `10-integration-requirements.md` — Systems list, integration patterns, API specs, third-party dependencies, auth for integrations
- `16-migration-and-transition-requirements.md` — Migration strategy, data mapping, rollback, training, go-live checklist

**Spawn prompt must emphasize**: The data model must accommodate ALL entities across ALL features in the master feature inventory from day one. Do not design a minimal schema that would need expansion later. Integration requirements must cover ALL third-party systems mentioned anywhere in the Business Plan, including those described as future integrations.

#### Teammate 4: "user-experience-and-operations"
**Domain**: UX, business rules, reporting, and analytics
**Files to generate**:
- `04-stakeholder-analysis.md` — Stakeholder table, RACI matrix, communication plan, escalation paths
- `05-scope-definition.md` — In/out scope, change control
- `11-user-experience-requirements.md` — Personas, user journeys, UI/UX principles, responsive design, brand adherence
- `14-business-rules-and-logic.md` — Business rule catalog, decision tables, workflow state transitions (mermaid)
- `15-reporting-and-analytics-requirements.md` — Reports/dashboards list, KPI definitions, analytics capabilities

**Spawn prompt must emphasize**: Scope definition file (`05`) must explicitly state that ALL features from the Business Plan are in-scope. There is no MVP definition or phase breakdown. The in-scope list must be exhaustive. The out-of-scope section only contains items NOT mentioned in the Business Plan at all. Derive personas from ALL customer segments described in the Business Plan, including those targeted in later phases. Business rules must cover ALL feature interactions, including cross-feature rules that only emerge when everything is built together.

#### Teammate 5: "risk-and-planning"
**Domain**: Risk, cost-benefit, timeline, acceptance, and constraints
**Files to generate**:
- `17-acceptance-criteria.md` — UAT approach, test scenarios, entry/exit criteria, defect classification, sign-off process
- `18-assumptions-constraints-dependencies.md` — Assumptions/constraints/dependencies tables with impact analysis
- `19-risk-analysis-and-mitigation.md` — Risk register, risk heat map, top 10 risks with mitigation, monitoring cadence
- `20-cost-benefit-analysis.md` — Cost breakdown, benefits quantification, NPV, payback period, sensitivity analysis, 3–5 year TCO
- `21-timeline-and-milestones.md` — Milestone table, Gantt chart (mermaid), critical path, decision gates

**Spawn prompt must emphasize**: Risk analysis must include the additional risks specific to a full-build approach (complexity risk, integration risk from building all features simultaneously, testing scope risk). Cost-benefit analysis should reflect the complete build cost vs. the benefit of delivering all features at once (faster time-to-full-value, no re-architecture costs, no migration between phases). Timeline must be structured around parallel workstreams for the full feature set, NOT sequential phases. Use a Gantt chart showing concurrent development of all major functional areas. Milestones should mark completion of functional areas, not phase gates.

### Token Budget Management

Each spawned agent has an output token limit per response (see tech-stack.md § Model Specifications "Output token limit"). If a teammate's output is truncated, re-spawn it with a smaller scope. A single agent generating a large file (e.g., 07-functional-requirements.md with 200+ FRs) will hit this limit and fail. The team lead must proactively split heavy workloads BEFORE spawning agents. Note: the pipeline model's context window (see tech-stack.md § Model Specifications) means input context is not the bottleneck — the output token limit per agent response is the binding constraint.

#### Estimation Heuristics

Use these estimates to predict output size per file:
- Each functional requirement (FR) with full detail (user story format, acceptance criteria, mermaid flow): ~200–400 tokens
- Each business rule (BRL) with decision table: ~150–300 tokens
- Each data requirement (DR) with schema detail: ~200–400 tokens
- Each non-functional requirement (NFR) with quantified targets: ~150–250 tokens
- Tables, mermaid diagrams, and cross-references add ~30% overhead

#### Estimation Formula

~~~
Total ≈ (BRs × 150) + (FRs × 300) + (NFRs × 200) + (CRs × 100) + (SRs × 100) + (BRLs × 150) + (DRs × 200) + (IRs × 100) + (Diagrams × 300) + (Glossary terms × 50) + 2000 overhead
~~~

Diagram complexity varies: simple flow (~150 tokens), complex state machine (~500 tokens). Cross-reference overhead scales with feature count — add ~10% for projects with 100+ FRs.

Safe output budget per agent: see tech-stack.md § Model Specifications "Safe output budget" (calculated as output token limit minus 7K headroom for formatting overhead, error recovery, and retry margin).

**Token limit behavior**: If a teammate approaches the output token limit, the output will be truncated. The teammate should message the lead with: 'Output token limit approaching — generated [Filename] but did not complete [MissingFilename]. Re-spawn with reduced scope to complete missing files.' The lead must re-spawn the teammate with smaller scope.

#### Splitting Rules

During Phase 1 planning, BEFORE spawning any teammate:

1. **Estimate output size** for each file based on the number of requirements it must contain.
2. **If a single file is estimated to exceed the safe output budget (see tech-stack.md § Model Specifications)** (e.g., 07-functional-requirements.md with 100+ FRs): Split that file's generation into multiple agents, each handling a subset. For example:
   - Split by feature group or module (e.g., "FRs for authentication & user management" vs "FRs for billing & payments" vs "FRs for core product features")
   - Each sub-agent generates its portion with consistent formatting
   - The lead merges the outputs into a single file during Phase 4
3. **If a teammate's combined files are estimated to exceed the safe output budget (see tech-stack.md § Model Specifications)** but no single file is the problem: Split the teammate into multiple agents, each responsible for a subset of files.
4. **Lightweight files** (metadata, cover pages, glossaries, appendices) can be grouped together on a single agent.

#### Split Spawn Protocol

When splitting a teammate:
- Each sub-agent gets the SAME context (`_context.md`, writing guidelines, full-scope instruction)
- Each sub-agent gets a UNIQUE ID range subset (e.g., sub-agent A gets FR-001–FR-099, sub-agent B gets FR-100–FR-199)
- Each sub-agent's spawn prompt specifies EXACTLY which features/modules it is responsible for
- The lead tracks all sub-agents and merges their outputs in Phase 4

#### Known Heavy Files (likely to need splitting)

- `07-functional-requirements.md` — scales linearly with feature count. With 30+ features, this file almost certainly exceeds the safe output budget (see tech-stack.md § Model Specifications). Plan to split by feature group.
- `14-business-rules-and-logic.md` — if the product has complex cross-feature business rules, this can grow large. Monitor and split if needed.

#### Teammate Failure Recovery
If a teammate fails (crashes, times out, or produces truncated output):
1. Check which files were successfully written to `./plancasting/brd/`.
2. For missing files: re-spawn with the same context and file assignments.
3. For truncated files: re-spawn, instructing the agent to complete from the last complete section.
4. If a re-spawned teammate's output is still truncated after reducing scope, split the failing file's scope further into smaller chunks (one chunk per new agent), each with unique ID ranges, and merge the outputs in Phase 4. Do not retry the same scope more than once.
5. Do not proceed to Phase 4 until all assigned files are complete.

Do not proceed to Phase 4 until ALL teammates have completed their file generation.

### Phase 3: Coordination During Execution

While teammates are working:
1. Monitor progress via the shared task list.
2. Cross-team coordination is best-effort. The lead must front-load as much shared context as possible in the spawn prompts. Teammates communicate intermediate results to the lead via their completion messages for Phase 4 integration — teammates should not write directly to `_context.md` (the lead manages that file). Teammates should not depend on each other's outputs during parallel execution. Known dependencies (e.g., Teammate 2 → Teammate 3) are resolved by the lead before spawning, either by sequencing or by pre-loading context into the dependent teammate's spawn prompt. If a teammate's output depends on another teammate's output, the lead should spawn the dependent teammate AFTER the dependency completes:
   - When Teammate 4 defines KPIs → if Teammate 5 needs those KPIs, spawn Teammate 5 after Teammate 4 completes (or include estimated KPIs in Teammate 5's spawn prompt)
   - When Teammate 2 defines security requirements → if Teammate 3 needs those, spawn Teammate 3 after Teammate 2 completes (or include security context in Teammate 3's spawn prompt)
3. Resolve any conflicts or ambiguities raised by teammates.
4. Ensure consistency: if a teammate identifies a feature interaction that only exists because ALL features are being built together (e.g., a reporting feature that aggregates data from a feature originally planned for a later phase), ensure the interaction is properly documented.

### Phase 4: Structural Integration

After all teammates complete their tasks:

1. Collect all generated files into `./plancasting/brd/`.
2. Perform structural consistency checks:
   - **Full-scope coverage audit**: Cross-check the master feature inventory against all FR-xxx entries. Every feature in the inventory must have at least one corresponding functional requirement. Flag any gaps.
   - Verify all requirement IDs are unique across all files (no duplicates across teammates)
   - Validate all cross-reference links between files
   - Ensure terminology is consistent with `_context.md` glossary
   - Confirm all assumptions are marked with `> ⚠️ ASSUMPTION:`
   - Assumption volume check: Count all `> ⚠️ ASSUMPTION:` markers. If >= 30% of total requirements are assumptions (across ALL categories combined: BR + FR + NFR + CR + SR + BRL + DR + IR), flag as CRITICAL for business plan remediation. If flagged as CRITICAL, include in the Final Summary (Phase 6 Remediation, step 7: Final Summary) and recommend the user remediate the Business Plan before proceeding to Stage 2.
   - **Calculation**: Assumption Percentage = (count of `> ⚠️ ASSUMPTION:` blockquotes — each blockquote = 1 assumption regardless of size) / (count of unique requirement IDs: BR-xxx + FR-xxx + NFR-xxx + CR-xxx + SR-xxx + BRL-xxx + DR-xxx + IR-xxx) × 100. If a single requirement contains multiple assumption blockquotes, count each separately. If ≥ 30%, flag as CRITICAL in the final summary. Example: 150 total requirement IDs, 50 assumption blockquotes → 50/150 = 33% → CRITICAL. This assumption volume check applies to BRD generation only. Downstream stages (PRD, 2B) do not independently re-check assumption ratios — they inherit BRD's assumptions and may flag additional ones.
   - Validate mermaid diagram syntax in all files
   - Check that every BR has at least one corresponding FR
   - Verify MoSCoW priorities are distributed reasonably (see MoSCoW distribution targets in Known Failure Pattern #3). Flag if Must Have exceeds 70% of total requirements.
   - **When distribution may deviate from typical ranges**: High Must Have (70%+) is acceptable for enterprise/regulated products with mandatory compliance requirements or products with many interdependent features. Low Must Have (<50%) is acceptable for exploratory products or platform products with optional integrations. RED FLAG: if Business Plan describes 'MVP first, phases later' but all requirements are marked Must Have — indicates phasing hasn't been eliminated despite full-build approach.
   - **Cross-feature interaction check**: Identify requirements that interact across what the Business Plan originally described as separate phases. Ensure these interactions are explicitly documented.
3. Generate `22-glossary-and-appendices.md` — consolidating terms from all files, adding cross-reference matrix
4. Generate `README.md` — BRD overview, navigation guide, file descriptions, reading order, conventions. Include a prominent note: "This BRD covers the complete product scope as described in the Business Plan. No features have been deferred."
5. Fix any structural inconsistencies found (ID conflicts, broken links, missing cross-references).

### Phase 5: Deep Quality Review

Spawn 3 specialized review agents to perform a comprehensive quality audit. Each reviewer reads ALL generated BRD files plus `_context.md` and the original Business Plan, then produces a structured issue report.

With the pipeline model's context window (see tech-stack.md § Model Specifications), the combined BRD + Business Plan typically fits within a single review agent's context. For exceptionally large products (see tech-stack.md § Model Specifications "Large product threshold"), the lead should split each review agent's scope to a subset of BRD files (grouped by domain). Heuristic: if the combined BRD files exceed 60% of the model's context window (check tech-stack.md § Model Specifications "Context window"), split the review scope by domain. The lead then performs cross-file consistency checks in Phase 6 remediation.

#### Review Agent Spawn Protocol

Each review agent's spawn prompt must include:
- The instruction: "Check `./plancasting/tech-stack.md` for the `Session Language` setting. Generate all BRD content and user-facing output in the specified language. Code, technical identifiers, and file names remain in English."
- The instruction: "Read CLAUDE.md Part 1 (immutable rules) if it exists in the project root. Follow its conventions. Ignore Part 2 (project-specific configuration) — it is not yet populated at this stage."
- The list of all generated BRD files to review
- Instructions to read every file in `./plancasting/brd/` and relevant `./plancasting/businessplan/` files
- The issue report format (below)
- Their specific review checklist

#### Issue Report Format (used by ALL review agents)

Each agent produces a list of issues in this format:

    ## [AGENT-NAME] Review Report

    ### Issue [N]
    - **Severity**: CRITICAL | HIGH | MEDIUM | LOW
    - **File**: [filename]
    - **Location**: [section/requirement ID]
    - **Category**: [from agent's checklist]
    - **Description**: [What is wrong]
    - **Recommendation**: [How to fix it]
    - **Affected Requirements**: [List of requirement IDs impacted]

Severity definitions:
- Requirement is missing, contradictory, or would cause implementation failure. Blocks development.
- **HIGH**: Requirement is vague, incomplete, or technically infeasible. Would cause rework during development.
- **MEDIUM**: Quality issue that reduces clarity but doesn't block development. Inconsistency or missing detail.
- **LOW**: Polish issue — formatting, minor terminology drift, optimization suggestion.

#### Review Agent 1: "completeness-reviewer"
**Focus**: Coverage gaps, vagueness, and traceability
**Checklist**:
- [ ] Every feature in the master feature inventory has at least one FR
- [ ] Every BR has at least one corresponding FR
- [ ] Every FR has measurable acceptance criteria (not vague terms like "fast", "user-friendly", "intuitive", "seamless")
- [ ] Every FR specifies behavior for ALL states: normal operation, error conditions, edge cases, boundary conditions
- [ ] Every integration requirement (IR) specifies authentication method, error handling, retry policy, and fallback behavior
- [ ] Every data requirement (DR) specifies data types, validation rules, constraints, and retention policy
- [ ] Every business rule (BRL) specifies trigger conditions, actions, exceptions, and conflict resolution with other rules
- [ ] Every security requirement (SR) is specific and testable (not just "the system must be secure")
- [ ] All compliance requirements (CR) cite specific regulations/standards with section numbers
- [ ] Non-functional requirements have quantified targets (response time in ms, uptime percentage, throughput numbers)
- [ ] No requirement is a verbatim copy of Business Plan text — all requirements have been translated into structured format with IDs, acceptance criteria, and traceability
- [ ] Assumptions are reasonable and flagged with rationale
- [ ] No placeholder text, TODO markers, or "TBD" entries remain
- [ ] Cross-feature interactions are documented for features that span originally-separate Business Plan phases

#### Review Agent 2: "consistency-reviewer"
**Focus**: Contradictions, duplications, and terminology
**Checklist**:
- [ ] No contradictory requirements across files (e.g., one file says "real-time" while another says "batch processing" for the same data flow)
- [ ] No duplicate requirements with different IDs covering the same functionality
- [ ] Terminology is consistent across all files and matches `_context.md` glossary
- [ ] MoSCoW priorities are consistent — a requirement referenced as "Must Have" in one file is not "Should Have" in another
- [ ] Numerical targets are consistent — the same metric doesn't have different values in different files (e.g., uptime 99.9% in one place, 99.99% in another)
- [ ] User roles and personas are named consistently across all files
- [ ] Data entity names, attribute names, and relationship descriptions are consistent between data requirements and functional requirements
- [ ] Business rules don't conflict with each other (e.g., two rules that could fire simultaneously with contradictory outcomes)
- [ ] Integration requirements align with the technology stack in `plancasting/tech-stack.md`
- [ ] Timeline milestones are consistent with the scope described in functional requirements
- [ ] Cost estimates align with the technical complexity described in other sections

#### Review Agent 3: "technical-reviewer"
**Focus**: Technical feasibility, accuracy, and completeness
**Checklist**:
- [ ] Functional requirements are technically feasible with the specified tech stack
- [ ] Non-functional targets are realistic (e.g., not requiring 1ms response time for complex database queries)
- [ ] Data model can support all described functional requirements without fundamental restructuring
- [ ] Integration requirements reference real, available APIs/services (not fictional ones)
- [ ] Security requirements follow current best practices (not outdated approaches like MD5 hashing, basic auth for production APIs)
- [ ] Scalability requirements align with the chosen infrastructure and architecture patterns
- [ ] Mermaid diagrams are syntactically valid and accurately represent the described flows
- [ ] Performance requirements account for the full feature set running simultaneously (not just individual feature benchmarks)
- [ ] Data volume projections are realistic given the business model and growth targets
- [ ] Disaster recovery and backup requirements are achievable with the specified tech stack
- [ ] Rate limiting, caching, and optimization strategies are appropriate for the described usage patterns

### Phase 6: Remediation

After all 3 review agents complete their reports:

1. **Consolidate**: Merge all review reports into a single prioritized issue list. Remove duplicate findings (same issue reported by multiple reviewers — keep the most detailed version). Count issues by severity.

2. **Quality Gate Check**:
   - If CRITICAL issues exist → remediation is MANDATORY
   - If HIGH issues exist → remediation is MANDATORY
   - MEDIUM and LOW issues → fix what can be fixed efficiently, document the rest

3. **Fix Issues**: For each CRITICAL and HIGH issue:
   - Read the affected BRD file
   - Apply the recommended fix (or a better alternative if the recommendation is insufficient)
   - Verify the fix doesn't introduce new inconsistencies with other files
   - Mark the issue as resolved

4. **Remediation Principles**:
   - Fix the ROOT CAUSE, not just the symptom. If a vague FR is found, don't just add one word of specificity — rewrite the acceptance criteria properly.
   - When fixing contradictions, determine the CORRECT version by consulting the Business Plan, then update ALL files that reference the incorrect version.
   - When adding missing requirements, follow the same ID conventions and formatting as existing requirements.
   - When fixing technical feasibility issues, adjust the requirement to be achievable while preserving the business intent.

5. **Second Pass** (conditional): If the initial remediation resolved more than 15 CRITICAL+HIGH issues, perform a targeted re-review of ONLY the modified files to ensure fixes didn't introduce new problems. (Threshold: 15+ fixes indicates significant document modification, increasing the risk of introduced inconsistencies that require a re-review pass.) This re-review does not require spawning new agents — the lead performs it directly using the review checklists above. This is a single re-review pass — if it finds new CRITICAL issues, document them in the review log rather than entering a recursive loop.

6. **Document Remaining Issues**: Create `./plancasting/brd/_review-log.md` containing:
   - Review date and agent versions
   - Total issues found by severity (original counts)
   - Issues resolved by severity
   - Remaining MEDIUM/LOW issues with their descriptions and affected files
   - Any CRITICAL/HIGH issues that could not be fully resolved, with explanation and proposed resolution path
   - **Assumption Review Status** section (always include — Stage 2B reads this section for gate decisions):
     ```markdown
     ## Assumption Review Status
     - **Assumption volume**: [N]% ([count] assumptions / [count] requirement IDs)
     - **Flagged as CRITICAL**: YES / NO
     - **Operator reviewed**: NO (operator must change to YES after reviewing assumptions before Stage 2B)
     - **Date reviewed**: —
     - **Operator notes**: —
     ```
     The operator must manually update `Operator reviewed: YES` and add the review date after examining the assumptions. Stage 2B checks this marker to determine the gate outcome.

7. **Final Summary**: Output the following:
   - Total requirement counts by category (BR, FR, NFR, CR, SR, BRL, DR, IR)
   - Master feature inventory coverage: number of features covered vs total
   - Number of assumptions flagged
   - **Assumption volume**: Percentage of assumption blockquotes vs total requirement IDs. Each `> ⚠️ ASSUMPTION:` blockquote counts as 1 assumption regardless of how many distinct claims it contains. If ≥ 30%, include: "⚠️ CRITICAL: Assumption volume exceeds 30% ([N]%). Recommend reviewing and updating the Business Plan before proceeding to Stage 2. Proceeding with high assumptions risks downstream rework — Stage 2B validates but cannot fix fundamental Business Plan gaps." Ensure the assumption percentage is recorded in `./plancasting/brd/_review-log.md` § 'Assumption Review Status' (generated in step 6) — Stage 2B reads this file to make its gate decision.
   - **Pipeline halt** (if assumption volume >= 30%): Output a CRITICAL warning: "STOP — Do not proceed to Stage 2 until the operator has reviewed assumptions in BRD files and updated `_review-log.md` § Assumption Review Status to `Operator reviewed: YES`. Stage 2B will FAIL if this review has not been completed."
   - Number of mermaid diagrams generated
   - Number of cross-feature interactions identified
   - **Quality metrics**:
     - Total issues found: [N] (CRITICAL: [n], HIGH: [n], MEDIUM: [n], LOW: [n])
     - Issues resolved: [N] (CRITICAL: [n], HIGH: [n], MEDIUM: [n], LOW: [n])
     - Remaining issues: [N] (with severity breakdown)
     - Quality score: percentage of CRITICAL+HIGH issues resolved (target: 100%)
   - Any unresolved issues or areas needing human review

### Phase 7: Shutdown

Teammates terminate automatically upon task completion. No explicit shutdown is required. Verify all output files exist in `./plancasting/brd/` before declaring Stage 1 complete.

---

## Gate Decision

After Phase 6 remediation and the Final Summary are complete, determine the Stage 1 outcome using the following decision tree. Evaluate top to bottom and take the first match:

1. Any unresolved CRITICAL review issues (from Phase 5 reviewers) remaining after remediation? → **FAIL**
2. Any unresolved HIGH review issues remaining after remediation? → **FAIL**
3. Missing critical BRD sections (see Critical Sections definition below: 06, 07, 08, 09, 12, 13, 14)? → **FAIL**
4. Internal contradictions detected between BRD files (e.g., conflicting MoSCoW priorities, inconsistent data entity definitions, contradictory numerical targets)? → **FAIL**
5. Any business requirement (BR-xxx) not traceable to a specific Business Plan section? → **FAIL**
6. Master feature inventory coverage < 100% (features from Business Plan without corresponding FR-xxx entries)? → **FAIL**
7. All BRD sections complete, zero CRITICAL/HIGH issues, all BRs traceable to Business Plan, 100% feature inventory coverage, MoSCoW distribution within acceptable ranges (see Known Failure Pattern #3)? → **PASS**
8. Minor gaps in non-critical sections (e.g., 22-glossary-and-appendices.md incomplete, minor formatting issues in 00-cover-and-metadata.md or 21-timeline-and-milestones.md), but ALL core business requirements documented with traceability AND zero CRITICAL/HIGH issues AND feature inventory coverage = 100%? → **CONDITIONAL PASS** (document each gap with description and remediation plan in `_review-log.md`)
9. No rule matched? → **FAIL** (document the specific combination of metrics and escalate to operator for manual review)

**Definitions**:
- **Critical sections**: 06-business-requirements.md, 07-functional-requirements.md, 08-non-functional-requirements.md, 09-data-requirements.md, 12-regulatory-and-compliance-requirements.md, 13-security-requirements.md, 14-business-rules-and-logic.md
- **Non-critical sections**: 00-cover-and-metadata.md, 03-current-state-analysis.md, 04-stakeholder-analysis.md, 20-cost-benefit-analysis.md, 21-timeline-and-milestones.md, 22-glossary-and-appendices.md
- **Traceable**: A BR-xxx includes an explicit reference to a Business Plan section (e.g., "Derived from Business Plan § Product Description") — not a vague or circular reference

**Assumption volume interaction**: If assumption volume ≥ 30% (flagged as CRITICAL in the Final Summary), the gate can still be PASS or CONDITIONAL PASS — the assumption volume triggers a pipeline halt (operator must review before Stage 2), but it does not downgrade the gate outcome for Stage 1's own quality assessment. The `_review-log.md` § Assumption Review Status captures this separately for Stage 2B's gate evaluation.

Include the gate decision in the Final Summary output and in `_review-log.md`: "Stage 1 Outcome: [PASS | CONDITIONAL PASS | FAIL]"

- **PASS** → proceed to Stage 2 (subject to assumption volume pipeline halt if applicable)
- **CONDITIONAL PASS** → proceed to Stage 2 with documented exceptions (subject to assumption volume pipeline halt if applicable)
- **FAIL** → remediate and re-run Stage 1

---

## Writing Guidelines (Include in ALL teammate spawn prompts)

1. **Full Scope**: Every feature, capability, and function described anywhere in the Business Plan is in-scope. Ignore any phasing, sequencing, or deferral language in the Business Plan. If the Business Plan says "in Phase 3, we will add X," then X is a current requirement.
2. **Traceability**: Every requirement must trace to a specific Business Plan section. Use explicit references (e.g., "Derived from Business Plan § Market Analysis" or "Derived from Business Plan § Phase 2 Roadmap → Feature X").
3. **Measurability**: All requirements must include measurable acceptance criteria. Avoid vague terms like "fast," "user-friendly," or "scalable" without quantification.
4. **Completeness**: If the Business Plan lacks sufficient detail for a section, generate reasonable assumptions and mark them with `> ⚠️ ASSUMPTION: [Assumption text explaining why this is assumed and its impact]` blockquotes. The assumption text must explain both the reasoning and the potential impact if the assumption is wrong. Never leave sections empty.
5. **Consistency**: Use terminology defined in `./plancasting/brd/_context.md`. Define new terms and notify the lead for glossary inclusion (via message to lead — do not write directly to `_context.md`, as the lead manages that file during Phase 4 integration).
6. **Mermaid Diagrams**: Use mermaid syntax for all diagrams (flowcharts, sequence diagrams, state diagrams, Gantt charts, ER diagrams). Wrap in mermaid-tagged code blocks.
7. **Cross-references**: Use relative markdown links (e.g., `[See Functional Requirements](./07-functional-requirements.md#fr-003)`).
8. **Professional Tone**: Clear, precise, professional tone in the session language. Active voice (e.g., "The system validates the input" not "The input is validated"). No ambiguity.
9. **Structured Tables**: Use markdown tables for all structured data (requirements, risks, stakeholders, etc.).
10. **Depth**: This is an enterprise-grade BRD. Be exhaustive. Each file must be comprehensive enough to serve as a standalone reference for its domain.
11. **Requirement IDs**: Follow the ID format and ranges defined in `_context.md`. Ensure uniqueness within your assigned range.
12. **Cross-Feature Interactions**: When documenting a requirement, consider how it interacts with ALL other features (not just features from the same Business Plan phase). Document these interactions explicitly.
13. **Lowercase Anchors**: Use lowercase anchors in all heading IDs and cross-reference links (e.g., `#br-001` not `#BR-001`) for compatibility with case-sensitive systems and downstream PRD linking. When creating cross-reference links to other BRD sections, use lowercase in the anchor portion (e.g., `[See BR-001](./06-business-requirements.md#br-001)` not `#BR-001`). Markdown heading IDs are auto-generated in lowercase by most renderers.

## Gate Decision (Simplified Reference)

> The canonical gate decision logic is in the detailed Gate Decision section above (§ Gate Decision, after Phase 7). This simplified reference summarizes the three possible outcomes — if any discrepancy, the detailed decision tree above takes precedence.

- **PASS**: All 23 BRD files generated and complete, master feature inventory covers 100% of Business Plan features, zero CRITICAL/HIGH issues, all BRs traceable, all cross-references resolve, mermaid diagrams render without syntax errors. Note: assumption volume ≥ 30% triggers a pipeline halt (operator review before Stage 2) but does not downgrade the gate outcome.
- **CONDITIONAL PASS**: All BRD files generated, 100% feature inventory coverage, zero CRITICAL/HIGH issues, but minor gaps in non-critical sections (glossary, appendices, formatting). Document each gap in `_review-log.md`. Assumption volume interaction same as PASS.
- **FAIL**: Missing critical BRD files, master feature inventory incomplete, unresolved CRITICAL/HIGH issues, untraceable BRs, or files empty/corrupted. Re-run Stage 1.

> **Session Language**: Read `./plancasting/tech-stack.md` § 'Session Language' and generate all BRD content in the specified language. If Session Language is not set, STOP: 'Stage 1 requires Session Language to be defined in tech-stack.md by Stage 0.'

> **Prerequisite**: Verify `./plancasting/tech-stack.md` exists. If missing, STOP: 'Stage 1 requires `plancasting/tech-stack.md` from Stage 0. Run Stage 0 first.'
````
