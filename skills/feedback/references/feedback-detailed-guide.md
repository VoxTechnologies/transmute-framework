# Transmute — User Feedback Loop

## Stage 8: Continuous Improvement from User Feedback

````text
You are a product manager and engineer acting as the TEAM LEAD for a feedback-driven improvement cycle using Claude Code Agent Teams. Your task is to analyze user feedback, trace it back to existing BRD/PRD specifications, propose specification changes, implement code changes, and keep all documentation in sync.

**Stage Sequence**: ... → 7D (User Guide) → **8 (this stage)** / 9 (Dependency Maintenance) — run both sequentially, never concurrently (per CLAUDE.md notation). Run on a recurring cadence (weekly, biweekly, or monthly) post-launch.

**Prerequisites**: Stage 7V PASS or CONDITIONAL PASS (product deployed and running in production). If Stage 7D was run, verify it achieved PASS or WARN (check `./plancasting/_audits/user-guide/report.md` § `## Gate Decision`). 7D FAIL blocks Stage 8 until documentation issues are resolved. If 7D was skipped, this condition does not apply. Feedback input file `./feedback/input.md` must be prepared with the current feedback batch before starting this stage. See `execution-guide.md` § Stage 8 for skip conditions and recovery procedures.

**CRITICAL prerequisite — Stage 8/9 mutual exclusion**: Before proceeding, verify that Stage 9 (Dependency Maintenance) is not currently in progress. Check: (a) `git branch | grep 'chore/dependency-update'` — if a branch exists and is not yet merged, Stage 9 may still be in progress. (b) If Stage 9 is in progress, STOP — do not run Stage 8 until Stage 9 is committed and merged. Both stages modify `package.json`, lock files, and source code; concurrent execution causes merge conflicts and silent overwrites.

## Critical Concept: Living Documents

The BRD and PRD are not frozen artifacts. They are living documents that evolve with the product. This prompt maintains the chain: Feedback → Spec Update → Code Change → Test Update → Doc Update, ensuring every layer stays consistent.

## Input

- **User Feedback**: Provided as a markdown file at `./feedback/input.md`. This file should contain structured feedback (see format below).
- **Existing Specs**: `./plancasting/brd/`, `./plancasting/prd/`
- **Tech Stack**: `./plancasting/tech-stack.md`
- **Existing Codebase**: Your backend directory (e.g., `./convex/`), frontend directory (e.g., `./src/`), and `./e2e/` — adapt paths per `plancasting/tech-stack.md`
- **Project Rules**: `./CLAUDE.md`
- **Progress Tracker**: `./plancasting/_progress.md` (if it does not exist, skip progress tracking updates in Phase 4 step 2)
- **User Guide** (if exists): `./user-guide/` — documentation site (Stage 7D output, e.g., Mintlify — adapt to your docs framework per tech-stack.md). If this directory exists, documentation updates must also update the corresponding MDX pages here. If `./user-guide/` does not exist (Stage 7D was not run), Teammate 3 skips the "UPDATE USER GUIDE" task and focuses on developer documentation (`./docs/` from Stage 6D) and test updates only.

## Preparing the Feedback Input

Before running this prompt, prepare the feedback directory and input file:

```bash
mkdir -p ./feedback
```

Then create `./feedback/input.md` with structured feedback. Example format:

~~~markdown
# User Feedback Batch — [Date]

## Source: Support Tickets (Jan 15–31)

### TICKET-001: Users cannot find the export function
- **Frequency**: 12 tickets in 2 weeks
- **User Quote**: "I've looked everywhere but can't figure out how to export my data"
- **Affected Feature**: Data Export (FEAT-015)

### TICKET-002: Slow loading on dashboard
- **Frequency**: 8 tickets
- **User Quote**: "Dashboard takes 10+ seconds to load with 500+ items"
- **Affected Feature**: Dashboard (FEAT-003)

## Source: Analytics (Jan 1–31)

### ANALYTICS-001: 60% drop-off on onboarding step 3
- **Metric**: Funnel completion rate
- **Current**: 40% complete onboarding
- **Target**: 80% (from PRD)

## Source: Stakeholder Request

### STAKEHOLDER-001: Add bulk delete capability
- **Requester**: Operations Team Lead
- **Justification**: "Manually deleting items one by one is taking hours"
- **Priority Request**: High
~~~

**Language**: Check `./plancasting/tech-stack.md` for the `Session Language` setting. Generate all reports and user-facing output in the specified language. Code, technical identifiers, and file names remain in English.

## Stack Adaptation

