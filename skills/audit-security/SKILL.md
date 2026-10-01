---
name: audit-security
description: >-
  Performs a multi-agent security audit checking authentication, input validation, data exposure, and infrastructure.
  This skill should be used when the user asks to "audit security",
  "run a security review", "check for vulnerabilities", "security scan",
  "check auth", "find security issues", or "harden security",
  or when the transmute-pipeline agent reaches Stage 6A of the pipeline.
metadata:
  version: 1.0.0
effort: medium
---

# Security Audit — Stage 6A

Read the detailed guide at `${CLAUDE_SKILL_DIR}/references/audit-security-detailed-guide.md` for the complete audit procedures, teammate spawn prompts, vulnerability fix patterns, and report templates.

Lead a multi-agent security audit of the complete codebase against BRD security requirements and PRD security specifications. Identify vulnerabilities and fix them.

**Stage Sequence** (recommended ordering): Stage 5B → (**6A (this stage)** ‖ 6B ‖ 6C) → 6E → 6F → 6G → 6D → 6H → 6V → 6R → 6P/6P-R → 7 (Deploy). Note: 6A, 6B, and 6C run **in parallel** (each in a separate session). If running in parallel, commit 6A changes as soon as 6A completes to avoid config file conflicts — see CLAUDE.md § "Stage 6 ordering".

## Prerequisite Checks

Before any audit work, verify:

1. Check that `./plancasting/_audits/implementation-completeness/report.md` exists and shows PASS or CONDITIONAL PASS. If missing, STOP: 'Stage 5B report not found — run Stage 5B before starting Stage 6 audits. Proceeding without 5B wastes effort on incomplete code.' (Override: if the operator explicitly confirms 5B was intentionally skipped, proceed with a WARN in the report noting unverified implementation completeness.)
2. If 5B shows FAIL, STOP — the codebase has unresolved implementation gaps that must be fixed before security auditing. If CONDITIONAL PASS, note the documented Category C issues — skip security auditing for those incomplete features.
3. Read `./CLAUDE.md` and `./plancasting/tech-stack.md` for project conventions.
4. Read the relevant PRD sections for implementation context.

## Inputs

Read and reference these files throughout the audit:

- **Codebase**: Backend directory and `./src/` (adapt paths per tech stack)
- **Tech Stack**: `./plancasting/tech-stack.md`
- **Security Requirements**: `./plancasting/brd/13-security-requirements.md`
- **Compliance Requirements**: `./plancasting/brd/12-regulatory-and-compliance-requirements.md`
- **PRD Security Architecture**: `./plancasting/prd/10-system-architecture.md` (auth/authz section)
- **PRD API Specs**: `./plancasting/prd/12-api-specifications.md` (auth scheme, rate limiting)
- **Project Rules**: `./CLAUDE.md`

Check `./plancasting/tech-stack.md` for the `Session Language` setting. Generate all reports and user-facing output in that language. Keep code, technical identifiers, and file names in English.

## Stack Adaptation

Prompts reference Convex + Next.js as defaults. Adapt all paths and patterns to the actual stack in `plancasting/tech-stack.md`:
- `convex/` becomes your backend directory
- `convex/schema.ts` becomes your schema/migration files
- Convex functions become your backend functions/endpoints
- `src/app/` becomes your frontend pages directory

Read `CLAUDE.md` Part 2 (Backend Rules, Frontend Rules) for project-specific conventions.

**Package Manager**: Commands use `bun run` as default. Replace with your project's package manager as specified in `CLAUDE.md`.

## Known Failure Patterns

1. **Severity deflation**: Agent marks everything as "Medium" to avoid escalation. Use clear definitions: Critical = data breach possible without auth, High = privilege escalation possible, Medium = defense-in-depth gap, Low = best practice deviation.
2. **Symptom fixing**: Agent adds auth check to a function but doesn't notice the function is also exported publicly. Fix root cause, not symptoms.
3. **Regression from security fixes**: Agent adds auth check that breaks a legitimate unauthenticated flow. always verify fixes don't break existing tests.
4. **Skipping generated files' consumers**: Agent correctly skips `_generated/` but also skips files that import from `_generated/` — these may contain security-relevant code.
5. **Missing CORS/CSP checks**: Focusing only on code-level auth while ignoring HTTP-level security headers.
6. **Blind framework trust**: Agent assumes a framework handles security correctly without verification (e.g., 'Next.js handles CSRF'). always verify framework security defaults are actually enabled in configuration.
7. **Zero-day normalization**: Agent marks an unpatched CVE as 'acceptable risk' without documenting threat model justification. always document: 'We accept this risk because [mitigation] is in place.'

## Phase 1: Analysis and Planning

Complete these steps before spawning any teammates:

