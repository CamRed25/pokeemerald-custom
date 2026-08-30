# Session status — 2026-08-30 (continued)

Working notes for the in-progress RHH-base migration session. This is a session
handoff/status snapshot, not the authoritative objective definition — `next.md` remains
authoritative for scope, donor mapping, and integration order per `CLAUDE.md`. Read
`next.md` in full before continuing; this file just tracks *where this session left off*
and *how it's been operating*.

## Objective 11 (Registered-Item Shortcut Menu) — DONE

Checkpointed 2026-08-30 on `feature/registered-item-shortcut-menu`, merged to `custom`.
Full implementation writeup, the scope-narrowing decision (Key Items pocket only, not
"any item" as `next.md` originally envisioned — party-menu-type items like medicine need
different dispatch plumbing this pass didn't build), and the open follow-up item all live
in `next.md`'s objective 11 entry — read that, not this file, for the authoritative record.

Runtime-verified end to end (L opens the menu listing registered key items, item use,
reopen/cancel, Bag SHORTCUT toggle, Key Item Wheel unaffected) with real screenshot
evidence for every step. `make check` confirmed clean (only the pre-existing baseline
`KNOWN_FAILING`/`EXPECTED_FAIL`/`TO_DO`/labeled-`CRASH` entries, no new regressions).

**Incidents worth knowing about from this objective's verification pass** (details in this
project's persistent memory, not repeated here): a subagent ran a build command mid-way
through an unrelated multi-hour `make check` run and corrupted it — recovered by rebuilding
and re-running `make check` clean, and the `mgba-tester` agent definition now hard-bans
build commands. A second false regression report (Key Item Wheel "INVALID ITEM" crash) turned
out to be a test-script gap (skipped the Wheel's own setup special before checking it), not
real code — confirmed by directly re-running the Wheel's own already-passing dedicated test.

## How this session has been operating (continue this way)

- **Subagents reliably hit their turn budget mid-task.** Resume via `SendMessage` to the
  *same* agent (never spawn a fresh one to "continue" — it has no context). This happened
  repeatedly during Objective 11's runtime verification.
- **Never run `make`/`make clean`/any build command from `mgba-tester`** — it shares
  `build/` with this project's multi-hour `make check` runs and can corrupt one in progress.
  This is now a hard rule in `mgba-tester`'s own agent definition; don't rely on prompt text
  alone to prevent it happening from any other agent either.
- **Never run a concurrent `make`/build yourself while a `make check` is in progress**,
  even a small one — same shared `build/` directory risk. Pause or confirm the other run's
  state first.
- **Don't trust a runtime-verification agent's PASS claim without looking at the actual
  screenshot evidence yourself** — this session hit both a harness bug (screenshots
  silently going blank while the agent still reported PASS) and a false-positive "regression"
  (a test script's own setup gap misreported as a game-code bug). Spot-check the images.
- **Background `make check` runs**: launch with `nohup ... > log 2>&1 < /dev/null & disown`
  directly in `Bash` (fully detached from the tool's own job tracking), then poll/`Monitor`
  a `while kill -0 <pid>; do sleep N; done` loop — this survives where a tool-tracked
  background job doesn't.
- **When you need one arithmetic fact out of a multi-hour test suite** (e.g. a SaveBlock
  size constant), read the failing test's own `EXPECT_EQ(actual, expected)` message rather
  than trying to shortcut it with an ad hoc standalone compile.
- **Donor repos are cloned locally, reuse them — don't re-clone**:
  `/home/cam/Documents/repos/donors/emerald-plus`, `/home/cam/Documents/repos/donors/pokeemerald-bear`,
  `/home/cam/Documents/repos/donors/worpbane-worped-ex`. Read-only references per
  `CLAUDE.md` — never modify them.
- **`next.md` is authoritative for scope; this file is not.** If this file and `next.md`
  disagree, trust `next.md`.

## What's next

Re-read `next.md`'s Status summary and triage ranking for the next unfinished objective
after Objective 11, and branch that off `custom`'s new tip.