The examples in this prompt use Convex + Next.js paths. Adapt to your stack:
- `convex/` → your backend directory (e.g., `src/functions/` for Firebase, `app/` for Rails, `server/` for Django)
- `src/` → your frontend directory
- `src/components/features/` → your component directory
- `src/hooks/` → your data hooks directory
- `bun run` → your package manager command (e.g., `npm run`, `pnpm run`)
Always read `CLAUDE.md` and `plancasting/tech-stack.md` for your project's actual conventions.

## Known Failure Patterns

Based on observed feedback loop outcomes:

1. **Conflicting feedback**: User A wants a feature removed, User B wants it expanded. The lead must detect conflicts and resolve with a strategy (prioritize by frequency, escalate to stakeholder, or document as trade-off).
2. **Feature requests contradicting BRD**: Feedback requests capability that conflicts with an existing business rule. always check `./plancasting/brd/14-business-rules-and-logic.md` and `./plancasting/brd/06-business-requirements.md` for rules that might conflict with the feedback before accepting feature requests.
3. **Spec drift**: Cumulative feedback changes make BRD/PRD internally inconsistent. The spec-updater must verify consistency after every change.
4. **Cross-cutting feedback**: Feedback that maps to multiple features simultaneously (e.g., "the app is slow" affects performance across all features). Triage into specific, actionable items per feature.
5. **Feedback that requires architectural changes**: User wants real-time collaboration but the architecture has no WebSocket support. Defer to a separate Stage 5 re-run rather than patching.
6. **i18n key breakage**: UI text changes that break i18n translation keys. always update message files when changing user-facing text.

## Session Recovery

If this stage is interrupted mid-execution:
1. Check if `./feedback/analysis.md` exists — if so, Phase 1 (triage) completed. Skip to Phase 2.
2. Check if `./feedback/change-plan.md` exists — if so, Phase 1 (triage) completed and the change plan is ready.
3. Check if BRD/PRD files were modified since the change plan was created (e.g., `git log --oneline -- plancasting/brd/ plancasting/prd/`). If spec files were modified, Teammate 1 (spec-updater) likely completed — skip to spawning Teammate 2 (Phase 3 — code implementation).
4. Check if code changes exist beyond spec updates — if Teammate 2 was mid-implementation, review `git diff` to understand what was changed, then re-spawn Teammate 2 with instructions to complete remaining items from the change plan.
5. If `./feedback/resolution.md` exists with a complete summary — Phase 4 completed. The stage is done.
6. If none of the above files exist, restart from Phase 1.

**Warning**: Partial spec updates without corresponding code changes leave the project in an inconsistent state. If Phase 2 (spec-updater) completed but Phase 3 (code-implementer) did not, the BRD/PRD may reference features or changes that the code does not yet reflect. must complete Phase 3 before ending the recovery session — do not leave specs and code out of sync.

## Agent Team Architecture

### Phase 1: Lead Analysis — Feedback Triage

**Pre-flight Concurrency Check** (see also the top-level "CRITICAL prerequisite — Stage 8/9 mutual exclusion" above): Before proceeding, verify that Stage 9 (Dependency Maintenance) is not currently in progress. Check both: (1) `git log --oneline -5 | grep -i 'chore.*depend'` — if the most recent commit is an in-progress dependency update from the current day, STOP; (2) `git branch --list 'chore/dependency-update-*'` — if a maintenance branch exists, Stage 9 may be active. Do not run Stage 8 concurrently with Stage 9 (both modify `package.json` and lock files). Wait for Stage 9 to complete and commit before starting Stage 8.

As the team lead, complete the following BEFORE spawning any teammates:

1. **Verify Stage 7V PASS or CONDITIONAL PASS**: Check that `./plancasting/_audits/production-smoke/report.md` exists and shows PASS or CONDITIONAL PASS. If the file does not exist or shows FAIL, STOP — Stage 7V must achieve PASS or CONDITIONAL PASS before processing feedback.

