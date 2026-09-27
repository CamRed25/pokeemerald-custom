#ifndef GUARD_AUTOSAVE_H
#define GUARD_AUTOSAVE_H

// Requests coalesce until the field is stable. Requests during an autosave
// are part of that snapshot and do not schedule another write.
void Autosave_Request(void);
bool8 Autosave_IsEnabled(void);
void Autosave_SetEnabled(bool8 enabled);

// Queue only: field callbacks may still own controls or be fading in.
void Autosave_OnMapLoadComplete(void);
void Autosave_Update(void);

// Save subsystem guards shared with the coordinator.
bool8 Save_IsOperationInProgress(void);
bool8 SaveDialog_IsActive(void);

#endif // GUARD_AUTOSAVE_H
