---
name: feedback
description: >-
  Processes user feedback batches through the spec-update-code-test-docs chain.
  This skill should be used when the user asks to "process user feedback",
  "run the feedback loop", "analyze user feedback", "implement feedback changes",
  "triage support tickets", "run stage 8", "process feedback batch",
  or "update specs from feedback",
  or when the transmute-pipeline agent reaches Stage 8 of the pipeline.
metadata:
  version: 1.1.0
effort: medium
---

# User Feedback Loop — Stage 8

Read the detailed guide at `${CLAUDE_SKILL_DIR}/references/feedback-detailed-guide.md` for the complete feedback processing procedures, teammate spawn prompts, triage patterns, and report templates.

## Critical Concept: Living Documents

The BRD and PRD are not frozen artifacts. They are living documents that evolve with the product. This skill maintains the chain: Feedback -> Spec Update -> Code Change -> Test Update -> Doc Update, ensuring every layer stays consistent.

## Prerequisites

1. Read `CLAUDE.md` and `plancasting/tech-stack.md`.
2. Verify Stage 7V PASS or CONDITIONAL PASS: Check that `./plancasting/_audits/production-smoke/report.md` exists and shows PASS or CONDITIONAL PASS. If missing or FAIL, STOP -- Stage 7V must achieve PASS or CONDITIONAL PASS before processing feedback.
3. Verify `./feedback/input.md` exists. If not, stop: "No feedback to process. Create `./feedback/input.md` with feedback items before running Stage 8. Schedule Stage 8 after feedback batch is collected."
4. **Input Validation**: Verify `./feedback/input.md` follows the required structure. Required fields per feedback item: (1) ID (TICKET-001, etc.), (2) Category (Bug / UX Issue / Missing Feature / Enhancement / Performance / Documentation), (3) Description, (4) Affected Feature ID (FEAT-XXX or NEW). If required fields are missing, ask operator to provide them before Phase 1 begins.
5. Check `plancasting/tech-stack.md` for the `Session Language` setting. Generate all reports in the specified language.

## Inputs

- **User Feedback**: `./feedback/input.md` (structured feedback -- see format below)
- **Existing Specs**: `./plancasting/brd/`, `./plancasting/prd/`
- **Tech Stack**: `./plancasting/tech-stack.md`
- **Codebase**: Backend directory, `./src/`, `./e2e/` (adapt to your stack)
- **Project Rules**: `./CLAUDE.md`
- **Progress Tracker**: `./plancasting/_progress.md` (if exists)
- **User Guide** (if exists): `./user-guide/` (Mintlify docs from Stage 7D)
- **Feedback Archive** (if exists): `./feedback/archive/` -- review for recurring feedback

## Stack Adaptation

Examples use Convex + Next.js paths. Adapt to your stack:
- `convex/` -> your backend directory
- `src/` -> your frontend directory
- `npm run` -> your package manager command
Always read `CLAUDE.md` and `plancasting/tech-stack.md` for actual conventions.

## Preparing the Feedback Input

Create `./feedback/input.md` with structured feedback:

```markdown
# User Feedback Batch — [Date]

## Source: Support Tickets (Jan 15-31)

### TICKET-001: Users cannot find the export function
- **Frequency**: 12 tickets in 2 weeks
- **User Quote**: "I've looked everywhere but can't figure out how to export my data"
- **Affected Feature**: Data Export (FEAT-015)

## Source: Analytics (Jan 1-31)

### ANALYTICS-001: 60% drop-off on onboarding step 3
- **Metric**: Funnel completion rate
- **Current**: 40% complete onboarding
- **Target**: 80% (from PRD)

## Source: Stakeholder Request

### STAKEHOLDER-001: Add bulk delete capability
- **Requester**: Operations Team Lead
- **Justification**: "Manually deleting items one by one is taking hours"
- **Priority Request**: High
```

## Session Recovery

If this stage is interrupted mid-execution:
1. Check if `./feedback/analysis.md` exists -- if so, Phase 1 (triage) completed. Skip to Phase 2.
2. Check if `./feedback/change-plan.md` exists -- if so, the change plan is ready. Skip to spawning teammates.
3. Check if code changes exist beyond spec updates -- review `git diff` to understand what was changed, then resume from the incomplete teammate.
4. If `./feedback/resolution.md` exists with a complete summary -- Phase 4 completed. The stage is done.
5. If none of the above files exist, restart from Phase 1.

**Warning**: Partial spec updates without corresponding code changes leave the project in an inconsistent state. must complete Phase 3 before ending the recovery session.

## Execution Flow

### Phase 1: Lead Analysis — Feedback Triage

**Branch safety**: Verify `git status` shows a clean working directory before creating the branch -- commit or stash uncommitted changes first. Then create a dedicated branch: `git checkout -b feedback/batch-$(date +%Y-%m-%d-%H%M%S)`. The HMS suffix avoids same-day collisions.

