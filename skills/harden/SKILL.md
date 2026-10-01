---
name: harden
description: >-
  Hardens error handling, network failure recovery, and edge case resilience across the product.
  This skill should be used when the user asks to "harden error handling",
  "add resilience", "handle network failures", "add retry logic",
  "add circuit breakers", "handle edge cases", or "improve error recovery"
  — or when the transmute-pipeline agent reaches Stage 6G of the pipeline.
metadata:
  version: 1.0.0
effort: medium
---

# Stage 6G: Error Handling, Network Failures, and Edge Cases

Read the detailed guide at `${CLAUDE_SKILL_DIR}/references/harden-detailed-guide.md` for the complete hardening procedures, teammate spawn prompts, error pattern catalogs, and report templates.

Lead a multi-agent error resilience hardening project. Systematically review the COMPLETE product for error handling gaps, network failure scenarios, race conditions, and edge cases that individual feature implementations may have missed.

**Stage Sequence** (recommended ordering): Stage 5B → 6A/6B/6C (parallel) → 6E (Code Refactoring) → 6F (Seed Data) → **6G (this stage)** → 6D (Documentation) → 6H (Pre-Launch) → 6V → 6R → 6P/6P-R → 7 (Deploy)

## Rate Limiting Scope Boundary (6A vs 6G)

> **Cross-stage coordination**: Before implementing data-mutation rate limiting, read `./plancasting/_audits/security/report.md` from Stage 6A to verify which endpoints are already rate-limited (auth endpoints). Implement only DATA-MUTATION rate limiting here — auth endpoint rate limiting was handled in 6A.

Stage 6A implements rate limiting for **AUTH endpoints** (login, signup, password reset, forgot password / password reset initiation, MFA, session management, password change, email verification, invitation acceptance). Stage 6G (this stage) implements rate limiting for **DATA-MUTATION endpoints** (create, update, delete operations, file uploads, user profile updates). Verify 6A's auth-endpoint rate limiting before implementing to avoid duplication.

## Prerequisites

**Prerequisite**: Stage 6E must have completed before 6G starts — 6G depends on refactored error handling patterns from 6E. Do not run 6E and 6G in parallel.

Verify before starting:

1. `./plancasting/_audits/implementation-completeness/report.md` exists with PASS or CONDITIONAL PASS. If missing, STOP: "Stage 5B report not found — do not harden code with unverified implementation completeness."
2. If 5B shows FAIL, STOP. If CONDITIONAL PASS, review Category C issues and proceed with awareness.
3. `./plancasting/_audits/refactoring/report.md` (6E) exists. If missing, WARN: "Stage 6E not completed. 6G is RECOMMENDED after 6E for cleaner error handling patterns." If present, read the "Extracted Error Handling Patterns for Stage 6G" section to reuse existing patterns rather than creating duplicates.
4. Read `./CLAUDE.md` and `./plancasting/tech-stack.md` for project conventions.
5. If `./plancasting/_audits/security/report.md` (6A) is available, include in teammate prompts for rate limiting scope boundaries. If missing, WARN and implement data-mutation rate limiting regardless.

Check `./plancasting/tech-stack.md` for the `Session Language` setting. Generate all reports in that language. Code and file names remain in English. Replace all command references with the project's package manager from `CLAUDE.md`.

## Stack Adaptation

Source examples use Convex + Next.js. Adapt all paths and patterns to the actual tech stack: `convex/` becomes your backend directory, Convex OCC becomes your concurrency control, `src/app/` becomes your frontend pages, auto-generated directories (e.g., `convex/_generated/`, `prisma/generated/`) should never be edited.

## Known Failure Patterns

1. **Retry on non-idempotent operations**: Causes duplicate data. always verify idempotency before adding retries. Also beware: incrementing counters, appending to logs, sending notifications are not idempotent even with 'set' operations.
2. **Permanently open circuit breakers**: Never reset after transient outage. always include a reset mechanism (time-based or health-check-based). States: CLOSED -> OPEN (after 5 consecutive failures) -> HALF-OPEN (after 60s cooldown, allow one probe request) -> success: CLOSED, failure: OPEN.
3. **Error boundaries that lose state**: Form data lost when boundary catches error. always preserve user input.
4. **Over-aggressive timeouts**: 3-second timeouts on 10+ second operations. Match timeouts to actual characteristics.
5. **Silent error swallowing**: Errors caught but logged silently. Every caught error must be re-thrown, logged with context, or communicated to the user.
6. **Graceful degradation that hides features**: Show degraded state with explanation, not blank space.
7. **Over-broad idempotency keys**: Adding idempotency keys to operations that should not be retried (one-time deletions, irreversible actions). Distinguish between "safe to retry" (create/update) and "unsafe to retry" (delete, decrement, send).

