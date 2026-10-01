# Rules Candidates

> **Auto-generated staging area for rule candidates.** Do not edit the format section below.

## Purpose

During pipeline execution, Stages 5B (Completeness Audit) and 6R (Remediation) discover recurring implementation patterns and anti-patterns. Instead of immediately adding them to `.claude/rules/`, they are staged here as candidates for human review.

## Review Workflow

1. **Stages 5B and 6R** append MEDIUM and LOW confidence candidates to this file. HIGH confidence rules go directly to `.claude/rules/` (see CLAUDE.md § Path-Scoped Rules). (Stage 3 generates starter rules directly to `.claude/rules/` at HIGH confidence — it does not use this candidates file.)
2. **Operator reviews** candidates after each stage completes.
3. **Promote, edit, or discard** based on confidence level:
   - **HIGH** — Promote directly to the target `.claude/rules/` file. Copy the Rule Text verbatim.
   - **MEDIUM** — Edit the Rule Text to generalize, then promote to `.claude/rules/`.
   - **LOW** — Keep for observation. Promote if the pattern recurs in a later stage. Discard if it does not recur after two more stages.

## Beyond this project

Rules that prove out here and are not specific to this product (no feature IDs, no project-only paths, no product nouns) are stack-level knowledge the framework should carry for the next project. Stage 9 exports such rules to `plancasting/_rules-export.md`; the framework maintainer folds them into the canonical `rules-templates/` on the next sync (CONTRIBUTING.md § Promoting rules from projects).

## Confidence Criteria

- **HIGH**: 2+ distinct features (separate FEAT-IDs) affected with a clear, repeatable pattern. Two occurrences within the same feature count as 1 feature.
- **MEDIUM**: Single feature affected, but the pattern is generalizable to other features. The rule would likely prevent similar issues.
- **LOW**: Edge case, uncertain whether the pattern will recur, or the fix is context-dependent. Discard if the pattern does not recur in the next two rounds of Stage 5B or 6R execution.

## Candidate Format

Each candidate follows this structure:

```markdown
### [Descriptive Title]
- **Source Stage**: 5B / 6R (valid values: `5B` or `6R` only — other stages generate rules directly to `.claude/rules/` at HIGH confidence)
- **Date Added**: [YYYY-MM-DD — required for staleness policy's 60-day check]
- **Evidence**: [issue ID, commit hash, or PRD ref]
- **Trigger**: [what situation triggers this rule]
- **Rule Text**: [the actual rule to add to .claude/rules/]
- **Target File**: `.claude/rules/[filename].md` (include full path)
- **Confidence**: HIGH / MEDIUM / LOW
- **Affected Features**: [list of FEAT-IDs]
```

---

## Staleness Policy

Maximum 30 candidates at any time. If exceeded, discard the oldest LOW-confidence candidates first. Before appending new candidates, count existing entries. If at 30, discard the oldest LOW-confidence candidate to make room. **Staleness timeline**: A candidate is removed if EITHER (a) it is >60 calendar days old and has not been promoted, edited, or re-triggered by a new Stage 5B/6R finding, OR (b) it has been pending for 2+ Stage 9 maintenance cycles without promotion — whichever comes first. Re-triggering (a new Stage 5B or 6R finding that matches the candidate pattern) resets both the 60-day calendar clock and the maintenance-cycle counter. During each Stage 9 run, the operator reviews candidates matching either condition and either promotes (if still valid) or removes them. This prevents stale candidates from accumulating indefinitely. See `plancasting/transmute-framework/prompt_maintain_dependencies.md` § "Path-Scoped Rules Staleness Review" for the review procedure.
See also CLAUDE.md Part 1 § 'Path-Scoped Rules (`.claude/rules/`)' for the full rules specification.

---

## Candidates

<!-- Stages 5B and 6R append candidates below this line. HIGH confidence rules from Stages 5B and 6R go directly to `.claude/rules/` (bypassing this candidates file), while MEDIUM/LOW confidence rules are staged here for operator review. -->

<!-- EXAMPLE START — Stage 5B/6R: Delete everything between EXAMPLE START and EXAMPLE END markers before appending the first real candidate. -->

> **Example entry** (for reference only):
>
> ### Convex Query Requires Index for Pagination
> - **Source Stage**: 5B
> - **Date Added**: 2026-03-01
> - **Evidence**: FEAT-002 (task list)
> - **Trigger**: Any paginated query using `.paginate()` on a Convex table
> - **Rule Text**: Every `.paginate()` call must use an indexed query — unindexed pagination silently falls back to full table scan, causing timeouts on tables with 1000+ rows.
> - **Target File**: `.claude/rules/backend.md`
> - **Confidence**: MEDIUM (single feature — generalizable pattern, but needs confirmation in a second feature to promote to HIGH)
> - **Affected Features**: FEAT-002

<!-- EXAMPLE END -->
