# Plugin Architecture (internal reference)

Working detail for people and agents editing this plugin. The public-facing
overview lives in [README.md](../README.md); the contribution workflow lives in
[CONTRIBUTING.md](../CONTRIBUTING.md). This file covers what neither of those
does: how the layers depend on each other, and what breaks when an edit lands in
only some of them.

## Layer responsibilities

| Layer | Role |
|---|---|
| `commands/cast.md` | The `/transmuter:cast` entry point. Parses `$1`, routes to the pipeline agent (`full` / `resume` / empty) or maps a stage alias to a skill. Holds the alias table (`security` to `audit-security`, `a11y` to `audit-a11y`, and so on). |
| `agents/transmute-pipeline.md` | Full-pipeline orchestrator. Owns the Stage Skills Map, gate logic, parallel-safety rules, and `plancasting/_progress.md` state transitions. |
| `agents/{brd,prd}-writer.md`, `agents/feature-{backend,frontend,tests,reviewer}.md` | Teammates spawned by skills, never invoked by users directly. |
| `skills/<stage>/` | One directory per stage, using the two-file pattern below. |
| `templates/` | Files copied into generated projects. |

### Teammate ownership boundaries

These divisions are deliberate; collapsing them produces duplicate or missing
test coverage:

- `feature-backend` owns backend function tests.
- `feature-frontend` owns component tests.
- `feature-tests` owns E2E tests only.
- `feature-reviewer` is read-only by tool grant, not by convention.

### What `templates/` contains

- `CLAUDE.md` — the generated project's conventions file, split into Part 1
  (immutable framework rules) and Part 2 (project-specific configuration filled
  during Stage 3, verified by the manual Stage 4).
- `execution-guide.md` — canonical per-stage reference shipped into the project.
- `feature_scenario_generation.md` — scenario extraction algorithm read by
  Stages 6V and 7V.
- `progress.md`, `_rules-candidates.md`, and six path-scoped
  `rules-templates/` starter files.

## The two-file skill pattern

`skills/<stage>/SKILL.md` is the always-loaded layer: frontmatter (`name`,
`description`, `version`), prerequisite STOP/WARN checks, critical framing, and
the execution flow. It opens by pointing at
`${CLAUDE_SKILL_ROOT}/references/<stage>-detailed-guide.md`, the on-demand layer
holding full teammate spawn prompts, report templates, gate tables, and known
failure patterns.

All 23 skills follow this. Keep the split: moving spawn prompts up into
`SKILL.md` inflates the cost of every invocation of that stage, including the
invocations that never spawn anything.

Path variables are `${CLAUDE_SKILL_ROOT}` for skill-internal paths and
`${CLAUDE_PLUGIN_ROOT}` for plugin-root paths. Never hardcode either.

## Gate enforcement

`hooks/hooks.json` registers a `PreToolUse` hook on the `Skill` matcher that
runs `hooks/scripts/check-prerequisites.sh`. The script reads the tool-input
JSON from stdin, extracts the skill name, and checks per stage that prior-stage
artifacts exist, exiting non-zero with a `BLOCK:` message to stop the stage. It
is macOS-compatible by design (`sed`, no `grep -P`).

`.claude-plugin/hooks/` holds a stale second copy using an older `before:skill`
schema, whose script only warns and never blocks. It has been unreferenced since
v2.4.0. `hooks/hooks.json` at the plugin root is the live one, because
`plugin.json` declares no `hooks` field and auto-discovery applies. Edit
`hooks/`. Do not reconcile the two copies without first deciding which schema is
real — silently merging them can turn blocking gates into warnings.

## The consistency invariant

The largest source of bugs in this repository is a stage change landing in some
files but not others. v3.0.0 renamed the plugin to `transmuter` in the config
files but left the docs saying `/transmute:`, so every documented command
matched no installed plugin until v3.0.1.

Adding or modifying a stage touches up to eight places:

1. `skills/<stage>/SKILL.md` — frontmatter and flow
2. `skills/<stage>/references/<stage>-detailed-guide.md` — the full prompt
3. `commands/cast.md` — the Stage Name Mapping table **and** the help text block
4. `hooks/scripts/check-prerequisites.sh` — the `case` arm
5. `agents/transmute-pipeline.md` — Stage Skills Map row, plus any gate logic
6. `templates/CLAUDE.md` and `templates/execution-guide.md` — stage lists,
   prerequisites, skip conditions
7. `README.md` — pipeline diagram, stage table, command table
8. `.claude-plugin/plugin.json` version and the `README.md` changelog entry

Grep the stage name across the whole repository before calling a change
complete.

## Terminology that carries meaning

- **`6V-A` / `6V-B` / `6V-C`** — fixability categories (auto-fixable /
  code-fixable / human-judgment) used by Stages 6V and 6R. The `6V-` prefix is
  mandatory: bare `Category A/B/C` means Stage 5B's *size*-based categories.
  Mixing the two has caused real gate-routing bugs.
- **PASS / CONDITIONAL PASS / FAIL-RETRY / FAIL-ESCALATE** — evaluated in that
  priority order. Thresholds are numeric and specific; do not paraphrase them
  into vaguer wording when editing a gate.
- **Session Language** — a field in `plancasting/tech-stack.md`, the canonical
  output-language setting read by roughly 50 files across skills, agents, and
  templates. Downstream stages read it from `tech-stack.md` only, never from
  generated BRD or PRD text. Technical identifiers (`FR-001`, section headers,
  cross-reference codes) always stay in English.
- **Skill names carry no prefix** — `brd`, not `transmute-brd`. Some older prose
  still says "the transmute-brd skill"; the invocable name is the bare one.

## Authoring conventions

- `templates/` files and the 23 `references/*-detailed-guide.md` files are
  synced byte-identical from an external canonical "Transmute Framework
  Template" during audit passes. Drift there is a sync problem, not an authoring
  opportunity — check whether the canonical source changed first.
- Markdown frontmatter uses `---` delimiters. YAML values containing colons must
  be quoted.
- Agent frontmatter uses a `description: |` block ending in `<example>` and
  `<commentary>` pairs; these are the invocation triggers, so keep them
  concrete.
- Prefer explicit imperative instructions over implicit assumptions in every
  prompt file. Ambiguity in a skill prompt becomes non-determinism at run time.
- The README changelog is unusually detailed by design: it records which audit
  pass changed each file, which is how template sync state is tracked.
