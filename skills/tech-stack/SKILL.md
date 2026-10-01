---
name: tech-stack
description: >-
  Interactively discovers and configures the technology stack for a new product from a business plan.
  This skill should be used when the user asks to "discover tech stack",
  "configure technology stack", "select technologies", "run Stage 0",
  "start tech stack discovery", "define the stack", or "set up the project stack",
  or when the transmute-pipeline agent reaches Stage 0 of the pipeline.
metadata:
  version: 1.0.0
effort: medium
---

# Transmute — Tech Stack Discovery & Configuration (Stage 0)

Read the detailed guide at `${CLAUDE_SKILL_DIR}/references/tech-stack-detailed-guide.md` for the complete procedure, technology category tables, credential checklists, product type adaptation rules, and supported product types.

## Prerequisites

Before starting, verify:
1. `./plancasting/businessplan/` directory exists and contains `.md` or `.pdf` files. Supported formats: markdown (`.md`) and PDF (`.pdf`). If the directory is missing or contains no supported files, STOP and instruct the user to create it.
2. You have access to web search tools for technology research.

## Overview

This is an INTERACTIVE, multi-phase process. Do not rush through — each phase builds on the previous one. The output (`plancasting/tech-stack.md`) is referenced by every subsequent pipeline stage.

## Supported Product Types

- Web applications (SaaS, marketplace, dashboard, portal)
- Mobile applications (native, cross-platform, companion apps)
- Desktop applications (Electron, Tauri, native)
- IoT / Embedded devices (firmware, connected devices, sensor networks)
- Hardware products (PCB design, 3D modeling, manufacturing)
- AI/ML products (model serving, agent systems, data pipelines)
- API services (developer platforms, microservices)
- Hybrid products (multiple types with shared backend)

## Execution Flow

### Step 1: Session Language Selection

Ask the user what language they want for interaction and document generation. This is the FIRST step before any analysis. Record the selection. All subsequent communication and generated documents use the selected language. Code, technical identifiers, and file names always remain in English.

### Step 2: Business Plan Analysis (Round 0)

Read all files in `./plancasting/businessplan/`. Handle file types: `.md` and `.pdf` are processed directly. For DOCX, images, and other formats, notify the user to convert. If the user cannot convert, proceed with available files and document which were skipped.

Extract and summarize 19 categories of information (for each, note whether the Business Plan provides clear information or is ambiguous/silent):

1. Product type (web app, mobile app, IoT device, hardware, AI product, API service, hybrid)
2. Target audience (B2C, B2B, B2D, internal)
3. Scale expectation (user/device/transaction volumes projected)
4. Key features (ALL features — these hint at technical requirements, e.g., "real-time collaboration" implies WebSockets, "offline mode" implies local storage)
5. Technical hints (explicitly mentioned technologies, platforms, integrations)
6. Multi-tenancy signals (multiple organizations, workspaces, teams sharing the platform; per-org data isolation, branding, billing)
7. AI/ML components (AI agents, autonomous workflows, multi-step AI processes, tool use, LLM orchestration)
8. Notification signals (alerting, push messages, SMS, in-app messaging, email triggers — note which channels)
9. Billing model signals (subscription tiers, usage-based, per-seat, free trials, marketplace commission)
10. Background processing signals (report generation, data imports/exports, batch operations, scheduled tasks)
11. Public API signals (third-party integrations calling into this product, developer platform, webhooks)
12. Admin/back-office signals (admin users, operator dashboards, content moderation, support tools)
13. Authorization complexity signals (different user roles, permission levels, access control rules)
14. Data migration signals (replacing existing system, importing from spreadsheets or other tools)
15. Compliance/regulatory requirements (industry-specific regulations, certifications)
16. Revenue model (subscription, one-time, marketplace, hardware sales — affects payment integration)
17. Geographic scope (global, regional, single-country — affects CDN, i18n, data residency)
18. Language signals (Business Plan language, target user countries/languages, multilingual support mentions)
19. Third-party integrations (external systems, APIs, or services mentioned)

Present this summary to the user in a structured format showing each category and ask for corrections before proceeding. Note: SaaS products serving businesses almost always need multi-tenancy — flag this explicitly even if the Business Plan does not mention it directly.

