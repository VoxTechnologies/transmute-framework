---
description: Run the Transmute pipeline — full build or specific stage
argument-hint: '[stage-name|"full"|"resume"]'
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, Skill
---

# /transmuter:cast — Transmute Pipeline Controller

The user invoked `/transmuter:cast $ARGUMENTS`. The first argument is available as `$0` (argument indices are 0-based: `$0` is the first argument, `$1` the second). Parse `$0` to determine the mode.

## Mode Detection

Examine `$0`:

- **Empty, or `full`**: Run the full pipeline via the `transmute-pipeline` agent (unattended)
- **`attended`**: Run the full pipeline, stopping once after Stage 2B for the operator to approve the feature map (see the pipeline agent's Run Modes)
- **`resume`**: Resume the pipeline from the last completed stage via the `transmute-pipeline` agent
- **`help` or `?`**: Display the help text below
- **Any other value**: Match against the Stage Name Mapping table and invoke that stage's skill

## Stage Name Mapping

| Argument ($0) | Skill to Invoke | Stage |
|---|---|---|
| `tech-stack` | tech-stack | 0 |
| `brd` | brd | 1 |
| `prd` | prd | 2 |
| `validate` or `validate-specs` | validate-specs | 2B |
| `scaffold` | scaffold | 3 |
| `implement` | implement | 5 |
| `audit-completeness` or `audit` | audit-completeness | 5B |
| `security` or `audit-security` | audit-security | 6A |
| `a11y` or `accessibility` or `audit-a11y` | audit-a11y | 6B |
| `optimize` or `performance` | optimize | 6C |
| `docs` or `documentation` | docs | 6D |
| `refactor` | refactor | 6E |
| `seed-data` or `seed` | seed-data | 6F |
| `harden` or `resilience` | harden | 6G |
| `prelaunch` or `pre-launch` | prelaunch | 6H |
| `early-verify` or `5v` | verify, invoked with the argument `MODE: critical` (early runtime check after 5B) | 5V |
| `verify` or `verification` | verify | 6V |
| `remediate` or `remediation` | remediate | 6R |
| `polish` | polish | 6P |
| `redesign` or `frontend-redesign` or `design-elevation` | redesign | 6P-R |
| `smoke` or `smoke-test` | smoke | 7V |
| `user-guide` or `guide` | user-guide | 7D |
| `feedback` | feedback | 8 |
| `maintain` or `maintenance` | maintain | 9 |

If `$0` does not match any entry, show the help text and ask the user to try again.

## Execution

### Full Pipeline or Resume Mode

Spawn the `transmute-pipeline` agent using the Agent tool with the appropriate instruction:

- **Full mode**: "Run the complete Transmute pipeline from Stage 0 through Stage 9 unattended. Read `plancasting/_progress.md` if it exists to skip already-completed stages."
- **Attended mode**: "Run the complete Transmute pipeline from Stage 0 through Stage 9 in attended mode: stop after Stage 2B for the operator's feature-map sign-off as described in your Run Modes. Read `plancasting/_progress.md` if it exists to skip already-completed stages."
- **Resume mode**: "Resume the Transmute pipeline from the last completed stage. Read `plancasting/_progress.md` to determine current state."

### Specific Stage Mode

Invoke the corresponding skill directly using the Skill tool. For example, if `$0` is `brd`, invoke the `brd` skill.

Before invoking a specific stage:
1. Check if `plancasting/_progress.md` exists and warn if prerequisites are not met
2. Tell the user which stage is about to run and its expected output
3. Invoke the skill using the Skill tool

## Help Text

If `$0` is `help`, `?`, or unrecognized, print the block below verbatim (same language, same layout — it is reference material, not prose to paraphrase):

```
Transmute Pipeline — AI-driven business plan to production

Usage:
  /transmuter:cast              Run full pipeline (Stage 0-9)
  /transmuter:cast full         Same as above (unattended)
  /transmuter:cast attended     Full pipeline with one sign-off after Stage 2B
  /transmuter:cast resume       Resume from last completed stage
  /transmuter:cast <stage>      Run a specific stage

Individual stages (also invocable directly as /transmuter:<stage>):
  tech-stack (0), brd (1), prd (2), validate-specs (2B), scaffold (3),
  implement (5), audit-completeness (5B), early-verify (5V), audit-security (6A),
  audit-a11y (6B), optimize (6C), docs (6D), refactor (6E),
  seed-data (6F), harden (6G), prelaunch (6H), verify (6V),
  remediate (6R), polish (6P), redesign (6P-R), smoke (7V),
  user-guide (7D), feedback (8), maintain (9)

Note: redesign (6P-R) is an alternative to polish (6P) — run one, not both

Automated checks and manual stages (not invocable):
  Stage 4 — CLAUDE.md verification: automated (pipeline agent + gate hook before Stage 5)
  Stage 7 — Deployment: manual by default (deploy backend before frontend);
            automated when tech-stack.md sets Deployment: automated

Examples:
  /transmuter:cast brd          Generate Business Requirement Document
  /transmuter:cast implement    Run feature implementation orchestrator
  /transmuter:cast redesign     Run frontend design elevation
  /transmuter:cast resume       Continue from where you left off
  /transmuter:brd               Run BRD stage directly
```