## Phase 1: Lead Analysis and Planning

Complete BEFORE spawning teammates:

1. Read `./CLAUDE.md`, `./plancasting/tech-stack.md`, BRD non-functional requirements, and PRD `15-non-functional-specifications.md`. Read `./plancasting/_audits/performance/report.md` if it exists for timeout baselines.
2. **Rate limiting scope verification**: If `./plancasting/_audits/security/report.md` exists (6A), create a scope boundary table in `./plancasting/_audits/resilience/plan.md` listing: (a) all endpoints already rate-limited by 6A (auth-tier), (b) all data-mutation endpoints where 6G will add rate limiting. Flag overlaps or gaps.
3. Map all external dependencies: third-party APIs, auth provider, file storage, email service, other services from `plancasting/tech-stack.md`.
4. Identify all multi-step operations (workflows involving multiple mutations/actions in sequence).
5. If `./plancasting/_audits/refactoring/report.md` exists (6E), identify shared error handling patterns/utilities that 6E extracted. List them in the plan. Instruct teammates to USE these patterns rather than creating new ones.
6. Create `./plancasting/_audits/resilience/plan.md` with analysis and task assignments.
7. Decide execution order: parallel (default, low-risk API changes) or sequential (if high-risk API contract changes — spawn Teammate 1 first, then 2+3). High-risk = error response shapes fundamentally change, new required error codes on 5+ endpoints, mutation return types change.

## Phase 2: Spawn Hardening Teammates

**Shared Context — Idempotency Classification**: A mutation that increments a counter, appends to a log, or sends a notification is not idempotent even if it uses a 'set' operation — the side effect accumulates on retry. All teammates must classify mutations before adding retry logic.

### Teammate 1: "backend-resilience"

Scope: Backend error handling, external service failures, data consistency.

Tasks:

1. **External service failure handling**: For each external API call, verify try/catch, timeout configuration.
   - **Timeout baselines**: fast API calls: 3-5s; file operations: 30s; AI model calls: 60-120s; long-running workflows: per business SLA. Use measured latencies from performance report + 50% buffer if available.
   - **Retry with exponential backoff**: For transient failures (network errors, 5xx, 429). Formula: delay = min(2^attempt x 1000ms, 30000ms) + random(0, 1000ms) jitter, where attempt starts at 1. Retry 1: ~2-3s, retry 2: ~4-5s, retry 3: ~8-9s, then stop. For 429 responses, honor `Retry-After` header (both seconds-value and HTTP-date formats per RFC 7231, capped at 30s).
   - **For backend mutations**: Verify idempotency FIRST. Only add automatic retries for idempotent mutations. Non-idempotent mutations must surface errors to the user with manual retry option.
   - **Circuit breaker decision**: For serverless environments, use retry-with-exponential-backoff alone (recommended default). Only implement full circuit breakers if: long-running servers with persistent state, or specific external service has frequent prolonged outages. Circuit breakers on QUERY paths: return cached/fallback data. On mutation paths: return graceful error (NOT cached data). In serverless, persist state via database or key-value store.
   - Verify user receives meaningful error messages. Verify graceful degradation.

2. **Multi-step operation safety**: Verify failure at step N does not leave inconsistent state. Implement idempotency where appropriate. For long-running workflows (Convex Workflows, Step Functions, Temporal, Inngest): verify step retry, explicit timeouts on event-wait calls, idempotency keys, progress checkpoints, compensation logic, persistent workflow state. Document test procedures for kill-and-resume scenarios.

3. **Data validation hardening**: Verify business rule violations throw clear typed errors. Handle concurrent modification with retry prompts. Add stale-data validation for check-then-act patterns.

4. **Rate limiting for data-mutation endpoints**: Check 6A report first. Implement DATA-MUTATION rate limiting only. Verify file uploads have server-side size limits.

**Making non-idempotent mutations safe**: Identify natural deduplication key, add `idempotencyKey` parameter, check existence before inserting, return existing record if duplicate. If no natural key exists, do not add automatic retry.

**API contract changes**: Document with before/after examples. Lead reconciles in Phase 3.

If an issue requires architectural changes, document in `plancasting/_audits/resilience/unfixable-violations-backend.md` and continue.

### Teammate 2: "frontend-resilience"

Scope: UI error states, network failure UX, offline behavior.

Tasks:

1. **Error boundary completeness**: Every route has an error boundary with user-friendly message and "try again" action. Nested boundaries for independent page sections.
2. **Network failure UX**: Every mutation has error handling. User sees feedback on failure. Retry mechanism exists. Form data preserved on submission failure.
3. **Loading and timeout states**: All queries show loading state. Timeout handling after 10 seconds with retry option. Adapt to data layer (REST: AbortController, reactive backends: check undefined for 10+ seconds). Safe navigation during loading (no unmount errors).
4. **Backend connection resilience**: Graceful handling of connection loss with "reconnecting" indicator. Automatic recovery on reconnection. No data loss during disconnection.
5. **Optimistic update rollback**: Verify rollback works. User notified on failure. No UI flash (optimistic -> rollback -> error). Verify via: (1) unit test hook rollback logic, (2) E2E test complete flow, (3) manually verify no layout shift.

If an issue requires architectural changes, document in `plancasting/_audits/resilience/unfixable-violations-frontend.md` and continue.

### Teammate 3: "edge-case-hardener"

Scope: Cross-cutting edge cases, concurrent usage, boundary conditions.

Tasks:

1. **Concurrent usage**: Two users editing same entity (handle concurrency rejection gracefully). User viewing entity that another soft-deletes (show deleted state, redirect, or disable actions). Permission changes during active usage.
2. **Empty and boundary conditions**: 0 items, 1 item (singular/plural), maximum items (pagination), max-length text (truncation/overflow), negative/zero/large numbers, timezone handling.
3. **Authentication edge cases**: Session expiry mid-operation. Logout in another tab. Deep links with unauthenticated users (redirect to login, then back). Invitation flow edge cases (expired invites, registered emails).
4. **Navigation edge cases**: Back/forward navigation preserving state. Direct URL access (deep linking). Unsaved changes confirmation. 404 for invalid routes and entity IDs.
5. **E2E resilience tests**: Write tests in `e2e/resilience/` directory (create if needed, follow Playwright config conventions). Focus on data loss and user confusion scenarios.

If an issue requires architectural changes, document in `plancasting/_audits/resilience/unfixable-violations-edge-cases.md` and continue.

## Phase 3: Post-Completion Reconciliation

After all teammates complete:
- Review cross-team findings and reconcile (retry logic needs UI feedback, concurrent edit scenarios need server-side resolution).
- Resolve shared-file conflicts.
- Merge per-teammate unfixable-violations files into `plancasting/_audits/resilience/unfixable-violations.md`. Include each under a subsection header (e.g., '## Backend Resilience Gaps'). Remove duplicate entries. Delete per-teammate files.

## Phase 4: Verification and Report

1. Run full test suite:
   ```bash
   bun run typecheck
   bun run lint
   bun run build
   bun run test
   bun run test:e2e
   ```
   All existing tests must pass. New resilience tests must also pass.

2. Generate `./plancasting/_audits/resilience/report.md` with:
   - External service failure handling patterns implemented
   - Multi-step operation safety measures
   - UI error handling improvements
   - Edge cases addressed
   - New E2E tests added (in `e2e/resilience/`)
   - Remaining risks and recommendations
   - Reference to `unfixable-violations.md` under Blocking Issues (if any exist)

## Gate Decision

Include under a `## Gate Decision` heading (6H parses this heading):

- **PASS**: All external calls have error handling and retry/circuit breaker patterns; all multi-step operations have consistency guarantees; new resilience tests pass.
- **CONDITIONAL PASS**: Core features (P0/P1) are resilient; non-critical features (P2/P3) have documented gaps.
- **FAIL**: Critical user flows lack error handling; multi-step operations can leave data inconsistent.

## Phase 5: Shutdown

Request shutdown for all teammates. Verify all modifications are saved and committed.

## Critical Rules

1. never add retry logic to non-idempotent mutations — fix idempotency first.
2. never swallow errors silently — re-throw, log with context, or communicate to user.
3. never add circuit breakers without a reset mechanism (time-based or health-check-based).
4. Retry backoff must use exponential backoff with jitter: delay = min(2^attempt x 1000ms, 30000ms) + random(0, 1000ms). Maximum 3 retries. Maximum delay cap: 30s.
5. always preserve user input across error recovery.
6. always run the full test suite after resilience changes.
7. Match timeout values to actual operation characteristics — file uploads and AI operations need longer timeouts.
8. Reference Stage 5B output to avoid hardening incomplete features.
9. For long-running workflows: verify step failure handling, timeout handling, and resume-from-failure capability.
10. Rate limiting scope: 6G = data-mutation endpoints ONLY. Auth endpoints are 6A's responsibility.