1. Read `./CLAUDE.md`, `./plancasting/tech-stack.md`, and `./feedback/input.md`.
2. Read `./plancasting/prd/_context.md` (or `plancasting/prd/README.md`) and `./plancasting/brd/_context.md` (or `plancasting/brd/00-cover-and-metadata.md`) for existing feature inventory. Extract maximum existing requirement IDs (max FR-NNN, max US-NNN, max SC-NNN, etc.) and include in `change-plan.md` so Teammate 1 knows the starting point for new IDs.
3. **Categorize each feedback item**:

   | Category | Description | Action |
   |---|---|---|
   | Bug | Product doesn't match existing spec | Fix code to match spec |
   | UX Issue | Product matches spec but spec is wrong | Update spec + fix code |
   | Missing Feature | Capability not in current spec | Add to spec + implement |
   | Performance | Doesn't meet NFR targets | Optimize (use Stage 6C) |
   | Enhancement | Existing feature needs improvement | Update spec + modify code |
   | Documentation | User guide unclear, missing, or incorrect | Update `user-guide/` and `docs/` |

4. **Trace to existing specs**: For each item, find related PRD feature/user story/screen spec, BRD requirement, and code files.
   - Check `./plancasting/brd/14-business-rules-and-logic.md` and `./plancasting/brd/06-business-requirements.md` for rules that might conflict
   - **Decision audit**: If implementing would change a specification marked as a key constraint in Stage 1/2, escalate as `STAKEHOLDER_DECISION_REQUIRED`
   - **Recurring request check**: Review `./feedback/archive/` (if exists) to identify recurring feedback. If the same request appears in 2+ feedback batches, increase priority by 1 tier (P2->P1, P1->P0). Cap at P0. Document: "Priority bumped due to [N] recurring requests across [batch dates]."

5. Create `./feedback/analysis.md` with triage table, impact assessment, and effort estimates (XS <15 min / S 15-30 min / M 30-60 min / L 1-2 hours / XL 2-4 hours).

   **Batch limit**: If APPROVED items exceed the feedback batch limit (check `tech-stack.md` § Model Specifications "Feedback batch limit"; default: 15 items), split into priority-ordered batches. Process only the first batch. **Effort-based splitting**: If estimated effort for the batch exceeds 3-5 hours, split into sub-batches by priority tier.

### Conflict Detection and Resolution

Before creating the change plan, scan for conflicting feedback items:
1. Group feedback by affected feature (FEAT-NNN)
2. Within each group, check for opposing requests (simplify vs add options, remove vs enhance)
3. Classify the conflict type to determine resolution strategy:
   - **Simplicity vs Power**: Design decision -- often resolvable via feature-flag by plan tier
   - **UX vs Performance**: Trade-off decision -- benchmark both before choosing
   - **Safety vs Convenience**: Policy decision -- escalate to stakeholder, don't guess
   - **Quantitative conflict** (80% want A, 20% want B): frequency wins; document minority concern
   - **Qualitative conflict** (both sides have merit, no clear majority): escalate or propose A/B test
4. Document the conflict type, resolution strategy, and rationale in the change plan
5. Unresolvable conflicts: mark as `STAKEHOLDER_DECISION_REQUIRED` and defer both items

**Escalation procedure for deferred conflicts**: Document both sides in `change-plan.md` with rationale and impact assessment. Mark as `[STAKEHOLDER DECISION REQUIRED]`. Set a 48-hour deadline for stakeholder decisions. If no decision by deadline, set status to `DEFERRED -- Next batch [DATE]`.

**Spec file limit**: If a single item requires changes to >5 spec files (BRD + PRD combined), flag as 'complex' and recommend a dedicated session.

6. **Assign status markers**: `APPROVED`, `STAKEHOLDER_DECISION_REQUIRED`, or `DEFERRED`. Include in change plan. Each entry must include a `Status:` field so teammates can check it before starting work.

7. Create `./feedback/change-plan.md` with ordered changes list. Each entry includes: status marker, spec changes, code changes, test changes, documentation changes, task dependency mapping.

8. Create task list for teammates.

### Phase 2: Spawn Improvement Teammates

**Prerequisite check**: Before spawning Teammate 1, verify `./feedback/change-plan.md` exists and contains at least one APPROVED item. If not, STOP and re-run Phase 1.

Spawn 3 teammates SEQUENTIALLY (spec -> code -> test/docs). Each teammate skips items marked `STAKEHOLDER_DECISION_REQUIRED` or `DEFERRED`.

**Teammate 1 -- "spec-updater"**: Update BRD and PRD based on feedback. Add new requirements with next available IDs. Modify acceptance criteria. Add traceability markers (`Updated based on user feedback [TICKET-001]`). Update version tracking in cover/metadata files. Run consistency check after all updates.

**Teammate 2 -- "code-implementer"** (BLOCKED by Teammate 1): Implement code changes against updated specs. Fix bugs to match spec. Modify UI/backend for UX issues and enhancements. Implement missing features. Add traceability comments (`// FEEDBACK FIX: [feedback-id]`). The `FEEDBACK FIX` comment supplements (does not replace) the standard `@traces` header. Run `build` to catch build-breaking issues before Teammate 3.

