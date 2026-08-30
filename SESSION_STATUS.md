# Session status — 2026-08-30

Working notes for the in-progress RHH-base migration session, currently on branch
`custom`. This is a session handoff/status snapshot, not the authoritative objective
definition — `next.md` remains authoritative for scope, donor mapping, and integration
order per `CLAUDE.md`. Read `next.md` in full before continuing; this file just tracks
*where this session left off* and *how it's been operating*.

## Branch state (read this before doing anything git-related)

`custom` is now the consolidated trunk — it has everything: Options Plus, Quest Menu,
Soft Level Scaling, Catch Mode, the SwSh-style UI bundle (party/storage/summary/start
menu), a repo-wide agent-tooling optimization pass, and Key Item Wheel. `master` also
has the agent-tooling commits (cherry-picked, since `.claude/agents/`+`CLAUDE.md` should
be usable from any branch) but none of the game-feature work — `master` tracks upstream
and stays vanilla-plus-tooling. `optimizations` and `feature/swsh-ui-qol-bundle` are now
historical — their content is fully merged into `custom`, nothing new should be added to
them. `Key-wheel` (objective 10's branch) is currently identical to `custom` (just
merged, fast-forward). Builds clean on `custom` as of this session (`make -j$(nproc)`
verified after the merge).

**Per `CLAUDE.md`'s Progression loop** (this session formalized this — read the
"Progression" and "When stuck" sections there first): each objective now gets verify →
ponytail-review (applied) → commit → merge into `custom` → branch the next objective off
`custom`. Don't branch a new objective off anything other than `custom`'s current tip.

## Completed this session

1. **Ponytail audit + fixes on Options Plus / Quest Menu** (`optimizations` branch,
   pre-merge). Dead `CheckConditions` gate removed (always returned TRUE), duplicate
   `try_free`/`try_alloc` macros replaced with the project's existing
   `FREE_AND_SET_NULL`, 12 `if(x) return TRUE; else return FALSE;` wrappers collapsed to
   direct returns (4 needed `!!` normalization — `QuestMenu_GetSetQuestState` returns a
   raw bitmask, not canonical 0/1, and callers do `== TRUE` comparisons). Real ROM
   savings were negligible (~76 bytes) since the compiler had already optimized most of
   the dead branches away — the actual win was source clarity, not size.
2. **Agent-usage optimization pass** (`feature/swsh-ui-qol-bundle`, then propagated to
   `master`/`custom`/`optimizations`). All 7 `.claude/agents/*.md` files were bloated
   ~2x by one-clause-per-paragraph formatting; compressed to ~48% of original size with
   zero content loss (verified line-by-line, every rule/handoff-format preserved).
   Removed a `TeammateIdle` hook (`.claude/settings.json`) that fired a full unpinned
   `claude -p` call on every idle event for 3 agent types regardless of whether they
   were actually stuck — weak targeting, likely the largest hidden usage sink in the
   repo. Pruned 79 of 127 tracked mgba regression screenshots down to one canonical shot
   per name each tracked test script actually produces.
3. **Branch consolidation.** Merged `optimizations` + `feature/swsh-ui-qol-bundle` into
   `custom` (both were strict descendants once `master` was cherry-picked/merged
   through all of them — no conflicts). This is what made `custom` the real trunk again;
   before this it was 4-6 commits behind the actual state of the project.
4. **Created `overhaul-planner`** (Opus, `Read`-only, no search tools, `maxTurns: 10`) —
   distinct from `deep-engineer`: plans large from-scratch additions/overhauls given
   caller-supplied target+donor paths, never searches the repo itself, returns
   `NEEDS_EVIDENCE` rather than guessing. Deliberately the cheapest-to-run shape for the
   most expensive model in the roster.
5. **Formalized the Progression loop and stuck-handling policy in `CLAUDE.md`** — see
   "Progression" and "When stuck" sections there. Also added build-output-filtering
   guidance to `debugger.md`/`migration-worker.md` (pipe through `grep` for
   error/undefined-reference patterns instead of reading the raw log; `debugger` alone
   keeps an exception to pull the full transcript if the filtered view isn't enough).
6. **Objective 10 (Key Item Wheel) — DONE, checkpointed** (commits `34fe990554`,
   `f2ce33e96c` on `custom` via `Key-wheel`). Full detail in `next.md`'s Status summary.
   Highlights:
   - `registeredItems[MAX_REGISTERED_ITEMS]` appended additively to SaveBlock1 (not the
     donor's shrink-`MAX_REMATCH_ENTRIES` approach) — matches this project's own
     precedent from Quest Menu.
   - Caught a real bug via direct code review before checkpointing (not just
     build-clean): `tUsingRegisteredKeyItem`'s task-data index had drifted out of sync
     between `item_menu.c` and `item_use.c`. `migration-worker` moved it to make room
     for the wheel's own sprite-slot data without realizing the macro's actual use-site
     is a *different* task. One-line fix.
   - Runtime verification needed a new debug-menu shortcut (`Debug_RegisterKeyItems`,
     wired to `Debug_EventScript_Script_2`) because two separate `mgba-tester` attempts
     couldn't reliably navigate the Bag to register 2 items under Xvfb/xdotool timing.
     With that shortcut, direct verification succeeded: wheel opens with correct box
     placement/icons, D-pad selection dispatches the right item, confirmed end-to-end via
     the vanilla "Dad's advice, can't ride here" message (which also exercises the fixed
     code path). New tracked regression test:
     `.claude/tests/mgba/features/key_item_wheel_test.sh`.

## What's next

Per `next.md`'s triage ranking, the next unscheduled objective is **#11 (Registered-item
shortcut menu, 60%)** — deliberately sequenced after #10 so its design question (the
donor's 10-slot `RegisteredItemSlot registeredItems[10]` vs. the wheel's now-real 4-slot
`registeredItems[MAX_REGISTERED_ITEMS]`) can be resolved against a concrete SaveBlock1
layout instead of guessing blind. Donor: `ebears/pokeemerald-bear`
(`tx_registered_items_menu.c`, ~719 LOC, already cloned at
`/home/cam/Documents/repos/donors/pokeemerald-bear`). Decide whether it's the same
underlying storage as the wheel (reconcile slot counts / pick one canonical array) or a
genuinely separate system before implementing.

