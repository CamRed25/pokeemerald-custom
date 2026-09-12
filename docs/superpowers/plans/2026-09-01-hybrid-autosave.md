# Hybrid Autosave Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a safe, optional hybrid autosave system with one manual snapshot and one explicitly recoverable autosave snapshot.

**Architecture:** Reuse the existing 32-sector flash format and split the two complete save groups into fixed manual and autosave groups. Add a small autosave coordinator that queues requests and performs a full save only at stable field safe points; extend the title screen to inspect and explicitly recover a valid autosave.

**Tech Stack:** C, GBA flash save driver, existing pokeemerald task/callback system, pokeemerald C test framework, mGBA shell harness.

**Spec:** `docs/superpowers/specs/2026-09-01-hybrid-autosave-design.md`

**Research inputs:**

- `docs/research/autosave-legacy-migration-2026-09-01.md`
- `docs/research/autosave-safe-map-load-guards-2026-09-01.md`
- `docs/research/autosave-title-screen-recovery-2026-09-01.md`
- `docs/research/autosave-failure-injection-2026-09-01.md`
- `docs/research/autosave-runtime-coverage-2026-09-01.md`

## Global Constraints

- Preserve sectors 28–31 for Hall of Fame, Trainer Hill, and Recorded Battle data.
- Do not add a third complete snapshot or change the cartridge save-capacity assumption.
- Manual saves remain explicit and continue using the existing save dialog.
- Autosaves never run during battles, link play, active menus, fades, or Battle Pyramid active challenges.
- Autosave recovery requires an explicit title-screen choice.
- Donors and existing unrelated working-tree changes remain untouched.
- The current two-slot rotating behavior remains the legacy compatibility path
  until a valid fixed-role marker is written.
- Autosave failure tests must prove that manual save sectors and normal
  Continue remain unchanged; preservation of a previous autosave is a
  separate atomicity decision and must be documented by the implementation.

---

### Task 1: Map the current save groups and define testable helper seams

**Files:**
- Modify: `include/save.h`
- Modify: `src/save.c`
- Test: `test/save.c`

**Interfaces:**
- Produces fixed logical group constants, a save-role marker definition, and independently testable status/selection helpers.
- Consumes the existing `SECTOR_ID_*`, `NUM_SAVE_SLOTS`, `GetSaveValidStatus`, `TryLoadSaveSlot`, and `WriteSaveSectorOrSlot` behavior.

- [ ] **Step 1: Add failing C tests for logical group selection.**

  Add tests for these exact rules: manual maps to physical group 0, autosave maps to physical group 1, an invalid autosave is not recoverable, and a valid manual group remains preferred when both groups are valid.

- [ ] **Step 2: Run the focused save tests to confirm the new helpers are absent.**

  Run:

  ```bash
  make check
  ```

  Expected: the existing suite remains green except for the newly added tests, which fail because the new helper interfaces do not exist.

- [ ] **Step 3: Introduce explicit logical-group constants and helper declarations.**

  Add named constants for the physical manual and autosave groups. Append a four-byte role/version marker to `SaveBlock2`, which grows it from 3892 to 3896 bytes and remains below the 3968-byte sector payload limit. Do not use the sector footer for new metadata because its ID, checksum, signature, and counter are already consumed by the existing format.

- [ ] **Step 4: Implement pure group-role and validity helpers.**

  Refactor the existing scan logic so it can validate either physical group without changing the active RAM save blocks. Preserve the current newest-valid scan for legacy saves until the format marker is present.

- [ ] **Step 5: Run the focused save tests.**

  Run:

  ```bash
  make check
  ```

  Expected: the logical-group tests pass and no existing save tests regress.

- [ ] **Step 6: Commit the isolated save-group seam.**

  ```bash
  git add include/save.h src/save.c test/save.c
  git commit -m "Add logical save group selection"
  ```

### Task 2: Add fixed-role writing and legacy migration

**Files:**
- Modify: `include/save.h`
- Modify: `src/save.c`
- Modify: `src/new_game.c`
- Modify: `test/save.c`

