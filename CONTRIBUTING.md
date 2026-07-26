# Contributing to Transmute Framework

Thank you for your interest in contributing to Transmute. This guide covers how the plugin is structured and how to make changes.

## Getting Started

1. **Fork** the repository on GitHub
2. **Clone** your fork locally:
   ```bash
   git clone https://github.com/<your-username>/transmute-framework.git
   cd transmute-framework
   ```
3. **Create a branch** for your work:
   ```bash
   git checkout -b feat/my-change
   ```
4. **Make your changes** and test them
5. **Commit** with a descriptive message:
   ```bash
   git commit -m "feat(stage-name): description of change"
   ```
6. **Push** and open a Pull Request against `main`

### Commit Message Convention

Use conventional commits: `type(scope): description`

| Type | Use for |
|------|---------|
| `feat` | New features, new stages |
| `fix` | Bug fixes, gate corrections |
| `docs` | Documentation changes |
| `refactor` | Code restructuring without behavior change |
| `style` | Formatting, whitespace |
| `chore` | Maintenance, tooling |

## Plugin Architecture

```
transmute-framework/
├── .claude-plugin/plugin.json   # Plugin manifest
├── commands/cast.md             # Pipeline controller (/transmuter:cast)
├── agents/                      # 7 agent definitions (pipeline orchestrator + feature teams)
├── skills/                      # 23 stage skills (one per pipeline stage)
│   └── <stage-name>/
│       ├── SKILL.md             # Skill definition with frontmatter + instructions
│       └── references/          # Optional detailed guides loaded via ${CLAUDE_SKILL_ROOT}
├── hooks/
│   ├── hooks.json               # Hook registration (PreToolUse gate enforcement)
│   └── scripts/
│       └── check-prerequisites.sh   # Gate enforcement script
└── templates/
    ├── CLAUDE.md                # Generated project CLAUDE.md template
    ├── progress.md              # Progress tracking template
    ├── execution-guide.md       # Canonical stage reference document
    ├── feature_scenario_generation.md  # Scenario extraction algorithm for 6V/7V
    ├── _rules-candidates.md     # Rule candidate staging area template
    └── rules-templates/         # Stage 3 starter rule templates
        ├── _api-contracts-template.md
        ├── _auth-template.md
        ├── _backend-template.md
        ├── _data-model-template.md
        ├── _frontend-template.md
        └── _testing-template.md
```

## How to Add a New Stage

1. Create a skill directory: `skills/<stage-name>/SKILL.md`
2. Add frontmatter with `name`, `description`, and `version`
3. Add the stage to the mapping table in `commands/cast.md`
4. Add prerequisite checks in `hooks/scripts/check-prerequisites.sh`
5. Add the stage row to `agents/transmute-pipeline.md` Stage Skills Map
6. If the stage has complex instructions, add a `references/` subdirectory

A stage also appears in the templates, README tables, and version metadata. See the full eight-place checklist in [docs/plugin-architecture.md](docs/plugin-architecture.md#the-consistency-invariant) before opening the PR.

## How to Modify an Existing Stage

1. Read the full SKILL.md — understand what it does
2. If the skill has a `references/` directory, read those too
3. Make your changes
4. Test by running the stage against a sample business plan

## File Conventions

- **Paths**: Project artifacts use `./plancasting/` prefix. Code output dirs (`src/`, `docs/`, `seed/`) stay at project root
- **Plugin variables**: Use `${CLAUDE_SKILL_ROOT}` for skill-internal paths, `${CLAUDE_PLUGIN_ROOT}` for plugin-root paths
- **Skill names**: Short names without prefix (e.g., `brd`, not `transmute-brd`)

## Testing

There is no automated test suite — the plugin is prompt engineering, not traditional code. To validate changes:

1. Create a test project with a simple business plan in `plancasting/businessplan/`
2. Run the modified stage: `/transmuter:cast <stage-name>`
3. Verify the output matches expectations

## Areas Needing Help

We welcome contributions in these areas:

- **New stage ideas** — additional pipeline stages for specific workflows
- **Documentation improvements** — clearer explanations, examples, tutorials
- **Gate logic refinements** — edge case handling, better error messages
- **Template improvements** — better starter rules, more robust CLAUDE.md template
- **Bug reports** — especially for specific tech stack + business plan combinations

Look for issues labeled [`good first issue`](https://github.com/VoxTechnologies/transmute-framework/labels/good%20first%20issue) or [`help wanted`](https://github.com/VoxTechnologies/transmute-framework/labels/help%20wanted) for entry points.

## Reporting Issues

When filing a bug report, include:
- Stage number and name
- Business plan type (what kind of product)
- The error or unexpected output
- Claude Code version (`claude --version`)

## Code Style

- Markdown files use `---` frontmatter delimiters
- YAML values with colons must be quoted
- Prefer explicit instructions over implicit assumptions in skill prompts
