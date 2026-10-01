---
description: Template for frontend rules — component states, hook data mapping, responsive behavior, design tokens, and image optimization for the frontend framework.
paths: ["[FRONTEND_DIR]/**"]
---

# Frontend Rules

> **This is a template.** Stage 3 (Scaffold Generation) reads this template and generates `.claude/rules/frontend.md` with actual project values. Stage 3 must: (1) replace ALL `[BRACKETED]` placeholder markers (e.g., `[FRONTEND_DIR]`, `[FRONTEND_FRAMEWORK]`, `[LOADING_COMPONENT]`, `[ERROR_COMPONENT]`, `[EMPTY_COMPONENT]`, `[IMAGE_COMPONENT]`, `[DESIGN_TOKENS_PATH]`, `[ICON_LIBRARY]`, `[ICON_REGISTRY_PATH]`, `[BREAKPOINT_CONFIG]`, `[MOBILE_BREAKPOINT]`, `[CLIENT_ENV_PREFIX]`), (2) replace each `<!-- TODO -->` HTML comment with a proper `<!-- Source: Stage 3 | Evidence: [ref] | Confidence: HIGH -->` annotation (`// TODO:` inside code blocks are code example placeholders — replace those with actual code patterns), (3) update the `paths` patterns in frontmatter with actual project paths, and (4) remove ALL other HTML comments (e.g., `<!-- Stage 3: ... -->`, `<!-- Note: ... -->`) — these are template-only guidance that must not appear in generated rule files. Stage 4 confirms replacements are complete. After Stage 3 renders this template, verify no placeholders remain: `grep -nE '\[[A-Z_]+\]' .claude/rules/frontend.md` — the output should be empty (all `[BRACKETED]` markers replaced with actual values). **Rule count limit**: The rendered output must contain ≤ 15 rules (individual bullet-point directives). This template contains conditional sections — omit sections that don't apply to the selected tech stack. If the rendered output exceeds 15 rules after omitting inapplicable sections, split into two rule files (e.g., `frontend.md` → `frontend.md` + `frontend-ssr.md`) and update CLAUDE.md Part 2 § Path-Scoped Rules accordingly. Do not edit this template directly — edit the generated `.claude/rules/frontend.md` instead.

## Component States

<!-- TODO: Stage 3 — replace with actual component state pattern for [FRONTEND_FRAMEWORK]. Source: tech-stack.md | Confidence: HIGH -->

- Per CLAUDE.md Part 1 Component Rules #1, every component must handle all five states (default, loading, empty, error, disabled). For data-fetching components, use `[LOADING_COMPONENT]` for loading states and `[ERROR_COMPONENT]` for error states (include a retry action where appropriate); never render a blank screen.
<!-- Stage 3: If [EMPTY_COMPONENT] does not exist in the scaffold, create it in the shared components directory (e.g., src/components/EmptyState.tsx) -->
- Additionally: empty states must use `[EMPTY_COMPONENT]` (a shared component or layout pattern for empty-state messaging — if none exists, Stage 3 should create one during scaffold generation) with a descriptive message and, where applicable, a call-to-action (stack-specific enhancement beyond Part 1).

```typescript
// TODO: Replace with actual state handling pattern for [FRONTEND_FRAMEWORK]
// if (isLoading) return <[LOADING_COMPONENT] />;
// if (error) return <[ERROR_COMPONENT] error={error} onRetry={refetch} />;
// if (!data || data.length === 0) return <[EMPTY_COMPONENT] />;
```

## Hook Data Shapes

<!-- TODO: Stage 3 — replace with actual hook pattern. Source: tech-stack.md | Confidence: HIGH -->

- Never cast backend responses with `as unknown as Type` — create explicit mapping functions when shapes differ; co-locate response types with hooks, and when a backend field is renamed or computed, map it explicitly with a comment documenting the mapping. Run typecheck (see `.claude/rules/api-contracts.md` § Type Alignment) after modifying hook response mappings.

```typescript
// TODO: Replace with actual hook mapping pattern
// function mapResponse(raw: BackendResponse): FrontendType {
//   return { id: raw._id, name: raw.title, ... };
// }
```

## Responsive Behavior

<!-- TODO: Stage 3 — replace with actual breakpoint system. Source: tech-stack.md | Confidence: HIGH -->

