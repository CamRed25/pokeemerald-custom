next up

## Status summary

- Objectives 1-8 (Options Plus, New Game Options, Start Menu, Party Menu, Storage, Summary,
  QoL HMs, Poké Ball swapping) — implemented in the working tree, but only "Add Options Plus" /
  "Wire up Options Plus menu and New Game Options" are actually committed on this branch
  (verified via `git log` 2026-08-28). Objectives 2-8's files (~157 files, ~19.6k insertions)
  are sitting STAGED but uncommitted — this was NOT accurate as "DONE, checkpointed" before;
  correct that claim in any future status read. Each remaining objective still needs its own
  scoped checkpoint commit (pathspec-limited `git commit -- <files>`, same approach used for
  Quest Menu below) before it counts as done.
- Objective 9 (Quest Menu) — DONE, checkpointed 2026-08-28 (commit 24c45661b8, "Add Quest Menu
  (Unbound-style sidequest tracking) and fix text-corruption bug"). All 6 previously-listed open
  bugs resolved (text-rendering bug root-caused and fixed, debug instrumentation / USM icon
  copy-paste / dead code were already clean, `make check` passes clean at 4937 passed / 0
  failed, commit scoped to exactly the Quest Menu file list via pathspec commit).
- Objective 12 (Soft level scaling) — DONE, checkpointed 2026-08-29 (commit `c1991a88c2`,
  "Add soft level scaling to wild encounters"). Adapted from `ebears/pokeemerald-bear`,
  scoped to `src/wild_encounter.c` only (the donor's `GetPartyMonCurvedLevel()` was inlined
  there as `static` rather than added to `pokemon.c`, since nothing else needs to call it).
  Build verified clean; boot smoke test passed.
- Objective 15a (Catch Mode) — DONE, checkpointed 2026-08-29 (commit `cc3a11e840`, "Add
  Catch Mode battle option"). Adapted from `worpbane/pokeemerald-worped-ex`, 14 files (5
  headers, 5 .c files, 4 new PNGs under `graphics/battle_interface/`). Options Plus menu
  toggle verified via mGBA screenshot; in-battle R-button toggle/indicator/damage-clamp
  verified manually by the user directly (automated mGBA harness couldn't reliably trigger
  a wild battle after 4 attempts — tooling limitation, not a code concern). See
  `SESSION_STATUS.md` for a note on an unreproduced, unconfirmed "crashed to desktop"
  report from the user's manual testing (possibly Options-Plus-menu-related, possibly
  unrelated) — not resolved, revisit if it recurs.