**Teammate 3 -- "test-and-docs-updater"** (BLOCKED by Teammate 2): Update existing tests to match new specs. Add new tests for each new feature/behavior. Update developer docs (`./docs/`). Update user guide only if `./user-guide/` directory exists -- journey pages, FAQ, troubleshooting, changelog, validate docs.json navigation. If multi-language, update BOTH `en/` and `<session-lang>/` versions. If no user guide exists, focus on `./docs/` and `./e2e/` instead. Run full verification suite: typecheck, lint, test, test:e2e, build.

### Phase 3: Coordination During Execution

1. Monitor progress.
2. Enforce dependency ordering -- Teammate 2 starts only after Teammate 1 completes, Teammate 3 after Teammate 2.
3. If Teammate 2 finds spec insufficient: relay to Teammate 1 for clarification. Max 2 coordination rounds per item (each round = Teammate 2 messages lead -> lead messages Teammate 1 -> Teammate 1 responds -> lead relays). If more than 2 rounds, escalate item to DEFERRED status and move on.

### Phase 4: Review and Close Loop

1. Run full test suite.
2. Update `plancasting/_progress.md` if it exists and features changed (new rows for new features, update Notes column for existing features with significant behavioral changes).
3. Generate `./feedback/resolution.md` with resolution table, summary statistics, spec version updates, and recommendations for next cycle.
4. **Archive processed feedback** -- copy (do not move) `input.md` to `./feedback/archive/`:
   ```bash
   mkdir -p ./feedback/archive
   cp ./feedback/input.md ./feedback/archive/$(date +%Y-%m-%d-%H%M%S)-input.md
   ```
5. Update `plancasting/tech-stack.md` if new dependencies were added.
6. Output summary.

## Gate Decision

- **PASS**: All APPROVED items resolved, tests pass, specs consistent, docs updated. Proceed to re-deployment (Stage 7) and re-verification (Stage 7V). Consider re-running Stage 6V if UI changes were made.
- **CONDITIONAL PASS**: Some items deferred due to complexity but all attempted items resolved. Document deferred items with `Status: DEFERRED -- Next batch [DATE]`. Schedule follow-up Stage 8 session.
- **FAIL**: Test suite fails, spec inconsistency detected, or APPROVED items left unresolved. Do not proceed to Stage 7 until PASS or CONDITIONAL PASS.

## Known Failure Patterns

1. **Conflicting feedback**: User A wants removal, User B wants expansion. Resolve by frequency, escalate to stakeholder, or document trade-off.
2. **Feature requests contradicting BRD**: always check BRD business rules before accepting.
3. **Spec drift**: Cumulative changes make BRD/PRD inconsistent. Verify consistency after every change.
4. **Cross-cutting feedback**: "The app is slow" affects multiple features. Triage into specific, actionable items per feature.
5. **Architectural changes needed**: Defer to a separate Stage 5 re-run rather than patching.
6. **i18n key breakage**: always update message files when changing user-facing text.

## Running This Prompt Repeatedly

Designed for regular cadence (weekly, biweekly, monthly). Each run processes a new batch, updates living docs, implements changes, archives feedback. Over time, `./feedback/archive/` builds a complete audit trail from user voice to product change.

## Cross-Stage References

- Dependency updates: defer to **Stage 9** (Dependency Maintenance) for safe, batched updates.
- UI changes: re-run **Stage 6V** (Visual & Functional Verification).
- After deploying: run **Stage 7V** (Production Smoke Verification).
- If performance feedback: use **Stage 6C** (Performance Optimization).
- User guide auto-deploys via GitHub on push if Mintlify GitHub App is configured.
- If user guide is fundamentally outdated, consider re-running **Stage 7D** instead of patching.
- Stage 8 runs in a continuous loop: collect feedback -> update specs -> implement fixes -> update docs -> deploy (Stage 7) -> verify (Stage 7V) -> collect more feedback -> repeat.

## Critical Rules

1. never implement feedback contradicting a BRD business rule without spec-updater resolution first.
2. never modify a spec without updating all cross-references.
3. always defer architectural changes to a separate Stage 5 re-run.
4. always run the full test suite after code changes.
5. always update i18n message files when changing user-facing text.
6. For batches >15 items, split into multiple runs (max 15 APPROVED items per run, unless overridden in tech-stack.md).
7. After UI changes, recommend re-running Stage 6V.
8. After deploying, run Stage 7V.
9. never skip the traceability chain -- every code change must trace to a spec.
10. Resolve conflicting feedback BEFORE implementing either side.
11. If deployment causes production failures, revert with `git revert` (not `git reset --hard`), re-run 7V, investigate before re-attempting.
12. never run Stage 8 and Stage 9 concurrently. Complete one and commit before starting the other.
