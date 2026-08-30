# Session status — 2026-08-29

Working notes for the in-progress RHH-base migration session on branch
`feature/swsh-ui-qol-bundle`. This is a session handoff/status snapshot, not the
authoritative objective definition — `next.md` remains authoritative for scope, donor
mapping, and integration order per `CLAUDE.md`. Read `next.md` in full before continuing;
this file just tracks *where this session left off* and *how it's been operating*.

## Side branch: `optimizations` (2026-08-29, off this branch's HEAD)

Created at the user's request to audit everything added since the fork
(`4dc3dc6588`, verified via `git merge-base HEAD RHH/master`) for optimization
opportunities — 9 areas, 51 source/header files. **Conclusion: the codebase is
already well-behaved.** Real, in-scope findings after rigorous checking: 2 tiny
ones — dead debug `DebugPrintf` instrumentation removed from `dma3_manager.c`'s
per-VBlank hot path (was stray uncommitted cruft, not even staged), and an
unused `TestDrawSprite()` debug/test function removed from `even_sprite.c`/`.h`.
Everything else checked out clean: menu/UI code is event-driven
(`JOY_NEW`-gated, not per-frame) so recalculation cost is negligible regardless
of what it does; several flagged patterns turned out to be verbatim code
inherited from the pre-fork upstream (`pokemon_storage_system.c`,
`pokemon_summary_screen.c`, `option_menu.c`) rather than anything this
migration introduced, so out of scope; Quest Menu's apparent O(n²) sort is
trivial since `QUEST_COUNT` is currently only 2. **Note for future sessions:**
the `Explore` agent has no Bash access (Read/Glob/Grep/Skill only) — it cannot
run `git diff`/`git show` itself despite being asked to; extract diffs via
Bash yourself first and hand them over, or verify its "checked against
pre-fork" claims independently before trusting them.

## In flight right now

- **Objective 10 — Key Item Wheel.** Up next. See Todo item 1 below for the full donor map
  and the `MAX_REMATCH_ENTRIES` risk to check before implementing.

## Completed this session

