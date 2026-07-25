# Transmute Framework — Execution Guide

## Plan Casting: From Business Plan to Production

Transmute is a product development framework that transforms business plans into production-ready products using AI agent teams. The act of using Transmute is called **Plan Casting** — you write your Business Plan, and AI agent teams autonomously cast it into a fully functional product.

> "Transmute your business plan into a production-ready product."

This guide covers the end-to-end Transmute pipeline, consisting of stages 0 through 9 (with sub-stages) from interactive tech stack discovery through continuous post-launch improvement.

---

## Transmute Pipeline Overview

> **Canonical source**: This section and the table below are the canonical stage reference. CLAUDE.md § "Pipeline Execution Guide" provides a compact summary; execution-guide.md is authoritative for definitions and recovery procedures.

~~~
Business Plan → Tech Stack → BRD → PRD → Spec Validation → Scaffold + Verify → Implementation → Completeness Audit → Quality Assurance → Pre-Launch → Live Verification → Remediation → Visual Polish or Redesign → Deploy → Production Smoke → User Guide → Feedback / Maintenance
   [Input]        [0]       [1]   [2]      [2B]              [3+4]             [5]                [5B]              [6A–6G]         [6H]           [6V]               [6R]              [6P / 6P-R]          [7]        [7V]              [7D]        [8] / [9]
~~~

> **Notation**: The `+` symbol means sequential stages sharing a single Claude Code session (3+4 = paste Stage 3 prompt, let it complete scaffold + populate CLAUDE.md Part 2, then verify Part 2 before exiting — all in one session). `/` between alternatives (6P / 6P-R) = run exactly one, never both. `/` between sequential stages (8 / 9) = run both, but one at a time, never concurrently. `[6A–6G]` is simplified (includes security, accessibility, performance, refactoring, seed data, resilience, and documentation sub-stages — excludes 6H, 6V, 6R, and 6P/6P-R which are shown separately). Stage 6 sub-stages run in **execution order** (not alphabetical): 6A (Security) + 6B (Accessibility) + 6C (Performance) in parallel, then sequentially: 6E (Code Refactoring) → 6F (Seed Data) → 6G (Error Resilience Hardening) → 6D (Documentation) → 6H (Pre-Launch gate) → 6V (Live Verification) → 6R (Remediation) → 6P (Visual Polish) or 6P-R (Frontend Design Elevation — use instead of 6P when a full design overhaul is needed). 6D runs after 6G despite its lower letter because all code-modifying stages must complete before documentation. See "Stage 6 ordering" below for the mandatory execution order and detailed dependencies. See table below for per-stage details.

| Stage | Input | Output | Prompt File | Estimated Duration |
|---|---|---|---|---|
| 0. Tech Stack Discovery | Business Plan + user input | `./plancasting/tech-stack.md`, `.env.local`, `.env.local.example`, initial project scaffold (optional) | `prompt_tech_stack_discovery.md` | 15–30 min (interactive) |
| 1. BRD Generation | Business Plan + tech-stack.md | `./plancasting/brd/` | `prompt_generate_brd.md` | 30–60 min |
| 2. PRD Generation | BRD + Business Plan + tech-stack.md | `./plancasting/prd/` | `prompt_generate_prd.md` | 45–90 min |
| 2B. Spec Validation | BRD + PRD + Business Plan + tech-stack.md | `./plancasting/_audits/spec-validation/report.md` (primary), `traceability-by-coverage.md` (complete analysis from Teammate 1), `traceability-draft.md` (interim artifact — superseded by traceability-by-coverage.md), `gaps-by-coverage.md`, `consistency-report.md`, `quality-report.md` | `prompt_validate_specs.md` | 30–60 min |
| 3. Scaffold Generation | PRD + BRD + tech-stack.md (Stage 2B must PASS or CONDITIONAL PASS) | Project code skeleton, `plancasting/_codegen-context.md`, `_scaffold-manifest.md`, `_progress.md`, `ARCHITECTURE.md` (derived from PRD system architecture), `.claude/rules/*.md` (starter rules), `plancasting/_rules-candidates.md` (empty) | `prompt_generate_scaffolding.md` | 60–120 min |
| 4. CLAUDE.md Verification | — | `./CLAUDE.md` (Part 2 fully populated, all `[BRACKETED]` placeholders replaced) | N/A (verify Part 2 was populated by Stage 3 with no `[BRACKETED]` placeholders remaining; verify `.claude/rules/*.md` generated; customize if needed) | 5 min |
| 5. Feature Implementation | Scaffold + PRD + BRD | Complete working product, `plancasting/_briefs/`, `plancasting/_implementation-report.md` | `prompt_feature_orchestrator.md` | ~30–60 min per feature (e.g., 10 features ≈ 5–10 hrs; 35 features ≈ 2–4 days) |
| 5B. Implementation Completeness Audit | Codebase + PRD + BRD | `./plancasting/_audits/implementation-completeness/report.md`, updated `.claude/rules/` (if patterns found) | `prompt_implementation_audit.md` | 45–90 min |
| 6A. Security Audit | Codebase + BRD/PRD | `./plancasting/_audits/security/report.md` | `prompt_audit_security.md` | 30–60 min |
| 6B. Accessibility Audit | Codebase + BRD/PRD | `./plancasting/_audits/accessibility/report.md` | `prompt_audit_accessibility.md` | 30–60 min |
| 6C. Performance Optimization | Codebase + PRD | `./plancasting/_audits/performance/report.md` | `prompt_optimize_performance.md` | 30–60 min |
| 6D. Documentation Generation | Codebase + PRD/BRD | `./docs/`, `./plancasting/_audits/documentation/report.md` | `prompt_generate_documentation.md` | 30–60 min |
| 6E. Code Refactoring | Codebase | `./plancasting/_audits/refactoring/report.md` | `prompt_refactor_code.md` | 45–90 min |
| 6F. Seed Data Generation | Codebase + PRD | `./seed/`, `./plancasting/_audits/seed-data/report.md`, updated `package.json` with seed scripts | `prompt_generate_seed_data.md` | 30–60 min |
| 6G. Error Resilience Hardening | Codebase + BRD/PRD | `./plancasting/_audits/resilience/report.md` | `prompt_harden_resilience.md` | 45–90 min |
| 6H. Pre-Launch Verification | Complete project | `./plancasting/_launch/readiness-report.md`, `./plancasting/_launch/checklist.md` | `prompt_prelaunch_verification.md` | 30–60 min |
| 6V. Visual & Functional Verification | Running app + PRD | `./plancasting/_audits/visual-verification/report.md` | `prompt_visual_functional_verification.md` | 30–120 min (scales with scenario count) |
| 6R. Runtime Remediation | 6V report + codebase | `./plancasting/_audits/runtime-remediation/report.md`, updated `.claude/rules/` (if fix patterns found) | `prompt_runtime_remediation.md` | 15–45 min |
| 6P. Visual Polish & UI Refinement | Running app + 6R report (or 6V report if 6R was skipped) | `./plancasting/_audits/visual-polish/report.md` | `prompt_visual_polish.md` | 20–40 min |
| 6P-R. Frontend Design Elevation *(alternative to 6P)* | Same as 6P (Stage 6V must have completed with PASS or CONDITIONAL PASS; if 6V found 6V-A/B issues, 6R must be PASS or CONDITIONAL PASS; if 6V found only 6V-C, 6R is skipped) | `./plancasting/_audits/visual-polish/{context,design-plan,slop-inventory,progress,report}.md`, `screenshots/visual-polish/` | `prompt_frontend_redesign.md` | 2–4 hrs (interactive) |
| 7. Deployment | Verified codebase (6H READY + 6V PASS or CONDITIONAL PASS + 6R PASS/CONDITIONAL PASS if run + 6P or 6P-R PASS or CONDITIONAL PASS + 6D complete (mandatory for software products)) | Production environment | (manual / CI/CD) | 15–30 min |
| 7V. Production Smoke Verification | Production URL | `./plancasting/_audits/production-smoke/report.md` | `prompt_production_smoke_verification.md` | 25–45 min |
| 7D. User Guide Generation | PRD/BRD + production URL + 7V report | `./user-guide/`, `./plancasting/_audits/user-guide/report.md` | `prompt_generate_user_guide.md` | 30–60 min |
| 8. Feedback Loop | User feedback | Updated specs + code | `prompt_feedback_loop.md` | Per batch |
| 9. Dependency Maintenance | Codebase + lock file | `./plancasting/_maintenance/report-YYYY-MM-DD.md` | `prompt_maintain_dependencies.md` | Monthly/Quarterly |

All stages follow the **Transmute Full-Build Approach**: every feature described in the Business Plan is built. No MVP, no phased delivery. You plan cast the entire product at once. (Features are implemented in priority order P0→P3, so the product is functional at any interruption point — but the goal is always to complete all features.)

---

## Prerequisites

Before starting, ensure the following are in place.

**Claude Code**: Installed and authenticated. Verify with `claude --version`. **Recommended model**: see `plancasting/tech-stack.md` (generated by Stage 0) § Model Specifications for the current pipeline model, context window, and model ID. If `tech-stack.md` does not yet exist (before Stage 0), use the latest Claude model available in your Claude Code installation. Stage 0 will record the selected model. To set: `claude config set --global model <model-id>`. The pipeline generates and reads large document sets (BRD/PRD can span many files) — the full context window prevents context overflow during heavy stages (especially Stages 1, 2, 5, and 6V). The lighter-stage alternative (see tech-stack.md § Model Specifications) is viable for audit stages (6A–6G) where document volume is lower, but the pipeline model is recommended for document generation (Stages 1–3), orchestration (Stage 5), and verification (6V) where output quality and long-context reasoning matter most.

**Node.js**: Version 20.17 or later (required by Stage 7D Mintlify CLI; v18+ is sufficient for stages before 7D). Verify with `node --version`. (Other runtimes like Bun or Deno may be selected during Stage 0.) **Note**: Stage 7D (User Guide Generation) requires Node.js v20.17.0+ for the Mintlify CLI. Install globally with `npm i -g mint` (the current CLI package, rebranded from `@mintlify/cli`), then use `mint dev`. For one-off usage without installing: `npx mint dev`. If running Stage 7D, ensure Node.js is upgraded accordingly.

**Git**: Installed and configured with user name/email. Verify with `git --version`. The pipeline uses git commits between stages as recovery points and branch operations for 6P-R and Stage 8/9 workflows.

**Playwright** (needed before Stage 6V): Install browsers for visual verification: `npx playwright install --with-deps chromium` (or `bunx playwright install --with-deps chromium` if using Bun — see Package Manager Note below). Use the Playwright version matching your project's `package.json` devDependency. If no version is pinned, use the latest stable release. Without this, 6V/7V Playwright tests will fail immediately.

**tmux or iTerm2**: Recommended for Agent Team split-pane visibility (not strictly required).

**Business Plan**: Your Business Plan markdown files must be placed at `./plancasting/businessplan/`. This directory is read-only input for all stages. The Business Plan can be a single file or multiple files — the prompts will read all `.md` and `.pdf` files in the directory.

**Credential tiers** (used by Stage 0 to categorize product-specific credentials in `tech-stack.md`): 🔴 Red = before Stage 3, 🟡 Yellow = before Stage 5, 🟠 Orange = before Stage 7, 🔵 Blue = optional.

**Pipeline Infrastructure Credentials**: These are required by the Transmute pipeline itself (not the product being built — E2B provides sandbox execution for autonomous code generation during Stage 5). Have these ready before starting:

| Credential | Purpose | Where to get it |
|---|---|---|
| `TRANSMUTER_ANTHROPIC_API_KEY` | AI features within the product being built (if applicable — NOT for Claude Code CLI authentication, which uses its own credentials) | [console.anthropic.com](https://console.anthropic.com/) |
| `E2B_API_KEY` | Sandbox environment for code execution | [e2b.dev/dashboard](https://e2b.dev/dashboard) |
| `SANDBOX_AUTH_TOKEN` | Auth token for sandbox ↔ backend callbacks | Auto-generated (run `openssl rand -hex 32`) |

These must be set as environment variables on your backend deployment. The command depends on your backend platform:
- **Convex**: `bunx convex env set E2B_API_KEY <value>`
- **Railway/Render**: Set via dashboard or CLI (`railway variables set E2B_API_KEY=<value>`)
- **AWS/GCP/Azure**: Use your cloud provider's secrets manager or environment configuration

Product-specific credentials (auth, payments, email, etc.) are collected during Stage 0.

**Credential gates**: Infrastructure credentials (Anthropic, E2B, Sandbox token) must be *obtained* and added to `.env.local` before starting Stage 3. They must be *deployed to the backend environment* as soon as that environment exists: immediately after Stage 3 creates the backend, or immediately after Stage 0 if Stage 0 initializes the backend. Stage 3's pre-flight validates that `.env.local` contains no placeholder values — it will STOP if any 🔴 credentials are still placeholders. However, deploying to the backend environment can be deferred until after Stage 3 creates the backend if Stage 0 did not initialize one — but deploy immediately once the backend exists (the pre-flight Step 2 notes this explicitly). Product-specific credentials (auth, payments, email) are collected during Stage 0 and must be validated before Stage 5. See Stage 3 section for the full credential validation procedure.

**Credential Safety**: Credential values must ONLY exist in two places: `.env.local` (local development) and your hosting platform's environment variable configuration (production/staging). They must NEVER appear in: `.md` files (tech-stack.md, BRD, PRD, reports), git commit messages, code comments, chat messages, or terminal log output. When referencing credentials in documentation or reports, use variable names only (e.g., `STRIPE_SECRET_KEY`), never the value. If a credential is accidentally committed to git, rotate ALL affected credentials immediately and purge the value from git history using `git filter-repo` or `BFG Repo-Cleaner`.

Note: Additional cloud accounts, API keys, and tool installations for the product itself will be determined and collected during Stage 0 (Tech Stack Discovery).

**Package Manager Note**: Shell commands in this guide use `npm` / `npx` as generic defaults. If Stage 0 selects a different package manager (e.g., Bun, pnpm, yarn), substitute accordingly: `npm run` → `bun run`, `npx` → `bunx`, `npm install` → `bun install`, etc. Each prompt file includes a 'Stack Adaptation' section that auto-detects your package manager from `tech-stack.md` and adjusts commands accordingly — no manual substitution is needed within prompt sessions.

**`--dangerously-skip-permissions` flag**: This flag allows Claude Code to read/write files and run commands without per-action confirmation. It is required for autonomous pipeline execution but should only be used in trusted project directories.

---

## Stage 0: Tech Stack Discovery

**Goal**: Interactively determine the product type, research the latest technologies, select the optimal tech stack, and collect all required credentials.

**Prerequisite**: Your Business Plan must already be in place at `./plancasting/businessplan/` — the discovery prompt reads it first to understand your product before asking questions.

### 0.1 Execute

**Important**: Replace `~/project` with your actual project directory path throughout this guide. All subsequent stages use `cd ~/project` — substitute your real path each time.

~~~bash
mkdir -p ~/project
cd ~/project

# Verify Business Plan is in place
ls ./plancasting/businessplan/
# If this command fails: echo 'ERROR: ./plancasting/businessplan/ directory not found. Create it and add your Business Plan markdown files.'

claude --dangerously-skip-permissions
~~~

Paste the contents of **`prompt_tech_stack_discovery.md`**.

### 0.2 What Happens

This is an INTERACTIVE session. Claude will:

1. **Language Selection** — Ask you to choose your preferred language for the entire pipeline. All subsequent interactions, generated BRD/PRD documents, and reports will be in your selected language. Code and technical identifiers remain in English (variable names, function names, class names, file names, directory names, git branch names, commit messages, and code comments). The selected language is recorded in `tech-stack.md` § "Session Language". CLAUDE.md Part 2 does not track this — the language preference is read from tech-stack.md by all downstream stages.
2. **Read your Business Plan** — Analyze all markdown files in `./plancasting/businessplan/`. Extract product type, target audience, scale, key features, technical hints, compliance needs, and integration requirements.
3. **Present its understanding** — Show you what it extracted and ask for confirmation/corrections. This means fewer questions for you — the Business Plan already answers many of them.
4. **Ask targeted gap-filling questions** — Only ask about things the Business Plan doesn't clearly cover (e.g., multi-tenancy, authorization model, team technical expertise, technology preferences, budget sensitivity).
5. **Design Direction Discovery** — For products with a frontend, interactively collect:
   - **Design reference URLs**: Websites/apps whose visual style you admire (the agent visits each URL to analyze the aesthetic)
   - **Figma designs**: If you have existing Figma files (share URLs or exported assets), share them for direct design token extraction
   - **UI Component Library selection**: Choose from curated options (Untitled UI, shadcn/ui, Radix, Chakra, etc.) or bring your own
   - **Aesthetic direction**: Choose from 3 tailored visual directions, or describe your own
   This prevents the pipeline from generating generic "AI slop" — your design preferences are recorded in `plancasting/tech-stack.md` and used by Stage 3.
6. **Technology Research** — Search the web for the latest technologies appropriate for your product, informed by the specific features and requirements in your Business Plan.
7. **Present Recommendations** — For each technology category, present 2–3 curated options with rationale tied to your Business Plan requirements. You choose for each category.
8. **Collect Credentials** — Identify all API keys and secrets needed, categorized by when they're required in the pipeline (🔴 before Stage 3, 🟡 before Stage 5, 🟠 before Stage 7, 🔵 optional before Stage 7D). Guide you to sign-up pages. Save credentials securely to `.env.local`.
9. **Generate Configuration** — Produce `plancasting/tech-stack.md` (including Session Language, Business Plan Insights, Design Direction, multi-tenancy config, authorization model, and more), `.env.local`, `.env.local.example`, and optionally initialize the project.

### 0.3 Supported Product Types

The discovery prompt handles diverse product types:

- **Web applications**: SPA, SSR, static sites — framework, BaaS, hosting, auth, analytics
- **Mobile applications**: iOS, Android, cross-platform — React Native, Flutter, native SDKs
- **Desktop applications**: Electron, Tauri, native — platform-specific tooling
- **IoT / Embedded**: ESP32, Raspberry Pi, STM32 — firmware frameworks, RTOS, cloud platforms, protocols
- **Hardware products**: PCB design (KiCad, Altium), 3D modeling (FreeCAD, OpenSCAD), DFM considerations
- **AI/ML products**: LLM integration, model serving, vector databases, agent frameworks
- **Hybrid products**: Multiple types combined (e.g., IoT device + cloud dashboard + mobile app)

### 0.4 Verify Output

After completion:

~~~bash
# Tech stack document exists
cat ./plancasting/tech-stack.md

# Credentials are saved
cat .env.local.example  # Shows which credentials are needed (not the values)
~~~

### 0.5 Skip This Stage (If You Already Know Your Stack)

If you already have a defined tech stack (like the sample prompt in the guide), you can skip the interactive discovery and manually create `plancasting/tech-stack.md`:

~~~bash
cat > ./plancasting/tech-stack.md << 'EOF'
# Tech Stack Configuration

## Product Type
Web Application

## Technology Stack
<!-- EXAMPLE — replace with your actual tech stack -->
| Category | Technology | Purpose |
|---|---|---|
| Framework | Next.js (App Router) | Frontend + SSR |
| Backend | Convex | Real-time BaaS |
| Auth | WorkOS | Authentication |
| ... | ... | ... |

## Session Language
English

## Specifications
- Color profile: Display P3
- Multi-tenant: yes

## Model Specifications

These values govern session limits, token budgets, and splitting thresholds across all pipeline stages. Update this section when upgrading the pipeline model. All prompt files read their limits from here — no other files require changes.

| Parameter | Value | Derivation |
|---|---|---|
| Pipeline model | Claude Opus 5 (`claude-opus-5`) | Auto-detected from Claude Code session |
| Lighter-stage alternative | Claude Sonnet 5 (`claude-sonnet-5`) | For audit stages (6A–6G) where document volume is lower |
| Context window | 1,000,000 tokens | Per-model specification |
| Output token limit | 32,000 tokens per response | Per-agent response cap |
| Safe output budget | 25,000 tokens | Output limit minus 7K headroom for formatting/error recovery |
| Session feature limit | 25–30 features | Quality degrades beyond this in Stage 5 |
| Feedback batch limit | 10 items | Per Stage 8 session (~3–5 hours work) |
| Verification scenario cap (6V) | 150 scenarios | Per 6V session (7V is fixed at 15 — SMOKE scope) |
| Large product threshold | >500K tokens or >100 files | When to split validation by feature group |
EOF
~~~

> **Note**: The table above is an **example** using Next.js + Convex. Replace with your actual stack (e.g., SvelteKit + Supabase, Remix + Firebase, etc.).

> ⚠️ **WARNING — DO NOT use this template as-is.** This minimal template is for illustration only. If skipping Stage 0, ensure your `tech-stack.md` also includes: Project Initialization (init command and package manager), Multi-Tenancy Configuration, Authorization Model, Auth Provider details, Design Direction (fonts, colors, reference URLs), Theme & Appearance, Model Specifications, and Data Retention & Deletion Policy. Missing fields will cause downstream stages to make assumptions. See `prompt_tech_stack_discovery.md` § "Required Fields for Pipeline Continuity" for the complete list.

Then create `.env.local` with your credentials and proceed to Stage 1.

> **Living document**: After Stage 0 completes, `plancasting/tech-stack.md` becomes a living document read by all downstream stages. If your tech stack, team composition, or design direction changes, re-run Stage 0 in a new session — it will read the existing `tech-stack.md` and update only the fields that have changed. **Re-run impact**: For minor changes (adding a library), downstream stages adapt automatically. Minor examples: adding a new npm package, changing an icon library, adjusting design tokens. For major changes (switching backend provider or framework) after Stages 1–3 have completed, re-run all stages from Stage 1 through the current stage — the BRD/PRD/scaffold may contain framework-specific decisions that are now invalid. Major examples: switching backend provider (e.g., Convex → Supabase), switching framework (e.g., Next.js → SvelteKit), switching auth provider (e.g., Clerk → WorkOS), changing database engine. **Cleanup after major stack change**: When re-running from Stage 1 after switching backend/framework, delete the existing scaffold, `.claude/rules/`, and `_progress.md` from the old stack (or start from a clean directory). Stage 3 generates a new scaffold for the new stack and will not automatically clean up files from the previous stack.

---

## Stage 1: BRD Generation

**Goal**: Transform the Business Plan into a comprehensive Business Requirement Document covering ALL features.

### 1.1 Directory Setup

~~~bash
cd ~/project

# Verify Business Plan and tech stack are in place (created during Stage 0)
ls ./plancasting/businessplan/
cat ./plancasting/tech-stack.md
~~~

### 1.2 Execute

~~~bash
# Launch Claude Code with bypass permissions
claude --dangerously-skip-permissions
~~~

Paste the contents of **`prompt_generate_brd.md`** into the Claude Code session.

### 1.3 What Happens

The lead agent will:
1. Read all files in `./plancasting/businessplan/`
2. Extract ALL features from ALL sections (ignoring any phasing language)
3. Create `./plancasting/brd/_context.md` with the master feature inventory and shared conventions
4. Spawn 5 specialized teammates in parallel:
   - **business-core**: Executive summary, objectives, business/functional requirements
   - **technical-infrastructure**: Non-functional, security, compliance requirements
   - **data-and-integration**: Data model, integrations, migration
   - **user-experience-and-operations**: Stakeholders, scope, UX, business rules, reporting
   - **risk-and-planning**: Acceptance criteria, risks, costs, timeline
5. Coordinate cross-team dependencies
6. Review all files for consistency and completeness
7. Generate glossary, README, and final summary

### 1.4 Verify Output

After completion, verify:

~~~bash
# Check all expected files exist
ls ./plancasting/brd/

# Expected: 23 numbered files (00 through 22), plus _context.md, _review-log.md, and README.md
# Verify exact count against prompt_generate_brd.md teammate assignments if count differs
~~~

Review the final summary output by the lead. Check:
- Total requirement counts (BR, FR, NFR, CR, SR, BRL, DR, IR)
- Master feature inventory coverage (should be 100%)
- Number of assumptions flagged (review these — they may need your input)

### 1.5 Human Review Checkpoint

Before proceeding to Stage 2, review:
- `./plancasting/brd/_context.md` — Is the master feature inventory complete?
- `./plancasting/brd/06-business-requirements.md` — Are the business requirements accurate?
- `./plancasting/brd/07-functional-requirements.md` — Are ALL features captured as FRs?
- Any items marked with `> ⚠️ ASSUMPTION:` — Correct or confirm these.
- **Assumption review timing**: Read `./plancasting/brd/_review-log.md` § "Assumption Review Status" (generated by Stage 1). If assumption volume ≥30%, operator MUST review and confirm assumptions in the BRD files and update the review status to `Operator reviewed: YES` before running Stage 2 (so the PRD uses corrected assumptions). If <30%, proceed directly. **Where to mark**: Set the review status in `./plancasting/brd/_review-log.md` by adding the line: `Assumption Review Status: Operator reviewed: YES`. **Assumption volume** = (number of requirements with `⚠️ ASSUMPTION` markers) / (total number of requirements across all BRD files) × 100%. **Consequence if skipped**: Stage 2B gate rule 2 checks this marker — if assumption volume ≥30% and the marker is not set to `Operator reviewed: YES`, Stage 2B will return FAIL. You must review and set the marker, then re-run Stage 2B. See `prompt_validate_specs.md` for the full decision tree.

Commit the generated files before making edits so you can review your changes with `git diff`. Make edits directly to the BRD files if needed. The PRD stage reads from these files.

---

## Stage 2: PRD Generation

**Goal**: Transform the BRD into a development-ready Product Requirement Document with user stories, screen specs, API specs, and more.

### 2.1 Execute

In the same project directory (`~/project`), start a new Claude Code session:

~~~bash
claude --dangerously-skip-permissions
~~~

Paste the contents of **`prompt_generate_prd.md`**.

### 2.2 What Happens

The lead agent will:
1. Read all BRD files and the Business Plan
2. Build a Feature Decomposition Map (features → BRD requirements)
3. Create `./plancasting/prd/_context.md` with expanded ID ranges for the full product
4. Spawn 5 specialized teammates:
   - **product-strategy**: Product overview, feature map, single-release plan, feature flags
   - **user-stories**: Epics, user stories (Given-When-Then), job stories, user flows
   - **screen-specs**: Information architecture, screen specifications, interaction patterns
   - **api-and-technical**: System architecture, data model, API specs, technical specs
   - **quality-and-operations**: Testing strategy, non-functional specs, operational readiness, risks
5. Coordinate dependencies (feature IDs → user stories → screen specs → API specs → tests)
6. Verify 100% BRD functional requirement coverage
7. Generate traceability matrix, glossary, and README

### 2.3 Verify Output

~~~bash
ls ./plancasting/prd/

# Expected: 18 numbered files (01 through 18), plus _context.md, README.md, _review-log.md, and optionally _brd-issues.md
~~~

Review the final summary. Critical checks:
- BRD coverage percentage (target: 100% of FR-xxx covered)
- Number of cross-feature interactions identified
- Open questions requiring human decision

### 2.4 Human Review Checkpoint

Before proceeding to Stage 2B, review:
- `./plancasting/prd/02-feature-map-and-prioritization.md` — Is the priority ordering (P0–P3) correct for dependencies?
- `./plancasting/prd/04-epics-and-user-stories.md` — Are acceptance criteria clear and testable?
- `./plancasting/prd/12-api-specifications.md` — Are the API designs appropriate for your backend (see plancasting/tech-stack.md)?
- `./plancasting/prd/_brd-issues.md` — If this file exists, review the BRD quality issues flagged during PRD generation. Stage 2B's cross-validation naturally covers these (BRD ↔ PRD consistency checks), but review them now so you have context.
- Open questions list — Resolve these before proceeding.

Commit the generated files before making edits so you can review your changes with `git diff`.

---

## Stage 2B: Specification Validation

**Goal**: Independent cross-validation of BRD and PRD for consistency, completeness, and quality — catching spec errors before they become code bugs.

### 2B.1 Execute

~~~bash
claude --dangerously-skip-permissions
~~~

Paste the contents of **`prompt_validate_specs.md`**.

### 2B.2 What Happens

A fresh Agent Team (independent from the teams that generated BRD/PRD) performs:

1. **Requirements coverage audit**: Verifies every BRD functional requirement (FR-xxx) is covered by at least one PRD user story, screen spec, and API endpoint. Flags gaps.
2. **Consistency validation**: Checks terminology, data model, user flow ↔ screen spec alignment, API ↔ screen data needs, and priority alignment between BRD and PRD.
3. **Quality validation**: Verifies acceptance criteria are testable (Given-When-Then, unambiguous, measurable), screen specs are complete (all states documented), API specs are fully typed, and specifications are technically feasible with the chosen tech stack.

The team also **fixes CRITICAL and HIGH issues** directly in the BRD/PRD files.

The validation includes MoSCoW↔P0-P3 priority mapping (BRD uses MoSCoW, PRD uses P0-P3 — see prompt file for mapping guide), P0 coverage as a binding constraint, and BRD assumption volume re-check from Stage 1.

### 2B.3 Verify Output

~~~bash
cat ./plancasting/_audits/spec-validation/report.md
~~~

Also verify supporting files exist: `ls ./plancasting/_audits/spec-validation/` — should contain `report.md`, `traceability-by-coverage.md` (authoritative final analysis), `traceability-draft.md` (lead's initial skeleton — superseded by `traceability-by-coverage.md`; retained for audit trail; the lead does not delete interim artifacts), `gaps-by-coverage.md`, `consistency-report.md`, and `quality-report.md`.

Check:
- Requirements coverage percentage (target: 100%)
- Number of CRITICAL and HIGH issues found and fixed
- BRD ↔ PRD consistency score
- Acceptance criteria quality score

### 2B.4 Human Review Checkpoint

If the validation report shows remaining blockers, resolve them before proceeding to Stage 3: edit the BRD/PRD files directly, or start a Claude Code session and ask it to fix the specific issues cited in the report. If the issues are fundamental (wrong product understanding), re-run Stages 1 and 2. Non-critical issues can be addressed during development. If 2B returned CONDITIONAL PASS due to assumption volume, verify you completed the assumption review described in Stage 1.5.

---

## Stage 3: Development Scaffold Generation

**Goal**: Generate the complete project codebase skeleton — all schemas, all backend functions, all pages, all components, all hooks, all tests — for the entire product.

### 3.0 Prerequisite Gate (MANDATORY)

Verify Stage 2B has passed before generating scaffolding. Check `./plancasting/_audits/spec-validation/report.md` — its `## Gate Decision` must show PASS or CONDITIONAL PASS. If the file does not exist, STOP: "Stage 2B report not found — run Stage 2B before Stage 3." If the gate shows FAIL, STOP: "Stage 2B FAIL — resolve spec validation issues before scaffolding."

### 3.1 Credential Validation Gate (MANDATORY)

Before proceeding to scaffold generation, ALL credentials must be validated. This gate catches issues that would otherwise surface hours into the pipeline (missing keys, wrong key names, expired tokens, service tier limits).

**Ordering**: Steps 1 and 3 (placeholder check, API key validation) can run before the project exists. Steps 2 and 4 (backend env vars, code cross-check) require a running backend or project files — if those don't exist yet, run them after Stage 3.2 completes. In practice: run Steps 1 and 3 now, then after Stage 3.2 creates the project, return to run Steps 2 and 4.

**`.env.local` timing**: Stage 0 generates `.env.local` with placeholder values. Populate all 🔴 pipeline infrastructure credentials with real values BEFORE starting Stage 3. The pre-flight check below must pass before proceeding.

**Step 1: Check for placeholder values**
~~~bash
# Check for placeholder values in .env.local
grep -E 'YOUR_.*_HERE|TODO_.*|CHANGE_ME|PLACEHOLDER|^[A-Z_]+=\s*$' .env.local
~~~
If any 🔴 credentials are still placeholders, **stop and provide them now**.

**Step 2: Validate pipeline infrastructure credentials**

Verify the Transmute pipeline's own credentials are set on the backend deployment. Use your backend platform's environment variable command. (If the backend environment hasn't been created yet — e.g., Stage 0 didn't initialize it — skip this step and return to it after Stage 3.2 completes project initialization — see the Stage 3.2 MANDATORY CHECKPOINT below for the exact sequence.)

**Example (Convex)**:
~~~bash
bunx convex env list | grep -E "TRANSMUTER_ANTHROPIC_API_KEY|E2B_API_KEY|SANDBOX_AUTH_TOKEN"
~~~
**Example (Railway)**:
~~~bash
railway variables | grep -E "TRANSMUTER_ANTHROPIC_API_KEY|E2B_API_KEY|SANDBOX_AUTH_TOKEN"
~~~

All three must be present and non-empty. If any are missing, set them now using your platform's CLI:

**Example (Convex)**:
~~~bash
bunx convex env set E2B_API_KEY <your-e2b-key>
bunx convex env set SANDBOX_AUTH_TOKEN $(openssl rand -hex 32)
# TRANSMUTER_ANTHROPIC_API_KEY should already be set from Stage 0
~~~
**Example (generic)**:
~~~bash
# Set via your backend platform's CLI or dashboard
# E2B_API_KEY=<your-e2b-key>
# SANDBOX_AUTH_TOKEN=$(openssl rand -hex 32)
~~~

**Step 3: Test each credential with a minimal API call**

For each critical credential, make a lightweight validation call.

> **Security note**: Shell commands that reference `$VARIABLE` will expand environment variables in shell history. Prefix the command with a space (requires `HISTCONTROL=ignorespace` in `.bashrc`/`.zshrc`) to exclude it from history.
~~~bash
# Anthropic: verify API key works and model ID is valid
# Note: Model ID and API version below may be outdated — verify current values at console.anthropic.com/docs
curl -s -o /dev/null -w "%{http_code}" https://api.anthropic.com/v1/messages \
  -H "x-api-key: $TRANSMUTER_ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model":"<MODEL_ID>","max_tokens":1,"messages":[{"role":"user","content":"hi"}]}'
# Replace <MODEL_ID> with the model ID from your plancasting/tech-stack.md § AI/LLM Model field
# (e.g., claude-opus-5 — or any valid model from console.anthropic.com/docs/models).
# Current Claude model IDs carry NO date suffix: claude-opus-5, claude-sonnet-5, claude-fable-5.
# Only claude-haiku-4-5 has a dated full form (claude-haiku-4-5-20251001).
# Expected: 200. If 401: bad key. If 400/404: bad model ID or API version.

# E2B: verify API key and sandbox creation works
# (This is validated implicitly when the pipeline starts — no standalone ping endpoint)

# BaaS: verify deployment is reachable (adapt env var name to your BaaS — e.g., NEXT_PUBLIC_CONVEX_URL, NEXT_PUBLIC_SUPABASE_URL)
curl -s -o /dev/null -w "%{http_code}" $(grep NEXT_PUBLIC_CONVEX_URL .env.local | cut -d= -f2-)
# Expected: 200 or 404 (server responds). If connection refused: wrong URL.

# Auth provider: verify API key
# (Adapt to your auth provider's health/introspect endpoint)
~~~

**Step 4: Cross-check env var naming consistency**

> **Note**: The commands below scan `convex/` and `src/` directories, which only exist after project initialization (Stage 3.2). If you are running Stage 3.1 before Stage 3.2, skip this step and run it AFTER project initialization completes. Adapt directory names (`convex/`, `src/`), env var prefix (`NEXT_PUBLIC_`), and env access pattern (`process.env.*`) to your stack per `plancasting/tech-stack.md`.

~~~bash
# Ensure every process.env.* reference in the codebase matches .env.local
grep -roh 'process\.env\.\w\+' convex/ src/ | sort -u | while read var; do
  name="${var#process.env.}"
  if ! grep -q "^${name}=" .env.local .env 2>/dev/null && \
     ! grep -q "^NEXT_PUBLIC_${name#NEXT_PUBLIC_}=" .env.local 2>/dev/null; then
    echo "⚠️  ${name} referenced in code but not in .env.local"
  fi
done
~~~

If ALL checks pass, proceed to Stage 3. If ANY fail, resolve before continuing — issues caught here save hours of debugging later.

### 3.2 Project Initialization

Before running the scaffold generator, initialize the project based on your tech stack. If Stage 0 (Tech Stack Discovery) already initialized the project, skip this step.

Example for Next.js + Convex (adapt to your `plancasting/tech-stack.md`; substitute `bunx`/`bun install` if using Bun — see Package Manager Note in Prerequisites):

~~~bash
cd ~/project

# Initialize frontend project
npx create-next-app@latest . --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"

# Install backend
npm install convex

# Initialize backend
npx convex dev
# This will prompt you to log in and create a project
# Press Ctrl+C after initial setup completes
~~~

> **Note**: The example above is Next.js-specific. For other frameworks, substitute your framework's init command (e.g., `bunx create-vite`, `npx create-svelte`, `npx create-remix`). See `plancasting/tech-stack.md` § "Project Initialization" for your project's command.

For other stacks, refer to the initialization instructions in your `plancasting/tech-stack.md`.

> ⚠️ **MANDATORY CHECKPOINT — Return to Stage 3.1 NOW**: After Stage 3.2 completes project initialization, immediately return to Stage 3.1 and complete Steps 2 and 4 (credential validation and backend environment setup) before proceeding to Stage 3.3. The correct ordering is: Stage 3.1 Step 1 + Step 3 → Stage 3.2 → Stage 3.1 Steps 2 + 4 → Stage 3.3.
> - **Step 2**: Deploy 🔴 pipeline infrastructure credentials to the backend environment (e.g., `bunx convex env set E2B_API_KEY <value>`)
> - **Step 4**: Cross-check env var naming: `grep -roh 'process\.env\.\w\+' src/ [backend-dir]/ | sort -u` and verify every referenced var matches `.env.local.example`
>
> Do NOT proceed to Stage 3.3 without completing these steps. Skipping causes Stage 5 failures that are difficult to diagnose.

### 3.3 Execute

~~~bash
claude --dangerously-skip-permissions
~~~

Paste the contents of **`prompt_generate_scaffolding.md`**.

Note: This scaffold prompt uses Next.js + Convex as the example stack but reads `./plancasting/tech-stack.md` and adapts to whatever stack you specified in Stage 0. The prompt's Stack Adaptation section handles the translation automatically. If your stack is significantly different (e.g., mobile-only, IoT firmware), you may need to customize the scaffold prompt's teammate assignments to match your architecture.

### 3.4 What Happens

The lead agent will:
1. Read all PRD, BRD files, and `./plancasting/tech-stack.md`
2. Build a Code Generation Map (PRD artifacts → code files)
3. Create `./plancasting/_codegen-context.md` with naming conventions and file mappings
4. Spawn 5 specialized teammates (adapted to your tech stack):
   - **backend**: Schema/database, server functions, APIs, crons, webhooks
   - **pages-and-routing**: All pages/screens, layouts, navigation, loading/error states
   - **ui-components**: Design direction, all components, custom hooks, utilities
   - **feature-flags-and-config**: Feature flag system, middleware, auth config, environment setup
   - **testing-and-ci-cd**: Test infrastructure, CI/CD pipelines, project config, `plancasting/_progress.md`
5. Validate imports, types, and cross-references
6. Generate `ARCHITECTURE.md`
7. Generate `.claude/rules/` starter rules from `tech-stack.md` using templates in `plancasting/transmute-framework/rules-templates/`
8. Create empty `plancasting/_rules-candidates.md` for downstream rule staging

### 3.5 Verify Output

~~~bash
# Verify backend schema and functions (adapt path to your backend per `plancasting/tech-stack.md`)
ls ./convex/

# Verify pages (adapt directory structure to your stack per `plancasting/tech-stack.md`)
find ./src/app -name "page.tsx" | wc -l

# Verify components (adapt directory structure to your stack per `plancasting/tech-stack.md`)
find ./src/components -name "*.tsx" | wc -l

# Verify hooks (adapt directory structure to your stack per `plancasting/tech-stack.md`)
ls ./src/hooks/

# Verify tests exist (adapt path to your backend per `plancasting/tech-stack.md`)
ls ./convex/__tests__/
ls ./e2e/

# Verify path-scoped rules exist (adapt path to your backend per `plancasting/tech-stack.md`)
ls .claude/rules/

# Verify rules candidates staging file
ls ./plancasting/_rules-candidates.md

# Attempt a build
npm run typecheck
~~~

**Scaffold coverage** is the percentage of PRD-specified features that have corresponding scaffold files (backend functions, pages, components, hooks, test stubs). It is measured by comparing the feature list in `_progress.md` against the generated files in `_scaffold-manifest.md`. Coverage ≥95% = PASS, ≥80% = CONDITIONAL PASS, <80% = FAIL. See the Stage 3 prompt's `## Gate Decision` section for the full calculation. Note: "scaffold coverage" (percentage of PRD features with corresponding scaffold files) differs from Stage 2B's "requirement traceability coverage" (BRD→PRD requirement mapping). These are distinct metrics.

The type check may have errors at this stage — expected errors include: missing hook implementations, unresolved backend function references, and optional dependency errors. These will be resolved during Feature Implementation (Stage 5). Unexpected errors (syntax errors, import failures, or type errors in existing scaffold files) indicate Stage 3 did not complete successfully — investigate before proceeding.

**Git initialization**: Initialize a git repository (if not already initialized during Stage 0 or project setup) and make an initial commit after Stage 3 completes. Commit after each stage for recovery points (e.g., `git add -A && git commit -m 'chore: complete Stage <N> (<description>)'`):
~~~bash
# Verify .gitignore includes .env.local, node_modules/, and other sensitive/generated files.
# If Stage 3 did not generate a .gitignore, create one before committing.
cat .gitignore | grep -E 'env\.local|node_modules'

git init
git add -A
git commit -m "chore: initial scaffold (Stage 3)"
~~~

### 3.6 Human Review Checkpoint

Review:
- `./convex/schema.ts` (adapt path to your backend per `plancasting/tech-stack.md`) — Does the data model look correct?
- `ARCHITECTURE.md` — Does the architecture diagram make sense?
- `./plancasting/_progress.md` — Are ALL features listed?
- `./plancasting/_scaffold-manifest.md` — Does the manifest list every component file, its target page, and its consuming hook? This manifest is the handoff contract Stage 5 reads to understand which components already exist. The manifest should list ALL scaffold-generated components: pages, layout components, feature components, backend functions/mutations/queries, hooks, and shared utilities. Compare against the PRD screen specifications (`plancasting/prd/08-screen-specifications.md`) and API specifications (`plancasting/prd/12-api-specifications.md`) for completeness. If incomplete (missing entries), Stage 5's frontend teammate won't know the components exist and will rebuild UI inline, creating orphan files and bloated pages. Check the manifest during this review; if incomplete, edit it to add missing components before starting Stage 5.

---

## Stage 4: CLAUDE.md Verification

**Goal**: Verify that the project conventions file is correctly set up with both framework rules (Part 1) and project-specific configuration (Part 2).

### 4.1 Understanding the Lifecycle

CLAUDE.md has a specific lifecycle in the Transmute pipeline:

1. **Before Stage 3**: You place the CLAUDE.md template in the project root (it contains Part 1 framework rules + Part 2 placeholders).
2. **During Stage 3** (Scaffold): The scaffold generator fills in Part 2 with project-specific details while preserving Part 1.
3. **Stage 4** (this step): You verify both parts are intact and correct.

If Stage 3 has already completed, CLAUDE.md should be fully populated. If you're running Stage 4 independently (e.g., after a disconnect), you may need to install or fix it.

### 4.2 Install (only if CLAUDE.md doesn't exist)

If Stage 3 did not create or update CLAUDE.md, install the template:

~~~bash
# Check if CLAUDE.md exists
cat CLAUDE.md | head -5

# If it doesn't exist, copy the template
# Copy the CLAUDE.md template from the Transmute Framework Template repo root into the project root.
# The template lives at the ROOT of the Transmute Framework Template (not inside plancasting/transmute-framework/).
# If you cloned/copied the template repo, the file is already at ./CLAUDE.md.
# If starting from scratch, copy from wherever you stored the template repo:
cp /path/to/transmute-framework-template/CLAUDE.md ./CLAUDE.md
~~~

### 4.3 Verify Part 1 (Immutable Framework Rules)

Confirm all critical Part 1 sections are intact:

~~~bash
# Framework marker exists
grep "DO NOT remove or weaken any rule in Part 1" CLAUDE.md

# Design & Visual Identity section exists
grep "Design & Visual Identity" CLAUDE.md

# Progress Tracking section exists
grep "Progress Tracking" CLAUDE.md

# Traceability Rules section exists
grep "Traceability Rules" CLAUDE.md

# Testing Rules section exists
grep "Testing Rules" CLAUDE.md
~~~

If ANY of these checks fail, Part 1 was corrupted. Replace CLAUDE.md with the template and re-run Stage 3's CLAUDE.md update, or manually fill Part 2.

### 4.4 Verify Part 2 (Project-Specific Configuration)

Confirm placeholders have been replaced with actual project details:

~~~bash
# Should return NO matches (all placeholders filled)
grep '\[PROJECT_NAME\]' CLAUDE.md
grep '\[e\.g\.' CLAUDE.md
grep '\[N\]' CLAUDE.md
grep '\[One-sentence' CLAUDE.md

# Comprehensive check: ALL brackets in Part 2 are placeholders — none should remain
sed -n '/^## Part 2/,$p' CLAUDE.md | grep -n '\['
# If this returns matches, those are unfilled placeholders (e.g., [BACKEND_DIR], [FRONTEND_DIR])
~~~

If placeholders remain, ask Claude Code to fill them:

~~~bash
claude --dangerously-skip-permissions
~~~

~~~
Read CLAUDE.md, plancasting/tech-stack.md, and the generated codebase structure.
Fill in the Part 2 (Project-Specific Configuration) sections of CLAUDE.md
with actual project details.

CRITICAL RULES:
- Do NOT modify, delete, or rewrite Part 1 (Immutable Framework Rules).
- Do NOT rewrite the entire file. ONLY edit the placeholder content in Part 2.
- Preserve all HTML comments (they contain structural guidance).
~~~

### 4.5 Verify Loading

CLAUDE.md is automatically loaded by Claude Code when starting a session in the project directory:

~~~bash
cd ~/project
claude --dangerously-skip-permissions
# Type: "What does CLAUDE.md say about Design & Visual Identity?"
# Claude should answer with the full design quality guidelines from Part 1
~~~

After verification passes (all Part 1 sections intact, no Part 2 placeholders remain), commit: `git add CLAUDE.md && git commit -m "chore: complete Stage 4 (CLAUDE.md verification)"`. Proceed to Stage 5.

---

## Stage 5: Feature Implementation

**Goal**: Implement ALL features with complete business logic, UI, and tests — producing a fully functional product.

### 5.1 Pre-flight Check

Before starting, verify everything is in place:

~~~bash
cd ~/project

# 1. Business Plan exists
ls ./plancasting/businessplan/
# If this command fails: echo 'ERROR: ./plancasting/businessplan/ directory not found. Create it and add your Business Plan markdown files.'

# 1B. Spec Validation passed
cat ./plancasting/_audits/spec-validation/report.md | head -20
# Verify this file exists and shows PASS or CONDITIONAL PASS.
# If FAIL: STOP — go back to Stage 2B and resolve spec validation issues before Stage 5.

# 2. Tech stack is configured
cat ./plancasting/tech-stack.md | head -10

# 3. **Product Credential Gate** (re-check — credentials may have been added since Stage 3):
grep -E 'YOUR_.*_HERE|TODO_.*|CHANGE_ME|PLACEHOLDER|^[A-Z_]+=\s*$' .env.local
# If ANY credentials are still placeholders, STOP and provide them now.
# Stage 5 implements real features that connect to real services.
# Placeholder credentials will cause authentication failures, email sending errors,
# payment integration failures, and AI API call failures.

# 4. BRD exists and is complete
ls ./plancasting/brd/

# 5. PRD exists and is complete
ls ./plancasting/prd/

# 6. Scaffold code exists (check your main entry points)
ls ./src/ || ls ./app/  # frontend
ls ./convex/ || ls ./server/ || ls ./api/ || ls ./functions/  # backend directory (adapt to your stack: convex/, server/, api/, functions/, etc.)

# 7. CLAUDE.md is in place
cat ./CLAUDE.md | head -5

# 8. Progress tracker exists with all features
cat ./plancasting/_progress.md

# 9. Dev server runs (adapt commands to your stack)
npm run dev &  # adapt to your package manager (bun run dev &, etc.)
# Verify the app loads, then stop the dev server before proceeding
# Stop the backgrounded dev server:
lsof -ti:3000 | xargs kill 2>/dev/null  # adapt port number to your stack
~~~

**Important**: Stop the backgrounded dev server (`lsof -ti:<port> | xargs kill`) before proceeding to Stage 5 execution. Do NOT use Ctrl+C — the server was backgrounded with `&`. This start-verify-stop is a pre-flight check only. The Stage 5 orchestrator manages its own dev server lifecycle during implementation. Leaving it running can cause port conflicts.

### 5.2 Execute

~~~bash
claude --dangerously-skip-permissions
~~~

Paste the contents of **`prompt_feature_orchestrator.md`**.

### 5.3 What Happens — Per Feature

For each feature in the queue (P0 → P1 → P2 → P3, ALL features):

1. **Lead analyzes** the feature, reads relevant PRD/BRD sections, produces a Feature Implementation Brief in `./plancasting/_briefs/`
2. **backend teammate** implements schema changes, server functions, and backend tests
3. **frontend teammate** (after backend completes) implements hooks, components, pages, and component tests
4. **e2e-tester teammate** (after frontend completes) writes Playwright E2E tests including cross-feature tests
5. **Lead runs Quality Gate**: full type check, all tests, regression check, traceability audit
6. **Lead updates** `plancasting/_progress.md` and proceeds to next feature

### 5.4 After All Features Complete

The orchestrator automatically runs the **Full-Product Completion Sequence**:

1. **Full Integration Test Suite** — all tests across all features
2. **Cross-Feature Integration Sweep** — audits data flows between features
3. **Onboarding Flow Verification** — tests first-time user experience
4. **Performance Validation** — bundle size, Lighthouse scores, query performance
5. **Final Implementation Report** — saved to `./plancasting/_implementation-report.md` (preliminary self-assessment; the independent audit at `./plancasting/_audits/implementation-completeness/report.md` is produced by Stage 5B)

### 5.5 Session Limit Management

The orchestrator can process the number of features specified in tech-stack.md § Model Specifications "Session feature limit" per session before quality degrades. If your product exceeds the session feature limit:

1. Commit progress: `git add -A && git commit -m "chore: Stage 5 progress"`
2. Exit the Claude Code session after reaching the session feature limit
3. Start a fresh session with `claude --dangerously-skip-permissions`
4. Paste the Stage 5 orchestrator prompt again
5. It will read `_progress.md`, see which features are ✅ Done, and resume from the next incomplete feature

**Pre-Stage 5 feature sizing**: Before starting Stage 5, review `plancasting/_progress.md` and `plancasting/_scaffold-manifest.md`. If any feature spans 15+ source files (backend + frontend + tests combined), split it into sub-features (FEAT-003a, FEAT-003b) in `_progress.md` before pasting the prompt. Sub-features inherit the parent's priority and dependencies. The parent feature is marked `✅ Done` only when ALL sub-features are `✅ Done`.

**Stage 5 Resumption Logic**:
1. Orchestrator reads `plancasting/_progress.md` on startup
2. All `✅ Done` features → skipped
3. First `🔧 In Progress` feature → resume from that feature
4. First `🔄 Needs Re-implementation` feature → rebuild from scratch
5. `⏸ Blocked` features → skipped (treated like ✅ Done for resumption; operator must unblock manually before re-running). When unblocking, restore to the pre-block status: if the feature was `🔧` before blocking, unblock to `🔧` (resume); if it was `🔄` before blocking, unblock to `🔄` (rebuild from scratch)
6. First `⬜ Not Started` feature → start there
7. All features `✅ Done` → generate implementation report and exit
8. If session limit reached mid-feature → commit work, mark feature `🔧`, start new session and re-paste prompt. **Exception**: if the feature was `🔄 Needs Re-implementation`, keep it as `🔄` (not `🔧`) so the next session rebuilds from scratch — marking it `🔧` would cause the next session to resume partial work from the broken implementation instead of rebuilding.

> **Scanning order**: The orchestrator scans `_progress.md` top-to-bottom. It skips `✅ Done` and `⏸ Blocked` features. The first non-skippable feature encountered is processed: `🔧` = resume from incomplete layer, `🔄` = rebuild from scratch, `⬜` = start fresh. This is a positional scan, not a global status-priority scan — the orchestrator does NOT search all `🔧` before all `🔄`.

### 5.6 Monitor Progress

During execution, you can check progress at any time:

~~~bash
# View current progress
cat ./plancasting/_progress.md

# View feature briefs
ls ./plancasting/_briefs/

# Run tests manually
npm run test
npm run test:e2e
~~~

### 5.7 Human Review Checkpoint

After the orchestrator completes, review:
- `./plancasting/_implementation-report.md` — Is PRD coverage at 100%? (preliminary self-assessment; Stage 5B produces the independent audit)
- Assumptions list — Are they acceptable?
- PRD gaps list — Do any require specification updates?
- Known issues / technical debt — Are they acceptable for launch?
- Launch Readiness Assessment — Does the orchestrator recommend launch?

---

## Stage 5B: Implementation Completeness Audit

**Goal**: Verify that ALL features are truly implemented — not just scaffolded — and fix any gaps. This stage addresses a known pattern where backend is fully implemented but frontend components remain as stubs.
Issues are classified into three size-based categories (A/B/C). The Category C escalation thresholds determine the 5B gate outcome (one of four outcomes: PASS, CONDITIONAL PASS, FAIL-RETRY, FAIL-ESCALATE). Key thresholds — either condition independently triggers FAIL-ESCALATE: (a) 6+ Category C issues regardless of other counts, OR (b) 6+ total unfixed issues globally across all features and categories. See § "Gate Decision Outcomes" below for the full 5B gate table.

**Why this stage exists**: Stage 5 runs for hours, and the orchestrator's per-feature quality gates degrade as the session progresses (even with the pipeline model's full context window, quality declines beyond the session feature limit — see tech-stack.md § Model Specifications). By the end, frontend stubs often pass the quality gate unchallenged. Stage 5B runs with a fresh context window, focused solely on finding and fixing these gaps.

### 5B.1 Pre-flight Check

~~~bash
cd ~/project

# Verify Stage 5 completed
cat ./plancasting/_progress.md | head -20
# All features MUST show ✅ Done (or ⏸ Blocked with documented reason) — if any features show ⬜ Not Started or 🔧 In Progress, Stage 5 did not complete. Do NOT proceed.

# Verify Stage 5's preliminary implementation report exists
# If this file does not exist, Stage 5 may not have completed fully.
# Check plancasting/_progress.md for incomplete features before proceeding.
cat ./plancasting/_implementation-report.md | head -10
~~~

### 5B.2 Execute

~~~bash
claude --dangerously-skip-permissions
~~~

Paste the contents of **`prompt_implementation_audit.md`**.

### 5B.3 What Happens

1. **Lead performs a full-codebase stub scan** — automated pattern detection for placeholder text, orphan components, dead handlers, mock data, and thin pages.
2. **Lead cross-references PRD against implementation** — every user story, screen spec, and API endpoint is verified to have a functional (not scaffold) implementation.
3. **Issues are classified** into three size-based categories (A/B/C). See § "Gate Decision Outcomes" below for canonical definitions. Examples: A = placeholder text, missing handlers; B = stub components needing real UI; C = substantial implementation gaps needing Stage 5 re-run.
4. **frontend-stub-fixer teammate** fixes all Category A and B frontend issues (the primary focus).
5. **backend-stub-fixer teammate** fixes any backend stubs found (usually fewer).
6. **e2e-verification teammate** runs the full test suite to verify fixes.
7. **Rule extraction** (post-gate): Lead scans audit findings for repeatable, tech-stack-specific patterns. HIGH confidence patterns (2+ features affected) are written to `.claude/rules/`; MEDIUM/LOW patterns are staged in `plancasting/_rules-candidates.md`. See CLAUDE.md § "Path-Scoped Rules" for the quality gate.

### 5B.4 Gate Decision

The audit produces one of four outcomes (PASS, CONDITIONAL PASS, FAIL-RETRY, FAIL-ESCALATE). See § "Gate Decision Outcomes" below for the canonical gate thresholds and routing logic.

**Output**: `./plancasting/_audits/implementation-completeness/report.md`

### 5B.5 If FAIL: Recovery Actions

- **FAIL-RETRY**: Diagnose why fixes failed (missing backend dependency, incorrect hook API, type mismatch), then re-run Stage 5B. Do not re-run without diagnosis — it will cycle endlessly without progress.
- **FAIL-ESCALATE**: Set affected features to `🔄 Needs Re-implementation` in `plancasting/_progress.md`. Re-run Stage 5 with the orchestrator prompt — it will read `_progress.md`, see features marked as 🔄, and rebuild only those features. Then re-run Stage 5B to verify. Mark ONLY the features listed in the 5B report as having issues — do not mark all features. Stage 5B performs a fresh scan; previous FAIL-ESCALATE state is not carried forward.

To re-run for specific features:
1. Update `plancasting/_progress.md` — change affected features' status to `🔄 Needs Re-implementation`
2. Start a new Claude Code session and paste the Stage 5 orchestrator prompt
3. The orchestrator reads `plancasting/_progress.md` on startup and rebuilds only features not marked as ✅ Done
4. After completion, re-run Stage 5B to verify

---

## Stage 6: Post-Implementation Quality Assurance

**Pre-flight for ALL Stage 6 sub-stages**: Verify `./plancasting/_audits/implementation-completeness/report.md` exists and shows PASS or CONDITIONAL PASS. Do not proceed with any Stage 6 work if 5B has not reached PASS or CONDITIONAL PASS (FAIL-RETRY and FAIL-ESCALATE both block Stage 6).

**Escalation back to 5B**: If any Stage 6 audit discovers that a feature is fundamentally unimplemented (not a stage-specific issue but a missing implementation that 5B should have caught), escalate to a Stage 5B re-run before continuing Stage 6. Set the affected feature to `🔄 Needs Re-implementation` in `_progress.md`, re-run Stage 5 for that feature, then re-run 5B.

**Stage 6 sub-stages** (listed in execution order, not alphabetical): 6A (Security Audit) + 6B (Accessibility Audit) + 6C (Performance Optimization) [parallel], then 6E (Code Refactoring) → 6F (Seed Data Generation) → 6G (Error Resilience Hardening) → 6D (Documentation Generation) → 6H (Pre-Launch Verification) → 6V (Visual & Functional Verification) → 6R (Runtime Remediation) → 6P (Visual Polish) or 6P-R (Frontend Design Elevation — alternative to 6P).

After the Implementation Completeness Audit passes (Stage 5B), run these audits before deploying to production. Stages 6A, 6B, and 6C can run in parallel, but later stages have dependencies — see "Stage 6 ordering" below for the full sequence.

**Unfixable Violation Protocols**: All Stage 6 sub-stages (6A-6G) include protocols for documenting issues that cannot be fixed without architectural changes. Each stage may create an `unfixable-violations.md` file in its respective audit directory (e.g., `plancasting/_audits/security/unfixable-violations.md`) documenting the violation, evidence, and recommended approach. Stage 6H consolidates all unfixable violation files and evaluates each as a potential launch blocker — an unfixable violation is launch-blocking ONLY if it prevents core business functionality.

**Recovery note**: For Stages 6A-6P: If a stage disconnects mid-execution, the partial changes are safe to keep. Start a new session and re-run the same prompt — the agent will detect existing work and complete any remaining items. These stages are idempotent.

**Stage 6 ordering** (mandatory default — dependencies between stages require this sequence. See individual stage notes for documented alternatives (e.g., 6D early-draft option)):

**Parallel group** (open 3 terminal windows, start an independent `claude --dangerously-skip-permissions` session in each):
- 6A Security + 6B Accessibility + 6C Performance — file conflicts are rare because these audits target different code aspects: auth/validation, ARIA attributes, and bundle/query optimization respectively.

**CRITICAL merge point**: As each parallel stage completes, commit its changes immediately (`git add -A && git commit -m 'chore: complete Stage 6X ...'`). If merge conflicts occur, resolve and re-run the conflicting stage. Do NOT start sequential stages until all three are committed.

**Sequential** (after parallel group committed):
1. 6E Code Refactoring (after all audits that modify code)
2. 6F Seed Data Generation (after refactoring stabilizes the schema)
3. 6G Error Resilience Hardening (after refactoring for cleaner error handling patterns)
4. 6D Documentation Generation (runs after 6G by default — all code changes must be finalized before documentation. **Alternative** for large projects: run after 5B PASS for an early draft, then re-run after 6E–6G if those stages modify code)
5. 6H Pre-Launch Verification (static final gate — READY/NOT READY)
6. 6V Visual & Functional Verification (live app verification gate)
7. 6R Runtime Remediation (auto-fix cycle for 6V failures — only if 6V finds 6V-A/B issues)
8. 6P Visual Polish & UI Refinement (fixes within existing design) OR 6P-R Frontend Design Elevation (full interactive redesign — use when the app needs a new visual identity, not just polish). See the "6P vs 6P-R" section below for guidance.

### 6A. Security Audit

**Goal**: Identify and fix authentication gaps, input validation issues, and data exposure risks. **Scope note**: 6A covers AUTH-related rate limiting (login attempts, password resets, password changes, token refresh, email verification, MFA device management, account linking, invitation acceptance, signup, logout). DATA-MUTATION rate limiting (user profile updates, API writes, bulk operations, file uploads) is covered by 6G. Edge cases: password change = 6A (auth operation), user profile update = 6G (data mutation), invitation acceptance = 6A (auth flow). This section is the canonical scope boundary definition.

~~~bash
claude --dangerously-skip-permissions
~~~

Paste the contents of **`prompt_audit_security.md`**.

**Output**: `./plancasting/_audits/security/report.md` with vulnerability findings, fixes applied, and BRD security requirement compliance matrix.

**Human Review**: Review the report for any issues marked as "requiring human decision" — these typically involve business trade-offs between security and usability.

### 6B. Accessibility Audit

**Goal**: Achieve WCAG conformance across the entire product.

~~~bash
claude --dangerously-skip-permissions
~~~

Paste the contents of **`prompt_audit_accessibility.md`**.

**Output**: `./plancasting/_audits/accessibility/report.md` with WCAG compliance status, violations fixed, and automated axe-core test results.

**Human Review**: Automated tools catch approximately 30–50% of accessibility issues. Manual screen reader testing is recommended for critical user flows after this audit.

### 6C. Performance Optimization

**Goal**: Meet PRD performance budgets (page load, bundle size, Lighthouse scores, backend query efficiency).

~~~bash
claude --dangerously-skip-permissions
~~~

Paste the contents of **`prompt_optimize_performance.md`**.

**Output**: `./plancasting/_audits/performance/report.md` with performance budget compliance, optimizations applied, and Lighthouse scores.

**Human Review**: Verify Lighthouse scores meet PRD targets. Performance optimizations rarely need manual review, but check for removed features that may have been misidentified as dead code.

### 6D. Documentation Generation

**Goal**: Generate developer documentation, API reference, and architecture docs.

~~~bash
claude --dangerously-skip-permissions
~~~

Paste the contents of **`prompt_generate_documentation.md`**.

**Output**: `./docs/` directory with developer guide, API docs, architecture docs, and changelog.

**Gate**: PASS / CONDITIONAL PASS / FAIL — see `prompt_generate_documentation.md` § Gate Decision for criteria.

**Ordering note**: The standard path is after 6G (all code changes finalized) per the Stage 6 ordering above — this is the mandatory default. **Early-draft alternative** (for projects with 20+ features where documentation parallelism is needed): run after 5B PASS to generate a draft, but you MUST re-run 6D after 6G completes to refresh documentation if 6E, 6F, or 6G modified code. The re-run is mandatory, not optional. Single-run after 6G is the recommended default for most projects.

**Human Review**: Review the developer documentation for accuracy. Technical API docs are usually accurate but developer onboarding content benefits from a human pass.

### 6E. Code Refactoring

**Goal**: Eliminate code duplication, improve abstractions, enforce consistency, optimize schema, and remove dead code — without changing any external behavior.

~~~bash
claude --dangerously-skip-permissions
~~~

Paste the contents of **`prompt_refactor_code.md`**.

**Output**: `./plancasting/_audits/refactoring/report.md` with before/after metrics, changes applied, and remaining technical debt.

**Ordering note**: Run after 6A–6C (per the Stage 6 ordering above) since those audits introduce code changes that benefit from refactoring. **Stage 6E must COMPLETE before Stage 6G starts** — do NOT run in parallel. Error handling pattern changes in 6E (refactored error helpers, new exception types) affect what 6G can harden.

**Gate**: PASS / CONDITIONAL PASS / FAIL — see `prompt_refactor_code.md` § Gate Decision for criteria.

**Human Review**: Verify the refactoring report shows zero test regressions. Spot-check key user flows to confirm no behavioral changes.

### 6F. Seed Data Generation

**Goal**: Generate realistic test data for development, testing, and demo environments.

~~~bash
claude --dangerously-skip-permissions
~~~

Paste the contents of **`prompt_generate_seed_data.md`**.

**Output**: `./seed/` directory with seed scripts for dev, test, demo, stress, and empty-state tiers, plus `./seed/README.md` with usage instructions.

**Gate**: PASS / CONDITIONAL PASS / FAIL — see `prompt_generate_seed_data.md` § Gate Decision for criteria.

**How to use**:
~~~bash
# Adapt to your package manager (npm run, bun run, pnpm run, etc.)
npm run seed:dev      # Minimal data for development
npm run seed:test     # Moderate data for testing (includes pagination-triggering volumes)
npm run seed:demo     # Curated scenarios for stakeholder demonstrations
npm run seed:stress   # High-volume data for performance testing
npm run seed:empty    # Empty-state users (no data) for UI verification
npm run seed:verify   # Referential integrity check on seeded data
npm run seed:reset    # Clear all data and re-seed
~~~

### 6G. Error Resilience Hardening

**Prerequisite**: Stage 6E must have completed — 6G depends on refactored error handling patterns from 6E. Do NOT run 6E and 6G in parallel.

**Goal**: Systematic cross-cutting review and improvement of error handling, network failure recovery, concurrent usage safety, and edge case handling.

~~~bash
claude --dangerously-skip-permissions
~~~

Paste the contents of **`prompt_harden_resilience.md`**.

**Output**: `./plancasting/_audits/resilience/report.md` with improvements applied across backend (retry logic, circuit breakers, data consistency), frontend (error boundaries, network failure UX, reconnection handling), and edge cases (concurrent usage, boundary conditions, auth and navigation edge cases).

**Human Review**: Test key user flows with network throttling enabled (browser DevTools → Network → Slow 3G) to verify the resilience improvements feel natural to users.

### 6H. Pre-Launch Verification

**Goal**: Final comprehensive check before production deployment. This is the last **static** analysis gate — it confirms the project is deployable in principle (credentials, config, builds, test suites). Stage 6V then tests **runtime** behavior against a running application. 6H must complete before 6V starts.

~~~bash
claude --dangerously-skip-permissions
~~~

Paste the contents of **`prompt_prelaunch_verification.md`**.

**Output**: `./plancasting/_launch/readiness-report.md` with a READY / NOT READY decision, blocker list, and post-launch checklist.

**6D early-draft check**: If 6D was run as an early draft (before 6G completed), verify the 6D report timestamp is later than the last 6E/6F/6G commit. If not, re-run 6D before proceeding to 6H.

**IMPORTANT**: If the report says NOT READY, do NOT proceed to Stage 7. Review the blocker list in the readiness report, manually fix each blocker (update code, credentials, or config), then re-run 6H in a new session — it will detect the fixes and re-evaluate.

### 6V. Visual & Functional Verification

**Goal**: Dynamically generate comprehensive test scenarios from PRD specs + codebase analysis, then execute them against the RUNNING application. Scenarios cover complete user workflows, auth context transitions, entity state variations, role permissions, and navigation paths — not just individual page loads. This is the stage that catches runtime errors, broken routes, invisible components, and spec mismatches that static code analysis cannot detect.

#### Pre-6V Setup (BEFORE starting Claude Code)

Verify the shared reference file and dev server port BEFORE starting a Claude Code session:

~~~bash
# 1. Verify feature_scenario_generation.md exists (REQUIRED — 6V fails immediately without it)
ls ./plancasting/transmute-framework/feature_scenario_generation.md
# If missing, copy from the Transmute Framework Template:
# mkdir -p ./plancasting/transmute-framework
# cp "/path/to/Transmute Framework Template/plancasting/transmute-framework/feature_scenario_generation.md" ./plancasting/transmute-framework/

# 2. Verify dev server port is available (the 6V prompt starts it internally)
lsof -i :3000  # if output shows a process, kill it: kill -9 <PID>
# Note: adapt port to your framework's default (Next.js: 3000, Vite/SvelteKit: 5173, Remix: 3000, Astro: 4321)

# 3. Start Claude Code session
claude --dangerously-skip-permissions
~~~

Paste the contents of **`prompt_visual_functional_verification.md`**.

> This prompt internally uses `./plancasting/transmute-framework/feature_scenario_generation.md` — a shared reference that defines the algorithm for extracting user flows, edge cases, and error paths from the PRD, then converting them into executable test scenarios. The 6V and 7V prompts reference it internally — do NOT paste it separately into Claude Code.

After Claude processes the prompt, it will begin in `full` mode by default. To override, append the scope on a new line at the end of the pasted prompt before sending (e.g., `MODE: critical`), or type it as a separate follow-up message (e.g., "Run in critical mode").

Scope modes:
- **`full`** — Comprehensive verification of all components, pages, API routes, and state management (default). Use for first verification or after major changes.
- **`critical`** — P0/P1 features only. Use for time-constrained runs.
- **`diff`** — Only screens affected by recent changes since the last 6V run. Requires a previous 6V report to diff against — do NOT use for the first 6V run. Use for incremental re-verification.

**Output**: `./plancasting/_audits/visual-verification/report.md` with per-screen pass/fail results, acceptance criteria results, visual compliance review, and generated Playwright test files in `e2e/verification/`.

**Dual execution mode**: The stage both generates reusable Playwright tests (Mode A) AND uses direct browser interaction for AI vision review (Mode B). Both run every time.

**IMPORTANT**: If the 6V report says PASS (all acceptance-criteria scenarios passing, zero 6V-A/6V-B issues — PASS means no actionable issues, not literally zero observations), skip 6R and proceed directly to 6P or 6P-R. If CONDITIONAL PASS with any 6V-A/B issues (regardless of whether 6V-C issues also exist), proceed to Stage 6R (Runtime Remediation) to auto-fix mechanical issues. If CONDITIONAL PASS with only 6V-C issues, skip 6R (it cannot fix those) and proceed directly to 6P or 6P-R. If the report says FAIL (critical failures found), fix critical issues manually first, then re-run 6V. Maximum 3 consecutive 6V FAIL re-runs — if 6V continues to FAIL after 3 runs, escalate to operator for manual triage (the failures may indicate architectural issues beyond the scope of 6V fixes). Do NOT proceed to 6R until critical issues are resolved.

**Human Review**: Review the generated screenshots in `./screenshots/` to confirm the AI's visual assessments are accurate. Pay special attention to layout issues the AI might have misjudged.

**Post-6V Routing**: See § "Gate Decision Outcomes" below for the canonical routing table. After 6R completes (or is skipped), see the "6P vs 6P-R" section below to choose between standard polish and full redesign.

### 6R. Runtime Remediation

> ⚠️ **Category System Note**: 6V/6R categories differ from 5B categories. See § "Gate Decision Outcomes" → "Category Systems" for both sets of canonical definitions. Key difference: 5B classifies by *size*, 6V/6R classifies by *fixability*.

**Goal**: Automatically fix mechanical issues found by Stage 6V (broken links, middleware gaps, missing loading states, unwired button handlers, etc.) and produce a structured TODO for issues requiring human judgment.

~~~bash
claude --dangerously-skip-permissions
~~~

Paste the contents of **`prompt_runtime_remediation.md`**.

**Input**: Stage 6V report at `./plancasting/_audits/visual-verification/report.md` + full codebase.

**Output**: `./plancasting/_audits/runtime-remediation/report.md` with:
- All 6V-A (auto-fixable) issues resolved and verified
- All 6V-B (semi-auto) issues attempted, with verification results
- All 6V-C (needs-human) issues documented with context and decision options
- Updated 6V report with remediation results appended
- Updated `.claude/rules/` with verified fix patterns (HIGH confidence) and `plancasting/_rules-candidates.md` with MEDIUM confidence patterns

**Remediation cycle**: 6R applies fixes then performs targeted re-verification of each fixed issue (using Playwright browser tools for spot-checks, not a full 6V re-run). Maximum 3 internal fix-verify cycles per run. After 3 internal fix-verify cycles, any remaining 6V-A/B issues auto-escalate to 6V-C (human judgment required). 6V-C issues must be resolved manually or documented as known limitations. Max 2 outer 6V→6R cycles. If issues persist after 2 cycles, document as known limitations and proceed to 6P/6P-R.

**Rule extraction**: After generating the remediation report, 6R evaluates each verified 6V-A/B fix for generalizability. Fixes that address tech-stack-specific gotchas become rules. 6V-C issues that reveal tech-stack limitations also become rules (prevents future agents from attempting impossible approaches). See § "Path-Scoped Rules — Self-Evolving Development" for the full lifecycle.

**Gate decision**: See § "Gate Decision Outcomes" → "Post-6R routing" for routing (PASS/CONDITIONAL PASS/FAIL).

### 6P vs 6P-R: When to Use Which

See § "Gate Decision Outcomes" → "6P vs 6P-R" for the canonical decision table. In brief: use **6P** (20–40 min) for contrast, hover states, spacing, and typography fixes within the existing design. Use **6P-R** (2–4 hrs, interactive) for distinctive visual identity, rebranding, design system establishment, font family or color palette overhauls, or when the product has zero design identity. Default to 6P unless the operator explicitly requests a design overhaul.

### 6P. Visual Polish & UI Refinement

**Goal**: Analyze the application's visual quality and automatically refine UI styling, layout, visibility, and micro-interactions to production-grade aesthetic quality. Uses the `frontend-design` skill (if available) for design decisions while working within the project's existing design system. If the `frontend-design` skill is not available (e.g., local CLI environment), 6P uses the project's existing design tokens in `src/styles/design-tokens.ts` as the design authority.

~~~bash
claude --dangerously-skip-permissions
~~~

Paste the contents of **`prompt_visual_polish.md`**.

**Input**: Running dev server + 6V/6R screenshots in `./screenshots/` + existing design system tokens.

**Output**: `./plancasting/_audits/visual-polish/report.md` with:
- All Category O (objective defects) fixed and verified
- All Category E (enhancements) applied using design system tokens
- Category D (design elevation) brief for human review
- Before/after comparison screenshots at 3 breakpoints + dark mode

> See § "Gate Decision Outcomes" → "Category Systems" for canonical category definitions (O/E/D).

**Prerequisite**: If Stage 6V found issues, Stage 6R must PASS or CONDITIONAL PASS before running 6P. If 6V passed with no issues, 6P can run directly after 6V. If 6R has unresolved critical functional issues, do NOT run 6P. **Exception**: If 6R FAIL persists after the maximum 2 outer 6V→6R cycles, document remaining issues as known limitations and proceed to 6P/6P-R. The 6R report MUST note: '6R FAIL (max-cycle exhaustion — proceeding with documented limitations).' This exception applies only when all remediation cycles are exhausted.

**Gate decision** (see § "Gate Decision Outcomes" → "Post-6P / 6P-R routing"):
- **PASS**: All Category O fixed, Category E applied, no regressions → proceed to Stage 7 (Deploy)
- **CONDITIONAL PASS**: All critical fixed + Category D brief for optional elevation → proceed to Stage 7 (Deploy), consider design review
- **FAIL**: Regressions remain or validation fails → investigate and fix:
  - If regressions are minor (wrong color, missing hover): fix manually in code, then re-run 6P to verify
  - If regressions are major (broken layout, missing components): commit all 6P work (`git add src/ plancasting/_audits/visual-polish/ && git commit -m "chore(6p): Stage 6P visual polish changes"`), then revert (`git revert <6P-commit>` — safer than `git checkout -- src/` which discards ALL uncommitted changes), re-run 6V to identify root cause, then try 6P again
  - Do NOT skip to Stage 7 with known regressions

### 6P-R. Frontend Design Elevation (Alternative to 6P)

**Goal**: Comprehensive visual redesign — not polish, but a full design overhaul. Use when the app needs a new visual identity, not just spacing/contrast fixes. This is an interactive stage: the operator participates in Phase 0 (context collection), Phase 1 (6-8 design decisions), and Phase 2 (Design Plan Confirmation — requires approval), then implementation (Phase 3+) runs autonomously.

**Prerequisite**: Same as 6P — Stage 6V must have completed; if 6V found 6V-A/B issues, 6R must be PASS or CONDITIONAL PASS before running 6P-R. If 6V found only 6V-C issues (human judgment), 6R is skipped — proceed directly to 6P-R. **Exception**: If 6R FAIL persists after the maximum 2 outer 6V→6R cycles, remaining issues are documented as known limitations and 6P-R may proceed (see 6P prerequisite for the max-cycle exhaustion rule).

~~~bash
claude --dangerously-skip-permissions
~~~

Paste the contents of **`prompt_frontend_redesign.md`**.

**Phases**: Phase 0 (Context — interactive), Phase 1 (Design Decisions — interactive, 6-8 choices), Phase 2 (Design Plan Confirmation — requires user approval), Phase 3+ (Autonomous Implementation), Final Phase (Verification).

**Creates a feature branch**: `redesign/frontend-elevation` — merge to main when satisfied with the results.

**After 6P-R completes** (PASS/CONDITIONAL PASS): Merge the `redesign/frontend-elevation` branch to main first, THEN always re-run Stage 7D (User Guide) in a fresh session to regenerate all content with the new visual design — this is required even if 7D ran before 6P-R:
1. Merge: `git checkout main && git merge redesign/frontend-elevation`
2. Re-paste the Stage 7D prompt in a fresh session — it will recreate all MDX pages with screenshots matching the new design
3. Manually update `docs.json` color tokens to match the new design palette (the generator does NOT auto-update config)
4. Before capturing screenshots, grep for actual image paths: `grep -r 'src="' user-guide/ --include='*.mdx'` for hardcoded images; for Mintlify components with image props, manually verify referenced images exist in `public/`
5. Commit both the regenerated pages and the updated config in a single commit

**Hybrid theme warning** (applies only if implementing a Hybrid theme — light marketing / dark app): NEVER use `setTheme()` to force light mode — it writes to localStorage and causes flicker. See `prompt_frontend_redesign.md` § "Known Failure Patterns" #11–#12 for the Hybrid theme `setTheme()` / localStorage pitfalls.

**Gate decision**: PASS / CONDITIONAL PASS / FAIL (same gate structure as 6P, but uses Critical/Major/Minor severity categories instead of 6P's O/E/D), plus a Phase 2 rejection path unique to 6P-R.
- PASS/CONDITIONAL PASS → Merge to main, Stage 7 → 7V → 7D (re-run).
- FAIL → Abandon the redesign branch (`git checkout main`) and either retry 6P-R in a new session or fall back to standard 6P. Delete the abandoned branch if not needed (`git branch -d redesign/frontend-elevation` — use `-D` if `-d` refuses because the branch is unmerged).
- **Phase 2 rejected** (operator declines the design plan) → `git checkout main` to abandon the branch. Either retry 6P-R with different design direction, or switch to 6P for lighter-touch polish. The Phase 2 rejection is NOT a failure — it is a design direction disagreement that the operator resolves by restarting or switching approaches.

---

## Stage 7: Deployment

After all pre-deploy gates pass (listed in execution order):
- **6H**: READY
- **6V**: PASS or CONDITIONAL PASS (never skip — see CLAUDE.md § Safety-Critical Rules)
- **6R**: PASS or CONDITIONAL PASS (if 6R was run; skipped if 6V returned PASS or CONDITIONAL PASS with only 6V-C issues)
- **6P or 6P-R**: PASS or CONDITIONAL PASS (one of 6P/6P-R always runs — even if 6V passes with zero issues, visual polish is applied before deploy)
- **6D** (mandatory for software products): Complete — its output serves as Stage 7's deployment reference (`./docs/developer/deployment.md`). If 6D was skipped: refer to your hosting provider's documentation for deployment steps; no earlier stages need re-running

Stage 7D (User Guide) is optional — skip if `plancasting/tech-stack.md` Documentation section indicates user documentation is not needed. If skipped, proceed directly to Stage 8 (the 7D gate does not apply).

> **PRODUCTION_TEST_USERS**: Before running 7V, ensure a `PRODUCTION_TEST_USERS` section exists in `e2e/constants.ts` with production test account credentials (email, password). These accounts must be created in the production auth provider.

### 7.1 Production Deployment

**Stack Adaptation**: The deployment commands below are Convex + Vercel examples. Adapt to your hosting provider and backend per `plancasting/tech-stack.md`.

Follow the deployment guide in `./docs/developer/deployment.md` (generated by Stage 6D — if 6D was skipped, refer to your hosting provider's documentation) and the post-launch checklist from `./plancasting/_launch/readiness-report.md`.

Example for Convex + Vercel (adapt to your tech stack):

~~~bash
# 1. Deploy backend to production
npx convex deploy

# 2. Configure hosting provider environment variables
# CRITICAL: .env.local is NOT automatically synced to Vercel/Netlify.
# Every environment variable must be explicitly set on the hosting platform.
#
# For Vercel:
#   - Add variables individually (Vercel will prompt for the value):
#     npx vercel env add NEXT_PUBLIC_CONVEX_URL production
#     npx vercel env add NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY production
#     # ... repeat for each variable in .env.local
#   - Or use the Vercel dashboard: Settings → Environment Variables → Add
#   - Add BaaS URL if not in .env.local (often auto-set by dev server only):
#     npx vercel env add NEXT_PUBLIC_CONVEX_URL production
#   - Verify all variables are set:
#     npx vercel env ls production

# 3. Build and deploy frontend
npm run build
# Deploy to Vercel, Netlify, or your hosting provider

# 4. Run post-launch checklist from readiness report
# - Verify DNS propagation
# - Verify SSL certificate
# - Run smoke test on production URL
# - Verify monitoring dashboards show live data
# - Verify error tracking receives test errors
# - Send test transactional email from production
# - Verify auth flow works on production domain
~~~

### 7.1.1 Verify Deployment

After deployment, verify the production environment is functional:
- Production URL loads without errors (not a blank page)
- Auth flow completes successfully on the production domain
- At least one authenticated page renders correctly
- Error monitoring dashboard shows the application is reporting (not zero traffic)
- Run Stage 7V (Production Smoke Verification) for comprehensive verification

### 7.1.2 Deployment Failure Recovery

If the Stage 7 deployment itself fails (distinct from 7V verification failures):

- **Frontend build failure**: Fix build errors locally, verify with `npm run build` (or equivalent), then retry deployment. Common causes: missing environment variables on the hosting platform, TypeScript errors that passed locally but fail in CI due to stricter settings.
- **Deployment succeeds but app is broken** (blank page, 500 errors): Roll back to the previous deployment using your hosting provider's rollback feature (e.g., `vercel rollback`, Netlify Dashboard → Deploys → select previous deploy → Publish). Investigate the root cause locally before retrying.
- **Backend deployment/migration failure**: See § "Troubleshooting" → "Backend deployment errors" for provider-specific recovery procedures. Do NOT deploy the frontend until the backend is stable.
- **Partial deployment** (backend deployed but frontend failed, or vice versa): Roll back the deployed component to match the other. Never leave backend and frontend at mismatched versions in production.

### 7.1.3 Environment Operations

After deployment, use these commands to manage environments. Refer to `plancasting/tech-stack.md` § "Environment Strategy" for your project-specific configuration (generated by Stage 0; if missing, define your environment strategy manually).

**Switching Environments**:

| Backend | Switch to Staging | Switch to Production |
|---|---|---|
| Convex | `npx convex dev --deployment <staging-deployment-name>` (substitute `bunx` for `npx` per your package manager) | `npx convex deploy --prod` |
| Supabase | Update `NEXT_PUBLIC_SUPABASE_URL` in `.env.local` to staging URL | Update to production URL |
| Firebase | `firebase use staging` | `firebase use production` |

**CDN Cache Clearing**:

| Provider | Command |
|---|---|
| Vercel | `npx vercel cache purge` (purges CDN + data cache). CDN only: `npx vercel cache purge --type cdn`. To also bypass build cache on next deploy: `npx vercel --force` |
| Netlify | `npx netlify deploy --build --clear` or Dashboard → Deploys → Clear cache |
| Cloudflare | `curl -X POST "https://api.cloudflare.com/client/v4/zones/{zone_id}/purge_cache" -H "Authorization: Bearer {token}" -d '{"purge_everything":true}'` |
| CloudFront | `aws cloudfront create-invalidation --distribution-id {id} --paths "/*"` |

**Database Migration Across Environments**:

For **BaaS with auto-migration** (Convex, Supabase, Firebase): schema changes are applied automatically during deployment (e.g., `npx convex deploy` pushes schema to production). Verify the deployment succeeded and spot-check production data integrity after each deploy.

For **migration-file workflows** (Drizzle, Prisma, Knex, raw SQL): promote schema changes following the schema promotion order in `plancasting/tech-stack.md` § "Database Migration Strategy" (generated by Stage 0; if missing, define your migration strategy manually).

If **dev → staging → prod**:

1. **Dev → Staging**: Apply and verify migrations on staging. Run integration tests against staging data.
2. **Staging → Prod**: After staging verification passes, apply the same migrations to production.
3. **Verify**: Confirm production schema matches expectations. Run smoke tests.

If **dev → prod** (no staging): apply migrations to production after thorough local testing and verification. Run smoke tests immediately after.

> **CAUTION**: NEVER run seed commands (e.g., `npm run seed:dev`) against a production database. Seed data is for development and staging only. Production data comes from real users.

### 7.2 Production Smoke Verification (7V)

**Goal**: Verify the DEPLOYED production application works correctly — confirming that deployment didn't introduce environment-specific failures (missing env vars, CDN issues, CSP blocking, auth misconfiguration).

~~~bash
claude --dangerously-skip-permissions
~~~

Paste the contents of **`prompt_production_smoke_verification.md`**. Provide the production URL.

**Prerequisite**: `./plancasting/transmute-framework/feature_scenario_generation.md` must exist (same file used by 6V — should already be present if 6V was run).

**Output**: `./plancasting/_audits/production-smoke/report.md` with infrastructure checks, public utility route verification, 6R fix verification (if 6R was run), 6P/6P-R visual polish spot-check, navigation smoke test, critical page loads, user flow results, visual comparison against 6V, and third-party integration status.

**IMPORTANT**: This is a LIGHTER check than 6V — focused on deployment-specific issues, not full spec compliance. Should complete in 25–45 minutes. Includes 6R fix verification (confirms remediation fixes survived deployment) and a navigation smoke test (catches CSS purge and middleware issues in production).

**Scope**: SMOKE — P0+P1 features only, max 15 scenarios. 6V scope modes (full/critical/diff) do not apply to 7V.

**If FAIL**: Investigate immediately. If a critical flow is broken, either hotfix + re-deploy or rollback. Do NOT leave a broken production deployment.

### 7.3 User Guide Generation (7D)

**Goal**: Generate a complete, deployable Mintlify documentation site with user-facing guides organized by user journey — ready for deployment to `docs.yourproduct.com`.

> **Note**: Mintlify is the default user guide framework. If `plancasting/tech-stack.md` § Documentation specifies a different framework (e.g., Docusaurus, Starlight, GitBook), substitute that framework's tooling, CLI commands, config files, and deployment steps throughout this section. The prompt (`prompt_generate_user_guide.md`) reads the tech-stack file and adapts accordingly.

**Prerequisite**: Stage 7V must achieve PASS or CONDITIONAL PASS (do NOT proceed if 7V has not been run or returned FAIL). The production application must be stable. Node.js v20.17.0+ is required for the Mintlify CLI (`mint dev` / `mint validate` / `mint broken-links` / `mint a11y` — install with `npm i -g mint`). If the Mintlify Claude Code plugin is installed, teammates can use the `/mintlify:mintlify` skill and MCP server for up-to-date platform reference. If `plancasting/tech-stack.md` § Documentation section is marked as `not needed: true`, skip this stage entirely — proceed directly to Stage 8.

**Directory Clarification**: This stage creates `./user-guide/` (user-facing Mintlify documentation site). Do NOT confuse this with `./docs/` created by Stage 6D (internal developer documentation). Separation of concerns: internal devs read `./docs/`, end-users read `./user-guide/`.

~~~bash
claude --dangerously-skip-permissions
~~~

Paste the contents of **`prompt_generate_user_guide.md`**. Provide the production URL.

**What Happens**:
1. Lead reads 7V report (must be PASS or CONDITIONAL PASS), Stage 5B report (for any CONDITIONAL PASS limitations to note in documentation), PRD user flows, and plancasting/tech-stack.md branding.
2. Lead derives journey categories by clustering PRD user flows (UF-*) by user goal — this is the core generic algorithm that makes the prompt product-agnostic.
3. Lead creates a content map (`./plancasting/_guide-context.md`) with journey structure, concept pages, writing style, and branding.
4. Three teammates run in parallel:
   - **journey-writer**: All journey guide pages + introduction + quickstart (from UF-*, SC-*, US-*)
   - **concepts-and-reference-writer**: Concept pages, FAQ, troubleshooting, changelog, API reference (conditional)
   - **config-and-structure**: docs.json configuration (root-only for English-only, root + per-language for multi-language), static assets, snippets, then validates after content teammates finish
5. Lead runs final audit: JSON validity, navigation completeness, jargon scan, translation parity, Mintlify CLI checks (`mint validate`, `mint broken-links`, `mint a11y`).
6. Gate decision: PASS (deploy) / WARN (deploy with known issues) / FAIL (fix first).

**Output**: `./user-guide/` directory containing a complete Mintlify site (`docs.json`, MDX pages, static assets, snippets). If multi-language is configured (session language ≠ English), content goes in `en/` and `<lang>/` subdirectories. If English-only, content goes at the `user-guide/` root with no language subdirectories. Audit report at `./plancasting/_audits/user-guide/report.md`.

**Deployment**:
1. Create a Mintlify project at [mintlify.com/start](https://mintlify.com/start) (if not already set up in Stage 0)
2. In the Mintlify dashboard, enable "Set up as monorepo" and set path to `/user-guide`
3. Connect the repository via the Mintlify GitHub App
4. Custom domain: add a CNAME record `docs → cname.mintlify-dns.com.` and set `canonicalUrl` in `docs.json`
5. Push to trigger auto-deploy — preview at `https://project-name.mintlify.app`

**Local preview** (optional): `mint dev` from the `user-guide/` directory (requires Node.js v20.17.0+, install CLI with `npm i -g mint`). Also run `mint validate` and `mint broken-links` to catch issues before pushing.

**If generated content has issues**: For minor fixes, edit the MDX files directly — they are standard markdown with Mintlify components. Run `mint dev` for local preview and `mint broken-links` to check links before pushing. For major issues (wrong journey structure, missing large sections), re-run Stage 7D — it is idempotent and deletes then recreates `./user-guide/` with fresh content derived from the current PRD (preventing stale pages from lingering).

### Post-Launch Monitoring

Refer to the PRD's operational readiness specifications:
- `./plancasting/prd/16-operational-readiness.md` — Monitoring, alerting, incident response
- `./plancasting/prd/15-non-functional-specifications.md` — SLIs, SLOs, error budgets

Monitoring and error tracking should be configured during Stage 6H (Pre-Launch Verification) and verified during Stage 7V.

---

## Stage 8: User Feedback → Specification Reflection Loop

**Prerequisite**: Stage 7V PASS or CONDITIONAL PASS (product deployed and verified in production). If Stage 7D was run, it must be PASS or WARN (non-blocking issues documented but not gate-failing; FAIL blocks Stage 8 until resolved). If 7D returned FAIL, re-run Stage 7D to resolve documentation issues before starting Stage 8. If 7D was skipped, this gate does not apply.

**Goal**: Continuously improve the product by processing user feedback into specification changes, code updates, and documentation updates — keeping BRD/PRD as living documents.

### 8.1 Prepare Feedback Input

Create `./feedback/input.md` with structured user feedback collected since the last feedback batch. Include support tickets, analytics data, survey results, and stakeholder requests. Follow the format specified in the prompt. **Batch limit**: Limit each feedback batch to the feedback batch limit defined in `tech-stack.md` § Model Specifications (default: 10 items if not specified). If you have more items, split into multiple batches and run Stage 8 once per batch.

### 8.2 Execute

~~~bash
claude --dangerously-skip-permissions
~~~

Paste the contents of **`prompt_feedback_loop.md`**.

### 8.3 What Happens

1. Lead triages feedback: categorizes (bug / UX issue / missing feature / enhancement / documentation / performance), traces to existing specs, and creates a change plan.
2. **spec-updater** teammate updates BRD/PRD to reflect needed changes.
3. **code-implementer** teammate implements code changes against updated specs.
4. **test-and-docs-updater** teammate updates tests, developer documentation (`docs/`), and user guide (`user-guide/` Mintlify site if it exists).
5. Lead generates a resolution report and archives processed feedback.

### 8.4 Verify Output

After Stage 8 completes, verify:
- `./feedback/resolution.md` exists with a complete resolution table (all APPROVED items have a status)
- All tests pass: `npm run typecheck && npm run test && npm run test:e2e` (adapt to your package manager)
- Updated BRD/PRD cross-references still resolve (spot-check 2-3 modified spec files)
- `./feedback/archive/` contains a timestamped copy of the processed input

### 8.5 Cadence

Run this prompt on a regular schedule:
- **Weekly**: For products with high user volume or rapid iteration needs.
- **Biweekly**: For most products in active development.
- **Monthly**: For stable products in maintenance mode.

Over time, `./feedback/archive/` accumulates a full history of user-driven changes, creating an audit trail from user voice to product evolution.

---

## Stage 9: Dependency Maintenance

**Goal**: Keep dependencies updated, apply security patches, and resolve breaking changes — preventing technical debt from accumulating.

### 9.1 Execute

~~~bash
claude --dangerously-skip-permissions
~~~

Paste the contents of **`prompt_maintain_dependencies.md`**.

### 9.2 What Happens

1. Records a test baseline and runs outdated/audit checks (e.g., `npm outdated` + `npm audit`, or equivalent for your package manager).
2. **security-and-patch-updater** applies security patches and patch version updates (lowest risk).
3. **minor-version-updater** applies minor updates and resolves deprecations (medium risk).
4. **major-version-updater** applies major updates one at a time using official migration guides (high risk).
5. Updates are applied sequentially (low risk → high risk) to isolate breaking changes.
6. Full test suite is run after each batch to ensure zero regressions.
7. **Rules staleness review**: Reviews `.claude/rules/` for stale rules referencing deprecated APIs, removed packages, or outdated file paths. Prunes stale candidates from `plancasting/_rules-candidates.md`.

### 9.3 Output

`./plancasting/_maintenance/report-YYYY-MM-DD.md` with updates applied, vulnerabilities resolved, deferred updates, and test results.

### 9.4 Cadence

- **Monthly**: For products with strict security requirements.
- **Quarterly**: For most actively maintained products.
- **On trigger**: When a dependency audit reports a critical vulnerability.

**Prerequisite**: Production deployment (Stage 7) complete is recommended but not mandatory — Stage 9 can update dependencies at any point after Stage 5. However, if the product is deployed, re-run 7V after deploying updated dependencies to verify production stability. **Warning**: If Stage 9 updates a dependency that introduces breaking changes, the deployed application may break. Always review changelogs for major/minor version bumps before deploying updated dependencies to production. Stage 9 must NOT run concurrently with Stage 8.

**Important**: Do NOT run Stages 8 and 9 concurrently — both modify `package.json`, lock files, and source code, causing merge conflicts. Run one, commit, then run the other.

---

## Gate Decision Outcomes (Universal)

> **Canonical source**: This section owns all gate definitions, category systems, routing tables, and recovery procedures. CLAUDE.md § "Pipeline Execution Guide" provides a compact summary with cross-references to this section.

### Gate Terminology

- **PASS** = no issues, proceed to next stage.
- **CONDITIONAL PASS** = known issues documented but not blocking — proceed to next stage. Each stage defines its own CONDITIONAL PASS conditions (see per-stage tables below).
- **FAIL** = blocking issues, must fix before proceeding.
- **WARN** (7D only) = documentation quality issues, proceed but address later.
- **READY / NOT READY** (6H only) = binary pre-launch gate.

### Category Systems

⚠️ **CRITICAL**: A, B, and C mean **DIFFERENT THINGS** in different stages. A "Category C" in 5B (size-based: ≥100 lines of incomplete code) is completely unrelated to a "6V-C" in 6V/6R (fixability-based: requires human judgment). **Always use the stage prefix** (5B-A, 6V-A, 6P-O, etc.) in reports and cross-stage references to prevent misinterpretation.

Four distinct classification systems are used across the pipeline (6V and 6R share the same system). Use the stage prefix in reports to avoid ambiguity.

| Stage | System | Labels | Classifies | Prefix in reports |
|---|---|---|---|---|
| 5B | Size-based | A, B, C | Lines of incomplete code per file | 5B-A, 5B-B, 5B-C (recommended for cross-stage references) |
| 6V/6R | Fixability | A, B, C | Whether agent can auto-fix | 6V-A, 6V-B, 6V-C |
| 6P | Defect type | O, E, D | Visual issue type | 6P-O, 6P-E, 6P-D |
| 6P-R | Severity | Critical, Major, Minor | Design review issue severity | 6PR-Critical, 6PR-Major, 6PR-Minor |

**5B categories** (size-based, non-blank non-comment lines): A (<30 lines per file), B (30–100 lines per file AND <150 lines total across all Category B files combined; if the combined total of all Category B files exceeds 150 lines, they collectively escalate to Category C), C (≥100 lines in any single file OR ≥150 lines total across all affected files / unbuilt features).

**6V/6R categories** (fixability-based):
- **A** (auto-fixable): broken links, dead code, incorrect imports — 6R fixes automatically
- **B** (semi-auto): stub components, missing loading states — 6R fixes with effort. Fixable by: adding component logic + local state, wiring existing hooks to components, adding inline handlers. NOT fixable (escalate to C) if it requires: restructuring state management, creating new hooks, changing API contracts, or modifying database schema.
- **C** (human judgment): architectural issues, design decisions — 6R documents for human review, does NOT attempt to fix

**6V/6R category boundary rules**: A single component can have mixed categories (e.g., a typo = A + missing loading state = B); categorize the component by its LEAST FIXABLE issue (A = least severe/auto-fixable, B = moderate/semi-auto, C = most severe/human-judgment). If fixing a B issue requires refactoring another file, it remains B. If it requires architectural changes (e.g., changing state management pattern), escalate to C.

**6P categories** (visual defect type):
- **O** (objective defects): contrast failures, layout overflow, broken images — agent MUST fix
- **E** (enhancements): missing hover states, flat typography, inconsistent spacing — apply & verify
- **D** (design elevation): font pairing, color palette, motion concepts, hero composition — document for human review

### Gate Outcomes by Stage

> **Note**: Stages 0, 2, and 4 rely on human review checkpoints — no formal PASS/FAIL gate. Stage 1 has a lightweight gate (PASS/CONDITIONAL PASS/FAIL based on file completeness and assumption volume — see `prompt_generate_brd.md` § Gate Decision). Stage 5 has an implicit completion gate: ALL features must show `✅ Done` in `_progress.md`, `_implementation-report.md` must be generated, and all tests must pass (`npm run test`, `npm run typecheck`, and `npm run lint` (adapt to your package manager)). Stage 5 does NOT declare PASS/FAIL; the independent quality audit is performed by Stage 5B.

**Stage 2B**: PASS / CONDITIONAL PASS / FAIL — coverage-based with P0 coverage as binding constraint. PASS requires 0 CRITICAL, 0 HIGH, ≥95% overall coverage. CONDITIONAL PASS allows ≤3 HIGH (no P0-blockers), ≥90% overall coverage — also possible when BRD assumption volume ≥30% but operator has confirmed review. FAIL if any unresolved CRITICAL, P0 coverage <95%, overall coverage <90%, or BRD assumption volume ≥30% not operator-reviewed. Full decision tree with 8 rules in `prompt_validate_specs.md`.

**Stage 3**: PASS (≥95% scaffold coverage + CLAUDE.md Part 2 populated + `_progress.md` lists all features + `.claude/rules/` generated from templates), CONDITIONAL PASS (≥80% scaffold coverage; CLAUDE.md Part 2 and `_progress.md` still required, but rules may be incomplete), FAIL (<80% OR CLAUDE.md Part 2 not populated OR `_progress.md` missing) — thresholds defined in the Stage 3 prompt (`prompt_generate_scaffolding.md`). If CONDITIONAL PASS: review `_scaffold-manifest.md` for coverage gaps and add missing scaffold files manually, or note them for Stage 5 to create. Incomplete rules will be supplemented by Stage 5B empirical rules.

**Stage 5B gate** (4 outcomes — gate decision is evaluated in priority order: PASS first, then CONDITIONAL PASS, then FAIL-RETRY, then FAIL-ESCALATE; the first matching outcome applies):

| 5B Result | Category C Count | Category A/B Count | Next Step |
|---|---|---|---|
| PASS | 0 | 0 | → Stage 6 (all audits). Requires: zero remaining issues AND all tests pass (no regressions from 5B fixes). |
| CONDITIONAL PASS | ≤3 (each with workaround) | ≤3 (each documented with workaround) | → Stage 6 (known issues tracked in report). All tests must pass. Three paths evaluated in order (a → b → c; first match wins): (a) 0 A/B + 1–3 C, all with workaround, (b) 1–3 A/B documented with workaround + 0 C, (c) A/B ≥1 AND C ≥1 with A/B ≤3 AND C ≤3 AND total (A/B + C) ≤5, ALL issues (both A/B and C) must have documented workarounds |
| FAIL-RETRY | 4–5 (without workaround) | OR 4+ A/B unfixed (without workaround), OR total unfixed 4–5, OR test failures from 5B fixes | Re-run 5B only (max 3 total 5B runs: Run 1 = initial, Run 2–3 = re-runs; Run 4+ auto-escalates all remaining issues to FAIL-ESCALATE). Applies only to issues WITHOUT documented workarounds — issues with workarounds are evaluated under CONDITIONAL PASS first (priority order). |
| FAIL-ESCALATE | 6+ (without workaround) | OR 6+ total unfixed issues (without workaround) globally (across all features and categories) | Set `🔄` on affected features in `_progress.md`, re-run Stage 5, then re-run 5B |

Note: CONDITIONAL PASS requires ALL listed issues to have documented workarounds. Issues without workarounds are evaluated under FAIL-RETRY/FAIL-ESCALATE. **Priority-order evaluation**: CONDITIONAL PASS is evaluated first. Issues WITH documented workarounds are counted under CONDITIONAL PASS; issues WITHOUT workarounds are counted under FAIL-RETRY/FAIL-ESCALATE. The same total count can yield different outcomes depending on workaround coverage.

**Threshold logic**: CONDITIONAL PASS has three valid paths evaluated in order (a → b → c; first match wins) — ALL require every listed issue to have a documented workaround: (a) 0 A/B + 1–3 Category C all with workaround, (b) 1–3 A/B documented with workaround + 0 C, (c) A/B ≥1 AND C ≥1 with A/B ≤3 AND C ≤3 AND total (A/B + C) ≤5, all issues (both A/B and C) with workaround. "Workaround" means a documented code workaround, user-facing alternative, or accepted limitation with mitigation — not merely acknowledging the issue exists. 4–5 Category C issues indicate systemic gaps that workarounds alone cannot address → FAIL-RETRY. 6+ Category C issues indicate fundamental implementation gaps → FAIL-ESCALATE. Additionally, 3 consecutive FAIL-RETRY outcomes for the same feature automatically escalate that feature to FAIL-ESCALATE regardless of issue counts. Per-feature escalation is independent of the global thresholds (6+ Category C, 6+ total unfixed) — a feature can escalate via consecutive FAIL-RETRY even when global counts are below FAIL-ESCALATE thresholds, and conversely, global thresholds can trigger FAIL-ESCALATE even when no single feature has 3 consecutive FAIL-RETRY runs.

**"Consecutive" definition**: "Consecutive" is tracked **per-feature**, not globally. If Feature A reports FAIL-RETRY 3 times across 3 separate 5B runs (even if other features pass or fail in between), Feature A escalates to FAIL-ESCALATE. Other features' run counts are independent.

**Run counter tracking**: 5B generates a fresh report each run. To track per-feature consecutive FAIL-RETRY counts, the lead appends a `## Run History` section at the bottom of each 5B report showing: `| FEAT-ID | Run N outcome | Run N-1 outcome | Run N-2 outcome |`. The lead reads the previous report's Run History before overwriting. To determine escalation: for each feature still in FAIL-RETRY, count how many consecutive 5B runs returned FAIL-RETRY for that specific feature. If 3, escalate that feature to FAIL-ESCALATE.

**Run counter reset**: A Stage 5 re-run (triggered by FAIL-ESCALATE) resets the global 5B run counter to 0 — the subsequent 5B run counts as Run 1 of a new cycle. Per-feature consecutive FAIL-RETRY counters also reset to 0 for features that were re-implemented in the Stage 5 re-run (features not re-implemented retain their prior counter).

**6H gate** (binary — no CONDITIONAL PASS):

| 6H Result | Condition | Next Step |
|---|---|---|
| READY | All preceding audits (5B, 6A through 6G) PASS or CONDITIONAL PASS; environment variables configured; no launch-blocking violations. Note: 6H is a static pre-deployment gate that runs BEFORE 6V — it confirms the project is deployable in principle. 6V then tests runtime behavior against a running application. | → Stage 6V (Verification) |
| NOT READY | Unfixed blockers remain (missing credentials, critical errors, broken builds) | Fix blockers, re-run 6H. If the blocker originates from a preceding stage's CONDITIONAL PASS (e.g., unresolved 6A condition), fix the underlying issue and re-run both the preceding stage and 6H. |

6H is the only stage using READY/NOT READY because it is a pre-launch gate: the product is either deployable or it is not.

**CONDITIONAL PASS cascading**: If any Stage 6[A–G] shows CONDITIONAL PASS, the 6H lead must evaluate each condition: (a) documented workarounds that don't block core functionality → proceed as READY, list under "Non-Critical Issues"; (b) unresolved blockers awaiting human decision → NOT READY unless operator explicitly accepts risk. **Operator override**: If 6H returns NOT READY but the operator decides to launch despite blockers, document the override in the readiness report with: reason, accepted blockers, risk assessment, and mitigation plan.

**6V gate system**: The 6V gate uses a dual system: (1) percentage-based pass rate determines the gate outcome (PASS: ≥90%, CONDITIONAL PASS: ≥80% and <90%, FAIL: <80% acceptance criteria pass rate), and (2) fixability-based categories (A = auto-fixable, B = moderate, C = human-judgment) determine post-gate routing (6R vs. skip). The pass rate is the sole gate determinant; categories affect routing only. Use `6V-` prefix in reports (e.g., "6V-A") to distinguish from 5B categories. Components with mixed categories are classified by most severe issue — if fixing a B issue requires architectural changes (e.g., changing state management pattern), escalate to C. All acceptance criteria count in the pass-rate denominator regardless of issue category (6V-A/B/C).

#### Post-6V Routing

| 6V Result | Next Step |
|---|---|
| PASS | Skip 6R → 6P or 6P-R |
| CONDITIONAL PASS (A/B issues) | → 6R → 6P or 6P-R |
| CONDITIONAL PASS (only 6V-C) | Skip 6R → 6P or 6P-R |
| FAIL | Fix manually, re-run 6V |

**6V flaky scenario handling**: A **flaky scenario** is a test that fails on the first run but passes on a subsequent re-run without code changes, typically caused by timing issues or external service latency. For both 6V and 7V: The verification agent automatically re-runs each failing scenario once before classifying it as a failure. If it passes on re-run, mark as flaky. **6V treatment**: flaky scenarios are excluded from both the pass-rate numerator and denominator (e.g., 18 pass + 1 fail + 1 flaky = 18/19 = 94.7%, not 18/20). Flaky scenarios do not block the 6V gate but must be documented for investigation. **Flaky threshold**: if more than 10% of total scenarios are flaky, the 6V gate returns CONDITIONAL PASS at best (not PASS), regardless of the adjusted pass rate, and all flaky scenarios must be investigated before proceeding to 6R. **7V treatment**: flaky = FAIL. Production flakiness is unacceptable — a flaky scenario in 7V counts as a failure in the pass-rate denominator (e.g., 13 pass + 1 flaky + 1 fail = 13/15 = FAIL). The entire 7V gate becomes FAIL if any scenario is flaky.

#### Post-6R Routing

> **When to use this table**: Use Post-6R Routing only if 6R actually ran (i.e., 6V returned CONDITIONAL PASS with A/B issues). If 6V returned PASS or CONDITIONAL PASS with only 6V-C issues, 6R was skipped — refer to Post-6V Routing above instead.

| 6R Result | Next Step |
|---|---|
| PASS | → 6P or 6P-R |
| CONDITIONAL PASS | Human reviews, then 6P or 6P-R |
| FAIL | Fix unresolved 6V-A/B issues manually, re-run 6V, then 6R if needed. **Cycle limits**: max 3 internal fix-verify cycles per 6R run (counter resets only after a full 6V re-run — re-pasting the 6R prompt without 6V does NOT reset it). **Max 2 outer 6V→6R cycles** — an outer cycle = one full 6V run followed by one 6R run. Cycle 1: 6V → 6R. Cycle 2: 6V → 6R. After Cycle 2 completes, document remaining issues as known limitations and proceed to 6P/6P-R. Track outer cycle count by noting "Outer Cycle: 1/2" or "2/2" in 6R report headers. |

**Note**: After 3 internal fix-verify cycles within a single 6R run, any remaining 6V-A/B issues are reclassified as 6V-C (requires human judgment). This prevents infinite automated fix attempts on issues that resist auto-remediation.

**Post-6P / 6P-R routing**:

| Result | Next Step |
|---|---|
| 6P PASS | Stage 7 → 7V → 7D |
| 6P CONDITIONAL PASS | Stage 7 → 7V → 7D (review Category D design brief separately) |
| 6P FAIL | Fix, or revert (commit 6P work: `git add src/ plancasting/_audits/visual-polish/ && git commit -m "chore(6p): Stage 6P visual polish changes"`, then `git revert <6P-commit>` — safer than `git checkout -- src/`), re-run 6P |
| 6P-R PASS | Merge branch to main, Stage 7 → 7V → 7D (re-run 7D) |
| 6P-R CONDITIONAL PASS | Merge branch to main, Stage 7 → 7V → 7D (re-run 7D, review remaining Minor items — address via Stage 8 Feedback Loop or manual fixes post-deploy) |
| 6P-R FAIL | Fix or revert, re-run 6P-R |
| 6P-R Phase 2 rejected | Operator types "REJECT PHASE 2" during interactive design discovery → `git checkout main`, retry 6P-R with new direction or switch to 6P. Delete the `redesign/frontend-elevation` branch if not needed: `git branch -d redesign/frontend-elevation` (use `-D` if `-d` refuses). |

**6P vs 6P-R** — mutually exclusive, run exactly one per pipeline execution. **Default**: 6P (faster, lower risk). Use 6P-R only if the operator explicitly requests a design overhaul or the product has zero design identity.

| Scenario | Use |
|---|---|
| Contrast fixes, hover states, spacing consistency | 6P — 20–40 min |
| Distinctive visual identity / rebranding / design system | 6P-R — 2–4 hrs (interactive) |
| Colors/borders/typography adjustments | 6P — 20–40 min |
| Font families, color palette, or generic look | 6P-R — 2–4 hrs (interactive) |
| Generic AI-generated aesthetic (needs distinctive identity) | 6P-R — 2–4 hrs (interactive) |

**Design system ownership / switching from 6P to 6P-R**: If the operator initially chose 6P but later decides a full redesign is needed:
1. Commit all current work including 6P changes: `git add src/ plancasting/_audits/visual-polish/ && git commit -m "chore(6p): Stage 6P visual polish changes"`
2. Revert the 6P commit: `git revert <6P-commit-hash>` (creates a new commit reversing 6P — safer than `git checkout -- src/` which discards ALL uncommitted `src/` changes)
3. Start a new session and run 6P-R

If 6P-R runs, it defines the design system; any prior 6P modifications must be reverted first to avoid stale token references. The `git revert` approach is preferred because it is reversible and preserves full git history.

**7V gate** (3-outcome): PASS or CONDITIONAL PASS before 7D. PASS = all critical flows work, all pages load, no console errors. CONDITIONAL PASS = all P0 critical flows pass but minor P1/P2 issues exist (documented for post-launch fix via Stage 8). FAIL = any critical flow broken or critical navigation failure. Production flakiness is unacceptable — a flaky scenario in 7V counts as a FAIL (see "6V flaky scenario handling" above for the precise calculation). FAIL → if issue is localized (1–2 files, <100 LOC): hotfix, re-deploy, re-run 7V. If issue affects multiple systems or requires architectural changes: rollback the deployment using your hosting provider's rollback feature (e.g., `vercel rollback`), verify the reverted deploy is stable, then investigate offline. If the code itself needs reverting: `git revert HEAD`, then re-deploy.

**7D gate**: Prerequisite: 7V PASS or CONDITIONAL PASS. PASS/WARN/FAIL before Stage 8. WARN replaces CONDITIONAL PASS for this stage (documentation quality issues that don't block launch). Skip 7D entirely if `tech-stack.md` Documentation section indicates user documentation is not needed.

**6A–6G audit gates** (standard 3-outcome): Each audit stage (6A Security, 6B Accessibility, 6C Performance, 6D Documentation, 6E Refactoring, 6F Seed Data, 6G Resilience) uses PASS / CONDITIONAL PASS / FAIL with stage-specific criteria defined in each prompt's `## Gate Decision` section. 6H aggregates all audit gates — if any shows FAIL, 6H cannot reach READY. **Recovery for any 6A–6G FAIL**: fix the issues identified in the stage's report, then re-run that stage in a new session (all 6A–6G stages are idempotent). If the issue requires changes to code that a different stage also modified, re-run both stages.

**Stage 8 gate**: PASS / CONDITIONAL PASS / FAIL. PASS = all approved feedback items resolved, tests pass. CONDITIONAL PASS = some items deferred due to complexity, resolved items pass. FAIL = test suite fails or spec inconsistency detected. PASS/CONDITIONAL PASS → deploy via Stage 7 → 7V. **FAIL recovery**: diagnose whether the failure is a test regression (fix the test or the code that broke it) or a spec inconsistency (review the updated BRD/PRD for contradictions, fix, then re-run Stage 8). **Note on user guide**: Stage 8's test-and-docs-updater makes incremental edits to `user-guide/` MDX files during feedback resolution. These edits are preferred over re-running 7D (which deletes and recreates the entire `user-guide/` directory). Re-run 7D only if Stage 8 significantly restructures user-facing features or navigation. See `prompt_feedback_loop.md` for full criteria.

**Stage 9 gate**: PASS / CONDITIONAL PASS / FAIL. PASS = all tests pass post-update, no new vulnerabilities. CONDITIONAL PASS = tests pass but some major updates deferred. FAIL = tests fail or critical vulnerabilities remain. PASS → merge and deploy via Stage 7 → 7V. **FAIL recovery**: revert the failing dependency update (`git revert <commit>` for the specific update batch), investigate the breaking change using the dependency's migration guide, then re-run Stage 9. If a critical vulnerability cannot be patched without a breaking major update, document the vulnerability and mitigation in the maintenance report and escalate to the operator. See `prompt_maintain_dependencies.md` for full criteria.

### Stage Skip Logic

Some stages can be skipped based on upstream gate results:

| Upstream Stage | Gate Result | Skip? | Reason |
|---|---|---|---|
| 6V | PASS (0 actionable failures) | Skip 6R | No failures to remediate |
| 6V | CONDITIONAL PASS (A/B issues) | Run 6R | Auto-fixable issues need remediation |
| 6V | CONDITIONAL PASS (6V-C only) | Skip 6R | 6R cannot fix human-judgment issues |
| 6V | FAIL | N/A — 6R not reached | Manual fixes required first, then re-run 6V |
| 6R | Not run (6V was PASS or C-only) | 6P/6P-R still runs | 6P/6P-R falls back to 6V report if no 6R report exists |
| 6D | `tech-stack.md` § Documentation has `developer-docs-needed: false`, or non-software product | Skip 6D | No developer documentation required |
| 6F | No database / no seed data applicable (per tech-stack.md) | Skip 6F | No data to seed |
| 7D | `not needed: true` in tech-stack.md | Skip 7D | No user guide required; proceed to Stage 8 |
| 5B | (any) | **Never skip** | Catches #1 cause of Stage 6 failures — frontend stubs and duplication |
| 6V | (any) | **Never skip** | Only stage that launches the app — catches all runtime-only failures |
| 6P or 6P-R | (any) | **Never skip** (run exactly one) | Visual quality gate before deployment |
| 7V | (any) | **Never skip** | Catches production-environment-specific failures |

**Note**: Stage 7V always runs SMOKE scope (max 15 scenarios, P0+P1 features only). 6V modes (full/critical/diff) do not apply to 7V. Both 6V and 7V read `./plancasting/transmute-framework/feature_scenario_generation.md` for scenario types and generation algorithms — ensure this file is accessible before running either stage.

---

## Path-Scoped Rules — Self-Evolving Development

The Transmute pipeline uses `.claude/rules/` to accumulate implementation knowledge that persists across sessions. Claude Code natively reads these files and applies matching rules based on `globs` frontmatter — no prompt changes needed for downstream stages to benefit.

### Rules Lifecycle

~~~
Stage 3 (Scaffold)          Stage 5B (Audit)              Stage 6R (Remediation)           Stage 9 (Maintenance)
├─ Read tech-stack.md       ├─ Scan audit findings         ├─ For each verified fix          ├─ Review all rules
├─ Read rules-templates/    ├─ Identify repeating patterns  ├─ Evaluate generalizability      ├─ Remove stale rules
├─ Generate starter rules   ├─ Classify confidence          ├─ Classify confidence            ├─ Update changed paths
│  └─ .claude/rules/*.md    ├─ HIGH → .claude/rules/        ├─ HIGH → .claude/rules/          └─ Prune old candidates
└─ Create empty             └─ MEDIUM/LOW → _rules-         └─ MEDIUM → _rules-
   _rules-candidates.md        candidates.md                    candidates.md

  [GENERATE]                   [GROW]                          [GROW]                          [PRUNE]
  theoretical                  empirical                       battle-tested                   hygiene
~~~

**Confidence levels** (pattern-based — determines auto-promote vs. staging):
- **HIGH** (auto-promoted): 2+ features (distinct FEAT-IDs from PRD) affected with clear, repeatable pattern. Two occurrences within the same feature count as 1 feature. → written directly to `.claude/rules/`
- **MEDIUM** (staged): Single feature but generalizable → added to `plancasting/_rules-candidates.md` for operator review
- **LOW** (staged): Edge case or uncertain applicability → added to `plancasting/_rules-candidates.md`

Note: CLAUDE.md § "Path-Scoped Rules" also defines a **stage-based confidence hierarchy** (Stage 3 theoretical < Stage 5B empirical < Stage 6R battle-tested). When two rules conflict, prefer the later stage's rule regardless of pattern-based confidence. The two systems are complementary: pattern-based confidence determines auto-promote vs. staging; stage-based confidence determines precedence when rules conflict.

### Quality Gate

Every rule requires structured evidence:

~~~markdown
## [Rule Title]
<!-- Source: Stage [3/5B/6R] | Evidence: [issue-ID/commit/PRD-ref] | Confidence: HIGH -->
[Concise directive — max 3 sentences]
~~~

- Stage 3 rules cite `tech-stack.md` sections or known framework documentation
- Stage 5B rules cite audit finding IDs (e.g., "Category B finding #3 in 3 features")
- Stage 6R rules cite 6V issue references (e.g., `SC-012`, `US-007`) and the fix commit hash

### Hygiene

- **Limits**: Max 15 rules per file, max 8 rule files. If exceeded, consolidate related rules.
- **Staleness review**: During Stage 9 (Dependency Maintenance), review all rules. Remove rules referencing deprecated APIs or resolved issues. Update rules with changed file paths.
- **Candidate review**: After each 5B or 6R run, the operator should review `plancasting/_rules-candidates.md` and promote, edit, or discard candidates.

### Promotion Decision Guide

When evaluating whether to promote a candidate rule:

1. Does the pattern affect 2+ distinct features (separate FEAT-IDs)? → **HIGH confidence** → promote to `.claude/rules/`
2. Single feature but generalizable to other features? → **MEDIUM confidence** → keep in `_rules-candidates.md`, promote if it recurs
3. Edge case or uncertain applicability? → **LOW confidence** → keep in `_rules-candidates.md`, discard if not observed after 2 more stages

### Stage Outputs (Rules)

| Stage | Rules Output | Trigger |
|---|---|---|
| 3 (Scaffold) | `.claude/rules/*.md` (starter rules), empty `plancasting/_rules-candidates.md` | Always (part of scaffold generation) |
| 5B (Audit) | Appends to `.claude/rules/*.md` (HIGH) or `plancasting/_rules-candidates.md` (MEDIUM/LOW) | When repeating patterns found across 2+ features |
| 6R (Remediation) | Appends to `.claude/rules/*.md` (HIGH) or `plancasting/_rules-candidates.md` (MEDIUM) | After verified 6V-A/B fixes |
| 9 (Maintenance) | Updates/removes stale rules in `.claude/rules/` | Always (part of maintenance review) |

### Rule Templates

Stage 3 uses tech-stack-agnostic templates from `plancasting/transmute-framework/rules-templates/` as the starting point. These templates contain `[BRACKETED]` placeholder markers (e.g., `[BACKEND_DIR]`, `[ERROR_TYPE]`) that Stage 3 renders with actual paths and stack-specific rules from `tech-stack.md`.

| Template | Generated Rule File | Scope |
|---|---|---|
| `_backend-template.md` | `.claude/rules/backend.md` | Backend validation, error handling, auth guards |
| `_frontend-template.md` | `.claude/rules/frontend.md` | State management, hooks, responsive behavior |
| `_api-contracts-template.md` | `.claude/rules/api-contracts.md` | Type alignment, field mapping, projections |
| `_auth-template.md` | `.claude/rules/auth.md` | Middleware, public routes, session handling |
| `_testing-template.md` | `.claude/rules/testing.md` | E2E selectors, async assertions, test isolation |
| `_data-model-template.md` | `.claude/rules/data-model.md` | Indexes, soft-delete, schema changes |

See CLAUDE.md § "Path-Scoped Rules" for the full specification (limits, format, evidence requirements).

---

## Git Commit Strategy

After each stage completes, create a git commit as a recovery point. Ensure `.gitignore` covers `.env.local`, `node_modules/`, and `bun.lockb`/`package-lock.json` (as appropriate) before using `git add -A`.

~~~bash
git add -A && git commit -m "chore: complete Stage N (description)"

# Examples:
# git commit -m "chore: complete Stage 1 (BRD generation)"
# git commit -m "chore: complete Stage 5 (feature implementation)"
# git commit -m "chore: complete Stage 6A (security audit)"
~~~

This enables recovery if a session disconnects mid-execution. See Troubleshooting section for recovery steps.

---

## Troubleshooting

### Agent Team session disconnects mid-execution

If a Claude Code session disconnects during a stage:
1. Check `./plancasting/_progress.md` (for Stage 5) or generated files to determine what was completed.
2. Start a new session with `claude --dangerously-skip-permissions`.
3. For Stages 1–3: Re-run the prompt. The lead will detect existing files and either skip or overwrite.
4. For Stage 5: The orchestrator reads `plancasting/_progress.md` at startup and resumes from the first non-completed feature.
5. For Stage 5B: Re-run the prompt. It performs a fresh scan each time and is inherently idempotent to code changes. (Note: if you edited PRD/BRD after a previous 5B run, the re-run will reflect the new spec.)
6. For Stages 6A–6P, 6P-R, 7V, 7D, 9: Re-run the prompt. These stages are idempotent — the agent detects existing work (partial reports, generated files) and completes any remaining items. Partial changes from the interrupted session are safe to keep.
7. For Stage 8: Idempotent for the same input batch — detects existing `feedback/resolution.md` and skips already-processed items. If processing a NEW feedback batch, archive or remove the previous `feedback/resolution.md` first to avoid stale skip logic.

### Agent teammates show IDLE status

**This is normal behavior** — teammates wait for the lead to dispatch work. IDLE after every turn means "waiting for input," not "crashed." No action is needed. If a teammate stays IDLE for an extended period, check the lead's output to see if it has finished dispatching work.

### Frontend stubs remaining after Stage 5

This is a known pattern — backend is fully implemented but frontend components remain as stubs. Do NOT attempt to fix individual files manually. Instead, run Stage 5B (Implementation Completeness Audit), which systematically scans for and fixes all stub patterns. If the audit reports Category C issues (entire features still scaffold-quality), re-run Stage 5 for those specific features, then re-run Stage 5B.

### Orphan components / duplicate UI after Stage 5

This is a different pattern from stubs. Stage 5's frontend teammate builds UI inline in page files instead of using the scaffold component files from Stage 3. The result: component files in `src/components/features/` that are never imported (orphans), and page files with 200+ lines of inline UI that should be decomposed into those components.

**Root cause**: The frontend teammate didn't check what scaffold files already existed before writing code. This is addressed by the mandatory SCAFFOLD INVENTORY step (Step 0) in the Stage 5 prompt, and the scaffold manifest (`plancasting/_scaffold-manifest.md`) generated by Stage 3.

**Fix**: Run Stage 5B, which now detects both stub AND duplication patterns. The frontend-stub-fixer teammate will move inline page UI into the scaffold components and update pages to compose them. If the project was built without the scaffold manifest, Stage 5B's automated scan (step 9: duplication suspect detection) will still catch pages with many hook imports but zero component imports.

### Type errors after scaffold generation

Some type errors are expected after Stage 3 because the scaffold generates interconnected code. These are resolved during Stage 5 as features are implemented. If errors prevent the dev server from running:
1. Start a Claude Code session.
2. Ask: "Read CLAUDE.md and plancasting/tech-stack.md, then fix all TypeScript errors in the project so that the dev server and type checker pass."

### Feature implementation produces regressions

The orchestrator runs full regression tests at each quality gate. If it cannot resolve a regression:
1. Check `./plancasting/_briefs/` for the feature that caused the regression.
2. Start a new Claude Code session.
3. Provide the regression details and ask for a targeted fix.

### Backend deployment errors

If backend deployment fails (e.g., `npx convex deploy`, database migration, etc.):
1. Check your schema/migration files for validation errors.
2. Run the dev server locally to see detailed error messages.
3. Refer to your backend provider's documentation (linked in `plancasting/tech-stack.md`).

### Stack-Specific Troubleshooting

The entries below address issues specific to particular technology stacks (Tailwind v4, Next.js, Mintlify, etc.). Skip sections that do not apply to your stack.

#### UI looks unstyled / no custom colors or fonts (Tailwind v4 config not loaded)

If the app renders but looks like unstyled HTML — no custom colors, no custom fonts, buttons have no fills, everything is flat and generic despite having a fully defined `tailwind.config.ts` with custom theme extensions:

**Root cause**: Tailwind CSS v4 changed its configuration model. Unlike v3, the JS config file (`tailwind.config.ts`) is **NOT automatically loaded**. You must explicitly reference it with `@config` in your CSS file. Without this, all `theme.extend` entries (colors, fonts, spacing, animations, shadows) are silently ignored — no error, no warning. CSS custom properties in `:root` still work (e.g., `body { background: var(--color-bg) }`) but all Tailwind utility classes like `bg-primary-500`, `font-display`, `text-text-heading` produce zero CSS output.

**Fix**: Add `@config` directive to your global CSS file immediately after the Tailwind import:
~~~css
@import "tailwindcss";
@config "../../tailwind.config.ts";
/* path is relative from the CSS file to tailwind.config.ts */
~~~

**How to detect**: If your site has a dark background (from raw CSS variables) but no styled buttons, no custom fonts, and no colored accents — this is almost certainly the cause.

#### Borders appear white / semantic utility classes produce no color (Tailwind v4 color lookup)

If custom borders render as white (browser default) despite `border-border` being used, or `ring-ring` / `bg-card` produce no visible color:

**Root cause**: In Tailwind v4, `border-border` looks up a color named `border` in the `colors` palette — NOT in `borderColor.DEFAULT`. This is a v3 → v4 behavior change. In v3, `borderColor.DEFAULT` was enough. In v4, all color utilities (`bg-*`, `text-*`, `border-*`, `ring-*`) resolve from the single `colors` object.

**Fix**: Add semantic token entries directly to `theme.extend.colors` in `tailwind.config.ts`:
~~~typescript
colors: {
  border: "var(--color-border)",
  ring: "var(--color-ring)",
  card: "var(--color-bg-card)",
  background: "var(--color-bg)",
  foreground: "var(--color-text-primary)",
  // ... rest of your color palette
},
~~~

**How to detect**: If card borders, input borders, and button outlines all appear as bright white on a dark background, while the `borderColor.DEFAULT` config is correctly set — this is the cause.

#### Frontend deployment shows blank page (CSP blocking scripts)

If the deployed site shows a blank white page and the browser console shows `Refused to load the script ... because it does not appear in the script-src directive of the Content Security Policy`:

**Root cause**: `'strict-dynamic'` in the CSP `script-src` directive causes browsers to **ignore** both `'self'` and `'unsafe-inline'`, blocking all Next.js chunk loading.

**Fix**: Remove `'strict-dynamic'` from `script-src` in `next.config.ts` unless nonce-based CSP is implemented. Use: `script-src 'self' 'unsafe-inline' [trusted-domains]`.

#### Frontend deployment shows SSR 500 error (i18n config not found)

If the deployed site shows "Application error: a server-side exception has occurred" and server logs show errors like "Couldn't find next-intl config" or similar i18n config resolution failures:

**Root cause**: i18n plugins (next-intl, next-international, etc.) set `experimental.turbo.resolveAlias` which Next.js 15+/16 ignores. The plugin's bundled `config.js` is a placeholder that throws — it expects to be aliased to your actual config file. This works locally with webpack but fails with Turbopack (default in Next.js 16).

**Fix**: Add manual aliases in `next.config.ts` for both bundlers:
~~~typescript
turbopack: {
  resolveAlias: {
    "next-intl/config": "./src/i18n/request.ts",  // relative path (Turbopack requirement)
  },
},
webpack(config) {
  config.resolve.alias["next-intl/config"] = path.resolve(process.cwd(), "./src/i18n/request.ts");
  return config;
},
~~~

#### Deployed app has missing features or auth failures (missing env vars)

If the deployed app partially works but specific features fail (auth, payments, email, analytics, AI):

**Root cause**: `.env.local` is NOT automatically synced to hosting providers (Vercel, Netlify, etc.). Each environment variable must be explicitly configured on the platform.

**Common miss**: `NEXT_PUBLIC_CONVEX_URL` (or equivalent BaaS URL) — this is often auto-injected by the dev server at `localhost` but never saved to `.env.local`, so it's easy to forget when configuring the hosting provider.

**Fix**:
~~~bash
# List all env vars on Vercel
npx vercel env ls

# Cross-check against .env.local.example
# Add any missing variables
echo "value" | npx vercel env add VARIABLE_NAME production

# Re-deploy after adding variables
npx vercel --prod
~~~

#### Stage 6V: Dev server won't start

The most common failure mode for Stage 6V. The stage cannot proceed without a running app.

**Symptoms**: Server process exits immediately, port already in use, build errors during startup.

**Solutions**:
- Port conflict: kill the existing process with `lsof -ti:3000 | xargs kill` (or your port)
- Missing env vars: compare `.env.local` against `.env.local.example` — the dev server may crash silently on missing config
- Build error: run `npm run build` (or equivalent) separately to see the full error output
- If the server starts but pages are blank: check browser console for hydration errors or missing `NEXT_PUBLIC_*` variables

#### Stage 6V: Auth redirect loop during verification

**Symptoms**: Teammate navigates to a protected page, gets redirected to login, login redirects back — infinite loop.

**Solutions**:
- Check that test user credentials in `e2e/constants.ts` are still valid
- Check that the auth provider's allowed redirect URLs include the dev server URL
- Check that the auth cookie/token is being set correctly (inspect browser storage)
- If using session-based auth, verify the session endpoint returns a valid token

#### Stage 5/6V: OAuth sign-in fails silently or redirects to error page

**Symptoms**: User clicks "Continue with Google/GitHub", gets redirected to auth provider error page ("Something went wrong") or returns to callback page with "Authentication failed" error.

**Diagnostic steps** (in order):
1. Check the full error URL in the browser — auth providers encode `error` and `error_description` in query parameters
2. Check backend/serverless function logs for the actual HTTP status code and error body from the auth provider's token exchange endpoint
3. Verify credentials match: compare `client_id` and API key in your environment against the auth provider dashboard (character-by-character — `Q` vs `0`, `l` vs `1` are common typos)
4. Verify the authorize URL includes ALL required parameters — `response_type=code` is commonly omitted
5. Verify the token exchange uses the correct authentication method (body vs header) per the provider's API docs
6. Check for intermediate auth states (email verification, MFA) that require user interaction before the token is issued

**Solutions**:
- Use the auth provider's API reference documentation (not cached knowledge) to verify the exact parameter format for authorize and token exchange endpoints
- Add error response logging to the token exchange code — never throw generic "auth failed" without logging the provider's actual error body
- Test the authorize URL with `curl -D - -o /dev/null "<authorize_url>"` — a 302 to the identity provider means success; a 302 to an error page means the request is malformed

#### Stage 7V: Pages load blank in production but work in dev

**Symptoms**: All pages return HTTP 200 but render blank white screen. Dev server works fine.

**Solutions**:
- Missing `NEXT_PUBLIC_*` env vars on hosting platform (most common cause)
- CSP `script-src` blocks Next.js chunks — check response headers for `Content-Security-Policy`
- Tailwind CSS purge removed dynamic classes — check if the site renders unstyled
- Compare `vercel env ls` (or equivalent) against `.env.local.example` — look for any missing variable

#### Stage 7V: Auth works in dev but fails in production

**Symptoms**: Login flow fails, returns 401, or redirects incorrectly on production domain.

**Solutions**:
- Auth provider callback URL not updated for production domain
- Auth provider configured for development environment, not production
- JWT signing keys or OIDC endpoints differ between environments
- Cookie domain mismatch (set for `localhost` but not production domain)

#### Stage 7D: Mintlify build fails

**Symptoms**: `mint dev` or `mint validate` fails, docs site won't render, or build errors during deployment.

**Solutions**:
- Invalid `docs.json` syntax — validate with a JSON linter or run `mint validate`
- Node.js version too old — Mintlify CLI requires Node.js v20.17.0+ (not v18)
- Broken internal links — run `mint broken-links` from the `user-guide/` directory, or cross-reference navigation entries against actual `.mdx` files
- Missing `openapi.json` — if API Reference tab references it, the file must exist
- CLI not found — install globally with `npm i -g mint` (current package name), or use `npx mint` for one-off usage. Legacy package `@mintlify/cli` is deprecated — use `mint` instead.

#### Stage 7D: Accessibility warnings in docs

**Symptoms**: `mint a11y` reports issues. Note: these are warnings, not build failures — `mint validate` and `mint dev` will still pass.

**Solutions**:
- Missing alt text on images — add descriptive `alt` attributes to all `<img>` tags
- Low contrast text — adjust colors in docs.json or page content
- Missing heading hierarchy — ensure pages use sequential heading levels (h1 → h2 → h3)

#### Stage 7D: Screenshots show loading spinners

**Symptoms**: User guide screenshots show skeleton screens or loading states instead of content.

**Solutions**:
- Playwright `browser_wait_for` not waiting long enough — increase wait time
- Screenshots taken before data loads — add explicit data-ready assertions
- Re-run Phase 1 step 8 with longer wait times or additional `browser_wait_for` conditions

#### Non-English language causing build failures

**Symptoms**: Lint errors, build failures, or encoding issues after selecting a non-English language in Stage 0.

**Solutions**:
- Verify that code identifiers and filenames remain in ASCII/English — only documentation content and user-facing strings should be in the selected language
- Check that `.eslintrc` or linter config supports Unicode strings in JSX
- Verify i18n JSON files are saved with UTF-8 encoding

#### Stage 8: Spec-updater creates conflicting requirement IDs

**Symptoms**: New FRs or USes have IDs that collide with existing ones.

**Solutions**:
- Teammate did not read `_context.md` for existing ID ranges — verify ID allocation
- Read `./plancasting/prd/_context.md` and `./plancasting/brd/_context.md` before generating new IDs

---

## Transmute Project Structure

After completing all stages of a plan cast, your project should contain (example shown for Next.js + Convex — adapt directory names and config files to your tech stack):

~~~
~/project/
├── plancasting/                # Plan Cast artifacts (specs, audits, progress tracking)
│   ├── businessplan/           #   [Input] Business Plan (read-only input for all stages)
│   ├── tech-stack.md           #   [Stage 0] Tech stack configuration (referenced by all stages)
│   ├── brd/                    #   [Stage 1] Business Requirement Document
│   │   ├── _context.md         #     Shared conventions, feature inventory
│   │   ├── _review-log.md      #     Assumption review status (checked by Stage 2B gate)
│   │   ├── 00-cover-and-metadata.md through 22-glossary-and-appendices.md
│   │   └── README.md
│   ├── prd/                    #   [Stage 2] Product Requirement Document
│   │   ├── _context.md         #     Feature decomposition map, ID registry
│   │   ├── _review-log.md      #     PRD review log
│   │   ├── _brd-issues.md      #     (optional) BRD issues found during PRD generation
│   │   ├── 01-product-overview.md through 18-glossary-and-cross-references.md
│   │   └── README.md
│   ├── _codegen-context.md     #   [Stage 3] Code generation map
│   ├── _scaffold-manifest.md   #   [Stage 3] Component→Page mapping (handoff to Stage 5)
│   ├── _progress.md            #   [Stage 3+5] Feature progress tracker
│   ├── _rules-candidates.md    #   [Stage 3] Rule candidates staging (populated by 5B/6R)
│   ├── _briefs/                #   [Stage 5] Feature implementation briefs
│   ├── _implementation-report.md #  [Stage 5] Preliminary implementation self-assessment
│   ├── _audits/                #   [Stage 2B, 5B, 6, 7V, 7D] Audit reports
│   │   ├── spec-validation/    #     BRD ↔ PRD cross-validation report
│   │   ├── implementation-completeness/ # [Stage 5B] Stub scan + fix report
│   │   ├── security/           #     Security audit checklist + report
│   │   ├── accessibility/      #     Accessibility audit checklist + report
│   │   ├── performance/        #     Performance targets + report + Lighthouse results
│   │   ├── refactoring/        #     Refactoring baseline, plan, and report
│   │   ├── seed-data/          #     [Stage 6F] Seed data generation report
│   │   ├── resilience/         #     Resilience hardening plan and report
│   │   ├── documentation/      #     [Stage 6D] Documentation generation report
│   │   ├── visual-verification/ #    [Stage 6V] Visual & functional verification report + screenshots
│   │   ├── runtime-remediation/ #    [Stage 6R] Remediation plan, report, and fix logs
│   │   ├── visual-polish/      #     [Stage 6P] Visual polish plan, report, and design elevation brief
│   │   ├── production-smoke/   #     [Stage 7V] Production smoke verification report
│   │   └── user-guide/         #     [Stage 7D] User guide generation audit report
│   ├── _launch/                #   [Stage 6H] Pre-launch verification
│   │   ├── checklist.md        #     Master pre-launch checklist
│   │   └── readiness-report.md #     Final READY/NOT READY decision
│   ├── _maintenance/           #   [Stage 9] Dependency maintenance reports
│   │   └── report-YYYY-MM-DD.md #    Per-run maintenance report
│   ├── _guide-context.md       #   [Stage 7D] User guide content map
│   └── transmute-framework/    #   Prompt files and execution guide
│       └── feature_scenario_generation.md #  [Pre-6V] Shared test scenario algorithm (must be copied here)
├── .env.local               # [Stage 0] Credentials (NEVER commit to git)
├── .env.local.example       # [Stage 0] Credential template for other developers
├── convex/                  # [Stage 3+5] Backend (adapt directory structure to your stack per `plancasting/tech-stack.md`)
│   ├── _generated/          #   Auto-generated (DO NOT EDIT)
│   ├── _internal/           #   Internal functions
│   ├── __tests__/           #   Backend tests
│   ├── schema.ts            #   Complete database schema
│   ├── crons.ts             #   Cron jobs
│   ├── http.ts              #   Webhook endpoints
│   ├── featureFlags.ts      #   Feature flag system
│   └── <domain>.ts          #   Domain-specific functions
├── src/                     # [Stage 3+5] Frontend (adapt directory structure to your stack per `plancasting/tech-stack.md`)
│   ├── app/                 #   Pages and routing
│   ├── components/          #   UI components (by feature)
│   ├── hooks/               #   Custom hooks (backend wrappers)
│   ├── lib/                 #   Utilities, types, constants
│   └── __tests__/           #   Frontend tests
├── e2e/                     # [Stage 3+5] Playwright E2E tests
│   ├── integration/         #   Cross-feature tests
│   ├── verification/        #   [Stage 6V] Generated visual & functional verification tests
│   ├── accessibility.spec.ts #  [Stage 6B] axe-core automated tests
│   └── <feature>.spec.ts    #   Per-feature tests
├── screenshots/             # [Stage 6V, 6P, 7V] Verification screenshots
│   ├── automated/           #   Page-level verification screenshots
│   ├── criteria/            #   Acceptance criteria verification screenshots
│   ├── vision/              #   AI vision review screenshots (multi-breakpoint)
│   ├── visual-polish/       #   [Stage 6P] Before/after comparison screenshots
│   │   ├── before/          #     Pre-polish state
│   │   └── after/           #     Post-polish state
│   └── production/          #   Production smoke verification screenshots
├── docs/                    # [Stage 6D] Generated internal documentation
│   ├── help/                #   Product help docs (internal — NOT the Stage 7D Mintlify site)
│   ├── api/                 #   Backend function API reference
│   ├── developer/           #   Developer onboarding guide
│   │   └── conventions.md   #   Coding conventions and project guidelines
│   ├── architecture/        #   System architecture documentation
│   └── changelog.md         #   Product changelog
├── seed/                    # [Stage 6F] Seed data scripts
│   ├── README.md            #   Usage instructions and persona credentials
│   ├── index.ts             #   Master seed orchestrator
│   ├── core.ts              #   Users, orgs, roles
│   ├── features.ts          #   Feature-specific data
│   ├── edge-cases.ts        #   Edge case records
│   ├── stress.ts            #   High-volume performance data
│   ├── empty-state.ts       #   Empty state verification data
│   └── reset.ts             #   Data reset function
├── user-guide/              # [Stage 7D] Mintlify user documentation site
│   ├── docs.json            #   Root Mintlify configuration (branding + navigation for English-only; branding + languages array for multi-language)
│   ├── *.mdx                #   Content pages (English-only: at root level)
│   ├── en/                  #   English documentation (multi-language only)
│   ├── <lang>/              #   Session language (multi-language only)
│   ├── public/              #   Static assets (logos, favicon)
│   └── snippets/            #   Reusable MDX snippets
├── feedback/                # [Stage 8] User feedback processing
│   ├── input.md             #   Current feedback batch (you create this)
│   ├── analysis.md          #   Feedback triage and traceability
│   ├── change-plan.md       #   Ordered change plan
│   ├── resolution.md        #   Resolution report
│   └── archive/             #   Processed feedback history
├── .claude/rules/           # [Stage 3, 5B, 6R, 9] Path-scoped development rules
│   ├── backend.md           #   Backend validation, error handling, auth guards
│   ├── frontend.md          #   State management, hooks, responsive behavior
│   ├── api-contracts.md     #   Type alignment, field mapping, projections
│   ├── auth.md              #   Middleware, public routes, session handling
│   ├── testing.md           #   E2E selectors, async assertions, test isolation
│   └── data-model.md        #   Indexes, soft-delete, schema changes
├── .github/workflows/       # [Stage 3] CI/CD pipelines
├── CLAUDE.md                # [Stage 4] Project conventions
├── ARCHITECTURE.md          # [Stage 3] System architecture docs
├── package.json
├── tsconfig.json
├── next.config.ts
├── vitest.config.ts
└── playwright.config.ts
~~~

### Upgrading the Pipeline Model

When a new Claude model is released:
1. Update ONLY `plancasting/tech-stack.md` § Model Specifications
2. Adjust derived values (session feature limit, safe output budget) based on the new model's specs
3. No prompt files require changes — they read limits from tech-stack.md
4. If the new model changes the output token limit, recalculate: Safe output budget = output limit − 7,000
5. If the new model changes the context window, recalculate session feature limit empirically (run 5 features, check quality gate pass rates, extrapolate)

---

## Transmute Prompt File Reference

All prompt files are located in `./plancasting/transmute-framework/`. When the guide says "Paste the contents of `prompt_xyz.md`", the full path is `./plancasting/transmute-framework/prompt_xyz.md`.

| Prompt File | Stage | Purpose |
|---|---|---|
| `prompt_tech_stack_discovery.md` | 0 | Interactive tech stack selection + credential collection |
| `prompt_generate_brd.md` | 1 | BRD generation from Business Plan |
| `prompt_generate_prd.md` | 2 | PRD generation from BRD |
| `prompt_validate_specs.md` | 2B | BRD ↔ PRD cross-validation |
| `prompt_generate_scaffolding.md` | 3 | Development scaffold generation |
| N/A (manual CLAUDE.md verification) | 4 | Project conventions (pre-written — customize for your stack) |
| `prompt_feature_orchestrator.md` | 5 | Automated feature implementation |
| `prompt_implementation_audit.md` | 5B | Implementation completeness audit and stub fixing |
| `prompt_audit_security.md` | 6A | Security audit and fixes |
| `prompt_audit_accessibility.md` | 6B | WCAG accessibility audit and fixes |
| `prompt_optimize_performance.md` | 6C | Performance audit and optimization |
| `prompt_generate_documentation.md` | 6D | Developer, API, and architecture docs (`docs/`) |
| `prompt_refactor_code.md` | 6E | Code quality refactoring |
| `prompt_generate_seed_data.md` | 6F | Seed data for dev/test/demo environments |
| `prompt_harden_resilience.md` | 6G | Error handling and resilience hardening |
| `prompt_prelaunch_verification.md` | 6H | Pre-launch readiness verification |
| `prompt_visual_functional_verification.md` | 6V | Visual & functional verification using dynamic feature scenarios |
| `prompt_runtime_remediation.md` | 6R | Auto-fix cycle for 6V-A/B issues |
| `prompt_visual_polish.md` | 6P | Visual polish & UI refinement using frontend-design skill |
| `prompt_frontend_redesign.md` | 6P-R | Full frontend design elevation (alternative to 6P — interactive) |
| N/A (manual / CI/CD deployment) | 7 | Production deployment — see `docs/developer/deployment.md` (6D) or hosting provider docs |
| `prompt_production_smoke_verification.md` | 7V | Production deployment smoke verification |
| `prompt_generate_user_guide.md` | 7D | Mintlify user guide generation from PRD |
| `prompt_feedback_loop.md` | 8 | User feedback → spec + code updates |
| `prompt_maintain_dependencies.md` | 9 | Dependency updates and security patches |

**Supporting files** (not prompts — do NOT paste these):

| File | Used By | Purpose |
|---|---|---|
| `feature_scenario_generation.md` | 6V, 7V | Shared algorithm for extracting test scenarios from PRD — must be copied to project's `plancasting/transmute-framework/` before first 6V/7V run; referenced internally by those prompts |

---

## Tips for Successful Plan Casting

**Review between stages.** Each human review checkpoint is an opportunity to catch errors before they propagate. A wrong assumption in the BRD becomes a wrong requirement in the PRD, which becomes wrong code in the scaffold, which becomes a bug in the product.

**Resolve assumptions early.** Every `> ⚠️ ASSUMPTION:` marker is a potential source of rework. Address them at the stage they appear, not later.

**Keep the Business Plan detailed.** The more detail in your Business Plan, the fewer assumptions the AI needs to make. Sections that are vague in the Business Plan will produce requirements marked as assumptions.

**Monitor token usage.** Agent Teams consume tokens proportional to the number of teammates multiplied by the context size. For large products (20+ features), Stage 5 can be substantial. Monitor your API usage.

**Use `plancasting/_progress.md` as your dashboard.** During Stage 5, this file is your real-time view into what's been completed, what's in progress, and what's remaining.

---

## Safety Rules

These rules prevent data loss and ensure recovery is always possible:

1. **Never delete generated BRD/PRD files** — later stages depend on them being complete and consistent.
2. **Never commit `.env.local`** — it contains secrets. Only commit `.env.local.example` with placeholder values.
3. **Always commit after each stage** — creates recovery points. See Git Commit Strategy section above.
4. **Do NOT manually edit PRD/BRD requirements from Stage 5 onward** (except via Stage 8 Feedback Loop) — if a spec issue appears during implementation or later stages (6A–9), note it in the feature brief (assumptions section) and address via Stage 8. Stage 2B may fix PRD/BRD directly, but once Stage 5 begins, specs are frozen outside of Stage 8. **Exception**: typos and naming consistency errors (e.g., `userID` vs `userId`) can be fixed immediately — these are not requirement changes.
5. **Do NOT rebuild files manually after a stage completes** — the next stage detects existing work and integrates with it. Manual changes can cause conflicts.
6. **Each stage = fresh Claude Code session** — start a new `claude --dangerously-skip-permissions` session for each stage. Git commit between stages.
7. **Prompt files location** — all prompt files are in `plancasting/transmute-framework/` within the template directory. When running locally, copy-paste prompt file contents into Claude Code sessions. The `plancasting/transmute-framework/` directory does NOT need to persist inside the project directory after the pipeline completes, with two exceptions: (a) `rules-templates/` must be accessible during Stage 3 (the scaffold reads them to generate `.claude/rules/`), and (b) `feature_scenario_generation.md` must be copied before Stage 6V. If you start from the Transmute Framework Template, both are already in place.
8. **Never run seed commands against production** — seed scripts include production safety checks, but always verify the environment before running `seed:*` commands. See `seed/README.md` for environment verification.
9. **Never run Stages 8 and 9 concurrently** — both modify `package.json`, lock files, and source code. Complete one, commit all changes, then start the other. Concurrent runs create merge conflicts and inconsistent state.
10. **Never run both 6P and 6P-R in the same pipeline execution** — they are mutually exclusive. Default to 6P; use 6P-R only for full design overhaul. See § "Gate Decision Outcomes" for switching guidance.

**CRITICAL: Always run Stage 5B after Stage 5 — never skip it.** Even if Stage 5's implementation report claims 100% coverage, experience shows two critical failure patterns that only Stage 5B detects: (1) frontend stubs that slip through fatigued quality gates (the orchestrator's per-feature gates degrade as the session progresses), and (2) duplication where pages rebuild UI inline instead of using scaffold components, creating orphan files. Stage 5B runs with a fresh context window and catches both. It's a 45–90 minute investment that prevents hours of debugging in Stage 6 and beyond. ROI: prevents the #1 cause of Stage 6 failures.

**Check the scaffold manifest during Stage 5.** If Stage 3 generated `plancasting/_scaffold-manifest.md`, ensure Stage 5 teammates read it in their SCAFFOLD INVENTORY step. This single file prevents the duplication pattern by telling the frontend teammate exactly which component files exist and which pages should import them.

**Use the Feedback Loop for post-launch changes.** After deployment, resist the urge to make ad-hoc code changes. Instead, collect feedback, run the Feedback Loop prompt (Stage 8), and let it update specs → code → tests → docs in one consistent pass. This keeps your living documents accurate.

---

<!-- SYNC NOTE: Gate definitions are canonical in execution-guide.md § "Gate Decision Outcomes".
     CLAUDE.md § "Pipeline Execution Guide" provides a compact summary with cross-references here.
     Path-scoped rules lifecycle is canonical in execution-guide.md § "Path-Scoped Rules".
     CLAUDE.md § "Path-Scoped Rules" provides the specification (limits, format, evidence). -->
