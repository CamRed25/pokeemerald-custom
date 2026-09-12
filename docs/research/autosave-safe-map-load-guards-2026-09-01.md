# Autosave Research: Safe Map-Load Seam and Guards

## Status

The target seams are identified, but the final coordinator seam and guard API
must be selected during implementation.

## Verified findings

- Ordinary warps lock field controls, start a fade, set `gFieldCallback`, and
  create `Task_WarpAndLoadMap`. See `src/field_screen_effect.c:530-539`.
- `Task_WarpAndLoadMap` eventually switches to `CB2_LoadMap`; the field callback
  is later executed by the overworld callback flow. See
  `src/field_screen_effect.c:694-720` and `src/overworld.c:1903-1922`.
- `CB2_LoadMap` initializes script state and unlocks player controls before
  handing back to the field-load continuation. See `src/overworld.c:1979-2004`.
- Fade completion is independently represented by `gPaletteFade.active` and
  weather fade state. See `src/field_screen_effect.c:517-528` and
  `src/overworld.c:1852-1881`.
- Link return paths have separate callbacks and asynchronous link-task waits;
  they must not share the ordinary warp completion trigger. See
  `src/field_screen_effect.c:177-273` and `src/overworld.c:2017-2072`.
- Link/Battle Frontier saving uses `SAVE_LINK`, partial SaveBlock writes, and
  `Task_LinkFullSave`; it is not a full autosave snapshot path. See
  `src/save.c:749-758`, `src/save.c:795-876`, and `src/save.c:994-1060`.
- Battle Pyramid explicitly performs a `SAVE_LINK` save during its challenge.
  See `src/battle_pyramid.c:946`.

## Guard requirements

Autosave execution must reject or defer while:

- `gMain.inBattle` or another battle callback is active;
- an overworld or wireless link is active, including link-task waits;
- a menu/script/facility callback still owns field control;
- `gPaletteFade.active` or weather fade-in/out is active;
- a save or link-save task is already running;
- `InBattlePyramid_()` is true or the Pyramid challenge is active.

The ordinary completion point is after map data is loaded, the selected field
callback has completed, fades are inactive, and field controls are restored.
The exact hook must be shared by ordinary map-load returns without catching the
special link/facility callbacks.

## Open implementation tests

- Ordinary warp requests exactly one queued autosave after stable completion.
- Duplicate requests during one warp coalesce.
- A request made during battle, link play, menu/script control, fade, or Pyramid
  play remains pending or is discarded according to the chosen coordinator rule.
- Returning from a facility does not save before its callback/script cleanup.

## Primary sources

- Target: `src/overworld.c`, `src/field_screen_effect.c`, `src/save.c`,
  `src/battle_pyramid.c`, `src/start_menu.c`.
