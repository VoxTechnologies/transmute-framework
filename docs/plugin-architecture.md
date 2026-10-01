# Plugin Architecture (internal reference)

Working detail for people and agents editing this plugin. The public-facing
overview lives in [README.md](../README.md); the contribution workflow lives in
[CONTRIBUTING.md](../CONTRIBUTING.md). This file covers what neither of those
does: how the layers depend on each other, and what breaks when an edit lands in
only some of them.

## Layer responsibilities

| Layer | Role |
|---|---|
| `commands/cast.md` | The `/transmuter:cast` entry point. Parses `$0` (the first argument; indices are 0-based), routes to the pipeline agent (`full` / `resume` / empty) or maps a stage alias to a skill. Holds the alias table (`security` to `audit-security`, `a11y` to `audit-a11y`, and so on). |
| `agents/transmute-pipeline.md` | Full-pipeline orchestrator. Owns the Stage Skills Map, gate logic, parallel-safety rules, and `plancasting/_progress.md` state transitions. |
| `agents/{brd,prd}-writer.md`, `agents/feature-{backend,frontend,tests,reviewer}.md` | Teammates spawned by skills, never invoked by users directly. A teammate is an Agent-tool subagent; Claude Code's experimental Agent Teams is an opt-in alternative (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`), described in the pipeline agent's Execution Model. |
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
- `progress.md`, `_rules-candidates.md`, and seven path-scoped
  `rules-templates/` starter files (scoped with `paths:` frontmatter;
  `_ai-provider-template.md` is rendered only for products with an AI/LLM
  provider).

## The two-file skill pattern

`skills/<stage>/SKILL.md` is the always-loaded layer: frontmatter (`name`,
`description`, `effort`, `metadata.version` — `version` is not a supported
top-level key, so it lives under `metadata`), prerequisite STOP/WARN checks,
critical framing, and the execution flow. It opens by pointing at
`${CLAUDE_SKILL_DIR}/references/<stage>-detailed-guide.md`, the on-demand layer
holding full teammate spawn prompts, report templates, gate tables, and known
failure patterns.

All 23 skills follow this. Keep the split: moving spawn prompts up into
`SKILL.md` inflates the cost of every invocation of that stage, including the
invocations that never spawn anything.

Path variables are `${CLAUDE_SKILL_DIR}` for skill-internal paths and
`${CLAUDE_PLUGIN_ROOT}` for plugin-root paths. Never hardcode either, and never
write `${CLAUDE_SKILL_ROOT}` — it is not a Claude Code variable and is left
unsubstituted (this plugin shipped with it through v3.0.1). In `commands/`,
argument indices are 0-based: `$0` is the first argument.

## Gate enforcement

`hooks/hooks.json` registers `hooks/scripts/check-prerequisites.sh` on two
events: `PreToolUse` with the `Skill` matcher (fires when Claude invokes a stage
skill, including from `/transmuter:cast <stage>`), and `UserPromptExpansion`
with a matcher listing the 23 stage names (fires when the user types
`/transmuter:<stage>` directly — that path never reaches `PreToolUse`). The
script reads the hook JSON from stdin, extracts the stage name from
`tool_input.skill` / `tool_input.skill_name` / `command_name`, strips a
`transmuter:` prefix, and checks per stage that prior-stage artifacts exist.
To block it writes the `BLOCK:` reason to stderr and exits **2**; exit code 1
is a non-blocking error in Claude Code (the message is shown and the stage runs
anyway), which is how the gates silently stopped gating before v3.1.0. It is
macOS-compatible by design (`sed`, no `grep -P`).

The former `.claude-plugin/hooks/` copy (an unsupported `before:skill` schema)
was deleted in v3.1.0; `plugin.json` declares no `hooks` field, so
`hooks/hooks.json` is found by auto-discovery.

## Conformance script

`scripts/conformance.sh` is the repository's test suite. Static checks (seconds, offline) verify the manifest, that every stage lands in `commands/cast.md`, the hook, the Stage Skills Map and the README, the Claude Code 2.1 facts above, and the gate hook's behaviour against fixtures (credential tiers, the Stage 4 placeholder check, the 5V bypass). `--live` loads the plugin with `claude -p` in a temporary directory and checks that `/transmuter:<stage>` is gated, that `/transmuter:cast help` prints the stage list and that `/transmuter:cast <stage>` routes `$0`. `examples/sample-plan/` is the fixture business plan for manual end-to-end runs.

## Opt-in execution modes (documented, not defaulted)

Claude Code 2.1 offers three frontmatter fields that would change how stages
run. They are recorded here with the reason each stays off until a measured
trial run shows it helps:

- `context: fork` (+ `agent`) on a skill runs it in a fresh subagent context.
  It would implement "Stage 5B runs with a fresh context window" without the
  operator opening a new session, but a forked skill cannot ask the operator
  anything (5B's "operator confirms 5B was intentionally skipped" override,
  6V's mode choice), and it runs in the background by default.
- `isolation: worktree` on `feature-*` agents or the 6A/6B/6C stages would
  give each parallel teammate its own git worktree, turning the "shared config
  files silently overwritten" hazard into an explicit merge. Stage 5's
  opt-in parallel waves (`tech-stack.md` § "Stage 5 parallel waves") use
  lead-managed `git worktree` per feature for the same reason; the agent-level
  field is not used because one feature's three teammates must share a tree.
- `allowed-tools` / `disallowed-tools` on the find-only stages (6A, 6B, 6V,
  6H, 7V) could enforce "never modify application code" by permission instead
  of prose; it needs a per-stage tool list because those stages still write
  reports and test files.

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
- The repository moved from `masterleopold/` to `VoxTechnologies/`, and all repo
  URLs were rewritten accordingly. One `masterleopold` reference remains, in
  `.github/FUNDING.yml`, and it is correct: that field takes a GitHub Sponsors
  **username**, not a repo path. A repo-wide rename that "finishes the job"
  there would redirect sponsorship to a different account.