2. Verify `./feedback/input.md` exists. If it does not exist, STOP. Do not proceed further. Exit the session with: "Feedback processing deferred — no input. Create `./feedback/input.md` with feedback items before running Stage 8. Schedule Stage 8 after feedback batch is collected." The project remains in production. Stage 7V or Stage 9 can be run independently when needed. If it exists, read `./CLAUDE.md`, `./plancasting/tech-stack.md`, and `./feedback/input.md`.

   **Duplicate Detection**: Verify that `input.md` has not already been processed in this cycle by checking `./feedback/archive/` for a timestamped copy with matching content. If a match exists, warn the operator that this feedback may have already been processed.

   **Input Validation**: Verify `./feedback/input.md` follows the markdown structure defined in the Preparing the Feedback Input section. If the format is unclear or missing required fields, STOP and ask the operator to reformat before proceeding.

   **Required fields per feedback item**: (1) ID (TICKET-001, etc.), (2) Category (Bug / UX Issue / Missing Feature / Enhancement / Performance / Documentation), (3) Description, (4) Affected Feature ID (FEAT-XXX or NEW). Optional: Frequency, User Quote, Source. Category must be one of: `Bug`, `UX Issue`, `Missing Feature`, `Enhancement`, `Performance`, `Documentation`. Reject unrecognized categories — ask operator to reclassify. If required fields are missing, ask operator to provide them before Phase 1 begins.

**Branch safety**: Verify `git status` shows a clean working directory before creating the branch — commit or stash uncommitted changes first. Then create a dedicated branch: `git checkout -b feedback/batch-$(date +%Y-%m-%d-%H%M%S)`. The HMS suffix avoids same-day collisions. CLAUDE.md shows the shorter `feedback/batch-YYYY-MM-DD` format — either is acceptable. Merge into main after the Gate Decision is PASS or CONDITIONAL PASS.

3. Read `./plancasting/prd/01-product-overview.md` and `./plancasting/brd/00-cover-and-metadata.md` (or `_context.md` if it exists in either directory) for existing feature inventory and requirement IDs. Extract the maximum existing requirement IDs (max FR-NNN, max US-NNN, max SC-NNN, etc.) and include them in `change-plan.md` so Teammate 1 knows the starting point for new IDs.
4. **Categorize each feedback item**:

   | Category | Description | Action |
   |---|---|---|
   | Bug | Product doesn't match existing spec | Fix code to match spec |
   | UX Issue | Product matches spec but spec is wrong | Update spec + fix code |
   | Missing Feature | Capability not in current spec | Add to spec + implement |
   | Performance | Doesn't meet NFR targets | Optimize (follow Stage 6C patterns from `prompt_optimize_performance.md`) |
   | Enhancement | Existing feature needs improvement | Update spec + modify code |
   | Documentation (user-facing + developer) | User guide or developer docs unclear, missing, or incorrect | Update `user-guide/` MDX pages and `docs/` developer pages as applicable |

5. For each feedback item, **trace to existing specs**:
   - Find the related PRD feature, user story, screen spec
   - Find the related BRD requirement — check `./plancasting/brd/14-business-rules-and-logic.md` and `./plancasting/brd/06-business-requirements.md` to identify constraints that would be violated
   - Find the related code files (backend functions, components, tests)
   - **Decision audit**: If implementing this feedback would change a specification that was marked as a key constraint in Stage 1/2 (business case, BRD business rules), escalate as `STAKEHOLDER_DECISION_REQUIRED` — the change may have business implications beyond UX
   - **Optional but recommended**: Review `./feedback/archive/` (if it exists) to identify recurring feedback. If the same feature request appears multiple times across batches, increase its priority in the change plan, even if the individual request frequency is low. Add a note: "Recurring request — users asked for this in [DATE] and [DATE]"
   - **Recurring request priority escalation**: If the same feature request appears in 2+ feedback batches, increase its priority by 1 tier (P2→P1, P1→P0). Cap at P0 — features already at P0 cannot be escalated further. Document in change-plan.md: 'Priority bumped due to [N] recurring requests across [batch dates].'

6. Create `./feedback/analysis.md` containing:
   - Feedback triage table: Feedback ID, Category, Related PRD IDs, Related BRD IDs, Related Code Files, Proposed Action, Priority
   - Impact assessment: which features are affected, how many users impacted
   - Effort estimate per item: XS (<15 min), S (15–30 min), M (30–60 min), L (1–2 hours), XL (2–4 hours). Use to determine batch sizes — target 3–5 hours of work per batch to fit in a single session.

   If the number of APPROVED items exceeds the feedback batch limit (see tech-stack.md § Model Specifications "Feedback batch limit"; default: 10 items if not specified in tech-stack.md — chosen to fit within a 3–5 hour session), split them into priority-ordered batches per Rule 6 below. Process only the first batch in this run. Update `change-plan.md`: assign each item a `Batch: N/M` label, mark non-current-batch items as `Status: DEFERRED — Next batch`. Teammates process only items in the current batch.

   **Effort-based splitting**: If estimated effort for the batch exceeds 3–5 hours based on item complexity, split into multiple sub-batches. Process the highest-priority sub-batch in this session, defer the rest to the next feedback cycle.

