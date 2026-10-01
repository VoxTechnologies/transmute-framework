---
description: Template for backend rules — argument validation, error handling, auth guards, query filtering, and index usage for the backend framework.
paths: ["[BACKEND_DIR]/**"]
---

# Backend Rules

> **This is a template.** Stage 3 (Scaffold Generation) reads this template and generates `.claude/rules/backend.md` with actual project values. Stage 3 must: (1) replace ALL `[BRACKETED]` placeholder markers (e.g., `[BACKEND_DIR]`, `[BACKEND_FRAMEWORK]`, `[ERROR_TYPE]` (cross-template: must match `.claude/rules/auth.md`), `[AUTH_HELPER]` (cross-template: must match `.claude/rules/auth.md`), `[VALIDATOR_SYSTEM]`, `[SOFT_DELETE_FIELD]` (cross-template: must match `.claude/rules/data-model.md`), `[TENANT_ID_FIELD]` (cross-template: must match `.claude/rules/data-model.md`)), (2) replace each `<!-- TODO -->` HTML comment with a proper `<!-- Source: Stage 3 | Evidence: [ref] | Confidence: HIGH -->` annotation (`// TODO:` inside code blocks are code example placeholders — replace those with actual code patterns), (3) update the `paths` patterns in frontmatter with actual project paths, and (4) remove ALL other HTML comments (e.g., `<!-- Stage 3: ... -->`, `<!-- Paths note: ... -->`, `<!-- Note: ... -->`) — these are template-only guidance that must not appear in generated rule files. Stage 4 confirms replacements are complete. After Stage 3 renders this template, verify no placeholders remain: `grep -nE '\[[A-Z_]+\]' .claude/rules/backend.md` — the output should be empty (all `[BRACKETED]` markers replaced with actual values). **Rule count limit**: The rendered output must contain ≤ 15 rules (individual bullet-point directives). This template contains ~15 baseline rules — Stage 3 has room for at most 2 additional stack-specific rules before splitting is required. This template contains conditional sections — omit sections that don't apply to the selected tech stack. If the rendered output exceeds 15 rules after omitting inapplicable sections, split into two rule files (e.g., `backend.md` → `backend.md` + `backend-queries.md`) and update CLAUDE.md Part 2 § Path-Scoped Rules accordingly. Do not edit this template directly — edit the generated `.claude/rules/backend.md` instead.

## Validation

<!-- TODO: Stage 3 — replace with actual validation pattern for [BACKEND_FRAMEWORK]. Source: tech-stack.md | Confidence: HIGH -->

<!-- Valid values: e.g., "Zod", "Valibot", "io-ts", "Convex v.object()", "Drizzle createInsertSchema()" -->
- Always validate arguments using `[VALIDATOR_SYSTEM]` before any business logic — define argument schemas in the same file as the function, not inline within the function body.
- Validate at the boundary (mutation/action entry point), not deep inside helpers.

```typescript
// TODO: Replace with actual validation pattern for [BACKEND_FRAMEWORK]
// Example:
// args: { title: v.string(), priority: v.union(v.literal("P0"), v.literal("P1")) }
```

## Error Handling

<!-- TODO: Stage 3 — replace with actual error type. Source: tech-stack.md | Confidence: HIGH -->

- Use `[ERROR_TYPE]` for all user-facing errors — never throw raw strings; include an error code and a human-readable message in every error.
- Log internal errors with context (function name, sanitized arguments — exclude credentials, tokens, passwords, and PII) before re-throwing — never expose internal stack traces or database details in error responses.

```typescript
// TODO: Replace with actual error pattern
// throw new [ERROR_TYPE]({ code: "NOT_FOUND", message: "Task not found" });
```

## Auth Guards

<!-- TODO: Stage 3 — replace with actual auth helper. Source: tech-stack.md | Confidence: HIGH -->

- Every mutation and action must call `[AUTH_HELPER]` as the first operation — never skip auth checks, even for "internal" functions.
- Store the authenticated user identity in a local variable and pass it explicitly to helpers.
- See `.claude/rules/auth.md` § Auth Guards for the complete auth pattern including middleware vs. backend scope.

```typescript
// TODO: Replace with actual auth guard pattern
// const identity = await [AUTH_HELPER](ctx);
// if (!identity) throw new [ERROR_TYPE]({ code: "UNAUTHENTICATED" });
```

## Query Filters

<!-- TODO: Stage 3 — replace with actual soft-delete field and filter pattern. Source: data-model schema | Confidence: HIGH -->

- Always apply soft-delete filter (`[SOFT_DELETE_FIELD] === null` or equivalent) on all queries (see `.claude/rules/data-model.md` § Soft Delete for field name and retention period).
- Never return soft-deleted records to the frontend unless explicitly requested by an admin view.
- Apply tenant isolation filters (org/workspace scoping) on every query — filter by `[TENANT_ID_FIELD]` (see `.claude/rules/data-model.md` § Tenant Isolation for the field name).

## Index Usage

<!-- TODO: Stage 3 — replace with actual index usage pattern. Source: tech-stack.md | Confidence: HIGH -->

- Prefer indexed queries over full-table scans for any collection with >100 expected records.
- Every query pattern must have a supporting index — see `.claude/rules/data-model.md` § Indexes for definition patterns and conventions.
- When adding a new query pattern, add the supporting index in the same commit.

## Environment Variables

<!-- TODO: Stage 3 — replace with actual env var access pattern. Source: tech-stack.md | Confidence: HIGH -->

<!-- If backend uses a different config location (e.g., Convex uses convex.json for some settings), document the actual location here -->
- Reference env var names exactly as defined in `.env.local.example` — never invent alternative names (e.g., using `DATABASE_URL` when `.env.local.example` defines `CONVEX_URL` causes silent empty-string reads at runtime).
- Never log, return, or expose env var values in API responses or error messages — use non-revealing checks (e.g., `!!process.env.KEY`) for validation.
- **Credential verification**: After setting auth provider credentials (API keys, client IDs, client secrets) in environment variables, verify them by making a lightweight API call (e.g., list users, get account info) to confirm the credentials are valid and match the intended environment (staging vs production). Character-level typos in credential values (e.g., `Q` vs `0`) cause cryptic "invalid client" errors that are difficult to diagnose.
