# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

A **Claude Code plugin**, not an application. Every file is markdown prompt engineering plus one bash hook script. No source code, no `package.json`, no build step, no dependency install, no automated test suite.

The plugin drives a 25-stage pipeline (23 automated skills, 2 manual stages) that turns a business plan into a deployed product. Its doctrine is the **Full-Build Approach**: every feature in the plan gets built, and `P0→P3` sets build *order*, never build *scope*. Reject any edit that introduces MVP-style deferral, phasing, or feature cutting.

The plugin is named `transmuter`; the repo and framework are named "Transmute". Commands are therefore `/transmuter:cast` and `/transmuter:<stage>`. That mismatch shipped as a user-facing bug in v3.0.0 — every documented command matched no installed plugin until v3.0.1 fixed it.

## Commands

Nothing to build or lint. To validate a change:

```bash
# Load the plugin for one session, from inside a test project directory
claude --plugin-dir /path/to/transmute-framework
```

```text
# Then run the stage you edited
/transmuter:cast <stage-name>     # e.g. /transmuter:cast brd
/transmuter:<stage-name>          # equivalent direct form
```

A test project needs a business plan at `plancasting/businessplan/*.md` (or `.pdf`). Stage 0 (`tech-stack`) must run before Stage 1, since the prerequisite hook and most skills read `plancasting/tech-stack.md`.

`plancasting/` is an artifact directory *of generated projects*. It never exists in this repository.

## Layout

| Path | Role |
|---|---|
| `commands/cast.md` | `/transmuter:cast` entry point and stage alias table |
| `agents/transmute-pipeline.md` | Pipeline orchestrator: Stage Skills Map, gate logic, progress state |
| `agents/*.md` (6 others) | Teammates spawned by skills, never invoked directly |
| `skills/<stage>/` | One directory per stage, two-file pattern (below) |
| `templates/` | Files copied into generated projects |
| `hooks/` | Live gate-enforcement hook — **not** `.claude-plugin/hooks/`, which is stale |

Each skill splits into `SKILL.md` (always loaded: prerequisites, framing, flow) and `references/<stage>-detailed-guide.md` (loaded on demand via `${CLAUDE_SKILL_ROOT}`: spawn prompts, report templates, gate tables). Keep the split. Use `${CLAUDE_SKILL_ROOT}` and `${CLAUDE_PLUGIN_ROOT}`; never hardcode paths.

## Before calling a stage change complete

A stage edit touches up to eight files, and landing it in only some of them is this repo's most common bug. Grep the stage name repo-wide, and check `SKILL.md`, its detailed guide, `commands/cast.md` (table **and** help text), `check-prerequisites.sh`, the pipeline agent's Stage Skills Map, `templates/`, `README.md`, and the version plus changelog. Full checklist: [docs/plugin-architecture.md](docs/plugin-architecture.md#the-consistency-invariant).

## Terminology that carries meaning

- **`6V-A/B/C`** — fixability categories for Stages 6V/6R. The prefix is mandatory; bare `Category A/B/C` means Stage 5B's *size*-based categories. Mixing them has caused gate-routing bugs.
- **PASS / CONDITIONAL PASS / FAIL-RETRY / FAIL-ESCALATE** — evaluated in that priority order, with numeric thresholds. Do not paraphrase them into vaguer wording.
- **Session Language** — a field in `plancasting/tech-stack.md`, the canonical output-language setting for ~50 files. Downstream stages read it from `tech-stack.md` only. Technical identifiers (`FR-001`, headers, cross-reference codes) stay English.
- **Skill names carry no prefix** — `brd`, not `transmute-brd`.

## Never-break rules encoded in the pipeline

Changes that weaken these are regressions, not refinements.

- Stage 5B always runs after Stage 5 — it catches frontend stubs and duplicate inline implementations that otherwise cascade through Stages 6–7.
- Stages 8 and 9 are never concurrent; both mutate `package.json`, lock files, and source.
- Stages 6A/6B/6C are the only parallel-safe stages, and only with commit-on-completion (shared configs like `next.config.ts` and `middleware.ts` can be silently overwritten).
- 6P and 6P-R are alternatives — one runs, not both.
- Stages 4 (CLAUDE.md Part 2 verification) and 7 (deployment) are manual and must stay non-invocable.

## Further reading

- [docs/plugin-architecture.md](docs/plugin-architecture.md) — layer responsibilities, teammate ownership boundaries, hook internals, consistency checklist, authoring conventions
- [README.md](README.md) — pipeline stages, gate logic, credential tiers, changelog
- [CONTRIBUTING.md](CONTRIBUTING.md) — contribution workflow, commit conventions