### Step 3: Gap-Filling Questions (Rounds 1-3)

Ask ONLY questions the Business Plan did not clearly answer. Skip questions already answered. Cover three rounds:

**Round 1**: Product type confirmation, target audience, scale expectation — only if ambiguous.

**Round 2**: Product-type-specific deep dive (web, mobile, desktop, IoT, hardware, AI/ML). For ALL product types: multi-tenancy details, i18n configuration, offline/local-first needs, admin panel, tech preferences, compliance, budget sensitivity.

**Round 3**: Feature-specific requirements — authentication, authorization model, theme/dark mode, design direction (reference URLs, logo, Figma files, UI component library, aesthetic direction), data retention, accessibility target, data migration, payments, notifications, email, file storage, background processing, search, public API, audit trail, analytics, monitoring, AI agent orchestration, CI/CD, user-facing documentation.

### Step 4: Design Direction Discovery

For products with a frontend, this is a critical sub-phase within Round 3:

1. **Design reference URLs** (1-5): Visit each URL to analyze visual patterns, color schemes, typography, layout approaches, and interaction styles
2. **Product logo** (PNG/SVG): Extract dominant colors to inform the palette
3. **Figma design files** (URL or .fig): Highest-authority source — extract tokens directly
4. **UI component library selection**: Present framework-specific options (e.g., shadcn/ui, Radix, Mantine for React)
5. **Aesthetic direction preference**: Suggest 3 tailored options based on product personality and target users

### Step 5: Technology Research (Phase 2)

Research the latest technologies using web search. For each technology category relevant to the product:

1. Run search queries adapted to the product type (e.g., "best react framework [current year]", "best backend as a service [current year]", "[technology A] vs [technology B] [current year]").
2. Evaluate each technology against five criteria:
   - (1) Active maintenance: GitHub commits within 6 months for OSS; active docs/changelog for SaaS
   - (2) Package downloads stable or growing
   - (3) Active community (recent issues being resolved)
   - (4) Documentation quality (examples for common use cases)
   - (5) Claude Code compatibility (can Claude effectively write code for this technology?)
3. Reject technologies that fail criteria (1) or (5).
4. Build a compatibility matrix ensuring all recommended technologies work well together.

**Technology categories for software products**: Language & Runtime, Frontend Framework, UI Component Library (skip if user already selected during Design Direction), Backend/API, Database, Authentication, File Storage, Media Processing, Hosting/Deployment, Email, Notifications, Payments & Billing, Search, Background Processing, Analytics, Error Monitoring, Feature Flags, AI Provider, AI Agent Framework, Vector Database, Multi-tenancy Strategy, Audit Logging, i18n Library, CI/CD, Package Manager.

**Technology categories for IoT/Embedded**: Firmware Language, Firmware Framework, RTOS, Communication Protocol, IoT Cloud Platform, Device Management, Companion App, Data Pipeline.

**Technology categories for Hardware**: EDA Tool, CAD Tool, Simulation, BOM Management, Version Control, Manufacturing Files.

### Step 6: Present Recommendations (Phase 3)

Present 2-3 options per category in this format:

```
### [Category Name]

**Recommended: [Technology A]**
- Why: [1-2 sentence rationale based on their requirements]
- Pricing: [Free tier / Starting price]
- AI compatibility: [How well Claude Code can work with it]

**Alternative: [Technology B]**
- Why: [When you'd choose this instead]
- Pricing: [Free tier / Starting price]

Your choice? [A / B / C]
```

Present ONE CATEGORY AT A TIME or in logical groups (3-4 at once). Do not overwhelm the user. After all selections, present the complete stack as a summary table and wait for explicit user approval before proceeding to credential collection.

### Step 7: Credential Collection (Phase 4)

Generate a credentials checklist categorized by pipeline stage and credential tier:

- **Pipeline Infrastructure** (always required):
  - `TRANSMUTER_ANTHROPIC_API_KEY` — Anthropic API key for pipeline AI operations
  - `E2B_API_KEY` — E2B sandbox API key for code execution
  - `SANDBOX_AUTH_TOKEN` — Sandbox authentication token