After that: #15b (move-info panel, 55%, same donor as Catch Mode). #13/#14 stay blocked
(no usable donor found yet for either).

Branch a new one off `custom`'s current tip (`feature/registered-item-shortcut` per
convention, or match whatever short name the user gives) when starting #11 — don't
branch off `optimizations`/`feature/swsh-ui-qol-bundle`, they're stale now.

## How this session has been operating (continue this way)

- **Follow `CLAUDE.md`'s Progression loop** — verify → ponytail-review (apply the
  fixes) → commit (scoped, pathspec-limited if the branch has unrelated staged content)
  → merge to `custom` → branch the next objective. Don't stop to ask between objectives
  unless genuinely blocked; see `CLAUDE.md`'s "When stuck" for the bug/design-question
  escalation paths.
- **Subagents reliably hit their turn budget mid-task.** Every `Explore`,
  `migration-worker`, and `mgba-tester` dispatch this session stopped at its turn limit
  at least once. Fix: `SendMessage` to the same agent, telling it explicitly what to
  drop and to report now from what it has — don't let it keep grinding on its own
  judgment of when to stop. `mgba-tester` in particular has a failure mode where it
  starts *writing a new permanent test script* instead of doing the one-shot
  verification asked for, burning its whole budget before reaching the emulator at all —
  if that happens, redirect it explicitly: no new script file, drive the harness
  functions directly.
- **Never trust a subagent's self-reported PASS/FAIL — check the actual screenshots.**
  This session: an `mgba_key` call using the wrong key name (`SELECT`/`DPAD_UP` instead
  of the harness's actual `BackSpace`/`Up`) silently no-op'd with a warning easy to miss
  in scrollback; a screenshot literally named `..._wheel_open_two_items.png` was still
  showing the Bag screen, not the wheel, when actually opened and viewed. `mgba_key`'s
  real mapping (`harness.sh` line ~90 comment): A=x, B=z, L=a, R=s, Start=Return,
  Select=BackSpace, D-pad=Up/Down/Left/Right (capitalized, not `DPAD_*`).
  Same pattern was seen in a prior session with Catch Mode (title-screen demo mistaken
  for a real battle) — this is a recurring failure mode, not a one-off.
  Read the PNGs yourself before believing a written verification claim.
- **Corrupted zero-byte `.o` files after an interrupted build are a real, recurring
  failure mode**, not just a hypothetical — hit it twice now (once with Catch Mode per
  the prior session's notes, once this session with Key Item Wheel: `battle_util.o`,
  `berry_blender.o`, `player_pc.o` were all 0 bytes with a newer mtime than their
  source, so Make considered them up to date and skipped recompiling them, producing a
  huge pile of unrelated-looking linker "undefined reference" errors). Diagnostic:
  `find build/emerald -name "*.o" -size 0`. Fix: delete the zero-byte ones and rebuild.
- **Rebuild output should be filtered, not read raw**, per the new instruction in
  `debugger.md`/`migration-worker.md` — `make ... 2>&1 | grep -iE "error|undefined
  reference"` costs tokens proportional to the actual error. Only fall back to the full
  transcript (debugger only) when the filtered view doesn't actually explain the
  failure.
- **Donor repos are cloned locally, reuse them — don't re-clone.**
  `/home/cam/Documents/repos/donors/emerald-plus` (zanderb27/emerald-plus),
  `/home/cam/Documents/repos/donors/pokeemerald-bear` (ebears/pokeemerald-bear),
  `/home/cam/Documents/repos/donors/worpbane-worped-ex` (worpbane/pokeemerald-worped-ex).
  Read-only references per `CLAUDE.md` — never modify them.
- **`next.md` is authoritative for scope; this file is not.** If this file and `next.md`
  disagree, trust `next.md`. Update or delete this file once its "What's next" is
  worked through, per `CLAUDE.md`'s instruction not to duplicate `next.md` long-term.
