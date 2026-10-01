---
description: Template for data model rules — index definitions, soft-delete patterns, migration strategy, reserved words, and timestamp conventions for the database schema.
paths: ["[SCHEMA_DIR]/**", "[MIGRATION_DIR]/**"]
---

# Data Model Rules

> **This is a template.** Paths note: if the backend is schemaless (e.g., Convex has no migration directory), Stage 3 should remove the `[MIGRATION_DIR]/**` pattern and omit the Schema Changes section. Stage 3 (Scaffold Generation) reads this template and generates `.claude/rules/data-model.md` with actual project values. Stage 3 must: (1) replace ALL `[BRACKETED]` placeholder markers (e.g., `[SCHEMA_DIR]`, `[MIGRATION_DIR]`, `[BACKEND_FRAMEWORK]`, `[SOFT_DELETE_FIELD]` (cross-template: must match `.claude/rules/backend.md` § Query Filters), `[RETENTION_PERIOD]`, `[TIMESTAMP_FORMAT]`, `[TENANT_ID_FIELD]` (cross-template: must match `.claude/rules/backend.md` § Query Filters), `[DATABASE]`, `[MIGRATION_LOG_PATH]`, `[MIGRATION_PATTERN]`). For schemaless backends (e.g., Convex), remove the `[MIGRATION_DIR]/**` pattern from frontmatter and omit the Schema Changes section entirely. Document the chosen `[RETENTION_PERIOD]` value in CLAUDE.md Part 2 § Architecture, (2) replace each `<!-- TODO -->` HTML comment with a proper `<!-- Source: Stage 3 | Evidence: [ref] | Confidence: HIGH -->` annotation (`// TODO:` inside code blocks are code example placeholders — replace those with actual code patterns), (3) update the `paths` patterns in frontmatter with actual project paths, and (4) remove ALL other HTML comments (e.g., `<!-- Stage 3: OMIT ... -->`, `<!-- Stage 3: Fill ... -->`) — these are template-only guidance that must not appear in generated rule files. Stage 4 confirms replacements are complete. After Stage 3 renders this template, verify no placeholders remain: `grep -nE '\[[A-Z_]+\]' .claude/rules/data-model.md` — the output should be empty (all `[BRACKETED]` markers replaced with actual values). **Rule count limit**: The rendered output must contain ≤ 15 rules (individual bullet-point directives). This template contains conditional sections — omit sections that don't apply to the selected tech stack. If the rendered output exceeds 15 rules after omitting inapplicable sections, split into two rule files (e.g., `data-model.md` → `data-model.md` + `data-model-migrations.md`) and update CLAUDE.md Part 2 § Path-Scoped Rules accordingly. Do not edit this template directly — edit the generated `.claude/rules/data-model.md` instead.

## Indexes

<!-- TODO: Stage 3 — replace with actual index definition pattern for [SCHEMA_DIR]. Source: tech-stack.md | Confidence: HIGH -->

- Every query pattern used in production code must have a supporting index in `[SCHEMA_DIR]` — add the corresponding index in the same commit as the query. Review index usage during Stage 9 — remove unused indexes to reduce write overhead.
- Compound indexes: place equality fields before range fields for optimal performance.

```typescript
// TODO: Replace with actual index definition pattern
// Example for [BACKEND_FRAMEWORK]:
// tasks: defineTable({ ... })
//   .index("by_org_status", ["orgId", "status"])
//   .index("by_assignee", ["assigneeId", "createdAt"])
```

## Soft Delete

<!-- TODO: Stage 3 — replace with actual soft-delete field name and pattern. Source: tech-stack.md, schema | Confidence: HIGH -->