**Interfaces:**
- Produces `SAVE_AUTOSAVE`, fixed-role full-save writing, role metadata initialization, and migration behavior for legacy saves.
- Consumes Task 1's group-selection and validation helpers.

- [ ] **Step 1: Add failing tests for write-role behavior.**

  Cover these exact cases in the save test seam: manual writes select group 0, autosave writes select group 1, an autosave write failure leaves the manual group untouched, and a legacy two-slot save is treated as manual-only until a new-format manual save succeeds.

- [ ] **Step 2: Implement a save-write context rather than overloading `gSaveCounter % NUM_SAVE_SLOTS`.**

  Add an explicit physical-group field used by `HandleWriteSector`, `HandleReplaceSector`, and their callers. Keep sector rotation within the selected group, but stop selecting the group from the global counter modulo operation for normal and autosave writes.

- [ ] **Step 3: Implement `SAVE_AUTOSAVE`.**

  Make it copy party/object state and write the complete RAM save blocks to physical group 1. Mark the snapshot role only after all sectors pass verification. Restore the previous write context and counters on failure.

- [ ] **Step 4: Preserve legacy saves.**

  Detect an absent format marker, select the newest valid legacy group as the manual state, and avoid treating the other legacy backup as a user-visible autosave. On the first successful manual save, write the new manual-role marker. Initialize a new game with the manual-role marker and no valid autosave marker.

- [ ] **Step 5: Run build and save tests.**

  Run:

  ```bash
  make check
  git diff --check
  ```

  Expected: save tests pass, the test ROM builds, and no whitespace errors occur.

- [ ] **Step 6: Commit fixed-role save writing.**

  ```bash
  git add include/save.h src/save.c src/new_game.c test/save.c
  git commit -m "Add fixed manual and autosave groups"
  ```

### Task 3: Implement the autosave coordinator and safe-point execution

**Files:**
- Create: `include/autosave.h`
- Create: `src/autosave.c`
- Modify: `src/overworld.c`
- Modify: `src/field_screen_effect.c`
- Modify: `src/save.c`
- Modify: `src/save_dialog.c`
- Test: `test/save.c`

**Interfaces:**
- Produces `Autosave_Request()`, `Autosave_IsEnabled()`, `Autosave_OnMapLoadComplete()`, and the task/callback that performs `TrySavingData(SAVE_AUTOSAVE)`.
- Consumes `TrySavingData`, `CopyPartyAndObjectsToSave`, the field callback/task lifecycle, and the save-type introduced in Task 2.

- [ ] **Step 1: Add failing coordinator tests.**

  Test that disabled mode drops requests, duplicate requests coalesce into one pending save, unsafe contexts defer the request, and a safe map-load completion consumes one request.

- [ ] **Step 2: Implement the coordinator state machine.**

  Store only a pending bit, an in-progress bit, and the last result. Reject requests while battle/link/menu/fade guards are active. Do not add timers or per-step saves.

- [ ] **Step 3: Hook the stable map-load completion seam.**

  Use the existing warp flow around `Task_WarpAndLoadMap`, `CB2_LoadMap`, and the field callback completion path. Request execution only after the new map is loaded, controls are restored, and the fade is complete. Version one does not add automatic saves to arbitrary script commands; returning to the field after a scripted activity is covered by the stable map-load hook.

- [ ] **Step 4: Implement successful and failed completion behavior.**

  Call `TrySavingData(SAVE_AUTOSAVE)` once per queued request. On success, clear the request and play the existing save sound through a non-blocking status path in `src/autosave.c`. On failure, clear the request without touching the manual group and avoid the manual save-failure screen.

- [ ] **Step 5: Run build and focused tests.**

  Run:

  ```bash
  make check
  git diff --check
  ```

  Expected: coordinator tests pass and the test ROM builds.

- [ ] **Step 6: Commit the safe-point coordinator.**

  ```bash
  git add include/autosave.h src/autosave.c src/overworld.c src/field_screen_effect.c src/save.c src/save_dialog.c test/save.c
  git commit -m "Add safe-point autosave coordinator"
  ```

### Task 4: Add the autosave option and title-screen recovery choice