-1. **Objective 15a (Catch Mode) — checkpointed.** Commit `cc3a11e840` (2026-08-29), scoped
   to 14 files (5 headers, 5 .c files, 4 new PNGs — see the commit message for the full
   list). Took three `migration-worker` passes (damage-clamp/scaffolding, then Options
   Plus/R-button/battle_main.c wiring, then the visual indicator sprite — each hit a
   36-50 turn limit and needed a `SendMessage` nudge to wrap up and report). Along the
   way: a build failure the worker misdiagnosed as "pre-existing/unrelated" turned out to
   be a genuinely stale zero-byte `build/emerald/src/main_menu.o` from an earlier
   interrupted build (root-caused by a `debugger` subagent, confirmed independently by
   this session via `git stash`/rebuild before AND after the debugger's fix). Runtime
   verification: the Options Plus menu toggle was confirmed via mGBA screenshots; the
   in-battle R-button toggle / indicator sprite / damage-clamp could **not** be confirmed
   via the automated `mgba-tester` harness after **four separate attempts** (two got stuck
   in the title-screen idle demo loop and mistook the credits/staff-roll animation for a
   battle, two more with better save fixtures still failed to trigger a wild encounter
   from repeated grass-walking) — this is a harness/navigation limitation, not a code
   signal. **The user manually tested the built ROM directly and confirmed Catch Mode
   works** (menu toggle and in-battle R-button toggle) — that manual confirmation is what
   this checkpoint relies on for the in-battle piece, not the automated harness. The user
   also reported a one-off "crashed to desktop" incident while in the Options Plus menu
   (possibly related to toggling Match Calls, possibly not — they were unsure) but later
   confirmed Catch Mode itself worked before that crash, and a dedicated `mgba-tester`
   repro attempt (basic toggle sequence, aggressive rapid toggling, save/reload cycle) could
   not reproduce it. **Treat as an open, unconfirmed lead, not resolved** — if it recurs,
   get the exact button sequence and any mGBA log output.
0. **Objective 12 (Soft level scaling) — checkpointed.** Commit `c1991a88c2` on this branch
   (2026-08-29), scoped to `src/wild_encounter.c` only. The prior session's `migration-worker`
   had already produced the diff (working-tree, uncommitted) — this session verified it against
   the donor (`ebears/pokeemerald-bear`), confirmed the port is faithful (and slightly improved:
   divides by actual `monCount` instead of a hardcoded `PARTY_SIZE`, guards the `monCount == 0`
   case the donor doesn't), built clean via `make -j$(nproc)`, ran a boot smoke test (PASS,
   `.claude/tests/mgba/screenshots/boot_smoke_20260829_064402.png`), then did the scoped
   pathspec-limited commit. Note: the donor map's `GetPartyMonCurvedLevel()` in `pokemon.c` was
   NOT ported there — the worker inlined it directly in `wild_encounter.c` as a `static`
   function instead, since nothing else needs to call it. `src/pokemon.c`'s staged `M` in the
   index is unrelated leftover from other objectives, untouched.
1. **Quest Menu (objective 9) — checkpointed.** Commit `24c45661b8` on this branch. All 6
   previously-blocking bugs resolved (see `next.md`'s "Open bugs / issues — RESOLVED"
   section for full detail): a real text-engine bug (unbounded right-edge glyph clip in
   `src/text.c`'s `RenderFont`) was root-caused and fixed by hard-wrapping two placeholder
   description strings in `src/quests.c`; three other listed bugs turned out to already be
   fixed in the working tree; `test/save.c`'s SaveBlock2/3 size constants were updated to
   match legitimate size growth (not regressions).
2. **`make check` verified clean.** 4937 passed, 0 failed (13 known-failing, 595 to-do, 8
   expect-failing — all pre-existing/expected). Confirms the SaveBlock2 additive extension
   for Quest Menu didn't regress anything.
3. **Corrected a stale claim in `next.md`.** It previously said objectives 1-8 were "DONE,
   checkpointed" — actually verified via `git log` that only "Add Options Plus" / "Wire up
   Options Plus menu and New Game Options" are committed on this branch. Objectives 2-8's
   files (~157 files, ~19.6k insertions) are sitting **staged but uncommitted** in the
   index, left over from a prior session. **Do not touch or commit these** unless you're
   specifically doing one of those objectives' own scoped checkpoint — they're not part of
   objective 12 or anything else currently in flight.
4. **Triaged objectives 10-15** (full detail in `next.md`'s "Objective 10-15 triage"
   section) by cloning the real donor repos and verifying (not assuming) each feature
   actually exists in them. Ranked by incorporation-readiness:

   | Rank | Objective | % | Status |
   |---|---|---|---|
   | 1 | 12 — Soft level scaling | 95% | **in flight now, see above** |
   | 2 | 15a — Catch Mode | 88% | next up |
   | 3 | 10 — Key Item Wheel | 75% | queued |
   | 4 | 11 — Registered-item shortcut menu | 60% | queued, sequence after #10 (see below) |
   | 5 | 15b — Improved move-info panel | 55% | queued, do after 15a |
   | 6 | 13 — Mugshots + dialogue nameplates | 15% | **blocked**, no usable donor |
   | 7 | 14 — Enhanced lighting | 12% | **blocked**, donor feature doesn't exist |
   | — | 16/17 — Game Corner / Battle Frontier | unscored | no donor identified yet |

## Todo, in order

Work through these one at a time (see "How this session has been operating" — agents are
being run in series, not parallel, per explicit user instruction this session).

1. ~~Objective 12 — Soft level scaling~~ (in flight, see above)
2. **Objective 15a — Catch Mode.** Donor: `worpbane/pokeemerald-worped-ex` (already cloned
   at `/home/cam/Documents/repos/donors/worpbane-worped-ex`). Donor map from prior
   discovery: `IsCatchModeAvailableInBattle()` / `TryApplyCatchModeDamageClamp()` in donor
   src/battle_util.c:246-267, damage-calc hook at donor src/battle_util.c:7979, toggle in
   donor src/battle_controller_player.c:834-839 (R-button), visual indicator in donor
   src/battle_interface.c (~2965-3078), SaveBlock2 bitfield `w_opCatchMode:1` (donor
   include/global.h:621), menu entry in donor src/option_plus_menu.c (multiple lines, see
   next.md triage section for full list). Target already has Options Plus
   (`src/option_plus_menu.c`) as the natural home for the toggle. Small/low-risk per triage.
3. **Objective 10 — Key Item Wheel.** Donor: `zanderb27/emerald-plus` (already cloned at
   `/home/cam/Documents/repos/donors/emerald-plus`, feature lives in `master` branch's
   `src/item_menu.c:2385-2462` `Task_KeyItemWheel()` despite the donor's own README naming
   a now-nonexistent "key-item-wheel" branch — don't waste time looking for that branch,
   the code is in master). **Key risk to resolve before implementing:** donor frees 8 bytes
   for its 4-item registry by shrinking `MAX_REMATCH_ENTRIES` 100→92; target still has the
   full 100-entry table and a single-slot `registeredItem` (not an array) — verify the
   target's rematch code doesn't hardcode assumptions about 100 slots before doing the same
   shrink. Needs new graphics (`key_item_box.png`/`.4bpp`/`.gbapal`, donor uses BG palette
   slot 13 — verify that's free in target) and target's dark-cave OBJWIN rendering path
   support. Full discovery detail in the (now-cleared) conversation, but re-derivable via
   the same donor path if needed — an Explore agent can re-survey this quickly if the
   original discovery notes aren't in context anymore.
4. **Objective 11 — Registered-item shortcut menu.** Donor: `ebears/pokeemerald-bear`
   (already cloned at `/home/cam/Documents/repos/donors/pokeemerald-bear`,
   `tx_registered_items_menu.c`, ~719 LOC, `TxRegItemsMenu_*` functions, ~line 140 onward).
   **Deliberately sequenced after #10**, not before, despite next.md's original "High
   priority" label on this one — the donor's shortcut menu uses a 10-slot
   `RegisteredItemSlot registeredItems[10]` array while the Key Item Wheel (#10) uses a
   4-slot scheme, and next.md doesn't clarify whether these are the same underlying storage
   or two independent systems. Resolve that design question with #10's actual SaveBlock1
   layout in hand before implementing this one — don't implement blind.
5. **Objective 15b — Improved move-info panel.** Same donor as 15a. Independent of Catch
   Mode (no shared state), but touches the same files (`battle_interface.c`,
   `option_plus_menu.c`) so it's efficient to do right after 15a in one integration pass.
   Donor: `TryToAddMoveInfoWindow()` / `TryToHideMoveInfoWindow()` /
   `SpriteCB_MoveInfoWin()` in donor src/battle_interface.c (~2774-3120+), plus
   `gCategoryIconSpriteId`/`gTypeIconSpriteId` globals in donor src/battle_main.c:244-245.
   Some implementation details were unconfirmed at discovery time (exact sprite-creation
   call sites for type/category icons) — expect to need a bit more exploration when this
   comes up.
6. **Objective 13 — Mugshots + dialogue nameplates. BLOCKED.** The donor next.md names
   (`poketransform`) has zero source code — verified via `gh api repos/Ddaretrogamer/
   poketransform/contents/`: only README, box art PNGs, and a PMD sprite/portrait
   art-credits file (`pmd_mugshot_credits.txt`, which is *art attribution*, not
   implementation credits). It's a binary ROM-patch distribution, not a code donor. Do not
   start this objective without first finding a real alternate source — a `gh search repos`
   attempt for a code-bearing mugshot/nameplate donor timed out mid-session
   (`dial tcp ... i/o timeout` / TLS handshake timeout on the GitHub search API) and was
   never retried. Retry that search, or ask the user if they know of a specific repo,
   before touching this objective.
7. **Objective 14 — Enhanced lighting. BLOCKED.** Donor (`zanderb27/emerald-plus`) does NOT
   actually contain the advertised lighting features (weather-compatible shading, GSC-style
   window lights, HGSS-style alpha-blended shadows) in its public `master` branch — checked
   via targeted grep across `src/`/`include/` in the cloned repo; the only match was a false
   positive (vanilla Team Rocket Hideout elevator light animation in
   `src/field_specials.c`). No `lighting` or `lighting-expanded-id` branch exists on the
   remote either (`git ls-remote --heads --tags origin` confirmed only `master`, `upcoming`,
   `selfhost-test`, `selfhost-test2`, `LOuroboros-patch-1`, plus vanilla-expansion tags).
   The target *does* already have the day/night + weather substrate this would hook into
   (`gTimeOfDay`, `UpdateTimeOfDay()`, `ApplyFogBlend()`, `MapHasNaturalLight()` in
   `src/field_weather.c`), so the integration point is ready whenever a real donor turns up
   — but there's currently nothing to port. Needs a fresh donor search before scheduling.
8. **Objectives 16/17 — Game Corner Expansion / Battle Frontier expansion.** Not triaged
   this session — next.md itself notes no concrete donor repo is pinned down for either.
   Lower priority than 9-15 per next.md's own framing. Leave alone until 9-15 are further
   along, then do a donor search pass similar to what was done for 10-15 this session.

## How this session has been operating (continue this way)

- **Follow `CLAUDE.md`'s model routing.** Exploration/discovery → `Explore` agent (Haiku).
  Normal implementation → `migration-worker` (Sonnet). Hard/non-obvious bugs, especially
  after a first fix attempt failed → `debugger` (Sonnet). Runtime/mGBA verification →
  `mgba-tester`. Architecture-level decisions or repeated debugging failure → `deep-engineer`
  (Opus) — reserve it, don't reach for it by default.
- **Run agents in series, not parallel.** The user explicitly corrected this mid-session
  ("run the agents in series not parallel") after several Explore agents were launched
  concurrently. Launch one, wait for its result, then launch the next — don't fan out
  multiple `Agent` calls in a single turn going forward, even though the tooling supports
  it.
- **Do NOT use the `Workflow` tool for this project's migration work.** The user explicitly
  said "dont start the workflow but go along the path of the agents" — use individual
  `Agent`/subagent calls (per `CLAUDE.md`'s subagent roster), not the multi-agent `Workflow`
  orchestration tool, even though a `migration-cycle` workflow script exists and *could*
  drive this whole loop. This was a deliberate user choice to keep token spend/orchestration
  lighter, not an oversight.
- **`mgba-tester` self-reports can be visually wrong — always open the screenshots yourself
  before trusting a "PASS."** This session, an `mgba-tester` run reported "PASS" for an
  in-battle R-button toggle check based on screenshots that were actually the title screen's
  idle staff-roll/credits animation (GBA "demo mode" — scrolling "Programmers: ..." names
  with a Bulbasaur sprite), not a real battle at all. It never got the emulator past the
  title screen into an actual battle, but still wrote up a "PASS (medium confidence)" for
  indicator-sprite behavior. Caught only because this session opened the actual PNG
  screenshots with `Read` instead of trusting the written report. Same pattern as the
  `migration-worker` build-failure misdiagnosis earlier this session (see the linker-error
  entry below) — subagents here have twice now confidently reported an incorrect result
  as verified. Always independently check: for build claims, rebuild yourself; for mGBA
  claims, `Read` the actual screenshot files, don't just read the agent's description of them.
- **Subagents reliably hit their turn budget before finishing a report.** Both `Explore` and
  `debugger`/`migration-worker` agents have stopped mid-task at their turn limit multiple
  times this session (visible as `status: completed` with a "stopped at its N-turn limit,
  partial result" note). The fix each time: `SendMessage` to the same agent id/name telling
  it to stop new exploration and write up its report now from what it already found, marking
  anything unconfirmed rather than chasing it further. Expect to do this again for future
  agents — don't assume a first "completed" notification is the final answer; check the
  `summary` field for "stopped at its N-turn limit" and resume if so.
- **Donor repos are cloned locally, reuse them — don't re-clone.**
  `/home/cam/Documents/repos/donors/emerald-plus` (zanderb27/emerald-plus),
  `/home/cam/Documents/repos/donors/pokeemerald-bear` (ebears/pokeemerald-bear),
  `/home/cam/Documents/repos/donors/worpbane-worped-ex` (worpbane/pokeemerald-worped-ex).
  These are read-only references per `CLAUDE.md` — never modify them.
- **Git clone gotcha:** plain `git clone` over HTTPS to GitHub failed twice this session with
  an HTTP/2 stream-cancellation error (`curl 92 HTTP/2 stream ... was not closed cleanly`).
  Fix: force HTTP/1.1 — `git -c http.version=HTTP/1.1 -c http.postBuffer=524288000 clone
  --depth 1 <url>`. Use this for any future donor clone.
  `gh` CLI is authenticated and available for repo search/content lookups when a donor's
  exact URL isn't known — don't guess GitHub URLs (there's a hard rule against fabricating
  URLs); use `gh search repos` or `gh api repos/<owner>/<repo>/contents/` instead. Note:
  `gh search repos` hit a transient network timeout once this session — retry rather than
  giving up on the first failure.
- **Commit technique for scoped checkpoints on this branch:** this branch has a huge amount
  of unrelated content sitting staged in the index from prior, not-yet-committed objectives.
  A plain `git commit` commits the *entire index*, not just what you just ran `git add` on —
  that would bundle unrelated prior work into the current checkpoint. Instead use a
  pathspec-limited commit: `git commit -m "..." -- <explicit file list>`. This commits only
  those files' current content and leaves everything else in the index untouched. This is
  how the Quest Menu checkpoint (commit `24c45661b8`) was done cleanly despite ~157 unrelated
  staged files sitting in the index at the time. Always `git status --porcelain` before and
  `git diff --cached --stat` after to confirm scope before/after committing.
- **`next.md` is authoritative for scope; this file is not.** If this file and `next.md`
  disagree on anything (priority, scope, status), trust `next.md` and treat this file as
  stale — update or delete this file once its todo list is fully worked through, since
  `CLAUDE.md` says not to duplicate/rewrite `next.md` into other workflow docs long-term.
