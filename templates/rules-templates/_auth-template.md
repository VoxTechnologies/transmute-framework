---
description: Template for auth rules — middleware configuration, public route whitelisting, session handling, and role-based authorization.
paths: ["[AUTH_DIR]/**", "[MIDDLEWARE_PATH]"]
---

<!-- Cross-template sync: [ERROR_TYPE] must match .claude/rules/backend.md § Error Handling. [AUTH_HELPER] must match backend.md § Auth Guards. Verify after Stage 3 with: grep -nE '\[ERROR_TYPE\]|\[AUTH_HELPER\]' .claude/rules/*.md -->

# Auth Rules

> **This is a template.** Paths note: the first pattern matches the auth directory recursively, the second matches a single middleware file (e.g., `middleware.ts`). Stage 3 (Scaffold Generation) reads this template and generates `.claude/rules/auth.md` with actual project values. Stage 3 must: (1) replace ALL `[BRACKETED]` placeholder markers (e.g., `[AUTH_HELPER]`, `[AUTH_DIR]`, `[MIDDLEWARE_PATH]`, `[PUBLIC_ROUTES_CONFIG]`, `[SESSION_PATTERN]`, `[TOKEN_STORAGE]`, `[PERMISSION_MODEL]`, `[ROLE_DEFINITIONS_PATH]`, `[ERROR_TYPE]` — must match the value in `.claude/rules/backend.md` § Error Handling), (2) replace each `<!-- TODO -->` HTML comment with a proper `<!-- Source: Stage 3 | Evidence: [ref] | Confidence: HIGH -->` annotation (`// TODO:` inside code blocks are code example placeholders — replace those with actual code patterns), (3) update the `paths` patterns in frontmatter with actual project paths, and (4) remove ALL other HTML comments (e.g., `<!-- Paths note: ... -->`) — these are template-only guidance that must not appear in generated rule files. Stage 4 confirms replacements are complete. After Stage 3 renders this template, verify no placeholders remain: `grep -nE '\[[A-Z_]+\]' .claude/rules/auth.md` — the output should be empty (all `[BRACKETED]` markers replaced with actual values). **Rule count limit**: The rendered output must contain ≤ 15 rules (individual bullet-point directives). This template contains conditional sections — omit sections that don't apply to the selected tech stack. If the rendered output exceeds 15 rules after omitting inapplicable sections, split into two rule files (e.g., `auth.md` → `auth.md` + `auth-roles.md`) and update CLAUDE.md Part 2 § Path-Scoped Rules accordingly. Do not edit this template directly — edit the generated `.claude/rules/auth.md` instead.

## Public Routes

<!-- TODO: Stage 3 — replace with actual public route configuration for [AUTH_DIR]. Source: tech-stack.md | Confidence: HIGH -->

- Add routes to the public whitelist EXPLICITLY in `[PUBLIC_ROUTES_CONFIG]` — never use wildcard patterns (e.g., `/api/*`).
- Every new public route must have a comment explaining why it is public.
- Review the public route list during every security audit.

```typescript
// TODO: Replace with actual public route configuration
// const publicRoutes = [
//   "/",              // Landing page
//   "/sign-in",       // Authentication page
//   "/sign-up",       // Registration page
//   "/api/webhooks",  // External webhook endpoints (verified by signature)
// ];
```

## Auth Guards

<!-- TODO: Stage 3 — replace with actual middleware and auth check pattern. Source: tech-stack.md | Confidence: HIGH -->

- Protected routes must verify BOTH authentication (is the user logged in?) AND authorization (does the user have permission?).
- Middleware at `[MIDDLEWARE_PATH]` handles route-level auth gating.
- Backend functions handle resource-level authorization (e.g., "does this user own this record?").
- Never rely solely on frontend route guards — always enforce auth on the backend.

## Session Handling

<!-- TODO: Stage 3 — replace with session pattern (e.g., JWT in httpOnly cookie, server session, OAuth token). Specify where tokens are stored (httpOnly cookie, not localStorage). Source: tech-stack.md | Confidence: HIGH -->

- Follow the project's session pattern: `[SESSION_PATTERN]`.
- Session tokens must be stored in `[TOKEN_STORAGE]` (e.g., httpOnly cookies, not localStorage).
- Handle token expiration gracefully — redirect to sign-in with a return URL; never expose session tokens in URLs, logs, or error messages.

## OAuth / External Auth Provider Integration

<!-- Conditional: Include this section ONLY if the auth provider (per tech-stack.md) uses OAuth/OIDC flows (e.g., WorkOS, Auth0, Clerk with OAuth, Supabase Auth with third-party providers). Omit for password-only or magic-link-only auth. -->
<!-- TODO: Stage 3 — replace with actual OAuth configuration for your auth provider. Source: tech-stack.md, auth provider documentation | Confidence: HIGH -->

- **Authorize URL completeness**: When constructing OAuth authorize URLs, always include ALL required OAuth2 parameters: `response_type=code`, `client_id`, `redirect_uri`, `state` (CSRF), and any provider-specific parameters. Consult your auth provider's API reference — do not rely on memory or assumed defaults.
- **Token exchange method**: Read the auth provider's token exchange documentation to determine the correct authentication method. Common patterns: `client_secret` in the JSON request body (most User Management APIs), `Authorization: Basic` header (standard OAuth2), or `Authorization: Bearer` header (admin APIs only). Using the wrong method causes "Invalid client secret" errors.
- **Callback session establishment**: The OAuth callback page must store the session in ALL required locations before navigating away. Typical locations: `[TOKEN_STORAGE]` (e.g., localStorage, httpOnly cookie), auth state event dispatch, and cookie-setting endpoint. If ANY storage step is skipped, the user will be redirected back to login immediately after sign-in.
- **Intermediate auth states**: OAuth token exchange may return intermediate states instead of a token — e.g., `email_verification_required`, `mfa_challenge_required`, `organization_selection_required`. The callback page must handle these states with appropriate UI (verification code input, MFA prompt, org selector) rather than treating them as errors. Consult the auth provider's "authentication errors" documentation for the full list of intermediate states.
- **Redirect URI consistency**: The redirect URI sent in the authorize request, registered in the auth provider dashboard, and used in the callback page must be identical (scheme, host, port, path). Mismatches cause silent failures. Verify by comparing: code → dashboard → callback.

## Role Checks

<!-- TODO: Stage 3 — replace with actual role/permission model. Source: tech-stack.md, BRD security requirements | Confidence: HIGH -->

<!-- e.g., src/auth/roles.ts, src/config/permissions.json, or convex/schema.ts -->
- **Permission model**: `[PERMISSION_MODEL]` (e.g., RBAC, ABAC, or Custom) — see `[ROLE_DEFINITIONS_PATH]` for the authoritative role/permission list.
- Verify role or permission before allowing mutations that modify shared resources.
- Role definitions live in `[ROLE_DEFINITIONS_PATH]`. Roles are scoped per-tenant — a user can have different roles in different organizations.
- Use the principle of least privilege — default to denied, explicitly grant access.
- Multi-tenant resources must verify that the authenticated user belongs to the target tenant.

```typescript
// TODO: Replace with actual role check pattern
// [ERROR_TYPE] must match the value in .claude/rules/backend.md § Error Handling
// const member = await getMembership(ctx, { userId: identity.id, orgId });
// if (member.role !== "admin") throw new [ERROR_TYPE]({ code: "FORBIDDEN" });
```
