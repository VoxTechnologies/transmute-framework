---
description: Template for API contract rules — ensures frontend types match backend responses; coordinates field mapping, projections, and type alignment between frontend and backend.
paths: ["[BACKEND_DIR]/**", "[HOOKS_DIR]/**", "[FRONTEND_TYPES_DIR]/**"]
---

# API Contract Rules

> **This is a template.** Stage 3 (Scaffold Generation) reads this template and generates `.claude/rules/api-contracts.md` with actual project values. Stage 3 must: (1) replace ALL `[BRACKETED]` placeholder markers (e.g., `[BACKEND_DIR]`, `[HOOKS_DIR]`, `[FRONTEND_TYPES_DIR]`, `[TYPECHECK_COMMAND]` — use the project's TypeScript check command from CLAUDE.md Part 2 § Commands), (2) replace each `<!-- TODO -->` HTML comment with a proper `<!-- Source: Stage 3 | Evidence: [ref] | Confidence: HIGH -->` annotation (`// TODO:` inside code blocks are code example placeholders — replace those with actual code patterns), (3) update the `paths` patterns in frontmatter with actual project paths, and (4) remove ALL other HTML comments — these are template-only guidance that must not appear in generated rule files. Stage 4 confirms replacements are complete. After Stage 3 renders this template, verify no placeholders remain: `grep -nE '\[[A-Z_]+\]' .claude/rules/api-contracts.md` — the output should be empty (all `[BRACKETED]` markers replaced with actual values). **Rule count limit**: The rendered output must contain ≤ 15 rules (individual bullet-point directives). This template contains conditional sections — omit sections that don't apply to the selected tech stack. If the rendered output exceeds 15 rules after omitting inapplicable sections, split into two rule files (e.g., `api-contracts.md` → `api-contracts.md` + `api-contracts-versioning.md`) and update CLAUDE.md Part 2 § Path-Scoped Rules accordingly. Do not edit this template directly — edit the generated `.claude/rules/api-contracts.md` instead.

## Type Alignment

<!-- TODO: Stage 3 — replace with actual type alignment pattern for [BACKEND_DIR] and [HOOKS_DIR]. Source: tech-stack.md | Confidence: HIGH -->

- Enforce CLAUDE.md Part 1 "API Contract Alignment" rules: backend response types live in `[BACKEND_DIR]`, frontend types that mirror them live in `[HOOKS_DIR]` or `[FRONTEND_TYPES_DIR]`.
- When the backend adds or removes a field, update the frontend type in the same PR. See `.claude/rules/frontend.md` § Hook Data Shapes for the frontend mapping pattern.
- Run type checking (`[TYPECHECK_COMMAND]`) before committing any API-related change.

## Projection Types

<!-- TODO: Stage 3 — replace with actual projection pattern from the project's codebase. Source: tech-stack.md | Confidence: HIGH -->

- Create SEPARATE types for different views of the same entity:
  - List view: lightweight projection (e.g., `TaskSummary`) with only the fields displayed in lists.
  - Detail view: full projection (e.g., `TaskDetail`) with all fields.
  - Form view: input type (e.g., `TaskInput`) matching the mutation arguments.
- Never use the full schema type for list views — it fetches unnecessary data and creates coupling.

```typescript
// TODO: Replace with actual projection types
// type TaskSummary = { id: string; title: string; status: string; };
// type TaskDetail = TaskSummary & { description: string; assignee: UserSummary; comments: Comment[]; };
// type TaskInput = { title: string; description?: string; priority: Priority; };
```

## Field Mapping

<!-- TODO: Stage 3 — replace with actual field mapping examples from the project. Source: tech-stack.md | Confidence: HIGH -->

- When the backend returns renamed or computed fields, hooks must map them explicitly.
- Never use `as unknown as Type` casts to force type compatibility.
- Document any field name divergence between backend and frontend with a comment.

```typescript
// TODO: Replace with actual mapping pattern
// Backend returns `_id`, frontend expects `id`:
// const mapped = { id: raw._id, ...rest };
// NOT: const mapped = raw as unknown as FrontendType;
```

## Null Handling

<!-- TODO: Stage 3 — replace with actual loading/null patterns from the project. Source: tech-stack.md | Confidence: HIGH -->

- Distinguish between `undefined` (not yet loaded → show loading), `null` (intentionally absent → show empty/default), and present values — never treat them as interchangeable.
- Backend functions must return `null` (not `undefined`) for "not found" responses to make the distinction explicit.
- Frontend components must handle all three states separately in their render logic.

## Response Versioning

<!-- Stage 3: Keep ONLY the section (A or B) that matches your backend type. Delete the other entirely. -->
<!-- TODO: Stage 3 — replace with actual versioning strategy if applicable. Source: tech-stack.md | Confidence: HIGH -->

### Option A: REST/GraphQL Backend

- When adding new fields to a backend response, make them optional with sensible defaults in the frontend type — this prevents breakage for already-deployed frontends reading the old shape.
- When deprecating fields, add a `@deprecated` JSDoc annotation to the frontend type and remove usage over 1–2 releases, not immediately.
- Use a naming convention for projection types: `[Entity]Summary` (list view), `[Entity]Detail` (full detail), `[Entity]Input` (mutation input). Avoid ambiguous names like `[Entity]Extended` or `[Entity]v2`.

### Option B: Reactive Backend (Convex, Firebase, Supabase Realtime)

- When adding new fields to a schema, add them as optional with server-side defaults. Existing subscribers receive the new shape immediately — ensure frontend components handle the field being absent for previously-created records.
- When removing fields, first stop reading them in the frontend, deploy, then remove from the schema.
- Use a naming convention for projection types: `[Entity]Summary` (list view), `[Entity]Detail` (full detail), `[Entity]Input` (mutation input). Avoid ambiguous names like `[Entity]Extended` or `[Entity]v2`.