### Conflict Detection and Resolution
Before creating the change plan, scan for conflicting feedback items:
1. Group feedback by affected feature (FEAT-NNN)
2. Within each group, check for opposing requests (simplify vs add options, remove vs enhance)
3. Classify the conflict type to determine resolution strategy:
   - **Simplicity vs Power**: Design decision — often resolvable via feature-flag by plan tier (Starter gets simple, Pro gets power)
   - **UX vs Performance**: Trade-off decision — benchmark both before choosing
   - **Safety vs Convenience**: Policy decision — escalate to stakeholder, don't guess
   - **Quantitative conflict** (80% want A, 20% want B): frequency wins; document minority concern
   - **Qualitative conflict** (both sides have merit, no clear majority): escalate or propose A/B test
4. Document the conflict type, resolution strategy, and rationale in the change plan
5. If a conflict cannot be resolved objectively, mark it as "stakeholder decision required" and defer both items

**Escalation procedure for deferred conflicts:**
1. Document both sides in `change-plan.md` with rationale and impact assessment
2. Mark as `[STAKEHOLDER DECISION REQUIRED]`
3. Include in the stage completion report so the platform can surface it to the project owner
4. Do not implement either conflicting change until resolution is confirmed

**Spec file limit**: If a single feedback item would require changes to more than 5 spec files (BRD + PRD combined — this typically means the feedback affects more than 3 features or spans multiple architectural layers), flag it as 'complex' and recommend a dedicated session with a single-item focus.

7. **Assign a status marker to each feedback item**:
   - `APPROVED` — no conflicts, ready to implement
   - `STAKEHOLDER_DECISION_REQUIRED` — conflicts with another feedback item or BRD rule, deferred until stakeholder resolves
   - `DEFERRED` — requires architectural changes or is out of scope for this cycle
   Include these status markers in the change plan and in the context passed to all teammates. Each entry in `change-plan.md` must include a `Status:` field with one of these markers so teammates can check it before starting work on that entry — teammates skip any entry marked `STAKEHOLDER_DECISION_REQUIRED` or `DEFERRED`. Set a 48-hour deadline for stakeholder decisions (document the deadline timestamp in `change-plan.md`). At the start of triage, record the deadline timestamp in `change-plan.md`. If no decision is received by the deadline, automatically change the status to `DEFERRED — Next batch [DATE]` and continue processing APPROVED items only. Document: "Awaiting stakeholder decision since [date]. Deadline passed — deferring to next batch." Do not block Stage 8 execution waiting for decisions beyond the deadline.

8. Before creating the new `change-plan.md`, read the existing `./feedback/change-plan.md` (if it exists) and extract any items still marked `DEFERRED`. Include these carried-over items in the new change plan. Merge procedure: (1) Load new feedback from `input.md`. (2) Load previous `change-plan.md`. (3) Extract items still marked DEFERRED (excluding permanently deferred items). (4) Append carried-over items to the new change plan with prefix `[CARRYOVER]` and their original feedback ID.

   Create `./feedback/change-plan.md`:
   - Ordered list of changes to make (highest impact + lowest effort first)
   - For each change:
     - **Status marker**: APPROVED / STAKEHOLDER_DECISION_REQUIRED / DEFERRED
     - Spec changes needed (BRD and/or PRD file + section)
     - Code changes needed (files to modify)
     - Test changes needed (new tests or modified tests)
     - Documentation changes needed
   - Task dependency mapping (spec changes must complete before code changes)

9. Create a task list for all teammates with dependency tracking.

### Phase 2: Spawn Improvement Teammates

**Prerequisite check**: Before spawning Teammate 1, verify `./feedback/change-plan.md` exists and contains at least one 'APPROVED' item. If the file does not exist or contains no approved items, STOP and re-run Phase 1.

Spawn the following 3 teammates. Tasks are dependency-ordered: spec changes → code changes → test/doc changes. Teammate 1 must batch ALL spec changes together before sending completion. Teammate 2 begins ONLY AFTER Teammate 1's completion message — this ensures Teammate 2 has a complete, consistent spec to implement against. The lead must not spawn Teammate 2 until Teammate 1 sends a completion message (expected format: "Teammate 1 complete — [n] spec files updated, [n] feedback items processed"). Spawn teammates sequentially: Teammate 1 first, then Teammate 2 after spec updates are complete, then Teammate 3 after code changes are complete. While waiting for each teammate to complete, the lead should monitor for questions or blockers and prepare context for the next teammate. If spec-code alignment requires more than 2 coordination rounds per feedback item, escalate that item to DEFERRED status.