- **Before Stage 3** (obtain before Stage 3, deploy to backend after Stage 3): Database/BaaS deploy key, Auth provider dev keys
- **Before Stage 5**: Email, payment, AI, monitoring API keys
- **Before Stage 7**: Production keys for hosting, domains, CDN
- **Before Stage 7D**: Mintlify account (if documentation site selected)

Collect credentials with strict security rules:
- never log, echo, or display credentials after collection
- Write ONLY to `.env.local` (git-ignored)
- Strongly encourage ALL red-tier credentials now
- Warn about placeholders that will block Stage 3

Validate each credential with a minimal test call. Resolve failures for pipeline infrastructure and red-tier credentials before proceeding.

### Step 8: Generate Configuration Files (Phase 5)

Generate these files:

**`./plancasting/tech-stack.md`** — Complete human-readable tech stack document containing:
- Session Language
- Product Type, Target Audience, Scale
- Business Plan Insights (technical implications from the 19-category analysis)
- Technology Stack table (category, technology, version, purpose, documentation URL)
- Model Specifications (pipeline model, context window, output token limit, safe output budget, large product threshold)
- Architecture Overview
- Key Design Decisions with rationale
- Development Commands (dev, build, test, lint)
- Specifications (color profile, locale, AI model, agent framework)
- Language & Internationalization configuration
- Multi-Tenancy Configuration
- Authorization Model
- Theme & Appearance
- Design Direction (UI library, aesthetic, logo, reference URLs, Figma, typography, color palette)
- Data Retention & Deletion
- Accessibility target
- Data Migration
- Documentation
- Credentials Reference (purposes only, NOT values)
- Starter Template

**`.env.local`** — Credentials file (never commit to version control)

**`.env.local.example`** — Template for other developers

**`.gitignore`** additions — ensure `.env.local` is listed

After generating, read back `plancasting/tech-stack.md` and verify all required fields are present.

### Step 9: Minimal Project Initialization (Phase 6)

If applicable, perform ONLY:
1. Create project scaffold (e.g., `create-next-app`, `create-vite`)
2. `git init` if not already a git repo
3. Install package manager lock file

Do not install product-specific packages, configure services, or create application directories. That is Stage 3's responsibility.

### Step 10: Handoff (Phase 7)

Inform the user of completion and next steps. Instruct them to start a new Claude Code session for Stage 1 (BRD Generation).

## Required Fields Verification

Before declaring complete, verify `plancasting/tech-stack.md` contains ALL of these (downstream stages depend on them):
- Session Language
- Product Type
- Multi-Tenancy Configuration
- Authorization Model
- Primary Database/BaaS
- Auth Provider
- Hosting Platform
- Dev Server Command
- Design Direction
- Theme & Appearance
- Data Retention & Deletion Policy
- Model Specifications (context window, output token limit, safe output budget)

If any field cannot be determined, mark as `> ⚠️ ASSUMPTION: [assumed value] — user should confirm`.

## Critical Rules

1. always read the Business Plan FIRST. never ask questions it already answers.
2. never assume product type if ambiguous. Ask for clarification.
3. never recommend technologies without researching current status via web search.
4. never skip credential collection — missing credentials cause pipeline failures.
5. never assume a default for multi-tenancy — this is a fundamental architectural decision.
6. never skip AI agent framework selection if AI features involve agents or multi-step workflows.
7. always present multiple options and let the user choose.
8. always explain WHY you recommend something, connecting to Business Plan features.
9. always consider Claude Code compatibility.
10. never skip Design Direction questions for products with a frontend.
11. When the user provides design reference URLs, visit each to analyze visual patterns.
12. When the user provides a product logo, extract dominant colors.

## Output Specification

| Output | Location | Description |
|---|---|---|
| Tech stack configuration | `./plancasting/tech-stack.md` | Human-readable, referenced by all pipeline stages |
| Credentials | `./.env.local` | Git-ignored, never committed |
| Credentials template | `./.env.local.example` | For other developers |
| Project scaffold | Project root | Minimal framework scaffold (if applicable) |
