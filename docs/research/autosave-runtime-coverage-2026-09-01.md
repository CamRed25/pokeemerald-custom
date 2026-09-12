# Autosave Research: Runtime Coverage Matrix

## Status

The required scenarios are identified, but no autosave implementation, fixture,
or runtime test script exists yet.

## Existing runtime infrastructure

- The repository has mGBA feature scripts under `.claude/tests/mgba/features/`
  and a shared harness under `.claude/tests/mgba/common/`.
- Existing save/reload coverage is
  `.claude/tests/mgba/features/options_plus_save_reload_test.sh`; it exercises
  the current manual save/reload flow, not autosave groups or recovery.
- There is no `autosave_test.sh` or autosave-specific save fixture.

## Required scenario matrix

| Scenario | Expected observation | Current status |
|---|---|---|
| Map-transition autosave | One autosave completes after stable ordinary warp | Not implemented |
| Reboot | Manual Continue remains default; autosave recovery is offered separately | Not implemented |
| Disabled mode | No new autosave is written while the option is disabled | Not implemented |
| Manual preservation | Manual snapshot remains unchanged after autosave activity | Not implemented |
| Autosave recovery | Explicit selection loads the autosave snapshot | Not implemented |
| Failed autosave | Failed autosave does not damage manual Continue | No fault seam |
| Battle Pyramid | No autosave during active Pyramid challenge | No dedicated test |
| Link save | No autosave during link play or link-save callbacks | No dedicated test |
| Return from facility | Safe-point behavior is correct after scripted/facility return | No dedicated test |

## Fixture requirements

The test needs distinguishable manual and autosave snapshots, such as different
player location, play time, or registered state, plus a pre-autosave legacy save
fixture. It must use disposable save/state paths and verify screenshots or RAM
state after each title-screen choice.

## Harness risks

- The current harness can detect emulator process death but cannot by itself prove
  which logical save group was loaded.
- Screenshots alone are insufficient for failure preservation; the test should
  inspect a stable visible summary or a known RAM field.
- Link and Battle Pyramid scenarios require dedicated fixtures or emulator state;
  ordinary overworld navigation cannot prove those exclusions.

## Primary sources

- Target harness: `.claude/tests/mgba/common/harness.sh`,
  `.claude/tests/mgba/features/options_plus_save_reload_test.sh`.
- Target runtime code: `src/main_menu.c`, `src/save.c`, `src/battle_pyramid.c`,
  `src/start_menu.c`, `src/field_screen_effect.c`, `src/overworld.c`.
