# Autosave Research: Title-Screen Detection and Recovery

## Status

The existing Continue path is verified. Autosave detection, summaries, and
explicit recovery are not implemented and need a new UI state.

## Verified findings

- Main-menu initialization creates `Task_MainMenuCheckSaveFile` after graphics
  setup. See `src/main_menu.c:578-632`.
- That task branches only on the global `gSaveFileStatus`, which is populated by
  the existing save loader. It has no independent autosave status. See
  `src/main_menu.c:646-690`.
- A valid save produces the normal menu type and the Continue action is selected
  through `ACTION_CONTINUE`. See `src/main_menu.c:761-900` and
  `src/main_menu.c:957-1102`.
- Continue calls `CB2_ContinueSavedGame` directly after the current manual save
  has already been loaded. See `src/main_menu.c:1097-1102`.
- The current summary window is populated directly from the loaded
  `gSaveBlock2Ptr` and flags: player, time, Pokédex count, and badge count. See
  `src/main_menu.c:2163-2224`.
- `LoadGameSave(SAVE_NORMAL)` copies the selected save into the normal RAM save
  blocks before Continue. See `src/save.c:879-900`.

## Required recovery design

1. Scan the fixed manual and autosave groups independently during title-screen
   setup without replacing the loaded manual RAM state.
2. Expose recovery only when autosave role metadata and every sector’s signature
   and checksum are valid.
3. Keep normal Continue mapped to the manual snapshot.
4. Add a separate explicit Recover Autosave action.
5. On selection, load the autosave into the normal RAM blocks and reuse
   `CB2_ContinueSavedGame`.
6. Render a separate autosave summary before confirmation; the current summary
   helper assumes the active RAM blocks represent the displayed save.
7. Canceling recovery must leave manual RAM state and the normal Continue path
   unchanged.

## Open implementation tests

- Manual-only save shows no recovery action.
- Valid newer autosave shows recovery and its own summary.
- Normal Continue still loads manual state.
- Canceling recovery leaves manual state active.
- Selecting recovery loads autosave state through the existing continuation.
- Corrupt or role-mismatched autosave is hidden.

## Primary sources

- Target: `src/main_menu.c`, `src/save.c`, `src/reload_save.c`, `include/save.h`.