**Files:**
- Modify: `include/global.h`
- Modify: `src/new_game.c`
- Modify: `src/main_menu.c`
- Modify: `src/save_dialog.c`
- Modify: `src/autosave.c`
- Modify: `src/strings.c`
- Test: `.claude/tests/mgba/features/autosave_test.sh`

**Interfaces:**
- Produces an Options Plus autosave toggle, an autosave availability query, and an explicit manual-versus-autosave recovery choice.
- Consumes independent group status/load helpers from Tasks 1–2 and the coordinator from Task 3.

- [ ] **Step 1: Add failing menu/runtime checks.**

  Add an mGBA test that reaches the title screen with a manual save and a newer autosave, verifies the recovery choice is visible, cancels recovery, and confirms normal Continue loads the manual snapshot.

- [ ] **Step 2: Add and initialize the autosave option.**

  Add `w_opAutosave:1` to the existing `SaveBlock2` options bitfield, using its one remaining bit so the structure does not grow. Default it to enabled in `src/new_game.c` and preserve it through manual saves and autosave recovery.

- [ ] **Step 3: Add autosave status to main-menu initialization.**

  Scan the autosave group without replacing the loaded manual RAM state. Add the recovery action only when the autosave marker, all sector signatures, checksums, and role metadata are valid.

- [ ] **Step 4: Implement explicit recovery loading.**

  Load the autosave group into the normal save blocks only after the player selects recovery. Then reuse `CB2_ContinueSavedGame`; do not create a second overworld continuation path.

- [ ] **Step 5: Add user-facing status text and sound behavior.**

  Reuse the existing save sound and add the minimum strings in `src/strings.c` needed for “Autosave complete,” “Recover autosave,” and the two save summaries. Keep the normal manual save dialog text unchanged.

- [ ] **Step 6: Run the mGBA scenario.**

  Run:

  ```bash
  bash .claude/tests/mgba/features/autosave_test.sh
  ```

  Expected: normal Continue loads the manual snapshot, recovery loads the autosave snapshot, cancel leaves the manual snapshot active, and disabling autosave prevents new autosave writes.

- [ ] **Step 7: Commit the option and recovery UI.**

  ```bash
  git add include/global.h src/new_game.c src/main_menu.c src/save_dialog.c src/autosave.c src/strings.c .claude/tests/mgba/features/autosave_test.sh
  git commit -m "Add autosave recovery controls"
  ```

### Task 5: Verify compatibility, failure recovery, and runtime safety

**Files:**
- Modify: `test/save.c` only if verified save-size values changed
- Modify: `.claude/tests/mgba/features/autosave_test.sh` only for verified harness corrections
- Create: `docs/research/autosave-verification-2026-09-01.md`

**Interfaces:**
- Consumes the complete implementation from Tasks 1–4.
- Produces reproducible build, unit-test, mGBA, legacy-save, disabled-mode, and failed-write evidence.

- [ ] **Step 1: Run the full C test suite.**

  ```bash
  make check
  ```

  Record the actual pass/fail/todo categories; do not label known harness limitations as passes.

- [ ] **Step 2: Run the default Emerald build.**

  ```bash
  make -j$(nproc)
  ```

  Expected: the ROM links successfully with the existing save-size assertions.

- [ ] **Step 3: Run the mGBA autosave scenarios.**

  ```bash
  bash .claude/tests/mgba/features/autosave_test.sh
  ```

  Verify: map-transition autosave, manual-save preservation, explicit recovery, disabled mode, autosave failure preservation, reboot, and Battle Pyramid/link exclusions.

- [ ] **Step 4: Verify legacy-save behavior.**

  Boot a pre-autosave save fixture, confirm it loads through the existing manual Continue path, perform one manual save, and confirm the new autosave role is not advertised until a successful autosave exists.

- [ ] **Step 5: Run diff and scope checks.**

  ```bash
  git diff --check
  git status --short
  ```

  Confirm only autosave-owned files changed before review.

- [ ] **Step 6: Write the evidence note and commit it.**

  ```bash
  git add docs/research/autosave-verification-2026-09-01.md
  git commit -m "Document hybrid autosave verification"
  ```