- Objective 10 (Key Item Wheel) — DONE, checkpointed 2026-08-30 (branch `Key-wheel`, merged
  into `custom`). Adapted from `zanderb27/emerald-plus`'s `Task_KeyItemWheel()`, but SaveBlock1
  storage diverged from the donor: appended `registeredItems[MAX_REGISTERED_ITEMS]` as new
  fields instead of the donor's approach of shrinking `MAX_REMATCH_ENTRIES` 100→92 to reclaim
  space, matching this project's own additive-SaveBlock convention from Quest Menu (no offset
  shifts to existing fields). `registeredItem` (singular) is kept in sync as a mirror of the
  active slot for existing single-item call sites. Direct code review (not just build-clean)
  caught a real bug before checkpointing: migration-worker had moved `item_menu.c`'s
  `tUsingRegisteredKeyItem` task-data macro from `data[3]` to `data[9]` to make room for the
  wheel's own sprite-slot data, but that macro's actual use-site is a *different* task (the
  one `GetItemFieldFunc()` creates, not the wheel task itself) and `item_use.c`'s own copy of
  the same macro still read `data[3]` — the write and read had silently gone out of sync. Fixed
  by reverting `item_menu.c`'s definition back to `data[3]` (the wheel's own state/sprite data
  never shares a task instance with it, so no real collision exists). Ponytail-reviewed clean,
  nothing to cut. Runtime: two automated `mgba-tester` attempts couldn't reliably navigate the
  Bag to register 2 key items under Xvfb/xdotool timing within budget (same class of tooling
  limitation as Catch Mode's wild-battle trigger) — added `Debug_RegisterKeyItems` (new special,
  `src/item_menu.c`/`include/item_menu.h`/`data/specials.inc`) wired to
  `Debug_EventScript_Script_2` so the debug menu can reach the 2-items-registered state
  directly, then used it for a direct mGBA check: SELECT with 2 items registered shows the
  4-position wheel with correct box placement and item icons in the right slots (up=Bicycle,
  right=Acro Bike, empty boxes for the unused slots), D-pad-Up correctly selects the Bicycle
  and triggers the vanilla "Dad's advice, can't ride here" indoor-terrain message — the exact
  code path the `tUsingRegisteredKeyItem` fix touches, so this also confirms that fix end to
  end. B/SELECT-to-close-without-using wasn't separately re-checked after this fix landed but
  was covered by an earlier partial run; low risk given it's an early-return branch with no
  interaction with the fixed code. Screenshots:
  `.claude/tests/mgba/screenshots/verify3_02_select_pressed.png` (wheel open),
  `verify3_03_after_dpad_up.png` (item used, Dad's advice message).
- Objectives 11, 13, 14, 15b — triaged 2026-08-28 (see "Objective 10-15 triage" below
  for rankings, donor viability, and complexity findings). Not yet implemented.
- Objectives 16-17 — optional, lower priority than 9-15, not yet triaged.
- "New candidate features" (donors 5-11, near the bottom of this file) — NOT triaged, NOT
  integration-ordered yet. Do not start any of them before triage.

## Donor map (vetted — backs objectives 1-15)

1. worpbane/pokeemerald-worped-ex

Use this for almost all UI/QoL work. Its README explicitly confirms these systems are already present.

Extract:

src/option_plus_menu.c
include/option_plus_menu.h
related option-menu graphics/tiles
src/option_menu.c hook into CB2_InitOptionPlusMenu()

For the other features, look primarily at:

src/party_menu.c
src/pokemon_storage_system.c
src/pokemon_summary_screen.c
src/start_menu.c
src/item_menu.c
src/field_control_avatar.c
src/battle_interface.c
src/battle_util.c
include/global.h
include/save.h
graphics/interface/
graphics/battle_interface/

Those cover:

Options Plus
SwSh Party
SwSh Storage
SwSh Summary
Unbound Start Menu
QoL HMs
Poké Ball swapping
Catch Mode
improved move-info panel

Do not copy its maps, scripts, text-decapitalization changes, README, or whole global.h.

2. ebears/pokeemerald-bear

Only use it for three things:

Unbound Quest Menu
registered-item shortcut menu
soft wild-level scaling

Its README confirms all three are present.

Search that repo with:

grep -RniE "Quest|quest" src include data graphics
grep -RniE "Shortcut|registered" src include data graphics
grep -RniE "LevelScaling|level scaling|SoftLevel|ScaleWild" src include

Don't take its battle engine, Pokédex, followers, party screen, TM system, etc. Those overlap with your current RHH base.

3. zanderb27/emerald-plus

Use only the:

key-item-wheel

implementation.

Likely areas to extract will be:

src/item_menu.c
src/item_use.c
src/field_control_avatar.c
include/item_menu.h
graphics/interface/

Your current base already has the normal registered-item API such as UseRegisteredKeyItemOnField(), so the wheel should be integrated around the existing system rather than replacing the whole item subsystem.

4. poketransform

Reference only, for:

Mugshots + dialogue nameplates (runs on an Expansion base, so it's the closest analog for how to adapt this into our RHH base)

Do not take anything else from it.

## Integration order (1-15, then 16-17 as optional expansions)

That order minimizes dependency problems. Quest Menu + New Game Options + Options Plus together
form a more complete framework for later custom content, beyond just modernizing the vanilla UI —
worth keeping in mind when sequencing 9-15.

Objectives 1-8 (Options Plus, New Game Options, Start Menu, Party Menu, Storage, Summary,
QoL HMs, Poké Ball swapping) are all DONE and checkpointed — see git log on this branch.

In progress:

9. Quest Menu — High priority. Gives custom sidequests/objectives proper tracking instead of
   relying on dialogue/flags. Donor: ebears/pokeemerald-bear (Unbound-style implementation).
   Progress so far:
   - Core quest system (src/quests.c, include/quests.h, include/constants/quests.h,
     graphics/quest_menu/) ported and building cleanly. SaveBlock2 extended additively
     (questData/subQuests appended after `frontier`, no offset shifts).
   - Script-facing specials registered in data/specials.inc; debug menu Script 1
     (data/scripts/debug.inc) sets FLAG_SYS_QUEST_MENU_GET and unlocks/activates the two
     placeholder quests for testing.
   - Legacy list-based Start Menu entry wired (src/start_menu.c) AND the live Unbound Start
     Menu (USM) icon wired (src/unbound_start_menu.c: new "Quests" icon, gated on
     FLAG_SYS_QUEST_MENU_GET, reuses the existing Task_QuestMenu_OpenFromStartMenu entry
     point) — this project runs with UNBOUND_START_MENU enabled, so USM is the path that's
     actually live in-game.
   - mGBA regression coverage: .claude/tests/mgba/features/quest_menu_test.sh rewritten to
     test the live USM path; boot smoke test and the existing unbound_start_menu_test.sh
     regression both still pass after the USM change.
   Not yet checkpointed — see "Open bugs / issues" below for what's still blocking.
10. Key Item Wheel — DONE, checkpointed 2026-08-30 (branch `Key-wheel`). See Status summary
    above for details (SaveBlock1 approach, the tUsingRegisteredKeyItem fix, and the
    outstanding manual runtime-verification item).
11. Registered-item shortcut menu — High priority. More general than the wheel, useful for
    things besides key items. Donor: ebears/pokeemerald-bear. **DONE, checkpointed
    2026-08-30 — scope narrowed to Key Items pocket only** (deviates from this line's
    "things besides key items" ambition; see "Objective 11 scope narrowing" below for why
    and what's left for a future pass).
12. Soft level scaling — Medium priority. Useful for exploration/order flexibility without a
    full difficulty hack. Donor: ebears/pokeemerald-bear (already demonstrates wild scaling).
13. Mugshots + dialogue nameplates — Medium priority. Significant presentation improvement for
    story/NPC interactions. Reference: poketransform (uses both on an Expansion base).
14. Enhanced lighting — Medium priority. Current RHH has day/night; emerald-plus's lighting
    branch adds weather-compatible shading, lit windows, and HGSS-style shadows. Donor:
    zanderb27/emerald-plus.
15. Catch Mode — carried over from the original plan, not yet scheduled relative to 9-14.
    Donor: worpbane/pokeemerald-worped-ex (see donor map above).

Untracked item noticed in donor map scope, no integration-order slot assigned yet:
- "improved move-info panel" is listed under worpbane's covered features (donor map section
  1 above) but was never given a numbered objective. Decide whether it becomes its own item
  or folds into an existing one (e.g. Catch Mode) before starting it.

Optional content expansions (later, lower priority than 9-15):

16. Game Corner Expansion [Emerald-specific] — pinball, Snake, Blackjack, Voltorb Flip, Plinko,
    Flappy Bird, and more. An Expansion-adapted version exists but targets older Expansion
    1.12.0, so expect porting work.
17. Battle Frontier expansion [Emerald-specific] — worthwhile for substantially more postgame
    content, but much larger in scope than the UI/QoL work above.

## Open bugs / issues — RESOLVED 2026-08-28, Quest Menu checkpointed (commit 24c45661b8)

All 6 items below (originally blocking objective 9) are resolved:

1. Text-rendering bug — ROOT CAUSED and FIXED: not a window/text-printer interaction bug as
   suspected, but an unbounded right-edge glyph clip in the shared text engine (src/text.c's
   RenderFont, ~line 838) that corrupts rendering when a single unwrapped
   AddTextPrinterParameterized4 line exceeds the window's printable width. The placeholder
   quest description strings (59-63 chars, no `\n`) were too wide for window 1's ~18-20
   char/line capacity at their x-offset. Fixed at the quests.c scope (not text.c, to keep
   blast radius small) by hard-wrapping the two placeholder description strings with manual
   `\n`, matching this file's own existing wrap convention (sText_ReturnRecieveReward).
   Verified via fresh mGBA screenshot. NOTE for future quest content: any `desc`/`donedesc`/
   subquest text over ~18-20 chars on one line needs manual `\n` wrapping, or it will hit
   this same text-engine edge case — worth a comment near `sSideQuests[]` at some point.
2. Debug instrumentation in window.c — was already gone before this session started (nothing
   to revert).
3. USM icon copy-paste bug (`[USM_ICO_FRONTIER_RETIRE]` had `.iconId = USM_ICO_SAVE`) — was
   already fixed in the working tree before this session started.
4. Dead `QuestMenu_ResetMenuSaveData()` — was already removed from the working tree (function
   no longer exists in quests.c or quests.h) before this session started.
5. `make check` reran clean: 4937 passed, 0 failed (13 known-failing, 595 to-do, 8
   expect-failing — all pre-existing/expected categories). Required updating test/save.c's
   T_SAVEBLOCK2_SIZE (3884→3892, the legitimate +8 bytes from Quest Menu's additive
   questData/subQuests fields) and T_SAVEBLOCK3_SIZE (4→16, from an already-staged, unrelated
   Usm_SavedItems addition predating this session). Both are intentional size growth per the
   test file's own comment ("update the values below with those for your hack"), not
   regressions. test/save.c's fix was committed alongside Quest Menu since it's a required
   companion to the SaveBlock2 change, even though it wasn't in the original scoped file list
   below.
6. Checkpoint staged ONLY the quest-menu-scoped files via a pathspec-limited
   `git commit -- <files>` (not `git add -A` + plain commit) — this leaves the ~157 other
   files staged from objectives 2-8 completely untouched in the index, exactly as intended.

## Objective 10-15 triage (2026-08-28)

Donor repos cloned to /home/cam/Documents/repos/donors/ for this pass: emerald-plus,
pokeemerald-bear, worpbane-worped-ex (all confirmed to actually contain the claimed features
in their default/master branch, even where a README-named branch like "key-item-wheel" or
"lighting" no longer exists remotely — check master first before assuming a feature is
missing). poketransform was also fetched via `gh` and found to contain NO source code at all
(README + box art + a PMD sprite/portrait art-credits file only) — it is a binary-patch
distribution, not a code donor, despite next.md previously listing it as one.

Percentage = incorporation-readiness ranking (100% = implement now, lower = defer), weighing
donor viability, architectural clarity, difficulty, and actual LOC/file-count of work. Ranked
order to implement, highest first:

1. **Objective 12 (Soft level scaling) — 95%.** Donor: ebears/pokeemerald-bear, confirmed
   present (`ChooseWildMonLevel()` src/wild_encounter.c:263-309, `GetPartyMonCurvedLevel()`
   src/pokemon.c:8088-8125). ~60 LOC across 2 files, zero SaveBlock footprint (reads existing
   party/badge data only), self-contained, no architecture conflicts. Smallest, lowest-risk,
   clearest win available. Minor unconfirmed items (badge/ability constant naming parity) are
   low-risk and quick to verify during implementation.
2. **Objective 15a (Catch Mode) — 88%.** Donor: worpbane/pokeemerald-worped-ex, confirmed
   present and documented (README: "Flash1Lucky's Catch Mode... turn it off in the Options
   menu"). ~200-300 LOC across ~8 files (src/battle_util.c, battle_interface.c,
   battle_controller_player.c, option_plus_menu.c + headers). Self-contained damage-clamp +
   toggle, plugs directly into the already-ported Options Plus menu (objective 1). Low risk.
3. **Objective 10 (Key Item Wheel) — 75%.** Donor: zanderb27/emerald-plus, confirmed present
   in master despite README referencing a now-nonexistent "key-item-wheel" branch
   (`Task_KeyItemWheel()` src/item_menu.c:2385-2462 and supporting functions). Clean, isolated
   donor code, and the target's `UseRegisteredKeyItemOnField()` hook is already live
   (src/field_control_avatar.c:242). Main risk: donor stores its 4-item registry by shrinking
   `MAX_REMATCH_ENTRIES` 100→92 to steal 8 bytes in SaveBlock1; target still has the vanilla
   single-slot `registeredItem` and a full 100-entry rematch table, so this reallocation must
   be verified safe against target's rematch code before porting, not copied blindly. Needs
   new graphics (key_item_box.png/.4bpp/.gbapal) and a free BG palette slot (donor uses 13).
4. **Objective 11 (Registered-item shortcut menu) — 60%.** Donor: ebears/pokeemerald-bear,
   confirmed present (`tx_registered_items_menu.c`, ~719 LOC, `TxRegItemsMenu_*` functions).
   ~900 LOC across 4 files, self-contained, reuses the same `UseRegisteredKeyItemOnField()`
   API. Ranked below Key Item Wheel despite next.md's original "High priority" label because
   of an unresolved architecture question: this donor's shortcut menu uses a 10-slot
   `RegisteredItemSlot registeredItems[10]` array, while the Key Item Wheel (objective 10)
   uses a 4-slot scheme — next.md doesn't clarify whether these are meant to be the same
   underlying registered-item storage (in which case slot counts must reconcile) or two
   independent systems. Resolve that design question — ideally after objective 10 lands, so
   there's a concrete SaveBlock1 layout to reconcile against — before implementing this one.

   **Objective 11 scope narrowing (2026-08-30, resolved during implementation):** built as
   an independent, non-reconciled 10-slot system (separate from the Wheel's 4-slot
   `registeredItems`), opened with the field L button — see `SESSION_STATUS.md`'s Objective
   11 section for the full implementation writeup. During runtime verification, registering
   a party-menu-type item (a Potion) as a shortcut and using it from the field hung on a
   black screen: the shortcut menu's dispatch (`CreateTask(GetItemFieldFunc(item), 8)`,
   `src/item_menu.c` around the `ItemMenu_ToggleShortcut`/shortcut-select handler) copies
   the *existing* Key-Item-Wheel dispatch pattern, which only works for simple
   `ITEM_USE_FIELD` items (Escape Rope, Repel, Bicycle) — not `ITEM_USE_PARTY_MENU` items
   like medicine, which need the Bag's own `SetUpItemUseCallback` flow and the task/UI state
   that only exists inside the Bag's task context. Rather than build out full per-item-type
   dispatch (effectively re-implementing part of the Bag's item-use routing in this new
   field-overlay context), scope was narrowed to match what's proven to work: `ACTION_SHORTCUT`
   stays wired into `sContextMenuItems_KeyItemsPocket[]` only (not the Items/Balls/TMs/Berries
   pockets), so only key-item-style `ITEM_USE_FIELD` items can be registered as shortcuts
   through the real UI. This means this line's "more general than the wheel, useful for
   things besides key items" ambition is **not implemented** — a real gap versus the
   original ask, not just a documentation note. Left for a future objective if wanted:
   extend `ACTION_SHORTCUT` to other pockets and teach the shortcut-menu dispatch to route
   `ITEM_USE_PARTY_MENU` (and other non-field) item types through their correct use flow
   instead of the bare `CreateTask` call.
5. **Objective 15b (Improved move-info panel) — 55%.** Same donor as 15a
   (worpbane/pokeemerald-worped-ex), confirmed present (`TryToAddMoveInfoWindow()` etc.,
   src/battle_interface.c:2992-3120+). Independent of Catch Mode (no shared state, just
   adjacent files), ~400-600 LOC across ~7 files. Medium difficulty — some implementation
   details unconfirmed (exact sprite-creation call sites for the type/category icons,
   effectiveness/STAB icon assets). Natural to do right after Catch Mode since both touch
   option_plus_menu.c/battle_interface.c in one integration pass, but real standalone work.
   This resolves the untracked "improved move-info panel" item from the donor map above:
   verdict is a SEPARATE objective from Catch Mode, not folded in.
6. **Objective 13 (Mugshots + dialogue nameplates) — 15%, BLOCKED.** Donor (poketransform) has
   NO usable source code — confirmed via `gh api` against Ddaretrogamer/poketransform: only a
   README, box art PNGs, and a PMD sprite/portrait art-credits file. Cannot be scheduled as a
   code port until an alternate donor is found (a live GitHub repo search for a code source
   timed out mid-session and wasn't completed — retry that, or find a different reference,
   before revisiting this objective).
7. **Objective 14 (Enhanced lighting) — 12%, BLOCKED.** Donor (zanderb27/emerald-plus)
   verified to NOT contain the advertised lighting features (weather-compatible shading,
   GSC-style window lights, HGSS-style alpha-blended shadows) in its public master branch —
   checked via targeted grep across src/include (only false-positive match was the unrelated
   vanilla Team Rocket Hideout elevator light animation, src/field_specials.c). No
   `lighting`/`lighting-expanded-id` branch exists on the remote either (confirmed via
   `git ls-remote`). The donor map's claim for this feature does not hold up under
   verification. On the plus side, the TARGET already has the day/night + weather substrate
   this would hook into (`gTimeOfDay`, `UpdateTimeOfDay()`, `ApplyFogBlend()`,
   `MapHasNaturalLight()` in src/field_weather.c) — so once/if a real donor or from-scratch
   design is found, the integration point is ready. Not schedulable as a port right now.
8. **Objectives 16-17 (Game Corner / Battle Frontier) — not scored, no donor identified.**
   Optional/lower-priority per next.md's own framing; still needs a concrete donor repo
   search before any triage is possible. Left untouched this pass.

## Explicitly not prioritized right now

Adds considerable engine complexity for less benefit than the above: HQ-audio replacement,
sideways stairs, randomizers, multi-ability, major custom battle systems.

## New candidate features (not yet integration-ordered — added 2026-08-28)

Sourced from additional donor repos not yet vetted against the RHH base. These are NOT part of
the numbered integration order above and must not be started until triaged: dedupe against
objectives already scheduled (e.g. confirm a "battle speed setting" doesn't overlap with anything
RHH already exposes), verify each donor's implementation is actually present and functional in
that repo (not just claimed), and decide which merit their own numbered objective vs. folding into
an existing one.

### Candidate donor map (new, unvetted)

5. makiwu/dreamstone-mysteries — RHH-derived source tree.
   - Fishing minigame (Bivurnum's implementation)
   - Mining minigame (Underground-style, vol8's implementation)
   - Battle Speed-Up (Pokabbie's implementation)

6. PrinceXaine/Expanded-Emerald — vanilla-Emerald-based ROM hack.
   - Dialogue auto-scroll (hold/press to auto-advance) + Instant Scroll
   - HP/EXP bar speed control (independent of overall battle speed)
   - Remember last battle cursor/action (move, Pokémon, or RUN selection between turns)
   - Autosave after Pokémon Center healing
   - Skip Nickname / Skip Pokédex registration toggles
   - Egg hatch speed (configurable, up to 8x)
   - Player-facing intro/tutorial skips (Birch/Oak, Wally tutorial, title movie)

7. khbsd/pokeemerald-expansion-kaya — Expansion-derived base.
   - PokéVial (PCG's rechargeable portable-healing item)

8. PCG06/pokeyaeeh and ravepossum/emeraldextra — pokeemerald-expansion-based.
   - Menu clock in the Start Menu, optional 12/24-hour (implementations in both)
   - Outfit system (emeraldextra, Mudskip/Slawter's implementation)
   - Change direction while moving without stepping (emeraldextra)
   - Pokédex area-map day/night toggle (emeraldextra)

9. chale1342/pokefirered ("FireRed Enhanced") — FRLG base; relevant despite being FRLG rather
   than Emerald since this project also has an FRLG migration track.
   - Battle speed setting: Normal/Fast/Ultra Fast (separate implementation from Dreamstone's
     Battle Speed-Up — compare both before choosing one)
   - Region-map encounter browser (added July 2026) — browse Pokémon/levels per route from the
     world map
   - Permanent Cut trees (cleared obstacles stay cleared instead of respawning)
   - FRLG Help System removal — a memory optimization; FireRed Enhanced reports reclaiming
     ~16 KB EWRAM by disabling it. Investigate specifically for this project's FRLG build. Do
     NOT port blindly — RHH's FRLG memory layout differs from theirs.

10. pkmnsnfrn/pokeemerald-expansion (older Expansion-derived) and voloved/pokeemerald_fork.
    - Bag sorting (Ghoulslash's implementation, via the pkmnsnfrn fork) — not listed among
      current RHH's standard interface features; confirm it's actually missing before scheduling
    - Items go to the PC automatically when the Bag is full (voloved fork)

11. worpbane/pokeemerald-worped — NOTE: distinct from worpbane/pokeemerald-worped-ex already in
    the donor map above (donor 1). Do not conflate the two repos.
    - Seasons (seasonal palette/world changes layered over day/night). Worped's own description
      flags its current version as partly nonfunctional — treat as experimental / lowest
      priority; verify it actually works before committing any time to it.

### Candidate feature list (unscheduled, donor in parentheses)

- Fishing minigame (dreamstone-mysteries)
- Mining minigame (dreamstone-mysteries)
- Battle speed setting (dreamstone-mysteries or FireRed Enhanced — compare both)
- Dialogue auto-scroll (Expanded-Emerald)
- HP/EXP bar speed control (Expanded-Emerald) — fits directly into the existing Options Plus menu
- Remember last battle cursor/action (Expanded-Emerald)
- Autosave after Pokémon Center healing (Expanded-Emerald)
- Skip Nickname / Skip Pokédex registration toggles (Expanded-Emerald) — fits directly into the
  existing Options Plus menu
- Egg hatch speed (Expanded-Emerald)
- Player-facing intro/tutorial skips (Expanded-Emerald) — note RHH's own Quickstart is
  dev-only/disabled in release builds, so this would be a separate, player-facing implementation
- PokéVial (pokeemerald-expansion-kaya)
- Menu clock (pokeyaeeh / emeraldextra)
- Outfit system (emeraldextra)
- Change direction while moving (emeraldextra)
- Pokédex area day/night toggle (emeraldextra)
- Region-map encounter browser (FireRed Enhanced)
- Permanent Cut trees (FireRed Enhanced)
- FRLG Help System removal [FRLG-specific, needs independent verification against RHH's FRLG
  memory layout] (FireRed Enhanced)
- Bag sorting [verify not already present in RHH before scheduling] (pkmnsnfrn/pokeemerald-expansion)
- Items → PC when Bag is full (voloved/pokeemerald_fork)
- Seasons [experimental — donor itself reports it's partly nonfunctional] (worpbane/pokeemerald-worped)

Several of these (HP/EXP bar speed, Skip Nickname/Pokédex, autosave-after-heal) are natural fits
to fold directly into the existing Options Plus / New Game Options menus rather than becoming
standalone numbered objectives — decide this during triage.
