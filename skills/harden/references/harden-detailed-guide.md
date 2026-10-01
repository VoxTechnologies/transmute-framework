# Transmute — Error Resilience Hardening

## Stage 6G: Error Handling, Network Failures, and Edge Cases

````text
You are a senior reliability engineer acting as the TEAM LEAD for a multi-agent error resilience hardening project using Claude Code Agent Teams. Your task is to systematically review the COMPLETE product for error handling gaps, network failure scenarios, race conditions, and edge cases that individual feature implementations may have missed.

**Stage Sequence**: Stage 5B → 6A/6B/6C (parallel) → 6E (Code Refactoring) → 6F (Seed Data) → **6G (this stage)** → 6D (Documentation) → 6H (Pre-Launch) → 6V → 6R → 6P/6P-R → 7 (Deploy)

## Why This Stage Exists

The Feature Orchestrator implements error handling per-feature, but certain failure modes are cross-cutting and only become visible when reviewing the product holistically:
- Network failures during multi-step operations (what if the network drops between step 2 and step 3?)
- Race conditions from concurrent backend reactive updates (e.g., Convex OCC conflicts, database transaction conflicts)
- Graceful degradation when external services are unavailable
- Retry and recovery patterns that should be consistent across all features
- User experience during errors (are all errors communicated clearly and actionably?)

## Known Failure Patterns

Based on observed resilience hardening outcomes:

1. **Retry on non-idempotent operations**: Agent adds retry logic to mutations that create records, causing duplicate data. always verify idempotency before adding retries.
2. **Permanently open circuit breakers**: Agent adds circuit breakers that never reset, permanently disabling a feature after a transient outage. always include a reset mechanism (time-based or health-check-based).
3. **Error boundaries that lose state**: Agent wraps forms in error boundaries, but when the boundary catches an error, the user loses all entered data. always preserve user input across error recovery.
4. **Over-aggressive timeouts**: Setting 3-second timeouts on operations that legitimately take 10+ seconds (file uploads, AI pipeline steps). Match timeouts to actual operation characteristics.
5. **Silent error swallowing**: Agent catches errors but logs them silently without user notification. Every caught error must either be re-thrown, logged with context, or communicated to the user.
6. **Graceful degradation that hides features**: Instead of showing a degraded experience, agent hides the entire feature. Show degraded state with an explanation, not a blank space.
7. **Over-broad idempotency keys**: Teammate adds idempotency keys to operations that shouldn't be retried (e.g., one-time deletions, irreversible actions like sending notifications). always distinguish between "safe to retry" (create/update mutations) and "unsafe to retry" (delete, decrement, send). Only add idempotency keys to create/update mutations.

## Rate Limiting Scope Boundary (6A ↔ 6G)

<!-- NOTE: This boundary definition is mirrored in `prompt_audit_security.md` (6A). Changes must be synchronized between both files. -->

> **Cross-stage coordination**: Before implementing data-mutation rate limiting, read `./plancasting/_audits/security/report.md` from Stage 6A to verify which endpoints are already rate-limited (auth endpoints). Implement only DATA-MUTATION rate limiting here — auth endpoint rate limiting was handled in 6A.

Stage 6A implements rate limiting for **AUTH endpoints** (login, signup, password reset, MFA, session management, password change, email verification, invitation acceptance). Stage 6G (this stage) implements rate limiting for **DATA-MUTATION endpoints** (create, update, delete operations, file uploads, user profile updates). If `./plancasting/_audits/security/report.md` exists, verify 6A's auth-endpoint rate limiting before implementing 6G's data-mutation rate limiting to avoid duplication. See execution-guide.md § "6A. Security Audit" for the complete boundary definition.

