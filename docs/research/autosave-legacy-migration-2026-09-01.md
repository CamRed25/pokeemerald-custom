# Autosave Research: Legacy-Save Migration

## Status

Source research complete for the current target behavior. Implementation design
and migration tests are still required.

## Verified findings

- The target defines two complete 14-sector save groups: sectors 0–13 and
  14–27. Sectors 28–31 are special-data sectors. See `include/save.h:12-29`.
- Normal full saves increment `gSaveCounter`, rotate the starting sector, and
  select the physical group with `gSaveCounter % NUM_SAVE_SLOTS`. See
  `src/save.c:139-171` and `src/save.c:177-210`.
- The loader validates both groups, chooses the group with the newer sector
  counter, and copies only that group into RAM. See `src/save.c:471-518` and
  `src/save.c:520-643`.
- Save validity currently means complete sector coverage plus valid signatures
  and checksums. There is no role/version metadata or distinction between a
  manual and autosave snapshot. See `src/save.c:520-589`.
- `LoadGameSave(SAVE_NORMAL)` always uses the existing rotating-slot loader and
  then copies party/object state from the selected save. See `src/save.c:879-900`.
- `ReloadSave()` also reloads through `LoadGameSave(SAVE_NORMAL)`, so migration
  must preserve this path or deliberately update it. See `src/reload_save.c:13-34`.

## Required migration behavior

1. Detect the new role/version marker without interpreting legacy slot age as
   an autosave.
2. Treat the newest valid legacy slot as the manual state.
3. Keep the legacy second slot unavailable for autosave recovery.
4. Establish fixed roles only after the first successful new-format manual save.
5. Make a new game contain a valid manual-role marker and no valid autosave.
6. Keep `ReloadSave()` and normal Continue on the manual path unless recovery
   is explicitly selected.

## Open implementation tests

- Two valid legacy slots with different counters load the newer slot as manual.
- A legacy save does not expose an autosave recovery action.
- The first successful new-format manual save establishes the manual role.
- A failed first migration save does not advertise either snapshot as valid.
- New-format manual and autosave markers cannot be confused by slot age alone.

## Primary sources

- Target: `include/save.h`, `src/save.c`, `src/load_save.c`,
  `src/reload_save.c`, `test/save.c`.
- Upstream comparison: [pret/pokeemerald `include/save.h`](https://github.com/pret/pokeemerald/blob/master/include/save.h)
  and [pret/pokeemerald `src/save.c`](https://github.com/pret/pokeemerald/blob/master/src/save.c).
