# Emerald → FireRed Migration Workflow

The current migration objective is defined in `next.md`.

At the beginning of every run:

1. Read `next.md` completely.
2. Treat it as the authoritative definition of:

   * the next objective
   * donor repositories
   * allowed donor scope
   * files/areas to investigate
   * exclusions
   * integration order
   * implementation constraints
3. Inspect the target repository and relevant donor code before making changes.
4. Do not duplicate or rewrite `next.md` into this workflow.
5. If this workflow and `next.md` conflict about migration scope, `next.md` wins.

## Model routing

### Haiku

Use for:

* repository exploration
* file and symbol searches
* locating donor implementations
* dependency/reference discovery
* documentation lookup
* documentation updates
* simple mechanical edits with fully specified behavior

### Sonnet

Default model.

Use for:

* normal implementation
* feature ports
* adaptation between Emerald and FireRed
* refactors
* integration
* tests
* builds
* routine debugging
* code review
* behavioral comparison

### Opus

Reserve for:

* architectural decisions
* major additions or overhauls
* large cross-cutting refactors
* ambiguous high-risk integrations
* difficult debugging after Sonnet has failed to establish the cause

When practical, use Opus to determine the solution and return routine implementation to Sonnet.

Do not use Opus merely because a task contains many files.

## Execution

Using the current objective from `next.md`:

1. Analyze the objective and its dependencies.
2. Inspect the target implementation.
3. Inspect only the donor repositories and areas permitted by `next.md`.
4. Build a dependency-aware implementation plan.
5. Follow the integration order specified by `next.md`.
6. Delegate independent work using isolated worktrees when appropriate.
7. Implement primarily with Sonnet.
8. Build and test after each meaningful integration unit.
9. Diagnose and repair failures before moving forward.
10. Compare completed behavior against the permitted donor implementation.
11. Perform an independent review for:

    * missing behavior
    * incorrect adaptation
    * unintended donor code
    * unrelated changes
    * dependency problems
12. Create a checkpoint commit on the feature's dedicated branch only after the unit is verified.
13. Never push automatically.

## Safety constraints

* Donor repositories are references unless `next.md` explicitly states otherwise.
* Never modify donor repositories.
* Respect all exclusions in `next.md`.
* Do not wholesale-copy files when only part of a donor implementation is relevant.
* Adapt donor functionality to the existing target architecture.
* Prefer existing target APIs and infrastructure instead of replacing working systems.
* Do not make unrelated cleanup or modernization changes.
* Do not use destructive Git operations.
* Do not push to a remote.

## Branching and commits

* Each feature/objective from `next.md` gets its own branch, created before implementation begins.
* Branch naming: `feature/<short-feature-name>` (e.g. `feature/quest-menu`, `feature/key-item-wheel`,
  `feature/game-corner`, `feature/merged-bike`).
* Never commit directly to `master`, and never bundle multiple unrelated features' changes into one
  branch/commit — if the current branch already contains finished, unrelated prior work, cut the new
  feature branch from a clean point (or stage only the new feature's files) rather than committing on
  top of it.
* Once a feature branch exists and the unit is verified, committing is allowed without asking first.
* Stage only the files scoped to the current objective (see `next.md`'s per-objective file lists where
  given) — never `git add -A` a branch that has unrelated changes sitting in the working tree.
* Pushing still always requires explicit user instruction — never push automatically, and never force-push.

## Progression

After completing an item from `next.md`:

1. Verify it.
2. If not already on a dedicated feature branch for this objective, create one (`feature/<name>`)
   before committing.
3. Commit the known-good state on that feature branch, staging only the files scoped to this objective.
4. Re-read `next.md`.
5. Determine the next unfinished objective from that file.
6. Continue according to its stated order and constraints.

Do not assume the objective from a previous run is still current. Always consult `next.md`.

## Project subagents

Custom agents live under `.claude/agents/` and override built-ins of the same
name.

**Two-stage handoff agents — read this before invoking `documentation-editor` or
`independent-reviewer`:** both are cheap Haiku evidence/audit stages now. Neither
edits/finalizes anything itself — each returns a compact handoff (`DOC_HANDOFF` /
`REVIEW_HANDOFF`) that MUST be picked up and finished by whoever invoked it (the
main session thread, or the calling workflow phase), acting as the Sonnet stage.
There is no separate "Sonnet reviewer" or "Sonnet doc-editor" agent file — that
finishing step is on you. Invoking one of these two and stopping once you have
the handoff text is an incomplete task, not a completed one:
  - `documentation-editor` → apply the `DOC_HANDOFF`'s proposed edit yourself
    (Edit/Write) and report the resulting diff.
  - `independent-reviewer` → run the bundled `code-review` skill against the
    diff using the `REVIEW_HANDOFF` as pre-filtered evidence, resolve anything
    marked `NEEDS_SONNET_CHECK`, and make the actual accept/reject call.

- **Explore** (Haiku, read-only) — file discovery, symbol/reference searches,
  locating implementations, comparing file structures, gathering information
  for other agents. Preloads `claude-mem:smart-explore` for structural
  search. Cannot edit or write.
- **documentation-editor** (Haiku, stage 1 of 2 — read-only) — verifies facts
  and drafts a `DOC_HANDOFF` for CLAUDE.md, README.md, Progress.md,
  Completed.md, migration notes, changelog entries, and simple non-obvious
  comments. May read implementation code to verify what it documents, but
  cannot edit anything itself — see the handoff rule above.
- **mgba-tester** (Haiku) — emulator operation, screenshots, runtime checks,
  and regression tests via the `.claude/tests/mgba/` harness. Uses
  `superpowers:verification-before-completion` before reporting any result.
  Not for build diagnosis or implementation.
- **migration-worker** (Sonnet) — normal migration implementation and
  integration: extracting donor code per `next.md`, adapting it to this
  codebase, wiring hook points. Uses `superpowers:using-git-worktrees` for
  isolation and `superpowers:verification-before-completion` before handing
  work off. Escalates ambiguous failures to `debugger`, architectural
  decisions to `deep-engineer`.
- **debugger** (Sonnet) — build/runtime failure diagnosis when the cause
  isn't obvious or a prior fix attempt failed. Uses
  `superpowers:systematic-debugging`. Not for routine build-error fixups
  during normal integration — those stay with `migration-worker`.
- **independent-reviewer** (Haiku, stage 1 of 2 — read-only) — cheap first-pass
  audit of a migration unit before checkpointing: runs `ponytail:ponytail-audit`
  once, filters to the current objective/diff, and drafts a `REVIEW_HANDOFF`.
  Does not make the final accept/reject call — see the handoff rule above.
- **deep-engineer** (Opus) — architecture, major subsystem redesigns,
  difficult cross-cutting changes, ambiguous root-cause debugging (after
  Sonnet has made multiple unsuccessful attempts), and planning major new
  functionality. Uses `mattpocock-skills:codebase-design` when architectural
  analysis is needed and `superpowers:writing-plans` to structure its plans.
  Not for routine implementation, searching, documentation, or mechanical
  editing. The sole architecture/escalation agent in this roster — prefers
  to return an implementation plan for `migration-worker` to execute rather
  than doing all the implementation itself.