**All teammates** must read the status markers in `./feedback/change-plan.md`. Teammates must skip any feedback item marked `STAKEHOLDER_DECISION_REQUIRED` — do not implement, modify specs, or write tests for those items. Only process items marked `APPROVED`.

#### Teammate 1: "spec-updater"
**Scope**: Update BRD and PRD to reflect feedback-driven changes

~~~
You are updating the BRD and PRD specifications based on user feedback analysis.

Read CLAUDE.md first. Check `./plancasting/tech-stack.md` for the `Session Language` setting. Write all spec updates in that language (code identifiers remain English). Then read ./feedback/analysis.md and ./feedback/change-plan.md.

Your tasks — for each change in the change plan that requires spec updates:

1. BRD UPDATES (if the change affects business requirements):
   - Add new requirements (using the next available ID in the appropriate range).
   - Modify existing requirements if the acceptance criteria need to change.
   - Add the feedback source as traceability: "Updated based on user feedback [TICKET-001]".
   - Update the assumptions section if any assumptions were invalidated by feedback.

2. PRD UPDATES (for all UX issues, enhancements, and missing features):
   - Update user stories: modify acceptance criteria, add new stories if needed.
   - Update screen specifications: modify layouts, add new states, change interaction behaviors.
   - Update user flows: modify paths based on UX feedback.
   - Update API specifications if new endpoints or modified behavior is needed.
   - Add change markers: `> 📝 UPDATED [Date]: [reason] — based on [feedback-id]`

3. VERSION TRACKING:
   - Update `./plancasting/brd/00-cover-and-metadata.md` revision history table.
   - Update `./plancasting/prd/01-product-overview.md` version.
   - Add changelog entries describing what changed and why.

4. CONSISTENCY CHECK: After all updates:
   - Verify cross-references between updated files still resolve.
   - Verify requirement ID uniqueness.
   - Verify updated acceptance criteria are testable.

When done, message the lead with: BRD changes (files modified, requirements added/modified), PRD changes (files modified, stories added/modified), new IDs assigned.
~~~

#### Teammate 2: "code-implementer"
**Scope**: Implement code changes based on updated specs

**Blocked by**: Teammate 1 completion (needs updated specs to implement against). **Enforcement**: The lead must not spawn Teammate 2 until Teammate 1 sends a completion message. Do not create Teammate 2's tasks in advance — wait for Teammate 1's message confirming spec updates are done.

~~~
You are implementing code changes based on updated BRD/PRD specifications.

Read CLAUDE.md first. Check `./plancasting/tech-stack.md` for the `Session Language` setting. Write all user-facing strings in that language (code and comments remain English). Then read ./feedback/change-plan.md.
Read the UPDATED BRD/PRD files (Teammate 1 has modified them).
Read ./plancasting/tech-stack.md for technology-specific patterns.

For each change in the change plan that requires code updates:

1. BUGS (code doesn't match spec):
   - Identify the existing spec (it was already correct).
   - Fix the code to match the spec.
   - Verify the fix against the acceptance criteria.

2. UX ISSUES / ENHANCEMENTS (spec was updated):
   - Read the UPDATED spec (user story, screen spec, API spec).
   - Modify the backend functions, components, hooks, and pages to match the new spec.
   - Follow all CLAUDE.md conventions including design direction.

3. MISSING FEATURES (new spec was added):
   - Read the NEW spec entries.
   - Implement following the same patterns as existing features.
   - Add schema changes if needed (additive only). If schema changes are made, run the backend's code generation step (e.g., `bunx convex codegen` for Convex, `npx prisma generate` for Prisma) before proceeding.
   - If codegen fails after schema changes: (1) revert the schema change (`git checkout -- <schema-file>`), (2) report the failure to the lead with the error output, (3) mark the feedback item as DEFERRED with reason 'schema migration requires dedicated session.' Do not proceed with broken generated files.
   - Add hooks, components, pages as needed.

4. For every code change:
   - Add traceability comment: `// FEEDBACK FIX: [feedback-id] — [description]`
   - These inline `// FEEDBACK FIX:` comments supplement (not replace) the standard `@module` / `@prd` / `@brd` traceability headers defined in CLAUDE.md Part 1. The existing traceability header block must remain intact.
   - Ensure existing tests still pass.

After code changes, run `bun run build` to catch build-breaking issues before Teammate 3.

When done, message the lead with: files modified, functions added/modified, components added/modified, any existing test failures.
~~~

#### Teammate 3: "test-and-docs-updater"
**Scope**: Update tests and documentation to reflect changes

**Blocked by**: Teammate 2 completion (needs code changes to test against). **Enforcement**: The lead must not spawn Teammate 3 until Teammate 2 sends a completion message. If Teammate 2 reports that existing tests are FAILING after their code changes, the lead must first determine the cause: (a) if it's a spec gap (ambiguous or insufficient spec) → escalate to Teammate 1 for spec clarification; (b) if it's a code bug in Teammate 2's implementation → Teammate 2 fixes before Teammate 3 starts. If Teammate 2's test failures require more than 2 spec-code coordination rounds, defer the problematic items (see Phase 3 coordination limits) and allow Teammate 3 to proceed with the remaining resolved items.

~~~
You are updating tests and documentation to reflect feedback-driven changes.

Read CLAUDE.md first. Check `./plancasting/tech-stack.md` for the `Session Language` setting. Write documentation and user-facing content in that language (code and test assertions remain English). Then read ./feedback/change-plan.md.
Read ./plancasting/tech-stack.md for technology context.

Your tasks:

1. UPDATE EXISTING TESTS:
   - If feedback changes acceptance criteria (spec changed), updating test assertions is required to match the new spec.
   - If feedback fixes a bug (code was wrong, spec was right), verify tests still match the ORIGINAL spec. If tests were written to match the buggy behavior, update test assertions to match the correct spec. Code fixes are Teammate 2's responsibility — flag any code issues to the lead.
   - If user flows changed, update E2E test steps.
   - If API behavior changed, update backend function tests.

2. ADD NEW TESTS:
   - For each new feature or modified behavior, add tests:
     - Backend function tests
     - Component tests (if UI changed)
     - E2E tests (if user flow changed)
   - Each new test must reference the feedback ID: `// Tests feedback fix: [feedback-id]`

3. UPDATE DEVELOPER DOCUMENTATION (if ./docs/ exists):
   - Update developer-facing pages affected by code/API changes (e.g., `./docs/help/` if Stage 6D created one — this is DIFFERENT from the Mintlify `./user-guide/` in task 4). Developer docs (`./docs/`) are technical and detailed; user docs (`./user-guide/`) are non-technical and task-focused — do not copy content between them.
   - Update API docs for modified functions.
   - Add entries to docs/changelog.md.

4. UPDATE USER GUIDE (SKIP this task entirely if `./user-guide/` directory does not exist — Stage 7D may not have been run. Also skip if `./plancasting/tech-stack.md` states documentation is "not needed"):
   Before modifying `./user-guide/`, verify `docs.json` exists and is valid JSON. If `docs.json` is missing or invalid, skip this task and note in the report: 'User guide site appears incomplete — recommend re-running Stage 7D.'
   - Update journey guide pages affected by UX changes (MDX files in user-guide/en/journeys/ for multi-language setups, or user-guide/journeys/ for single-language).
   - Update FAQ if new common questions emerged from feedback.
   - Update troubleshooting if new issues were resolved.
   - Add changelog entries using <Update> components in changelog.mdx.
   - If feedback resulted in previously-incomplete features now being fully implemented, convert "Coming Soon" placeholders to full documentation pages following the journey-writing pattern from Stage 7D.
   - If multi-language: update BOTH en/ and <session-lang>/ versions to maintain parity.
   - Validate docs.json navigation still matches the page structure after updates (add new pages to navigation if created).

5. VERIFICATION (Use your project's package manager per CLAUDE.md — commands below use `bun run` as the default example.):
   Ensure the dev server is running before executing E2E tests (start it if needed using the command from CLAUDE.md). If E2E tests cannot run (dev server fails to start), note this in your report and run only the non-E2E verification commands.
   ~~~bash
   bun run typecheck
   bun run lint
   bun run test
   bun run test:e2e
   bun run build
   ~~~
   All tests and the build must pass. Fix any failures.

When done, message the lead with:
- Tests added: [n] unit, [n] component, [n] E2E
- Tests modified: [n]
- Test results: PASS / FAIL (if FAIL, list failed test names)
- Docs updated: [file list]
~~~

### Phase 3: Coordination During Execution

While teammates are working:
1. Monitor progress via the shared task list.
2. Enforce dependency ordering:
   - Teammate 2 must not start until Teammate 1 messages completion.
   - Teammate 3 must not start until Teammate 2 messages completion.
3. If Teammate 2 discovers that a spec update from Teammate 1 is insufficient or ambiguous:
   - Teammate 2 messages the lead.
   - Lead messages Teammate 1 to clarify or update the spec.
   - Teammate 2 resumes after clarification.
   - **Coordination round definition**: 1 round = Teammate 2 messages the lead about an issue → lead messages Teammate 1 → Teammate 1 responds → lead relays to Teammate 2. **Why 2 rounds max?** Each round-trip takes ~15–20 minutes. More than 2 rounds signals the feedback is too ambiguous or requires design discussion, not code changes. If more than 2 such rounds occur for a single feedback item, escalate it to DEFERRED status with a note explaining the conflict, and move on to the next item.

### Phase 4: Review & Close Loop

After all teammates complete:

1. Run full test suite to verify everything passes.
2. Update `plancasting/_progress.md` if it exists AND new features were added (new rows), or if existing features had significant behavioral changes — defined as changes affecting more than 2 files, affecting the feature's acceptance criteria, or marked as 'enhancement' or 'UX issue' in the change plan (update Notes column with the feedback ID). If `plancasting/_progress.md` does not exist, skip this step.
3. Generate `./feedback/resolution.md`:
   - Feedback resolution table:

     | Feedback ID | Category | Action Taken | Spec Changes | Code Changes | Tests Added | Status |
     |---|---|---|---|---|---|---|
     | TICKET-001 | UX Issue | Moved export button to main nav | PRD SC-045 | ExportButton.tsx | export-flow.spec.ts | ✅ Resolved |

   - Summary statistics: total feedback items, resolved, deferred, out-of-scope.
   - Spec version updates made.
   - Recommendations for next feedback cycle.

4. Archive the processed feedback — copy (do not move) `input.md` to `./feedback/archive/`. The original input.md is preserved for reference until the operator replaces it with the next batch:
   ~~~bash
   mkdir -p ./feedback/archive
   cp ./feedback/input.md ./feedback/archive/$(date +%Y-%m-%d-%H%M%S)-input.md
   ~~~

5. If code changes added new dependencies, update `plancasting/tech-stack.md` to include them.

6. Output summary: total feedback items processed, resolved, spec changes made, code files modified, tests added.

## Gate Decision

- **PASS**: All APPROVED feedback items resolved, tests pass, specs consistent, documentation updated.
  1. **Merge**: Merge the feedback branch into main before proceeding to Stage 7 (Deploy).
  2. **6V re-run (if UI changes)**: If UI changes were made, must re-run Stage 6V using `prompt_visual_functional_verification.md`. Before the 6V re-run, verify the dev server port is available: `lsof -i :<PORT>` (where `<PORT>` is the dev server port from CLAUDE.md Part 2 or `plancasting/tech-stack.md`) — the 6V prompt starts the dev server internally. Paste the prompt with `MODE: diff | SCOPE: Re-verify only scenarios for features [FEAT-IDs] modified by feedback batch [date]` on the first line. `MODE: diff` tells 6V to compare against the previous baseline rather than generating a new full baseline; `SCOPE:` filters to only affected features.
  3. **6V issue chain**: If the 6V re-run finds 6V-A/B issues, follow the standard 6V→6R→6P/6P-R chain before re-deploying. 6P/6P-R re-run is required if feedback changes introduce new pages/screens or modify >5 components' visual design. Otherwise, previous 6P/6P-R output remains valid.
  4. **6V FAIL**: If the 6V re-run returns FAIL, the feedback changes must be fixed or reverted before re-deploying — do not deploy with a 6V FAIL.
  5. **Deploy workflow**: Complete 6V re-run on the feedback branch → if 6V passes, merge to main → deploy (Stage 7) → run 7V (Production Smoke).
- **CONDITIONAL PASS**: Some items deferred due to complexity but all attempted items resolved, tests pass.
  1. Document deferred items in `change-plan.md` with `Status: DEFERRED — Next batch [DATE]`.
  2. If any resolved items include UI changes, re-run Stage 6V (MODE: diff) before deploying — if 6V finds issues, follow the same 6V→6R→6P/6P-R chain as the PASS outcome. 6P/6P-R re-run is required if feedback changes introduce new pages/screens or modify >5 components' visual design. Otherwise, previous 6P/6P-R output remains valid.
  3. Merge the feedback branch into main before proceeding to Stage 7 (see Branch Safety above).
  4. Proceed to Stage 7 for resolved items. Schedule a follow-up Stage 8 session for deferred items.
  5. **Deferred item carryover**: Before each new Stage 8 run, read `./feedback/change-plan.md` from the previous run. Any items still marked `DEFERRED` that no longer have a `STAKEHOLDER_DECISION_REQUIRED` blocker are automatically re-introduced into the new batch's Phase 1 triage (the operator does not need to re-add them to `input.md` — the lead reads both `input.md` and prior `change-plan.md`). Items still marked `STAKEHOLDER_DECISION_REQUIRED` remain deferred until the operator resolves them.
- **FAIL**: Test suite fails after changes, or spec inconsistency detected, or APPROVED items left unresolved. Review test failures with Teammate 2. For spec inconsistencies, re-run Teammate 1 to clarify. Do not proceed to Stage 7 until PASS or CONDITIONAL PASS.

### Phase 5: Shutdown

1. Verify all teammates have sent their completion messages.
2. Verify all file modifications are saved and committed.
3. No further cleanup is needed — teammates terminate automatically after completing their tasks.

---

## Running This Prompt Repeatedly

This prompt is designed to be run on a regular cadence (weekly, biweekly, or monthly). Each run:
1. Processes a new batch of feedback in `./feedback/input.md`.
2. Updates the living BRD/PRD documents.
3. Implements code changes.
4. Updates tests and docs.
5. Archives the processed feedback.

Over time, `./feedback/archive/` builds a history of all feedback processed and changes made, creating a complete audit trail from user voice to product change.

## Cross-Stage References

- If feedback requires dependency updates, defer to **Stage 9** (Dependency Maintenance) for safe, batched updates.
- After implementing UI changes, re-run **Stage 6V** (Visual & Functional Verification) to verify visual correctness.
- After implementing code changes from feedback, deploy via Stage 7 and verify with Stage 7V. If user guide content was also updated, the documentation site (`./user-guide/`, Stage 7D) auto-deploys via GitHub on push (if the docs framework's GitHub App was configured per Stage 7D deployment instructions). Stage 8 runs in a continuous loop: collect feedback → update specs → implement fixes → update docs → deploy (Stage 7) → verify (Stage 7V) → collect more feedback → repeat.
- If feedback reveals that the user guide is fundamentally outdated or missing major journeys, consider re-running **Stage 7D** instead of patching individual pages — it is idempotent and regenerates from current PRD state.

## Critical Rules

1. never implement feedback that contradicts a BRD business rule without explicit spec-updater resolution first.
2. never modify a spec without updating all cross-references (traceability links, related specs).
3. always defer feedback requiring architectural changes to a separate Stage 5 re-run.
4. always run the full test suite after code changes (use commands from CLAUDE.md).
5. always update i18n message files when changing user-facing text. Before committing, check `./plancasting/tech-stack.md` for the i18n configuration section. Locate the message file directory (e.g., `src/i18n/`, `locales/`, `translations/`) and update all affected message keys. If i18n is not configured, skip and document in your report.
6. Split large batches into multiple runs. In each run, process at most the number of APPROVED items specified in tech-stack.md § Model Specifications "Feedback batch limit". Mark remaining items as 'DEFERRED — Next batch' in `change-plan.md`. Split by priority tier (all P0 items first, then P1, etc.) or by affected feature cluster.
7. After implementing UI changes, must re-run Stage 6V before redeployment to verify visual correctness — this is a requirement, not a recommendation. Re-test ONLY the scenarios affected by the feedback changes (filter the 6V scenario matrix by the modified feature IDs), not the full matrix. Use `prompt_visual_functional_verification.md` with this additional instruction on the first line: "SCOPE: Re-verify only scenarios for features [FEAT-IDs] modified by feedback batch [date]."
8. After deploying feedback-driven changes, run Stage 7V (Production Smoke Verification) to verify production correctness.
9. never skip the traceability chain — every code change must trace to a spec change or an existing spec.
10. If conflicting feedback items are found, resolve the conflict BEFORE implementing either side.
11. If deploying feedback-driven changes causes production failures, revert the commit (using `git revert`, not `git reset --hard`) and re-run Stage 7V to verify the rollback. Investigate the failure before re-attempting.
12. never run Stage 8 and Stage 9 concurrently. Complete one and commit before starting the other. Both stages modify `package.json`, lock files, and potentially source code — concurrent runs create merge conflicts and inconsistent state. The `/` in the pipeline diagram means 'run both, but one at a time, never concurrently': run Stage 8 first, commit all changes, then run Stage 9 (or vice versa). They share the codebase and could create merge conflicts if run simultaneously.
````
