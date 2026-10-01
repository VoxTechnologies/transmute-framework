---
description: Template for testing rules — E2E selectors, eventually-consistent assertions, test isolation, credential handling, and test data management for the testing framework.
paths: ["[TEST_DIR]/**", "**/*.test.*", "**/*.spec.*"]
---

# Testing Rules

> **This is a template.** Stage 3 (Scaffold Generation) reads this template and generates `.claude/rules/testing.md` with actual project values. Stage 3 must: (1) replace ALL `[BRACKETED]` placeholder markers (e.g., `[TEST_DIR]`, `[TEST_RUNNER]`, `[BACKEND_FRAMEWORK]`, `[AXE_INTEGRATION]`, `[HOOK_MOCK_PATTERN]`, `[TEST_CONSTANTS_PATH]`, `[SEED_COMMAND]`, `[BREAKPOINT_CONFIG]` (cross-template: must match `.claude/rules/frontend.md` § Responsive Behavior)), (2) replace each `<!-- TODO -->` HTML comment with a proper `<!-- Source: Stage 3 | Evidence: [ref] | Confidence: HIGH -->` annotation (`// TODO:` inside code blocks are code example placeholders — replace those with actual code patterns), (3) update the `paths` patterns in frontmatter with actual project paths, and (4) remove ALL other HTML comments (e.g., `<!-- Stage 3: ... -->`) — these are template-only guidance that must not appear in generated rule files. Stage 4 confirms replacements are complete. After Stage 3 renders this template, verify no placeholders remain: `grep -nE '\[[A-Z_]+\]' .claude/rules/testing.md` — the output should be empty (all `[BRACKETED]` markers replaced with actual values). **Rule count limit**: The rendered output must contain ≤ 15 rules (individual bullet-point directives). This template contains conditional sections — omit sections that don't apply to the selected tech stack. If the rendered output exceeds 15 rules after omitting inapplicable sections, split into two rule files (e.g., `testing.md` → `testing.md` + `testing-e2e.md`) and update CLAUDE.md Part 2 § Path-Scoped Rules accordingly. Do not edit this template directly — edit the generated `.claude/rules/testing.md` instead.

## Selectors

<!-- TODO: Stage 3 — replace with actual selector examples for [TEST_RUNNER]. Source: tech-stack.md | Confidence: HIGH -->
<!-- TODO: Stage 3 — replace this comment with annotation: Source: Stage 3 | Evidence: CLAUDE.md Part 1 § E2E Tests | Confidence: HIGH -->

- Per CLAUDE.md Part 1 E2E Tests, prefer `getByRole` and `getByText` over CSS class selectors or test IDs — use `getByTestId` only when no accessible role or text is available. Never select by CSS class names — for complex components, add `aria-label` to make them queryable by role.

```typescript
// TODO: Replace with actual selector examples
// GOOD: page.getByRole("button", { name: "Create Task" })
// GOOD: page.getByText("No tasks yet")
// AVOID: page.locator(".btn-primary")
// LAST RESORT: page.getByTestId("task-list-container")
```

## Eventually-Consistent Assertions

<!-- TODO: Stage 3 — replace with actual async assertion pattern for [BACKEND_FRAMEWORK]. Source: tech-stack.md | Confidence: HIGH -->

- Per CLAUDE.md Part 1 E2E Tests, use async assertion patterns for eventually-consistent backends (Playwright: `expect.poll()`/`expect.toPass()`; Jest/Vitest: custom polling helper).
- Never use `page.waitForTimeout()` as a substitute for proper async assertions.
<!-- Stage 3: Set timeout based on backend: Cloud BaaS (Convex, Supabase Cloud, Firebase): 10000ms. Local emulator: 5000ms. Traditional DB (Prisma, Drizzle direct): 3000ms. -->
- Set reasonable polling intervals and timeouts based on expected backend latency. Default timeout: 10000ms (10s) for cloud backends (Convex, Supabase, Firebase). Override to 5000ms (5s) if the project runs a local database in development. Recommended defaults below — adjust all values based on measured backend latency:
  - `expect.poll()`: periodic UI checks — `{ timeout: 10000, intervals: [100, 200, 500] }` for exponential backoff
  - `expect.toPass()`: complex multi-step assertions — `{ timeout: 10000 }` for multi-condition checks
  - Local dev: 2–5s timeout. Cloud backends (Convex, Supabase, Firebase): 10–15s timeout.

