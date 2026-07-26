# Transmute Framework

[![GitHub Release](https://img.shields.io/github/v/release/VoxTechnologies/transmute-framework)](https://github.com/VoxTechnologies/transmute-framework/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub Stars](https://img.shields.io/github/stars/VoxTechnologies/transmute-framework)](https://github.com/VoxTechnologies/transmute-framework/stargazers)
[![Claude Code Plugin](https://img.shields.io/badge/Claude_Code-Plugin-blueviolet)](https://docs.anthropic.com/en/docs/claude-code)

**Turn a business plan into a deployed product — autonomously.**

A Claude Code plugin that transforms business plans into production-ready products through **Plan Casting** — a 25-stage automated pipeline where AI agent teams read your business plan, generate specifications, scaffold a project, implement every feature, audit and harden the codebase, deploy it, and produce documentation.

You write the plan. Transmute casts it into reality.

**Try it**: [transmuter.3mergen.com](https://transmuter.3mergen.com/)

![Transmute Framework Demo](demo.gif)

## What is Plan Casting?

Plan Casting is the philosophy behind Transmute: **build everything in the business plan**. No MVP, no phased delivery, no feature cutting. Features are implemented in priority order (P0 → P3), but all are built. AI agent teams work autonomously through 25 stages — from tech stack selection to production deployment and user documentation.

## Installation

### Install from GitHub (recommended)

In Claude Code, run:

```
/plugin
```

1. Navigate to the **Marketplaces** tab
2. Select **Add marketplace** and enter: `VoxTechnologies/transmute-framework`
3. Navigate to the **Discover** tab
4. Find **transmuter** and install it

After this, just run `claude` — Transmute loads automatically in every session. No extra flags needed.

You can choose a scope during installation:

| Scope | Effect |
|---|---|
| **user** (default) | Available in all your projects |
| **project** | Shared with your team via `.claude/settings.json` |
| **local** | Only you, only this repository |

### Try It (one-time)

```bash
git clone https://github.com/VoxTechnologies/transmute-framework.git
claude --plugin-dir ./transmute-framework
```

This loads the plugin for the current session only. You'll need to pass `--plugin-dir` each time.

### Updating

```
/plugin
```

Navigate to the **Installed** tab and select **Update** next to transmuter, or run `/reload-plugins` to refresh all plugins.

### Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed and authenticated

## Quick Start

1. **Prepare your business plan** — write markdown files describing your product idea, target users, features, and business model.

2. **Create a project directory** and place your plan inside `plancasting/businessplan/`:
```bash
mkdir -p ~/my-project/plancasting/businessplan
cp my-plan.md ~/my-project/plancasting/businessplan/
cd ~/my-project
```

3. **Launch Claude Code** with the Transmute plugin:
```bash
claude --plugin-dir /path/to/transmute-framework
```

4. **Run the pipeline**:
```
/transmuter:cast
```

5. **Resume if interrupted**:
```
/transmuter:cast resume
```

## Pipeline

```
Business Plan → Tech Stack → BRD → PRD → Spec Validation → Scaffold + Verify
   [Input]        [0]       [1]   [2]      [2B]              [3+4]

→ Implementation → Completeness Audit → Quality Assurance → Pre-Launch
       [5]                [5B]              [6A–6G]         [6H]

→ Live Verification → Remediation → Visual Polish or Redesign → Deploy
        [6V]              [6R]              [6P / 6P-R]          [7]

→ Production Smoke → User Guide → Feedback / Maintenance
        [7V]            [7D]         [8] / [9]
```

| Stage  | Name                        | What Happens                                                                |
| ------ | --------------------------- | --------------------------------------------------------------------------- |
| **0**  | Tech Stack Discovery        | Interactive — choose framework, database, hosting. Outputs `plancasting/tech-stack.md` |
| **1**  | BRD Generation              | 5 AI writer agents + 3 reviewers generate Business Requirements            |
| **2**  | PRD Generation              | Multiple agents produce 18-section Product Requirements                    |
| **2B** | Spec Validation             | Cross-validates BRD against PRD for consistency                            |
| **3**  | Scaffold Generation         | Creates full project skeleton from PRD                                     |
| **4**  | CLAUDE.md Verification      | *Manual* — verify Part 2 has project specifics                             |
| **5**  | Feature Implementation      | Agent teams implement every feature in priority order (P0→P3)              |
| **5B** | Implementation Audit        | Verifies all PRD features are actually implemented                         |
| **6A** | Security Audit              | OWASP vulnerabilities, auth issues, injection risks                        |
| **6B** | Accessibility Audit         | ARIA, keyboard nav, color contrast, screen reader support                  |
| **6C** | Performance Optimization    | Bottlenecks, bundle size, slow queries                                     |
| **6E** | Code Refactoring            | Cleans up issues found in 6A–6C                                            |
| **6F** | Seed Data Generation        | Realistic test/demo data                                                   |
| **6G** | Error Resilience            | Error handling, fallbacks, recovery                                        |
| **6D** | Documentation               | Developer docs, API references                                             |
| **6H** | Pre-Launch Verification     | Final readiness check                                                      |
| **6V** | Visual & Functional Verify  | UI matches specs, interactions work correctly                              |
| **6R** | Runtime Remediation         | Fixes 6V failures (skipped if 6V passes clean)                             |
| **6P** | Visual Polish               | Final UI refinements                                                       |
| **6P-R** | Frontend Design Elevation | Interactive full design overhaul (alternative to 6P)                       |
| **7**  | Deployment                  | *Manual* — deploy backend first, then frontend                             |
| **7V** | Production Smoke Tests      | End-to-end live deployment verification                                    |
| **7D** | User Guide Generation       | End-user documentation                                                     |
| **8**  | Feedback Loop               | User feedback → spec updates → code changes                               |
| **9**  | Dependency Maintenance      | Keep dependencies current (monthly/quarterly)                              |

## Commands

### Pipeline Controller

| Command                     | Description                        |
| --------------------------- | ---------------------------------- |
| `/transmuter:cast`           | Run the full pipeline (Stages 0–9) |
| `/transmuter:cast full`      | Same as above                      |
| `/transmuter:cast resume`    | Resume from last completed stage   |
| `/transmuter:cast <stage>`   | Run a specific stage               |
| `/transmuter:cast help`      | Show all stage names               |

### Individual Stages

Each stage is also a standalone skill. The plugin namespace is `transmuter`, so the qualified form is `/transmuter:<stage>`. Claude Code autocomplete matches on the stage name as you type and labels the entry `(transmuter)`:

| Command                        | Stage | Description                      |
| ------------------------------ | ----- | -------------------------------- |
| `/transmuter:tech-stack`        | 0     | Interactive tech stack discovery |
| `/transmuter:brd`               | 1     | Business Requirements            |
| `/transmuter:prd`               | 2     | Product Requirements             |
| `/transmuter:validate-specs`    | 2B    | Spec validation                  |
| `/transmuter:scaffold`          | 3     | Project scaffolding              |
| `/transmuter:implement`         | 5     | Feature implementation           |
| `/transmuter:audit-completeness`| 5B    | Implementation audit             |
| `/transmuter:audit-security`    | 6A    | Security audit                   |
| `/transmuter:audit-a11y`        | 6B    | Accessibility audit              |
| `/transmuter:optimize`          | 6C    | Performance optimization         |
| `/transmuter:docs`              | 6D    | Documentation                    |
| `/transmuter:refactor`          | 6E    | Code refactoring                 |
| `/transmuter:seed-data`         | 6F    | Seed data generation             |
| `/transmuter:harden`            | 6G    | Error resilience                 |
| `/transmuter:prelaunch`         | 6H    | Pre-launch verification          |
| `/transmuter:verify`            | 6V    | Visual & functional verification |
| `/transmuter:remediate`         | 6R    | Runtime remediation              |
| `/transmuter:polish`            | 6P    | Visual polish                    |
| `/transmuter:redesign`          | 6P-R  | Frontend design elevation        |
| `/transmuter:smoke`             | 7V    | Production smoke tests           |
| `/transmuter:user-guide`        | 7D    | User guide generation            |
| `/transmuter:feedback`          | 8     | Feedback loop                    |
| `/transmuter:maintain`          | 9     | Dependency maintenance           |

Stages **4** and **7** are manual and cannot be invoked via commands.

## How It Works

1. **You provide a business plan** — markdown or PDF files describing your product
2. **Stage 0 is interactive** — you choose your tech stack (framework, database, auth, hosting, etc.)
3. **Stages 1–3 generate specs** — BRD, PRD (18 sections), and project scaffold
4. **Stage 5 builds the product** — per-feature agent teams (backend, frontend, test, reviewer) implement everything
5. **Stages 6A–6P/6P-R audit and harden** — security, accessibility, performance, refactoring, resilience, documentation, visual verification
6. **Stage 7 is manual deployment** — you deploy, then the plugin runs smoke tests
7. **Stages 8–9 are ongoing** — process user feedback and maintain dependencies

The pipeline is **gate-enforced** — you cannot skip stages. Prerequisites are checked before each stage runs. If a stage fails, fix the issue and run `/transmuter:cast resume`.

### Gate Logic

- **5B**: PASS requires zero issues + all tests pass; FAIL triggers RETRY (4-5 Category C, 3+ A/B unfixed, or test failures) or ESCALATE (6+ Category C); per-feature consecutive FAIL-RETRY tracking (3x → auto-escalate)
- **6V**: Dual gate system — PASS skips 6R, CONDITIONAL PASS routes to 6R, FAIL stops pipeline. Supports three scope modes: `full`, `critical`, `diff`
- **6R**: Max 3 internal fix-verify cycles per run before escalation; max 2 outer 6V→6R cycles total
- **7V**: 3-outcome gate — PASS or CONDITIONAL PASS proceeds to 7D (CONDITIONAL PASS documents minor P1/P2 issues for post-launch fix via Stage 8), FAIL requires hotfix + re-deploy or rollback
- **6P**: Issues categorized as Omission (O), Execution (E), or Design (D)
- **6P-R**: Severity levels — Critical, Major, Minor
- **6A/B/C**: Run as parallel agents for safe concurrent execution
- **8 + 9**: NEVER run concurrently — feedback loop and dependency maintenance are mutually exclusive

### Credential Tier System

Four credential tiers gate pipeline progression:

| Tier | Gate | Credentials |
|------|------|-------------|
| :red_circle: Placeholder | Before Stage 3 | No `YOUR_*_HERE`, `TODO_*`, `CHANGE_ME`, `PLACEHOLDER` patterns in `.env.local` |
| :yellow_circle: Service | Before Stage 5 | Product service credentials must be real |
| :orange_circle: Deploy | Before Stage 7 | Deployment credentials configured |
| :large_blue_circle: Production | Before Stage 7V | Live environment credentials verified |

### Progress Tracking (v2.0.0)

Pipeline status now includes a **Blocked** state (`⏸ Blocked`) alongside existing statuses (`✅ Done`, `🔧 In Progress`, `⬜ Not Started`, `🔄 Needs Re-implementation`), enabling clear state transition tracking across all 25 stages.

## Agent Teams

Several stages use Claude Code Agent Teams to parallelize work:

- **Stage 1** (BRD): 5 writer agents + 3 review agents
- **Stage 2** (PRD): Multiple writer agents producing 18 document sections
- **Stage 5** (Implementation): Per-feature teams with backend, frontend, test, and reviewer agents
- **Stage 6A–6C**: Three audit stages run as parallel safety agents (concurrent execution safe by design)
- **Stage 6V/7V**: Scenario generation via `feature_scenario_generation.md` template for systematic test coverage

## Project Output

After running the pipeline, your project will contain:

```
your-project/
├── plancasting/                 # All pipeline artifacts
│   ├── businessplan/            # Your input (read-only)
│   ├── tech-stack.md            # Stage 0
│   ├── brd/                     # Stage 1
│   ├── prd/                     # Stage 2 (18 sections)
│   ├── _progress.md             # Pipeline tracking
│   ├── _scaffold-manifest.md    # Stage 3
│   ├── _audits/                 # All audit reports
│   ├── _launch/                 # Pre-launch reports
│   └── _maintenance/            # Stage 9 reports
├── CLAUDE.md                    # Project conventions
├── .env.local                   # Credentials
├── src/                         # Product code
├── docs/                        # Developer documentation
├── seed/                        # Seed data
└── user-guide/                  # End-user guide
```

## Plugin Architecture

```
transmute-framework/
├── .claude-plugin/plugin.json   # Plugin manifest
├── commands/cast.md             # /transmuter:cast entry point
├── agents/
│   ├── transmute-pipeline.md    # Full pipeline orchestrator
│   ├── brd-writer.md            # BRD section writer
│   ├── prd-writer.md            # PRD section writer
│   ├── feature-backend.md       # Backend implementation
│   ├── feature-frontend.md      # Frontend implementation
│   ├── feature-tests.md         # E2E test writing
│   └── feature-reviewer.md      # Code review gate
├── skills/                      # 23 stage skills
│   ├── tech-stack/              # Stage 0
│   ├── brd/                     # Stage 1
│   ├── prd/                     # Stage 2
│   └── ...                      # One directory per stage
├── hooks/
│   ├── hooks.json               # Gate enforcement registration
│   └── scripts/
│       └── check-prerequisites.sh
└── templates/
    ├── CLAUDE.md                # Project CLAUDE.md template
    ├── progress.md              # Progress tracking template
    ├── execution-guide.md       # Pipeline execution reference
    ├── feature_scenario_generation.md  # 6V/7V scenario generation
    └── rules-templates/         # 6 path-scoped rules templates
        ├── _api-contracts-template.md
        ├── _auth-template.md
        ├── _backend-template.md
        ├── _data-model-template.md
        ├── _frontend-template.md
        └── _testing-template.md
```

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated
- Node.js v20.17+ (required by Stage 7D Mintlify CLI; v18+ sufficient for earlier stages)
- A business plan (markdown or PDF files)

## Changelog

### v3.0.1

**Command namespace correction** — the plugin was renamed to `transmuter` in v3.0.0's config files, but the docs still told users to type `/transmute:cast`. That prefix matches no installed plugin, so every documented command failed.

- All command references corrected to `/transmuter:cast` and `/transmuter:<stage>` across README, `commands/cast.md`, `CONTRIBUTING.md`, and `agents/transmute-pipeline.md`
- Install and update instructions now name **transmuter** in the `/plugin` marketplace listing (was **transmute**)
- Individual-stage table now shows the qualified `/transmuter:<stage>` form rather than bare short names, with the autocomplete behavior described in prose

**Model IDs refreshed to the current generation**

- Pipeline model: `claude-opus-4-6` → `claude-opus-5`; lighter-stage alternative: Sonnet 4.6 → `claude-sonnet-5` (`templates/execution-guide.md`, `skills/tech-stack/references/tech-stack-detailed-guide.md`)
- Fixed two non-existent model IDs used as examples: `claude-sonnet-4-5-20250514` and `claude-sonnet-4-6-20250514`. Neither is a real ID — current Claude models carry no date suffix, and the latter appeared in the Stage 7V guide that teaches agents to detect hallucinated model IDs
- Added a note to the Stage 0 credential-validation snippet recording that current IDs take no date suffix, and that `claude-haiku-4-5-20251001` is the only dated full form among the current models

### v3.0.0

**22nd-Pass Audit Sync** — comprehensive alignment of all plugin files with the canonical Transmute Framework Template (17th → 22nd pass audits).

**Safety-Critical Gate Fixes**
- 6V gate system: corrected to "worse-of" dual system (percentage-based AND fixability-based); plugin previously described pass rate as "sole gate determinant"
- Post-6R FAIL routing: corrected to "fix 6V-C manually" (human-judgment issues); plugin previously said "fix 6V-A/B manually" (opposite categories)
- 6P max-cycle exhaustion: expanded with explicit "effectively converts to CONDITIONAL PASS" framing, "NOT a true CONDITIONAL PASS" clarification, and updated report format string
- Stage 1 gate reclassified: no formal PASS/FAIL gate (grouped with Stages 0, 2, 4); plugin previously described a lightweight gate
- 6V/7V scenario caps: split into distinct rows (150 for 6V full, 15 for 7V smoke); plugin previously merged into single row

**Template Files** (all synced byte-identical with canonical template)
- CLAUDE.md: added missing Stage 3 prerequisite (2B must PASS/CONDITIONAL PASS), expanded 6R skip condition recovery detail, added 6D skip condition clause, corrected Stage 8 WARN description ("proceeding to Stage 8" not "deployment")
- execution-guide.md: 13 differences resolved including 6P-R prerequisite precision, credential tiers format, 5B "(without workaround)" qualifier removal, Stage 8 batch limit removal, skip conditions simplification
- feature_scenario_generation.md: 10 updates to skill reference copies (verify + smoke) — added Step 0 (filter by implementation status), generalized codebase paths to bracketed placeholders, expanded cycle detection to 3-step procedure, added Mermaid validation, expanded flaky handling stage distinction
- All 6 rule templates: cross-reference corrections (Auth Guards, Query Filters), baseline rule count, EMPTY_COMPONENT comment, testing cross-reference target, TODO comment format

**Skill Detailed Guides** (all 23 replaced with canonical prompt files)
- All stage prompts now match the 22nd-pass audit versions exactly
- Stale duplicate reference files removed (remediation-detailed-guide.md, security-detailed-guide.md, a11y-detailed-guide.md, audit-detailed-guide.md)
- SKILL.md reference paths updated to match new filenames

**Agent Definitions** (all 7 updated)
- feature-tests.md: narrowed from all-test-types to E2E-only (backend tests → backend builder, component tests → frontend builder)
- feature-reviewer.md: checklists aligned with template quality gate (10 items, blocking/secondary classification)
- feature-backend.md: added crash recovery, Session Language, 13 backend testing sub-rules, cross-feature integration, verification steps, completion message format
- feature-frontend.md: added 7 frontend testing pitfalls, expanded design guidelines (typography/color/motion/spatial/8 sub-rules), i18n, Session Language, feature flags
- brd-writer.md: fixed domain naming (3 mismatches), fixed domain file assignments, dynamic token budget, BRD issues handling
- prd-writer.md: dynamic token budget, BRD issues handling
- transmute-pipeline.md: Stage 4 adds `.claude/rules/*.md` verification

**Metadata**
- SKILL.md descriptions updated: docs (6D) reflects user-facing help docs, user-guide (7D) reflects broader input sources
- Gate Logic section header: removed stale version reference

### v2.8.0

**14th-Pass Audit Sync: Gate Precision, BRD File Robustness, Crash Recovery, Framework Agnosticism**

**Templates** (synced from canonical Transmute Framework Template — 13th and 14th pass audits)
- **CLAUDE.md**: "Never skip" list now includes 6P/6P-R explicitly with "(default: 6P)"; Stage 7 prerequisites tightened from "6V complete" to "6V PASS or CONDITIONAL PASS"; 6R skip conditions add 6V FAIL handling; Stage 8 prerequisite clarifies 7D FAIL blocks; Stage 5 resumption positional scan now includes `🔧 In Progress`; added Pipeline Execution Guide lifecycle note
- **execution-guide.md**: 6F output column adds `package.json` with seed scripts; Node.js prerequisite updated to v20.17+; 6V routing clarified for mixed 6V-A/B/C issues; 6R max-cycle exhaustion requires explicit report annotation; Stage 7 prerequisites use "6V PASS or CONDITIONAL PASS"; PRODUCTION_TEST_USERS note added before 7V; 7D lead reads 7V "PASS or CONDITIONAL PASS"; 5B category prefix changed to 5B-A/5B-B/5B-C; Stage 5 completion gate expanded with `typecheck` command
- **rules-templates/_api-contracts-template.md**: Added REST/GraphQL vs reactive backend choice comment for Stage 3
- **rules-templates/_data-model-template.md**: Added CLAUDE.md Part 2 sync requirement for retention period and child entity strategy
- **rules-templates/_testing-template.md**: Added explicit default timeout values (10s cloud, 5s local)

**Skills** (19 skill reference files updated)
- **audit-a11y**: BRD file references use grep-based search with common locations; Level A WCAG exception for shared config files
- **audit-security**: Rate limiting scope boundary expanded with inline 6A/6G scope summary
- **implement**: Steps 4-5 split (spec validation gate + scaffold validation); steps renumbered 4-11; design token path parameterized; E2E scaffold inventory checks `_scaffold-manifest.md`
- **feedback**: Context file reading updated (prd/01-product-overview.md primary); codegen failure protocol added; user-guide `docs.json` validation; 6P/6P-R re-run skip logic after feedback
- **redesign**: Font fallback mapping (Fontshare → Google Fonts alternatives); Step 7.3 heading clarified as "not a full 7D re-run"
- **brd**: Language directive now STOPs if Session Language section missing
- **docs**: 5B report missing now STOPs instead of WARNing; 25% threshold examples expanded; `_doc-context.md` preserved for session recovery
- **prd**: Spawn prompt includes preliminary data entity list; retry limit: "Do NOT retry the same scope more than once"
- **scaffold**: Auth file disambiguation rule; CSS framework adaptation note; design token path parameterized (2 locations); Next.js config heading conditional
- **harden**: BRD file references use grep-based search; unfixable violations merge note expanded; teammate read instructions use grep
- **audit-completeness**: Retry tracking decision table added (Run 1/re-run/max retries/per-feature escalation)
- **maintain**: Bun v1.2+ native `outdated` noted; E2E test trigger for UI-affecting updates; exact version numbers in tech-stack.md; rule count update instructions; staleness conditions use OR (60 days or 2 cycles)
- **optimize**: Step renumbering (6A/6B reads as separate steps 3-4); Core Web Vitals critical fix exception for shared configs
- **smoke**: 6P/6P-R report check split for distinct report file paths
- **remediate**: `Last completed phase:` field added to crash recovery protocol
- **tech-stack**: Red-tier credential WARNING added; skip condition describes typical red-tier credentials
- **validate-specs**: Critical rules must be included in all teammate spawn prompts; new rule 7 (HIGH 4-5 CONDITIONAL PASS); rules renumbered 7→8, 8→9; cross-references updated
- **verify**: Auth redirect conditional clarified (BOTH must find zero issues); `.gitignore` for `last-verified-commit.txt`; console warning filtering expanded
- **polish**: Interrupted 6P-R detection check added

### v2.6.0

**10th-Pass Audit Sync: Full Reference Parity, Safety Rule Consolidation, Terminology Alignment**

**Templates** (synced from canonical Transmute Framework Template — 8th through 10th pass audits)
- **CLAUDE.md**: 5B restored to "Never skip" list (was split into standalone rule); Stage 6 ordering parenthetical restored as "(mandatory — not merely recommended)"; notation explanation expanded with detailed `/` symbol semantics; 6D prerequisite restored to "strongly recommended" with documentation reasoning; Stages 8+9 conflict list restored "and source code"; candidate staging 30-limit guidance restored
- **execution-guide.md**: "Recommended Stage 6 ordering" → "Stage 6 ordering" (mandatory); restored 6D/6H inline ordering notes; restored 6H detailed goal (static vs runtime gate distinction); restored 6P-R max-cycle exhaustion exception; 5B restored to unskippable stages; restored "lock files" in 8+9 conflict list; Stage 7 6D prerequisite restored to "strongly recommended"
- **rules-templates/_api-contracts-template.md**: Restored 4-step instruction with explicit HTML comment removal guidance
- **rules-templates/_backend-template.md**: Restored concrete env var example (DATABASE_URL vs CONVEX_URL) replacing external reference
- **rules-templates/_data-model-template.md**: Added conditional OMIT instruction for schemaless backends (Convex, Firebase)
- **rules-templates/_frontend-template.md**: Restored "unavailable in any icon library" qualifier for inline SVG exception

**Skills** (full reference parity — Option A sync)
- **All 23 skills**: Reference files now contain complete template prompt content (full parity with canonical framework template)
- **10 new reference files created**: validate-specs, audit-security, audit-a11y, optimize, seed-data, harden, docs, prelaunch, feedback, maintain — these skills previously had no detailed reference guides
- **13 existing reference files expanded**: tech-stack (+780 lines), verify (+727 lines), implement (+468 lines), scaffold (+443 lines), user-guide (+424 lines), remediate (+415 lines), prd (+391 lines), polish (+341 lines), smoke (+247 lines), refactor (+205 lines), brd (+140 lines), audit-completeness (+136 lines), redesign (+14 lines) — all now include complete teammate spawn prompts, output templates, and gate logic

**Agents**
- **transmute-pipeline.md**: "QA & Hardening" → "Quality Assurance" (terminology alignment with template); restored "and source code" in Stages 8+9 concurrency warning

**Terminology**
- Stage 6A–6G label: "QA & Hardening" → "Quality Assurance" across pipeline agent, README, and all references

### v2.5.0

**7th-Pass Audit Sync: Gate Edge Cases, Parallel Safety, Template Precision**

**Templates** (synced from canonical Transmute Framework Template — 5th through 7th pass audits)
- **CLAUDE.md**: Recovery procedure cross-references expanded with specific section examples; staleness policy wording clarified ("whichever comes first"); added `style` commit type
- **execution-guide.md**: Assumption volume calculation formula added; 6V/6R B-category fixability criteria (what B can/cannot fix, escalation to C); CONDITIONAL PASS path evaluation order explicitly stated (a→b→c); flaky scenario definition expanded with root cause context; 6D skip condition now references specific `tech-stack.md` field
- **feature_scenario_generation.md**: Step 5 restructured with 6V-only qualifier on step header; estimation time breakdown added (≤50 scenarios vs 50-150); personas scoring phrasing aligned ("cap: 5 points")
- **_rules-candidates.md**: Restored missing `Date Added` field in candidate format and example (breaking fix — staleness policy requires this field)
- **rules-templates**: `_frontend-template.md` restored "Additionally:" prefix with stack-specific context; `_testing-template.md` comment metadata format aligned

**Skills**
- **verify/SKILL.md**: B-category fixability criteria added; flaky scenario definition expanded
- **verify/references/verification-detailed-guide.md**: B-category fixability criteria added (2 locations — gate section + report template)
- **remediate/references/remediation-detailed-guide.md**: B-category fixability criteria added to category system note
- **maintain/SKILL.md**: Staleness review policy updated — "60 days without promotion or re-trigger, or 2+ cycles — whichever comes first"

### v2.4.0

**Comprehensive Template Sync & Agent Hardening**

**Templates** (synced from canonical Transmute Framework Template)
- **CLAUDE.md**: Structural overhaul — replaced verbose Pipeline Execution Guide sections (Prerequisites, CLI Workflow, Critical Per-Stage Warnings, Key Gates & Recovery) with concise Safety-Critical Rules + Cross-References table pattern; added inline style exception (Component Rules #4); added third-party `any` type wrapping guidance (TypeScript Rules); added traceability exemptions for utility/config/test files; added Icon Registry and Design Tokens rows to Part 2 Technology Stack
- **execution-guide.md**: 30+ changes — scaffold coverage definition (≥95% PASS), 5B gate tightening (test-pass requirement, CONDITIONAL PASS ≤3 with workarounds), 6R cycle counter reset semantics (requires full 6V re-run), assumption review timing (before Stage 2, not 2B), credential canonical source moved to execution-guide.md, 6A scope expansion (invitation acceptance, password-reset edge case), recovery procedures for 6A-6G/8/9/7V, Stage 4 copy path fix and commit instruction, 6V duration updated to 30-120 min
- **feature_scenario_generation.md**: Unresolvable cycle fallback with WARNING documentation, scenario cap override via tech-stack.md, `_progress.md` fallback for pre-Stage-5 runs
- **_rules-candidates.md**: Staleness policy fixed (OR condition, was AND), overflow handling at 30 candidates, corrected example to MEDIUM confidence
- **rules-templates** (all 6): Fixed grep verification pattern (`\[[A-Z_]+\]` — was false-positive matching markdown links), Stage 3 TODO comment format, backend sanitization guidance (exclude credentials/tokens/PII), auth provider built-in feature check, test count preservation section, data model cross-references to backend rules

**Agents**
- **transmute-pipeline.md**: Full Stage 7 prerequisite chain (6H+6V+6R+6P+6D), 5B FAIL-RETRY thresholds expanded (3+ A/B unfixed, test failures), per-feature consecutive FAIL-RETRY escalation tracking, 6R cycle counter reset semantics, "always run 5B" core responsibility, 6P input fallback (6V report if 6R skipped)
- **brd-writer.md**: 8 Known Failure Patterns, Language Rule (session language from tech-stack.md), Deduplication Rule (Variant Test)
- **prd-writer.md**: 7 Known Failure Patterns, Language Rule
- **feature-backend.md**: 5 Known Failure Patterns, Cross-Feature Integration Levels (Data-only/UI reference/Workflow)
- **feature-frontend.md**: 6 Known Failure Patterns, dynamic design token path (from Part 2 table), Cross-Feature UI Updates note
- **feature-tests.md**: 2 Known Failure Patterns, Cross-Feature E2E note (integration tests + responsive viewports)

**Skills**
- **scaffold**: Scaffold coverage definition with gate thresholds, CLAUDE.md template location note, Stage 4 commit instruction
- **implement**: 🔄 recovery semantics (rebuild from scratch), completion check includes Blocked, Rule 11 Launch Readiness Assessment check
- **audit-completeness**: FAIL-RETRY/ESCALATE blocking note, 5B Quality Standard (scaffold→working, not production polish)
- **audit-security**: Password-reset edge case, Safety-Critical Rules reference
- **verify**: Port adaptation note (framework-specific defaults), diff mode first-run warning
- **remediate**: 6R cycle counter reset semantics, outer cycle tracking guidance
- **smoke**: 6R prerequisite added, SMOKE scope paragraph
- **docs** / **seed-data**: Gate mention added

**Hooks**
- **Created `check-prerequisites.sh`** — was referenced by hooks.json but missing (blocking bug). Lightweight script: checks for `plancasting/` directory, warns on missing `CLAUDE.md` and `tech-stack.md`, always exits 0 (warns, never blocks)

### v2.3.0

**Gate Precision & Terminology Alignment**

- **5B gate**: Added priority-order evaluation (PASS → CONDITIONAL PASS → FAIL-RETRY → FAIL-ESCALATE), expanded CONDITIONAL PASS paths (a/b/c), fixed FAIL-RETRY threshold (4–5 total unfixed), added FAIL-ESCALATE precedence rule, per-feature run state reading from previous reports
- **6R gate**: Updated to 6V-A/6V-B/6V-C terminology, auto-escalation after 3 cycles, max 2 outer 6V→6R cycles, CONDITIONAL PASS next steps clarified
- **6P gate**: Category E discretionary — skip if conflicts with design system, negligible impact, or risks regression
- **6P-R**: Severity classification (Critical/Major/Minor), session boundary for 6P→6P-R switching
- **3 gate**: CONDITIONAL PASS requires Part 2 + `_progress.md`, FAIL expanded with OR conditions, coverage terminology note
- **2B gate**: Coverage definition disambiguation vs Stage 3, FAIL edge case examples
- **Stage 8 prerequisite**: 7D PASS/WARN check added (FAIL blocks Stage 8)
- **Scaffold**: Standalone project exception for pipeline credentials, Next.js-conditional config rules
- **6G**: Added FORGOT PASSWORD edge case classification, 6E section reference fix
- **Remediate**: Crash recovery uses subsection counting, cycle limit auto-escalation wording
- **Stage 9**: Pre-flight concurrency check against Stage 8
- **Stage 0**: Cross-reference to Stage 3 credential gate for standalone projects
- **User guide**: Pre-deletion image path capture for 6P-R reruns, pre-flight cleanup note
- **Feedback**: 6V re-run instruction with full 6V→6R→6P chain
- **Progress tracking**: 🔄 status set by 5B audit OR operator

### v2.2.0

**Comprehensive Template Sync (2-Pass Deep Audit)**

**Rules Templates** (all 6 templates updated)
- Added `Source:` and `Confidence:` metadata to all `<!-- TODO -->` HTML comments for traceability
- Added post-render verification grep command to all template headers: `grep -n '\[.*\]' .claude/rules/<name>.md`
- Backend: Expanded validation phrasing ("in the same file as the function, not inline within the function body")
- Data Model: Added default 90-day retention with GDPR rationale; added "ALL timestamps are UTC" rule
- Auth: Added glob note for frontmatter clarity; added `[RBAC / ABAC / Custom]` permission model type; added per-tenant role scoping
- Testing: Added exponential backoff timeout guidance (`intervals: [100, 200, 500]`); expanded axe-core framework-specific integration patterns; explicit five-state enumeration
- Frontend: Design tokens note clarified (Stage 3 creates based on tech-stack.md design direction)
- API Contracts: Added source annotations to all TODO comments

**New Template File**
- Added `_rules-candidates.md` — staging area template for rule candidates from Stages 5B and 6R

**CLAUDE.md Template Updates**
- Pre-6V Setup: Expanded to numbered 2-step checklist (file copy + port verification)
- Stage 0: Expanded outputs list and skip conditions with section enumeration
- Stage 3 prerequisite: Added credential validation details
- .env.local timing: Expanded with backend deployment timing and mid-pipeline credential guidance
- 6A/6G scope: Added account linking, invitation acceptance, signup, logout to 6A; file uploads to 6G; added decision rule with edge cases
- 6V modes: Clarified applies to 6V only, not 7V (7V always SMOKE scope)
- 2B gate: Added "none P0-blocking" detail and assumption review conditional
- 5B gate: Expanded with detailed thresholds (PASS/CONDITIONAL/FAIL-RETRY/FAIL-ESCALATE), per-feature escalation tracking
- 6V gate: Added category definitions, flaky scenario exclusion from percentage, expanded routing rules
- 6R: Expanded skip conditions and key rules
- 7D: Added WARN description (documentation quality issues that don't block launch)
- Stage 7 prerequisites: Reordered (6H READY first)
- Added stage skip conditions and tips/troubleshooting cross-references
- Added Test Count Preservation rule to Part 1
- CONDITIONAL PASS cascading: Expanded 6H evaluation guidance

**Execution Guide Updates**
- Stage 6G: "Error Resilience Hardening" → removed "Error" from sub-stage name
- Stage 6R: "Remediation loop" → "Remediation cycle" terminology alignment
- 6V/6R: All "Category A/B" → "6V-A/6V-B" in fixability context
- 5B: "5B-A/B/C" → "Category A/B/C (no prefix)" for size-based categories
- Pre-6V Setup: Reorganized with CRITICAL file existence check
- Added Deployment Failure Recovery section (§ 7.1.2)
- Per-feature escalation: Expanded "consecutive" definition (per-feature, not global)
- 6V flaky handling: Added exclusion from gate percentage
- 6P/6P-R switching: Safer `git revert` approach (creates reversible commit)
- Credential gates: Expanded timing details
- Stage 0 skip: Added Project Initialization field requirement

**Feature Scenario Generation Updates**
- WARNING section expanded to multi-line with bullet points
- Implicit dependency algorithm: Added keyword detection rules for inference
- Added cycle detection and transitive reduction sections
- Negative variant counting: Explicit counting rules for Step 9 trimming
- User impact scoring: Detailed 0-8 point algorithm replacing general description
- Flaky scenario: Clarified exclusion from 6V gate percentage
- Progress audit checklist: Expanded with explicit status emoji enumeration

**Skill & Agent Updates**
- remediate/SKILL.md: Full "Category A/B/C" → "6V-A/6V-B/6V-C" migration; "loop" → "cycle"
- remediate/references: Same terminology migration across detailed guide
- verify/references: "Category A/B" → "6V-A/6V-B" in next steps
- transmute-pipeline agent: "Category A/B" → "6V-A/6V-B" in post-6V routing table

---

### v2.1.0

**6R Cycle Semantics**
- Clarified "Max 3 completed loops" → "Max 3 internal fix-verify cycles within a single 6R run" — cycles happen within one session, not across separate runs
- Added explicit FAIL recovery: "do NOT re-run 6R — manually fix 6V-C issues first, re-run 6V, then 6R if needed"

**6V Routing**
- Added explicit routing rules: PASS → skip 6R, CONDITIONAL PASS with 6V-A/B → run 6R, CONDITIONAL PASS with only 6V-C → skip 6R

**`6V-` Prefix Consistency**
- All fixability-based A/B/C categories now consistently use `6V-` prefix across all skills, agents, and templates to distinguish from Stage 5B's size-based categories

**Assumption Review Timing**
- New operator checkpoint between Stages 1 and 2B: review `_review-log.md` when BRD assumption volume ≥30%

**Stage Skill Updates**
- 5B (audit-completeness): Enhanced known failure patterns, multi-file classification, session recovery restructuring
- 6P (polish): Dark mode escalation to 6P-R, expanded prerequisites, 22 critical rules
- 6P-R (redesign): `6V-` prefix consistency
- 6R (remediate): Cycle terminology, FAIL recovery guidance

**Template Updates**
- CLAUDE.md: `.env.local` timing, Pre-Stage 3 setup, CONDITIONAL PASS cascading, enhanced gate criteria
- execution-guide.md: 6R gate table updated
- API contracts template: Bullet consolidation

### v2.0.0

**Gate Logic Overhaul**
- 5B: FAIL now triggers RETRY (re-run Stage 5 for affected features) or ESCALATE (4+ Category C issues)
- 6V: Dual gate system — PASS/CONDITIONAL PASS/FAIL routing with scenario-driven verification
- 6R: Max 3 internal fix-verify cycles per run before mandatory escalation
- 7V: Binary gate — PASS or FAIL (hotfix + re-deploy / rollback)
- 8 + 9: NEVER concurrent rule enforced

**Credential Tier System**
- Four tiers (:red_circle: Placeholder, :yellow_circle: Service, :orange_circle: Deploy, :large_blue_circle: Production) with specific credential names gating pipeline progression at Stages 3, 5, 7, and 7V

**Scenario Generation**
- New `templates/feature_scenario_generation.md` for systematic 6V/7V test scenario creation from PRD features and user flows

**New Template Files**
- `templates/execution-guide.md` — pipeline execution reference
- `templates/feature_scenario_generation.md` — scenario generation for 6V/7V
- 6 rules-templates: `_api-contracts-template.md`, `_auth-template.md`, `_backend-template.md`, `_data-model-template.md`, `_frontend-template.md`, `_testing-template.md`

**Enhanced Progress Tracking**
- Added `⏸ Blocked` status to progress file alongside existing states
- State transition diagram for pipeline flow visualization

**Path-Scoped Rules Enhancements**
- Confidence hierarchy for rule prioritization
- Auto-promote threshold for validated rules
- Staleness review for outdated path-scoped rules

**6V Scope Modes**
- Three verification modes: `full` (all features), `critical` (P0/P1 only), `diff` (changed files only)

**6P / 6P-R Categorization**
- 6P: Issues categorized as Omission (O), Execution (E), or Design (D)
- 6P-R: Severity levels — Critical, Major, Minor

**Parallel Safety**
- 6A/B/C explicitly designed for safe concurrent execution as parallel agents

### v1.0.0

- Initial release: 25-stage pipeline from business plan to production deployment

## Built With Transmute

> Have you built something with Transmute? [Open an issue](https://github.com/VoxTechnologies/transmute-framework/issues/new?template=feature_request.md&title=%5BShowcase%5D+) to get featured!

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on adding stages, modifying skills, and reporting issues.

## License

[MIT](LICENSE)