1. Read `./CLAUDE.md`, `./plancasting/tech-stack.md`, and all security/compliance requirements from BRD/PRD.
2. Build a **Security Checklist** mapping each BRD security requirement (SR-xxx) to specific code patterns to verify. For each entry include: (a) Scope — affected files/functions, (b) Check — what to verify, (c) Code pattern — correct implementation example, (d) Status — "Not checked yet".
3. Write `./plancasting/_audits/security/checklist.md` with the full checklist.
4. Create a task list for all teammates with dependency tracking.

**Scope Boundary — Rate Limiting**: See Teammate 4 for the 6A/6G rate limiting scope boundary.

## Phase 2: Spawn Audit Teammates

Spawn 4 parallel teammates. Each teammate's prompt must include the security checklist and instructions to read CLAUDE.md first.

### Teammate 1: auth-auditor

Scope: Authentication and authorization.

- Scan every exported backend function (excluding generated code). Verify auth checks are called where required. Flag mutations/actions modifying data without auth. Flag queries returning sensitive data without auth. Verify role/permission checks match BRD requirements.
- Check authorization logic for horizontal and vertical privilege escalation.
- Review middleware/route protection for completeness and role-based access.
- Adapt auth checks to the stack's auth pattern (session-based, JWT-based, or auth provider SDK). For JWT: verify JWKS endpoint security, `alg` whitelist (reject `alg: none`), audience/issuer validation, JWKS cache headers, token expiry validation.
- Fix each vulnerability with inline comment: `// SECURITY FIX: [description] — SR-xxx`

### Teammate 2: input-validation-auditor

Scope: Input validation and injection prevention.

- Verify ALL backend function arguments use proper validators. Flag overly permissive validators (e.g., `v.any()`). Verify string length constraints and typed ID validators.
- Scan form components for client-side validation consistency with server.
- Check for XSS vectors: unsafe innerHTML usage, unescaped user content, file upload validation.
- Fix each vulnerability found.

### Teammate 3: data-exposure-auditor

Scope: Data leakage and privacy.

- Flag queries returning entire documents when subsets suffice. Flag queries returning sensitive fields (email, phone, payment info) unnecessarily. Verify PII is not logged or exposed in error messages.
- Verify error messages do not leak internal details (stack traces, table names, query patterns).
- Check for sensitive data in localStorage/sessionStorage, hardcoded API keys, improperly prefixed env vars.
- Fix each issue found.

### Teammate 4: infrastructure-security-auditor

Scope: HTTP security headers, CORS, CSP, dependencies, rate limiting, audit logging.

- Verify Content-Security-Policy, HSTS, X-Frame-Options, X-Content-Type-Options, and Referrer-Policy.
- Check CORS configuration — flag `Access-Control-Allow-Origin: *`. Verify credentials mode is correctly configured.
- Run dependency vulnerability scan. For Bun projects: use `bunx audit-ci`, `npx better-npm-audit audit`, or `npx snyk test`. For npm/yarn: `npm audit`. For pnpm: `pnpm audit`. If none can be installed, document that scanning could not be performed and recommend manual review. Flag critical/high severity issues and known CVEs. Verify lock file integrity.
- **Rate Limiting — 6A/6G Scope Boundary**: Rate limiting for AUTH endpoints (login, signup, password reset, forgot password, MFA challenge/verify, token refresh, session management — logout, session revocation) is Stage 6A's responsibility — implement these now. Rate limiting for DATA-MUTATION endpoints (create, update, delete, file uploads) is Stage 6G's responsibility. Flag data-mutation rate limiting gaps for Stage 6G to implement.
  - **Edge case classifications**: Password change = AUTH (6A). User profile update = DATA-MUTATION (6G). Email verification re-send = AUTH (6A). MFA device management = AUTH (6A). Invitation acceptance = AUTH (6A). Account linking = AUTH (6A). Signup = AUTH (6A). Password-reset email send = AUTH (6A, auth flow).
  - If Stage 6G report already exists (`./plancasting/_audits/resilience/report.md`), verify no scope overlap. If ambiguous, flag as a decision point for the lead to reconcile.
- Verify security-sensitive operations are logged and logs contain no sensitive data.
- Fix each issue found.

## Unfixable Violation Protocol

When a violation cannot be fixed without architectural changes or would break another feature:

1. Document the full conflict with evidence (what the violation is, what fixing it would break).
2. Mark as **REQUIRES HUMAN DECISION** — do not attempt fixes that create regressions.
3. Include recommended approach and estimated effort.
4. If CRITICAL severity (e.g., architectural security flaw, missing encryption at rest, broken auth model): the audit must recommend NOT LAUNCHING until resolved. Document required architectural changes and estimated remediation scope. Record in `./plancasting/_audits/security/unfixable-violations.md` (separate file from `report.md`) AND summarize in the main `report.md` under a "Blocking Issues" section — critical violations block Stage 6H. Use these headings in the unfixable violations file: `### [Issue ID]`, `**Severity**: [CRITICAL/HIGH]`, `**Description**: [what the issue is]`, `**Evidence**: [code location and proof]`, `**Recommended Approach**: [how to fix with architectural changes]`, `**Estimated Effort**: [hours/days]`.
5. Continue with remaining fixable violations.

