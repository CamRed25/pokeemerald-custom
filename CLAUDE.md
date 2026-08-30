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
12. Follow the commit → merge → next-branch cycle in **Progression** below, only
    once the unit is verified.

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
2. Run `ponytail:ponytail-review` over the objective's own diff (since it branched
   off `custom`) and apply the simplifications it finds. This is a required step
   for every objective before checkpointing, not an occasional cleanup pass —
   optimize the newly written code, don't just review it.
3. If not already on a dedicated feature branch for this objective, create one
   (`feature/<name>`) before committing.
4. Commit the known-good, ponytailed state on that feature branch, staging only
   the files scoped to this objective.
5. Merge that feature branch into `custom`.
6. Re-read `next.md` and determine the next unfinished objective from that file.
7. Branch a new feature branch off the now-updated `custom` for that next
   objective, and continue there according to its stated order and constraints.

This loop (verify → ponytail → commit → merge to `custom` → branch the next
objective → repeat) runs continuously without stopping to ask permission between
objectives, unless blocked — see "When stuck" below.

## When stuck

Keep the loop moving rather than stalling indefinitely on one objective.

**Stuck on a bug**, once `debugger` has already tried and failed to root-cause it:

1. Remove the affected file and reimplement that piece a genuinely different way
   — not a repeat of the same fix.
2. If the reimplementation still doesn't resolve it, fall back to the smallest
   patch that makes the build succeed and leaves existing game behavior
   unaffected (stub out or disable just the broken piece). Never leave the tree
   in a state that fails to build, and never ship a "fix" that breaks something
   that worked before.
3. Either way, note the unresolved bug in `next.md` (same pattern as the existing
   Catch Mode "unreproduced crash" note) — what it is, what was tried, and why it
   didn't work — so it isn't silently lost.

**Stuck on a design question** (a genuinely-could-go-either-way choice, not a
correctness question):

1. Don't stall gathering more evidence, and don't escalate purely for a decision.
2. Make a reasonable medium/middle-of-the-road choice — favor whichever option is
   cheapest to revise if it turns out to be the wrong one — and implement it.
3. Note the decision and the open question in `next.md` for later reconsideration.

This doesn't relax the existing escalation paths (`debugger` for bugs,
`deep-engineer` for real architectural ambiguity) — it's what happens after
those have already been tried and the loop is still stuck.

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
- **deep-engineer** (Opus) — architecture and ambiguous root-cause escalation:
  difficult cross-cutting bugs after Sonnet has made multiple unsuccessful
  attempts, and genuine architectural decisions. Uses
  `mattpocock-skills:codebase-design` when architectural analysis is needed
  and `superpowers:writing-plans` to structure its plans. Not for routine
  implementation, searching, documentation, mechanical editing, or planning
  a large addition/overhaul from scratch — that's `overhaul-planner`.
  Prefers to return an implementation plan for `migration-worker` to execute
  rather than doing all the implementation itself.
- **overhaul-planner** (Opus, read-only, `Read` tool only) — plans a large
  addition or overhaul of an existing system: given target/donor file paths
  from the caller, returns a phased implementation plan for
  `migration-worker`. Does not search the repo itself (no Glob/Grep/Bash) —
  the caller supplies exact paths, keeping this, the most expensive agent in
  the roster, cheap to run. Not for bug root-causing (`deep-engineer`) or
  routine feature ports (`migration-worker`).