- Use `[SOFT_DELETE_FIELD]` (e.g., `deletedAt`) for soft deletion — never hard-delete user data.
- All queries must filter out soft-deleted records by default (`[SOFT_DELETE_FIELD] === null`). Backend functions are responsible for filtering — do not rely on database triggers.
- Admin/audit views may include soft-deleted records — mark these queries explicitly.
- Retention policy: soft-deleted records are permanently purged after `[RETENTION_PERIOD]`.
- When soft-deleting a parent entity, apply the documented child strategy: cascade soft-delete (mark children too) or orphan (children remain active but lose parent reference). Document the chosen pattern in CLAUDE.md Part 2 § Architecture.
<!-- After filling this section, Stage 3 must also populate CLAUDE.md Part 2 § Architecture with the same soft-delete pattern (field name, retention period, child strategy). -->
<!-- Stage 3: Also update CLAUDE.md Part 2 Architecture section with the chosen retention period and child entity strategy — ensures CLAUDE.md and data-model.md are synchronized. -->
<!-- Stage 3: Determine the child entity strategy based on BRD data integrity requirements. Default if BRD doesn't specify: cascade soft-delete for owned entities (e.g., tasks owned by a project), orphan for shared entities (e.g., users referenced by multiple orgs). -->
<!-- Stage 3: Fill [RETENTION_PERIOD] based on BRD data retention requirements. Default if BRD doesn't specify: 30 days (allows buffer for user error recovery and backup cycles). If the product serves EU users, verify compliance with GDPR Article 17 (right to erasure). Document the chosen value in CLAUDE.md Part 2. Source: BRD data retention | Confidence: HIGH -->

## Schema Changes

<!-- Stage 3: OMIT this entire section if the backend has no migration system (e.g., Convex, Firebase). Only include for migration-based backends (e.g., Prisma, Drizzle, Supabase). If the backend uses BOTH a schema definition file AND a migration system (e.g., Prisma, Drizzle), keep this section and ensure both [SCHEMA_DIR] and [MIGRATION_DIR] patterns are populated in frontmatter. -->
<!-- TODO: Stage 3 — replace with actual migration pattern. Source: tech-stack.md | Confidence: HIGH -->

- Document all schema changes in `[MIGRATION_LOG_PATH]` or equivalent — never modify production schemas without a migration plan.
<!-- e.g., "Prisma: numbered .sql files in prisma/migrations/", "Drizzle: TypeScript files in src/db/migrations/", "Convex: schema-first in convex/schema.ts (no migration files)" -->
- For [BACKEND_FRAMEWORK], follow the migration pattern: `[MIGRATION_PATTERN]`.
- Backward-compatible changes (adding optional fields) can deploy without downtime; breaking changes (renaming fields, changing types) require a multi-step migration.

## Reserved Words

<!-- TODO: Stage 3 — replace with actual reserved word list for the database. Source: database documentation | Confidence: HIGH -->

<!-- Stage 3: For the selected database, consult official reserved word documentation. Common collisions: "user", "order", "group", "table", "index", "key", "type", "status". -->
- Check field names against `[DATABASE]` reserved words before defining them — if a reserved word is needed semantically, prefix it (e.g., `taskType` instead of `type`, `sortOrder` instead of `order`, `itemStatus` instead of `status`, `displayName` instead of `name`, `indexKey` instead of `key`).

## Timestamps

<!-- TODO: Stage 3 — replace with actual timestamp pattern. Source: tech-stack.md | Confidence: HIGH -->

- Include `createdAt` and `updatedAt` on ALL entities — `createdAt` is set once at creation and never modified; `updatedAt` is refreshed on every mutation.
- Store timestamps as `[TIMESTAMP_FORMAT]` (e.g., Unix milliseconds, ISO 8601 strings) — use server-side timestamps, never client-provided values, to prevent clock skew. ALL timestamps are UTC — never include local timezone offsets.

```typescript
// TODO: Replace with actual timestamp pattern
// createdAt: Date.now(),
// updatedAt: Date.now(),
```

## Tenant Isolation

<!-- TODO: Stage 3 — replace with actual tenant boundary from CLAUDE.md Part 2 Architecture section. Source: CLAUDE.md Part 2, tech-stack.md | Confidence: HIGH -->

- Every table containing user data must include a `[TENANT_ID_FIELD]` foreign key (e.g., `orgId`, `workspaceId`) — queries must always filter by tenant scope.
- Unique constraints on user-facing fields (e.g., project name, slug) must be composite with the tenant ID to allow the same name across different tenants.
- See `.claude/rules/backend.md` § Query Filters for the corresponding query-level enforcement pattern.