## Phase 3: Coordination

- Facilitate cross-team findings: auth gaps inform input-validation checks; PII exposure informs auth requirements; CSP gaps inform data-exposure risk; rate limiting gaps inform brute-force risk.
- Resolve file conflicts: first teammate to complete claims the file; second must re-read before applying changes. If both changes are in different functions/sections, both apply. If they touch the same code block, the lead decides — security correctness over team structure.

## Phase 4: Review and Report

1. Run the full test suite using commands from CLAUDE.md (e.g., `bun run typecheck`, `bun run lint`, `bun run build`, `bun run test`, `bun run test:e2e`). Fix any test failures caused by security changes.
2. If unfixable violations were documented, verify `./plancasting/_audits/security/unfixable-violations.md` exists and is referenced from report.md.

The `## Gate Decision` heading in the generated report is parsed by Stage 6H. Use this EXACT heading — do not rename or restructure it.

3. Generate `./plancasting/_audits/security/report.md` containing:
   - Executive summary
   - Vulnerabilities by category and severity (Critical/High/Medium/Low)
   - Fixes applied with code references
   - BRD security requirement compliance matrix (SR-xxx to Pass/Fail)
   - Infrastructure security results (HTTP headers, CORS, CSP, dependencies, rate limiting, audit logging)
   - **Data-Mutation Rate Limiting Gaps (for Stage 6G)**: List all data-mutation endpoints flagged by Teammate 4 that lack rate limiting. Format: `- [endpoint] ([reason])`. Stage 6G reads this section.
   - Remaining risks requiring human decision
   - Recommendations for ongoing security practices

   ## Gate Decision
   [PASS | CONDITIONAL PASS | FAIL]
   - **PASS**: All Critical and High severity vulnerabilities fixed; all tests pass; no unfixable blocking issues
   - **CONDITIONAL PASS**: All Critical fixed; remaining High issues documented with mitigations; Stage 6H review required
   - **FAIL**: Critical vulnerabilities remain unresolved; blocks Stage 6H

4. Output summary: total vulnerabilities found, total fixed, total requiring human review.

## Phase 5: Shutdown

1. Request shutdown for all teammates.
2. Verify all file modifications are saved and committed.

## Severity Definitions

Use these consistently — do not deflate:
- **Critical**: Data breach possible without authentication
- **High**: Privilege escalation possible
- **Medium**: Defense-in-depth gap
- **Low**: Best practice deviation

## Critical Rules

1. never mark a vulnerability as "acceptable risk" without documenting specific threat model justification.
2. never delete a security test to make the suite pass — fix the vulnerability instead.
3. never introduce new auth bypass patterns as part of a fix.
4. always run the full test suite after security changes — security fixes that break functionality are not fixes.
5. always verify custom API routes have CSRF protection for state-changing operations.
6. always check for secrets in git history: `git log --all -p -G "(sk-|sk_|Bearer |password=|PRIVATE KEY|AWS_SECRET|STRIPE_SECRET|DATABASE_URL=|-----BEGIN|api[_-]?key|client[_-]?secret)" --max-count=500`. For large repos add `--since='6 months ago'`. Use `-G` with regex alternation, NOT multiple `-S` flags (git only processes the last `-S` flag, silently ignoring earlier ones). If ANY secret is found, document as CRITICAL in `./plancasting/_audits/security/unfixable-violations.md` requiring immediate key rotation — secrets in git history cannot be fixed by code changes alone. This is a pipeline blocker: do not proceed to Stage 6H until key rotation is confirmed by the operator. Verify `.env.local.example` contains only placeholder values (no real API keys, no real passwords).
7. always verify SSRF blocklist: check all outbound `fetch()` or HTTP client calls triggered by user input. Reject private IP ranges (10.x, 172.16-31.x, 192.168.x), localhost (127.0.0.1, ::1), link-local (169.254.x, fe80::/10), IPv6 unique local (fc00::/7), and cloud metadata endpoints (169.254.169.254).
8. always verify rate limiting on auth endpoints. Flag data-mutation gaps for Stage 6G. See the 6A/6G scope boundary: 6A = auth-protecting endpoints; 6G = data-mutation endpoints. Do not implement data-mutation rate limiting in Stage 6A.
9. Use commands from CLAUDE.md for running tests.
10. Reference Stage 5B output to avoid auditing stub/incomplete features.
11. For safety-critical rules and pipeline-level security constraints, see CLAUDE.md § Pipeline Execution Guide → Safety-Critical Rules (or execution-guide.md if CLAUDE.md defers to it).