- Use the project's breakpoint system (`[BREAKPOINT_CONFIG]` — the path to the project's breakpoint definitions, e.g., `tailwind.config.ts` or CSS custom properties file) — never hardcode pixel widths; write base styles mobile-first, then layer larger breakpoints. Test all pages at the project's defined breakpoints (mobile, tablet, desktop, and wide breakpoints as defined in the project's Tailwind/CSS configuration — adjust to match your `[BREAKPOINT_CONFIG]` scale).
- Navigation must collapse to a mobile-friendly pattern below `[MOBILE_BREAKPOINT]` (the pixel value for the mobile/tablet cutoff, e.g., `768px`).

## Design Tokens

<!-- TODO: Stage 3 — replace [DESIGN_TOKENS_PATH] with actual path (e.g., src/styles/design-tokens.ts, src/tokens/colors.css). All components import from this single source. Stage 3 creates this file based on the design direction from `plancasting/tech-stack.md`; if Stage 0 did not provide a design direction, Stage 3 creates a minimal placeholder that Stage 5 can extend. -->

- Import all colors, spacing, typography, and shadows from `[DESIGN_TOKENS_PATH]` — never hardcode color or spacing values in component files; use the token scale, and if a new token is needed, add it to the design tokens file, not inline.

## Image Optimization

<!-- TODO: Stage 3 — replace with actual image component. Source: tech-stack.md | Confidence: HIGH -->

- Use `[IMAGE_COMPONENT]` for all images — never use raw `<img>` tags; always specify `width`/`height` or use `fill` with a sized container. Provide `alt` text for all images (empty `alt=""` only for purely decorative) and use WebP/AVIF for photos, SVG for icons.

## Accessibility

<!-- TODO: Stage 3 — replace with actual ARIA and keyboard patterns for [FRONTEND_FRAMEWORK]. Source: tech-stack.md | Confidence: HIGH -->

- Per CLAUDE.md Part 1 Component Rules #2 and #3, all interactive elements must have appropriate ARIA attributes and support keyboard navigation — use semantic HTML first, add ARIA only when native semantics are insufficient; tab order follows visual order, focus is trapped in modals, Escape closes overlays.

## Icon Usage

<!-- TODO: Stage 3 — replace [ICON_LIBRARY] and [ICON_REGISTRY_PATH] with actual values from tech-stack.md. Source: tech-stack.md | Confidence: HIGH -->

- Per CLAUDE.md Part 1 Component Rules #6, never use inline SVG `<path>` elements for standard UI icons — import all icons from `[ICON_LIBRARY]` using the project's established pattern; inline SVGs are permitted only for product logos, brand marks, or custom illustrations.
<!-- Stage 3: Include this rule only if the project uses an icon registry. If no registry, omit this bullet entirely. -->
- If an icon registry exists at `[ICON_REGISTRY_PATH]`, register new icons there first and import from the registry. If no registry is used (check tech-stack.md "Icon Registry" field — if empty or absent, omit this bullet in the generated rule), import directly from `[ICON_LIBRARY]` in component files.

## Environment Variables

<!-- TODO: Stage 3 — replace [CLIENT_ENV_PREFIX] with actual prefix (e.g., NEXT_PUBLIC_ for Next.js, VITE_ for Vite). Source: tech-stack.md | Confidence: HIGH -->

- Only variables prefixed with `[CLIENT_ENV_PREFIX]` are exposed to the browser — never reference server-only secrets without the prefix. Reference env var names exactly as defined in `.env.local.example` — never invent alternative names.

## SSR/Hydration

<!-- Stage 3: If framework uses SSR, replace this section with actual SSR patterns. If framework does not use SSR, DELETE this entire section. -->
<!-- TODO: Stage 3 — replace with actual SSR hydration pattern for [FRONTEND_FRAMEWORK]. Source: tech-stack.md | Confidence: HIGH -->

- Avoid referencing `window`, `document`, or `localStorage` during server-side rendering — use dynamic imports with `ssr: false` or `useEffect`/`onMounted` for browser-only code.
- Components that depend on browser APIs must be wrapped in client-only boundaries (e.g., `'use client'` in Next.js, `<ClientOnly>` in Nuxt) to prevent hydration mismatches.

## Error Boundaries

<!-- Stage 3: If the frontend framework is not React-based, adapt this section to the framework's error handling mechanism (e.g., Vue errorHandler, Svelte error boundary, Angular ErrorHandler). -->
<!-- TODO: Stage 3 — replace with actual error boundary pattern for [FRONTEND_FRAMEWORK]. Source: tech-stack.md | Confidence: HIGH -->

- Place error boundaries at route segment level (one per page/layout) and around independently-failing widgets — do not wrap the entire app in a single boundary.
- Every error boundary must render a user-friendly fallback with a retry action, not a blank screen.