**Edge case classifications** (mirrors Stage 6A's classification — both stages must agree on scope):
- PASSWORD CHANGE (user changing their own password): AUTH endpoint — Stage 6A (not 6G)
- FORGOT PASSWORD / PASSWORD RESET INITIATION (sends reset email): AUTH endpoint — Stage 6A (not 6G)
- USER PROFILE UPDATE (email, name, preferences): DATA-MUTATION — **Stage 6G** (this stage)
- EMAIL VERIFICATION (re-send verification email): AUTH endpoint — Stage 6A (not 6G)
- MFA DEVICE MANAGEMENT (add/remove MFA devices): AUTH endpoint — Stage 6A (not 6G)
- INVITATION ACCEPTANCE (creates org membership + establishes auth session): AUTH endpoint — Stage 6A (not 6G)
- ACCOUNT LINKING (connects external auth provider + updates profile): AUTH endpoint — Stage 6A (not 6G)
- SIGNUP (creates user record + authenticates): AUTH endpoint — Stage 6A (not 6G)
- LOGOUT / SESSION REVOCATION (terminates auth session): AUTH endpoint — Stage 6A (not 6G)
- TOKEN REFRESH (renews authentication token): AUTH endpoint — Stage 6A (not 6G)
- FILE UPLOADS (user-initiated uploads, avatar changes): DATA-MUTATION — **Stage 6G** (this stage)
- BULK OPERATIONS (batch create/update/delete): DATA-MUTATION — **Stage 6G** (this stage)

## Prerequisites

**Prerequisite**: Stage 6E must have completed before 6G starts — 6G depends on refactored error handling patterns from 6E. Do not run 6E and 6G in parallel.

This stage runs AFTER Stage 6E (Code Refactoring) — per CLAUDE.md Stage 6 ordering, resilience hardening should follow refactoring for cleaner error handling patterns. Before beginning:
1. Verify `./plancasting/_audits/implementation-completeness/report.md` exists and shows a PASS or CONDITIONAL PASS gate decision. If the file does not exist, STOP: "Stage 5B report not found — run Stage 5B before starting Stage 6 audits. Do not harden code with unverified implementation completeness."
2. If 5B shows FAIL (FAIL-RETRY or FAIL-ESCALATE — see execution-guide.md § "Gate Decision Outcomes" for definitions), STOP — re-run Stage 5/5B until PASS or CONDITIONAL PASS before resilience hardening. If CONDITIONAL PASS, review the documented Category C issues — proceed with awareness of known gaps. Do not harden features with Category C status — their implementation may change during re-implementation.
3. Verify `./plancasting/_audits/refactoring/report.md` exists (Stage 6E output). If missing, STOP: "Stage 6E (Code Refactoring) has not been completed. Stage 6G must run after 6E per CLAUDE.md mandatory ordering. Run 6E first, then restart 6G." If it exists, read it — especially the "Extracted Error Handling Patterns for Stage 6G" section (if present) — to reuse extracted error handling utilities rather than creating new ones.
4. Verify `./plancasting/_audits/performance/report.md` exists (Stage 6C output — per CLAUDE.md ordering, 6C runs before 6G). If missing, WARN and use generic timeout baselines from the relevant BRD file. Search with `grep -rl 'availability\|reliability\|non-functional' ./plancasting/brd/` to find the relevant BRD file. Common location: `08-non-functional-requirements.md` (file number may vary by project).
5. Read `./CLAUDE.md` and `./plancasting/tech-stack.md` for project conventions
6. Read `./plancasting/_audits/security/report.md` — 6A SHOULD be complete before 6G starts (6A runs in parallel with 6B/6C, all before 6E/6F/6G). Include the 6A report in all teammate spawn prompts so teammates can verify rate limiting scope boundaries and avoid duplicating 6A's auth-endpoint rate limiting. If the report is missing, WARN: "Stage 6A not completed — rate limiting scope boundaries cannot be verified. Proceed with caution: Teammate 1 should implement rate limiting for data-mutation endpoints only, assuming 6A will handle auth endpoints." Include this warning in the final report.

## Input

- **Codebase**: Your backend directory (e.g., `./convex/`) and frontend directory (e.g., `./src/`) — adapt paths per `plancasting/tech-stack.md`
- **Tech Stack**: `./plancasting/tech-stack.md`
- **PRD**: `./plancasting/prd/` (especially interaction patterns, non-functional specs)
- **BRD**: `./plancasting/brd/` (availability and reliability requirements)
- **Project Rules**: `./CLAUDE.md`
- **Performance Report**: `./plancasting/_audits/performance/report.md` (Stage 6C output — must exist before 6G starts, since 6C runs in the parallel group before 6G). Extract measured latencies for each operation type to calibrate timeout values and retry configurations. If this file does not exist, WARN: "Stage 6C (Performance Optimization) has not completed. Timeout values will use generic baselines instead of measured latencies — recalibrate after 6C completes."

**Language**: Check `./plancasting/tech-stack.md` for the `Session Language` setting. Generate all reports and user-facing output in the specified language. Code, technical identifiers, and file names remain in English.

## Stack Adaptation

The examples and file paths in this prompt use Convex + Next.js as the reference architecture. If your `plancasting/tech-stack.md` specifies a different stack, adapt all references accordingly:
- `convex/` → your backend directory
- `convex/schema.ts` → your schema/migration files
- Convex functions (query/mutation/action) → your backend functions/endpoints
- ConvexError → your error handling pattern
- `useQuery`/`useMutation` → your data fetching hooks
- `npx convex dev` → your backend dev command
- `src/app/` → your frontend pages directory
- Auto-generated directories: `convex/_generated/` → adapt to your backend's equivalent (e.g., `prisma/generated/`, `.next/`, `supabase/types/`). never edit files in auto-generated directories.
Always read `CLAUDE.md` Part 2 (Backend Rules, Frontend Rules) for your project's actual conventions.

**Package Manager**: Commands in this prompt use `bun run` as the default. Replace with your project's package manager as specified in `CLAUDE.md` (e.g., `npm run`, `pnpm run`, `yarn`).

## Output

Stage 6G generates:
- `./plancasting/_audits/resilience/report.md` — resilience audit report with gate decision
- `./plancasting/_audits/resilience/plan.md` — lead's analysis and task assignments
- `./plancasting/_audits/resilience/unfixable-violations.md` — merged from per-teammate unfixable violation files. Note: Per-teammate unfixable violation files (e.g., `unfixable-violations-backend.md`, `unfixable-violations-frontend.md`) are merged by the lead in Phase 3 into the single file above.
- Modified source files with error handling, retry logic, and edge case coverage

## Agent Team Architecture

### Phase 1: Lead Analysis & Planning

As the team lead, complete the following BEFORE spawning any teammates:

1. Ensure output directory exists: `mkdir -p ./plancasting/_audits/resilience`
2. Read `./CLAUDE.md`, `./plancasting/tech-stack.md`, and `./plancasting/prd/15-non-functional-specifications.md`. Search with `grep -rl 'availability\|reliability\|non-functional' ./plancasting/brd/` to find the relevant BRD file. Common location: `08-non-functional-requirements.md` (file number may vary by project). Read the BRD file for availability and reliability requirements. Read `./plancasting/_audits/performance/report.md` if it exists — use identified performance characteristics to inform timeout values and retry configurations.
3. **Rate limiting scope verification**: If `./plancasting/_audits/security/report.md` exists (Stage 6A output), read its rate limiting section and create a scope boundary table in `./plancasting/_audits/resilience/plan.md` listing: (a) all endpoints already rate-limited by 6A (auth-tier), (b) all data-mutation endpoints where 6G will add rate limiting. **Additionally, perform an independent scan** of all data-mutation endpoints in the codebase to verify 6A identified all gaps — do not rely solely on 6A's flagged gaps. If the independent scan finds endpoints 6A missed, add them to the resilience plan. Flag any overlaps or gaps for resolution before spawning teammates.
4. Map all external dependencies:
   - Third-party APIs called by your backend actions/functions (e.g., Convex actions, API routes, serverless functions)
   - Auth provider
   - File storage service
   - Email service
   - Any other external services from `plancasting/tech-stack.md`
5. Identify all multi-step operations (workflows that involve multiple mutations or actions in sequence).
6. If `./plancasting/_audits/refactoring/report.md` exists (Stage 6E output), identify shared error handling patterns, utilities, or helpers that 6E extracted (e.g., `handleApiError()`, `withRetry()`, shared validation helpers). List them in the resilience plan. Instruct all teammates to USE these existing patterns rather than creating new ones — 6E just eliminated duplication, and 6G should not reintroduce it.

7. Create `./plancasting/_audits/resilience/plan.md` with the analysis and task assignments.
8. Create a task list for all teammates with dependency tracking.

### Phase 2: Spawn Hardening Teammates

**Shared Context for All Teammates — Idempotency Classification**:
When evaluating mutations, classify them as either truly idempotent (safe to retry) or subtly non-idempotent (unsafe). A mutation that increments a counter, appends to a log, or sends a notification is not idempotent even if it uses a 'set' operation — the side effect accumulates on retry. All teammates must apply this classification when adding retry logic or error recovery to mutations.

Spawn the following 3 teammates.

**Execution Order Decision**:
Sequential execution required if: (a) API contract changes span both backend and frontend, (b) database schema modifications affect query patterns in other teammates' scope, or (c) shared middleware/config files are modified. Otherwise, default to parallel.
1. **Default (parallel)**: All 3 teammates run in parallel — use when the lead's Phase 1 analysis finds zero or low-risk API contract changes. If Teammate 1 discovers API contract changes during execution, they document changes in their completion message; the lead reconciles in Phase 3.
2. **Sequential (if HIGH-RISK API contract changes)**: If Phase 1 identifies high-risk API changes, spawn Teammate 1 first, then Teammates 2+3 in parallel after Teammate 1 completes. This avoids wasted frontend work on incompatible implementations. **HIGH-RISK API contract changes** include: error response shapes fundamentally change (e.g., from `{ error: string }` to `{ code, message, details }`), new required error codes added to 5+ endpoints, mutation return types change, or new input validation requirements added retroactively. If Phase 1 analysis identifies ANY of these, use Sequential order. Otherwise, use Default (parallel).
3. **Mid-execution escalation**: If Teammate 1 discovers critical API changes mid-execution that would invalidate Teammate 2's work, the lead notifies Teammate 2 immediately; less critical changes are reconciled in Phase 3.
4. Document the execution order decision and rationale in `./plancasting/_audits/resilience/plan.md`.

#### Teammate 1: "backend-resilience"
**Scope**: Backend error handling, external service failures, and data consistency

~~~
You are hardening backend resilience across the entire codebase.

Read CLAUDE.md first. Then read ./plancasting/_audits/resilience/plan.md.
Check `./plancasting/tech-stack.md` for the `Session Language` setting. Write all findings in that language.
Read `./plancasting/_audits/implementation-completeness/report.md` — skip hardening features marked as incomplete (Category C).
Read `./plancasting/_audits/security/report.md` to understand security changes already applied (especially rate limiting and auth hardening). **Rate limiting scope**: implement DATA-MUTATION endpoint rate limiting only — see the Rate Limiting Scope Boundary section above for the full 6A/6G boundary definition and edge-case classifications. If `./plancasting/_audits/security/report.md` does not exist (6A not yet complete), assume no auth rate limiting exists and implement data-mutation rate limiting only.

Your tasks:
1. EXTERNAL SERVICE FAILURE HANDLING: Scan all backend functions that call external APIs (e.g., Convex actions, API routes, serverless functions).
   For each external call:
   - Verify there is a try/catch with appropriate error handling.
   - Verify timeout is configured (not waiting indefinitely). **Timeout baselines**: fast API calls: 3–5s; file operations: 30s; AI model calls: 60–120s; long-running workflows: per business SLA. If `./plancasting/_audits/performance/report.md` exists, extract measured latencies for each operation type and use measured value + 50% buffer as the timeout. If `./plancasting/_audits/performance/report.md` does not exist (6C hasn't completed yet), use these generic baselines. After 6C completes, update timeout values based on measured p95 latencies from the performance report. Document this in the resilience report and re-visit timeout configuration after 6C completes if actual measured latencies differ significantly.
   - **For external API calls**: Implement retry logic with exponential backoff for transient failures (network errors, 5xx responses, and 429 rate limit responses). Configure: maximum 3 retries, delay = min(2^attempt × 1000ms, 30000ms) + random(0, 1000ms) jitter, where attempt starts at 1 — i.e., retry 1: ~2-3s, retry 2: ~4-5s, retry 3: ~8-9s, then stop. For 429 responses, honor the `Retry-After` header when present (parse both seconds-value and HTTP-date formats per RFC 7231) (capped at 30 seconds). **LLM calls**: a status-code retry policy is not enough — a Claude safety-classifier refusal is HTTP 200 with `stop_reason: "refusal"` and empty or partial `content`. Branch on `stop_reason` before parsing; a refusal is not retried on the same model (use server-side `fallbacks: "default"` or a graceful error), and a 400 is a request-shape bug, not a transient failure. See `.claude/rules/ai-provider.md` if present.
   - **For backend mutations**: Before adding retry logic, verify idempotency first (see Idempotency Note below for definitions and examples). Only add automatic retries for idempotent mutations; non-idempotent mutations must surface errors to the user with a manual retry option instead.
   - **Circuit breaker decision** (evaluate BEFORE implementing): In serverless environments (Convex actions, Lambda, Edge Functions), there is no persistent in-memory state between invocations. **Recommendation for most serverless products**: Use retry-with-exponential-backoff alone (option b below) — circuit breakers add complexity and state management overhead that rarely pays off in serverless architectures. Only implement full circuit breakers if the product uses long-running servers with persistent state, or if a specific external service has frequent, prolonged outages (>5 minutes).
     - **(a) Full circuit breaker** (long-running servers or frequent outages): States: CLOSED (normal) → OPEN (after 5 consecutive failures within a 5-minute sliding window, return cached/fallback response for 60-second cooldown) → HALF-OPEN (after cooldown, allow one probe request — success → CLOSED, failure → OPEN). In serverless, persist state via database table or key-value store (e.g., Convex table, Redis).
     - **(b) Retry-with-backoff only** (recommended default for serverless): The exponential backoff configured above provides sufficient resilience. No additional circuit state needed.
     - **(c) Fail fast** (non-critical features): Skip both circuit breakers and retries, surface errors to the user immediately. Choose when data integrity outweighs availability.
     Document the chosen approach for each external service.
   - Note: Circuit breakers apply differently by operation type. For QUERY paths: return cached or fallback data during cooldown. For ACTION/mutation paths: return a graceful error message (do not return cached data for mutations, as this would mask write failures). Circuit breakers are most effective on read-heavy paths with external dependencies.
   - Verify the user receives a meaningful error message, not a raw exception. Meaningful = (1) describes what went wrong in user terms (not technical terms), (2) suggests what the user can do (e.g., 'The server is temporarily unavailable. Please try again in a few moments.'), not a raw stack trace or exception name.
   - Verify the system degrades gracefully (e.g., if analytics service is down, the core feature still works).

2. MULTI-STEP OPERATION SAFETY: Identify all operations that involve multiple mutations or actions in sequence.
   See the Idempotency Note below before adding retry logic to multi-step operations.
   For each multi-step operation:
   - Verify that a failure at step N doesn't leave data in an inconsistent state.
   - Implement idempotency where appropriate (safe to retry without duplicate effects).
   - If full rollback isn't possible, ensure partial state is detectable and recoverable.
   - Document the failure mode and recovery procedure in a code comment.
   - **Long-running workflows**: If the project uses long-running workflows or step functions (e.g., Convex Workflows with `awaitEvent`, AWS Step Functions, Temporal, Inngest):
     - Verify workflow step failures are retried with exponential backoff
     - Set explicit timeouts for event-wait calls (don't rely on defaults)
     - Implement idempotency keys for retry safety
     - Add progress checkpoints to enable resume-from-failure
     - Implement compensation/cleanup logic for failed steps
     - Ensure workflow state is persisted so interrupted workflows can resume
     - Test: Document a test procedure for kill-and-resume scenarios in the resilience report, and if feasible, write an automated test that simulates process interruption

3. DATA VALIDATION HARDENING: Review all mutations.
   - Verify that business rule violations throw clear error messages using your backend's error type (e.g., `ConvexError`, custom `AppError`, HTTP error responses), not generic errors.
   - Verify that concurrent modification scenarios are handled (your backend's concurrency control — e.g., Convex OCC, database transactions, optimistic locking — handles this at the DB level, but the UI needs to handle retry prompts).
   - Add validation for data that could become stale between read and write (check-then-act patterns).

4. RATE LIMITING AND ABUSE PREVENTION:
   Before implementing rate limiting, check if Stage 6A already added it (read `./plancasting/_audits/security/report.md`). Implement DATA-MUTATION endpoint rate limiting only — see the Rate Limiting Scope Boundary section above for the full 6A/6G boundary and edge-case classifications.
   - Verify mutations that create data have rate limiting or throttling.
   - Verify file upload endpoints have size limits enforced server-side.

### API Contract Change Protocol

If a hardening fix changes the API contract (e.g., adding required fields, changing response shape, adding new error codes):
1. **Document the change** in the teammate's completion message with before/after examples
2. **Phase 3 reconciliation**: Since teammates run in parallel, API contract changes are reviewed and reconciled by the lead in Phase 3 integration. The lead applies any necessary frontend adjustments after both teammates complete, or re-spawns a targeted fix if the frontend teammate's work conflicts with the contract change.
3. **Update types**: If shared type definitions exist (e.g., in a `shared/` or `lib/types/` directory), update them as part of the backend fix — don't leave them for frontend to discover

### Idempotency Note for Retry Logic

(See 'Shared Context for All Teammates — Idempotency Classification' above for the full classification framework. The following are implementation guidelines specific to backend resilience:)

**Making non-idempotent mutations safe for retry**: If you find a non-idempotent INSERT mutation that should be retryable: (1) Identify a natural deduplication key (e.g., userId + projectName + timestamp for project creation), (2) Add an `idempotencyKey` parameter to the mutation, (3) Before inserting, check if a record with the same key already exists — if so, return the existing record instead of creating a duplicate, (4) Document the idempotency key composition in a code comment.
Example idempotency key: `const idempotencyKey = crypto.createHash('sha256').update([userId, projectId, taskTitle, timestamp].join('-')).digest('hex')` — reuse this key if retrying the same operation.

If a mutation cannot be made idempotent (no natural deduplication key exists), do not add automatic retry — instead, surface the error to the user with a manual retry option. For non-idempotent mutations inside multi-step operations, ensure the error is: (1) caught and logged with context, (2) communicated to the user with a clear description, (3) either rolled back or the state is marked as "needs manual recovery" with a retry button.

If you encounter a resilience issue that requires architectural changes beyond this stage's scope, do not attempt architectural redesigns. Document it in `plancasting/_audits/resilience/unfixable-violations-backend.md` and continue with other tasks.

When done, message the lead with: external calls hardened, multi-step operations secured, validation improvements, rate limits added, API contract changes (if any, with before/after).
~~~

#### Teammate 2: "frontend-resilience"
**Scope**: UI error states, network failure UX, and offline behavior

~~~
You are hardening frontend resilience across the entire codebase.

Read CLAUDE.md first. Then read ./plancasting/_audits/resilience/plan.md.
Check `./plancasting/tech-stack.md` for the `Session Language` setting. Write all findings in that language.
Read `./plancasting/_audits/implementation-completeness/report.md` — skip hardening features marked as incomplete (Category C).
Read `./plancasting/_audits/security/report.md` if available — 6A should be complete before 6G per the Stage 6 ordering (6A runs in parallel with 6B/6C, all before 6E/6F/6G) — understand any security changes affecting frontend error handling (CSP, CORS, etc.).

Your tasks:
1. ERROR BOUNDARY COMPLETENESS: Scan all pages and route segments.
   - Verify every route has an error.tsx (or your framework's error boundary equivalent) that catches unexpected errors.
   - Verify error boundaries display user-friendly messages with a "try again" action.
   - Verify error boundaries log the error for debugging (without exposing internals to the user).
   - Verify nested error boundaries exist for independent sections of the page (one failing widget shouldn't crash the entire page).

2. NETWORK FAILURE UX: Review all components that call mutations or actions.
   - Verify every mutation call has error handling (try/catch or error state from the hook).
   - Verify the user sees feedback when a mutation fails (not a silent failure).
   - Verify there's a retry mechanism for failed operations (manual "retry" button, or automatic retry with feedback).
   - Verify form data is preserved when submission fails (user doesn't have to re-enter everything).

3. LOADING AND TIMEOUT STATES:
   - Verify all queries show a loading state, not a blank screen or flash of content.
   - Add timeout handling: if a query exceeds its expected duration, show a "taking longer than expected" message with a retry option. Use calibrated timeout values from `./plancasting/_audits/performance/report.md` (if available) — set the timeout to 2× the measured p95 latency for each operation. If the performance report is unavailable, use 10 seconds as a conservative default. Adapt to your data layer: (a) REST/GraphQL: implement `AbortController` with timeout, (b) Reactive backends (Convex, Firebase, Supabase Realtime): check if the subscription has not returned data within the timeout window (e.g., `useQuery` returns `undefined` beyond the calibrated threshold), (c) For all: provide context-appropriate messaging.
   - Verify navigation during loading doesn't cause errors (component unmounts while query is pending).

4. BACKEND CONNECTION RESILIENCE: Review backend connection handling (e.g., Convex WebSocket, Supabase Realtime, Firebase listeners, REST API timeouts).
   - Verify the app handles backend connection loss gracefully (show a "reconnecting" indicator).
   - Verify the app recovers automatically when the connection is restored.
   - Verify no data is lost if the user performs actions while disconnected.

5. OPTIMISTIC UPDATE ROLLBACK:
   - For all optimistic updates in custom hooks, verify the rollback path works correctly.
   - Verify the user is notified when an optimistic update fails and is rolled back.
   - Verify the UI doesn't flash (show optimistic state → rollback → show error).
   Verify rollback by: (1) unit test the hook's rollback logic with error scenarios, (2) E2E test a complete optimistic update + rollback flow, (3) manually verify the UI doesn't visually flash (show optimistic state → rollback → show error instantly without layout shift).

If you encounter a resilience issue that requires architectural changes beyond this stage's scope, do not attempt architectural redesigns. Document it in `plancasting/_audits/resilience/unfixable-violations-frontend.md` and continue with other tasks.

When done, message the lead with: error boundaries added/fixed, network failure UX improvements, timeout handling added, reconnection handling verified.
~~~

#### Teammate 3: "edge-case-hardener"
**Scope**: Cross-cutting edge cases, concurrent usage, and boundary conditions

~~~
You are hardening edge case handling across the entire codebase.

Read CLAUDE.md first. Then read ./plancasting/_audits/resilience/plan.md.
Check `./plancasting/tech-stack.md` for the `Session Language` setting. Write all findings in that language.
Read `./plancasting/_audits/implementation-completeness/report.md` — skip hardening features marked as incomplete (Category C).
If your edge case scenarios involve browser-side error handling affected by security policies (CSP, CORS), consult `./plancasting/_audits/security/report.md`. Otherwise, skip the security report — it is primarily relevant to Teammate 2 (frontend-resilience).

Your tasks:
1. CONCURRENT USAGE SCENARIOS: Review features that multiple users can interact with simultaneously.
   - Verify what happens when two users edit the same entity at the same time (your backend's concurrency control will handle this — e.g., Convex OCC rejection, database transaction conflict, optimistic locking failure — verify the UI handles the rejection gracefully).
   - Verify what happens when a user is viewing an entity that another user soft-deletes (marks `deletedAt`). The UI should either: (1) show the deleted state with a notification, (2) redirect away from the deleted entity, or (3) disable further actions on it. Verify this for both the deleting user and other active viewers.
   - Verify what happens when a user's permissions change while they're using a feature.
   - Add appropriate UI handling for each scenario (notification, refresh prompt, redirect).

2. EMPTY AND BOUNDARY CONDITIONS: Systematic review of ALL components and functions.
   - Verify behavior with 0 items (empty lists, empty search results, empty dashboards).
   - Verify behavior with 1 item (singular vs plural text, single-item layouts).
   - Verify behavior with maximum items (pagination works, performance is acceptable).
   - Verify behavior with maximum-length text inputs (truncation, overflow, wrapping).
   - Verify number fields handle negative values, zero, and very large numbers correctly.
   - Verify date/time handling across timezones.

3. AUTHENTICATION EDGE CASES:
   - Verify behavior when a user's session expires mid-operation.
   - Verify behavior when a user is logged out in another tab.
   - Verify deep links work correctly when the user is not authenticated (redirect to login, then back to the intended page).
   - Verify invitation/onboarding flows handle edge cases (expired invites, already-registered emails).

4. NAVIGATION EDGE CASES:
   - Verify back/forward browser navigation doesn't break app state.
   - Verify direct URL access (deep linking) works for all routes.
   - Verify behavior when navigating away from unsaved changes (confirmation prompt).
   - Verify 404 pages work for invalid routes and invalid entity IDs.

5. Write E2E tests for the most critical edge cases found:
   - Add tests to `e2e/resilience/` directory. If the E2E test directory does not exist, create `e2e/resilience/` and follow the Playwright test conventions from `playwright.config.ts`.
   - Focus on scenarios that would cause data loss or user confusion if not handled.

If you encounter a resilience issue that requires architectural changes beyond this stage's scope, do not attempt architectural redesigns. Document it in `plancasting/_audits/resilience/unfixable-violations-edge-cases.md` and continue with other tasks.

When done, message the lead with: concurrent usage scenarios handled, boundary conditions fixed, auth edge cases fixed, navigation edge cases fixed, E2E tests added.
~~~

### Unfixable Violation Protocol

If a resilience issue requires architectural changes beyond this stage's scope (e.g., redesigning the data flow, adding a message queue), document it in the teammate's designated unfixable-violations file (`unfixable-violations-backend.md`, `unfixable-violations-frontend.md`, or `unfixable-violations-edge-cases.md` in `plancasting/_audits/resilience/`) with the issue description, root cause, and recommended architectural change. Do not attempt architectural redesigns during this stage. The lead merges these files in Phase 3.

### Phase 3: Post-Completion Review & Reconciliation

> **Note**: This phase describes what the lead does AFTER all teammates complete (post-hoc reconciliation), not during parallel execution. The lead reviews teammate outputs and applies cross-team adjustments.

After all teammates report completion:
1. Review completed work from the shared task list.
2. Facilitate cross-team findings:
   - If backend-resilience adds retry logic for a mutation → reconcile with frontend-resilience findings (the UI may need to show retry feedback).
   - If edge-case-hardener finds a concurrent edit scenario → reconcile with backend-resilience findings (may need server-side conflict resolution).
3. Resolve conflicts if multiple teammates modify the same file.
4. Merge per-teammate unfixable-violations files (`unfixable-violations-backend.md`, `unfixable-violations-frontend.md`, `unfixable-violations-edge-cases.md`) into a single `plancasting/_audits/resilience/unfixable-violations.md` if any exist. Merge by: (1) Creating the merged file. (2) Including each per-teammate file's contents under a subsection header (e.g., '## Backend Resilience Gaps'). (3) Removing duplicate entries if two teammates documented the same issue. (4) Deleting the original per-teammate files. (5) In `report.md`, reference only the merged file under a 'Blocking Issues' section.

### Phase 4: Verification & Report

After all teammates complete:

1. Run full test suite (use commands from CLAUDE.md):
   ~~~bash
   bun run typecheck
   bun run lint
   bun run build
   bun run test
   bun run test:e2e
   ~~~
   All existing tests must still pass. New resilience tests must also pass. The build must succeed — resilience changes that break production builds are caught here.

2. Generate `./plancasting/_audits/resilience/report.md`:
   - External service failure handling: services covered, patterns implemented (retry, circuit breaker, graceful degradation)
   - Multi-step operation safety: operations secured, consistency guarantees
   - UI error handling: error boundaries, network failure UX, timeout handling
   - Edge cases addressed: concurrent usage, boundary conditions, auth, navigation
   - New E2E tests added
   - Remaining risks and recommendations

   ## Gate Decision
   [PASS | CONDITIONAL PASS | FAIL]
   - **PASS**: All external service calls have error handling and retry/circuit breaker patterns; all multi-step operations have consistency guarantees; new resilience tests pass
   - **CONDITIONAL PASS**: Core features (P0/P1 per PRD feature priorities) are resilient; non-critical features (P2/P3) have documented gaps
   - **FAIL**: Critical user flows lack error handling; multi-step operations can leave data inconsistent
   Rationale: [brief explanation]

   (Use this exact `## Gate Decision` heading in the generated report — 6H parses this heading to extract gate decisions from all audit reports.)

3. Verify the merged `unfixable-violations.md` from Phase 3 step 4 is referenced from `report.md` under a 'Blocking Issues' section (if any unfixable issues exist).
4. Output summary: total improvements by category, new tests added, remaining risks.

### Phase 5: Shutdown

1. Commit all changes: `git add -A && git commit -m 'feat(resilience): Stage 6G error resilience hardening'` per CLAUDE.md git conventions.
2. Request shutdown for all teammates.
3. Verify all file modifications are saved.

## Critical Rules

1. never add retry logic to mutations that are not idempotent — fix idempotency first.
2. never swallow errors silently — every caught error must be re-thrown, logged, or communicated to the user.
3. never add circuit breakers without a corresponding reset mechanism (time-based or health-check-based).
4. Retry with exponential backoff (see Teammate 1 instructions for the canonical formula). Maximum retry count: 3. Maximum delay cap: 30s. Always include jitter to prevent synchronized retries from multiple clients.
5. always preserve user input across error recovery (forms, editors, multi-step wizards).
6. always run the full test suite after resilience changes.
7. Match timeout values to actual operation characteristics — file uploads and AI operations need longer timeouts.
8. Use the commands from CLAUDE.md for testing (e.g., `bun run test`).
9. Reference Stage 5B output to avoid hardening incomplete features.
10. If using long-running workflows or step functions (e.g., Convex Workflows, AWS Step Functions, Temporal, Inngest): verify workflow step failures are handled with proper retry/compensation logic and that event-wait calls (e.g., `awaitEvent`) have timeout handling.
11. Do not implement rate limiting on authentication endpoints (login, signup, password reset, MFA, session management) — these are Stage 6A's scope. Stage 6G handles DATA-MUTATION endpoints only. See Rate Limiting Scope Boundary section above.
````