```typescript
// TODO: Replace with actual eventually-consistent pattern
// await expect.poll(async () => {
//   return await page.getByRole("listitem").count();
// }, { timeout: 10000 }).toBeGreaterThan(0);
```

## Test Isolation

<!-- TODO: Stage 3 — replace with actual setup/teardown pattern. Source: tech-stack.md | Confidence: HIGH -->

- Each test must not depend on state from previous tests — use `beforeEach` to set up required state and `afterEach` to clean up if needed.
- For E2E tests, use unique identifiers (timestamps, UUIDs) for per-test data to avoid collisions; seed commands provide baseline state, but individual test assertions should create their own data rather than depending on seed data being present.

## Component Testing

<!-- TODO: Stage 3 — replace with actual component test patterns for [TEST_RUNNER]. Source: tech-stack.md | Confidence: HIGH -->

- Per CLAUDE.md Part 1 Component Tests, test all five states (default, loading, empty, error, disabled) for every component.
<!-- Stage 3: Check PRD § Non-Functional Requirements for WCAG level. Document the chosen level (AA or AAA) here. Default: AA. -->
- Include axe-core accessibility checks (`[AXE_INTEGRATION]`) in component tests (WCAG AA level minimum; upgrade to AAA if PRD requires it). <!-- Stage 3: Select the appropriate axe integration based on tech-stack.md — Next.js+Jest → jest-axe, Vite+Vitest → vitest-axe, Playwright E2E → @axe-core/playwright. Replace [AXE_INTEGRATION] with the selected package. If tech-stack.md does not specify a test framework, default to @axe-core/playwright for E2E and jest-axe for unit tests. -->
- Mock backend hooks using the project's mock pattern (`[HOOK_MOCK_PATTERN]` — e.g., `jest.mock()`, `vi.mock()`, or a custom setup function), not the API layer directly — this tests the component's behavior without coupling to API implementation details.

## Credentials

<!-- TODO: Stage 3 — replace with actual test constants location. Source: tech-stack.md | Confidence: HIGH -->

<!-- Test accounts are created by Stage 6F (Seed Data) seed scripts or manually. If 6F hasn't run, tests requiring auth must create accounts in beforeAll hooks or use a shared test seed. -->
- Never hardcode credentials in test files — reference test credentials from `[TEST_CONSTANTS_PATH]` (e.g., `e2e/constants.ts`); never log, commit, or share credential values; use separate test accounts for each test suite to avoid auth state leakage.

## Test Data

<!-- TODO: Stage 3 — replace with actual seed/factory pattern. Source: tech-stack.md | Confidence: HIGH -->

- Use seed data scripts or factory functions to generate test data — never use production data in tests.
- Factories should produce minimal valid objects — override only the fields relevant to each test.
- For E2E tests, use the project's seed commands (`[SEED_COMMAND]` — see CLAUDE.md Part 2 § Commands for actual command) to set up baseline data. See `.claude/rules/data-model.md` § Soft Delete for data cleanup considerations in test teardown.

## Responsive Testing

<!-- TODO: Stage 3 — replace with actual viewport setup pattern for [TEST_RUNNER]. Source: tech-stack.md | Confidence: HIGH -->

<!-- Cross-check: breakpoint values must match the project's Tailwind config or CSS breakpoints, NOT .claude/rules/frontend.md (which also contains a placeholder). Stage 3 fills both from the same source. -->
- E2E tests for critical user flows should test at multiple breakpoints (mobile, tablet, desktop as defined in the project's Tailwind/CSS configuration); set viewport size at the start of each responsive test or use parameterized tests for multiple breakpoints.
- Use role selectors (which adapt to layout) rather than position-based assertions that break at different viewports.

```typescript
// TODO: Replace with actual viewport test pattern
// test.describe('responsive', () => {
//   // Replace viewport values with values from [BREAKPOINT_CONFIG] to match .claude/rules/frontend.md § Responsive Behavior
//   for (const viewport of [{ width: 320, height: 667 }, { width: 768, height: 1024 }, { width: 1440, height: 900 }]) {
//     test(`works at ${viewport.width}px`, async ({ page }) => {
//       await page.setViewportSize(viewport);
//       // ... test assertions using role selectors
//     });
//   }
// });
```

## Test Count Preservation
<!-- Source: Stage 3 | Evidence: CLAUDE.md Part 1 § Test Count Preservation | Confidence: HIGH -->
- Test count must never decrease during refactoring — if a refactoring reduces test count, it is a regression. Restructure implementation-detail tests, but preserve all user-facing behavior tests.
