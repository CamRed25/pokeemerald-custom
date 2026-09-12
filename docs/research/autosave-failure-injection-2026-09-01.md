# Autosave Research: Failure Injection and Manual-Save Preservation

## Status

The failure-handling behavior is understood, but the repository has no existing
fault-injection seam for deterministic autosave write failures.

## Verified findings

- Full saves write all 14 sectors through `WriteSaveSectorOrSlot` and restore
  `gLastWrittenSector` and `gSaveCounter` if any sector is damaged. See
  `src/save.c:139-171`.
- Sector writes call `ProgramFlashSectorAndVerify` through `TryWriteSector`; a
  failed write sets a bit in `gDamagedSaveSectors`. See `src/save.c:232-245`.
- Replacement writes erase and program individual sectors, and failures also
  restore the previous sector/counter state. See `src/save.c:296-395`.
- `TrySavingData` treats any damaged-sector bit as an error and routes the error
  to `DoSaveFailedScreen(saveType)`. See `src/save.c:773-792`.
- The existing test suite only asserts SaveBlock sizes in `test/save.c`; it does
  not expose flash programming hooks or a write-failure fixture. See
  `test/save.c:1-34`.
- The flash implementation is reached through the save module’s private helper
  declarations, so a direct C-test failure simulation requires either a small
  injectable wrapper, a test-only flash backend seam, or a controlled emulator
  fault.

## Required preservation rule

An autosave failure must not erase, overwrite, invalidate, or select the manual
group. The autosave coordinator must clear or record the failed pending request,
avoid the manual save-failure screen, and return to the field. The save-write
context must restore its prior counter/group state after failure.

## Recommended reproducible check

- Seed a valid manual group and a valid prior autosave group.
- Force the first autosave-group sector write to fail, then allow the remaining
  writes to proceed or abort the operation deterministically.
- Confirm `TrySavingData(SAVE_AUTOSAVE)` reports failure, manual sectors and
  counter remain byte-for-byte unchanged, and the prior autosave is either kept
  valid or deliberately marked invalid according to the chosen atomicity rule.
- Reboot and confirm normal Continue still loads manual state.

## Open design issue

The proposed fixed-role layout removes the older same-role copy. Therefore,
“preserve the last autosave on failure” is a separate decision from preserving
the manual save. The design currently promises manual preservation but does not
yet specify whether a partially overwritten autosave group is recoverable.

## Primary sources

- Target: `src/save.c`, `include/save.h`, `test/save.c`, `src/save_failed_screen.c`.
