# Hybrid Autosave Design

**Status:** Design and research complete; implementation not started.

## Goal

Add an optional autosave system that preserves the player's last manual save
while keeping one recoverable autosave snapshot.

## Existing save constraints

The target uses 32 flash sectors. Fourteen sectors form each of two complete
save groups; the remaining four sectors are used by Hall of Fame, Trainer
Hill, and Recorded Battle data. The current implementation alternates the two
complete groups on every normal save. They are not independent user-visible
files.

The target's `SaveBlock2` is 3892 bytes against a 3968-byte sector payload,
leaving 76 bytes in that block. `SaveBlock1` is 15596 bytes and remains within
its four-sector allocation. The save format has no room for a third complete
snapshot without increasing the cartridge save capacity or removing existing
special data.

## Chosen architecture

Repurpose the two existing complete save groups as fixed logical snapshots:

- Physical group 0 (sectors 0–13): manual save.
- Physical group 1 (sectors 14–27): autosave backup.
- Sectors 28–31: unchanged special data.

Manual saves always replace the manual group. Autosaves always replace the
autosave group. Each group continues to write all of its sectors with the
existing per-sector signature, checksum, counter, and write verification.

This deliberately changes the current recovery model. The existing format
uses the two groups as rotating copies of the same save; this format uses them
as two different snapshots. A failed manual write can still leave a valid
autosave, and a failed autosave cannot damage the manual group, but each
logical group no longer has an older same-role copy. This tradeoff is required
to keep both full snapshots within the existing 128 KiB flash layout.

The save loader identifies each logical group independently. New-format
metadata identifies the group role and format version. A legacy save, whose
two groups are rotating normal-save copies, is loaded using the current
newest-valid behavior. On the first successful manual save after migration,
the new fixed-role layout is established and the autosave group remains
invalid until the first autosave succeeds.

The normal Continue action loads the manual group. If a valid autosave exists,
the title screen offers a separate recovery action and displays its save
summary before the player commits to loading it. Autosave recovery loads the
autosave group into the normal RAM save blocks and then continues through the
existing `CB2_ContinueSavedGame` path.

## Autosave triggers

Version one requests an autosave only at stable overworld boundaries:

- after a completed ordinary map warp and map load;
- after returning from a major facility or scripted activity to the field;

The implementation must not autosave during battles, link play, the Battle
Pyramid active challenge, active menus, fades, or while a save/link operation
is already running. Requests are coalesced and executed only after controls
are restored and the field is stable. Manual saves and link-save semantics
remain unchanged.

Version one does not autosave every step, every battle, or every item use.
This limits flash wear and avoids capturing transient states.

## User controls and failure behavior

Autosave is enabled by default and can be disabled in Options Plus. A
successful autosave uses the existing save sound and a short non-blocking
confirmation indicator. A failed autosave does not replace or invalidate the
last manual save; it records no recovery snapshot and returns control to the
field. Manual save failures continue to use the existing save-failure path.

The title screen prefers the manual save. Recovery is explicit so a newer
autosave cannot unexpectedly discard a player's intentional manual-save
checkpoint.

## Files and interfaces

- `include/save.h` / `src/save.c`: fixed logical group selection, independent
  validation/loading, role metadata, migration handling, and a new autosave
  save type.
- `include/autosave.h` / `src/autosave.c`: trigger request state, safe-point
  eligibility, duplicate-request suppression, and the asynchronous field
  save task.
- `src/overworld.c` and `src/field_screen_effect.c`: invoke the autosave
  safe-point completion hook after map loading is complete.
- `src/start_menu.c`: retain the existing forced manual-save script behavior;
  version one does not add automatic saves to arbitrary script commands.
- `src/main_menu.c`: detect autosave availability, display recovery choice and
  summary, and select the requested logical group before continuing.
- `src/start_menu.c` / `src/save_dialog.c`: preserve manual-save behavior and
  provide the autosave status/confirmation UI if the final save task needs a
  shared callback.
- `include/global.h` / `src/new_game.c`: add only the minimum format marker or
  metadata initialization required by the fixed-role layout.
- `test/save.c`: update save-size assertions and add pure validation/role
  selection coverage where the test framework permits it.
- `.claude/tests/mgba/features/autosave_test.sh`: exercise manual save,
  autosave, reboot, manual continuation, autosave recovery, disabled mode,
  and failed-write preservation.

## Non-goals

- A third complete save snapshot.
- Automatic loading of the autosave without player choice.
- Autosaving during battles or link sessions.
- Replacing the existing flash driver or manual save dialog.
- Expanding the cartridge save type or removing Hall of Fame/Trainer
  Hill/Recorded Battle storage.

## Research sources

- Target source: `include/save.h`, `src/save.c`, `src/save_dialog.c`,
  `src/main_menu.c`, `src/overworld.c`, and `src/field_screen_effect.c`.
- Upstream reference layout: https://github.com/pret/pokeemerald/blob/master/include/save.h
- Upstream save implementation: https://github.com/pret/pokeemerald/blob/master/src/save.c
