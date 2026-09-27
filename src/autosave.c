#include "global.h"
#include "autosave.h"
#include "battle_pyramid.h"
#include "event_data.h"
#include "field_weather.h"
#include "fieldmap.h"
#include "link.h"
#include "main.h"
#include "overworld.h"
#include "palette.h"
#include "save.h"
#include "save_dialog.h"
#include "script.h"
#include "sound.h"
#include "task.h"
#include "constants/battle_frontier.h"
#include "constants/songs.h"

static EWRAM_DATA bool8 sAutosaveEnabled = TRUE;
static EWRAM_DATA bool8 sAutosavePending = FALSE;
static EWRAM_DATA bool8 sAutosaveInProgress = FALSE;
static EWRAM_DATA u8 sAutosaveLastResult = SAVE_STATUS_EMPTY;

bool8 Autosave_IsEnabled(void)
{
    return sAutosaveEnabled;
}

void Autosave_SetEnabled(bool8 enabled)
{
    sAutosaveEnabled = enabled;
    if (!enabled)
        sAutosavePending = FALSE;
}

void Autosave_Request(void)
{
    if (sAutosaveEnabled && !sAutosaveInProgress)
        sAutosavePending = TRUE;
}

static bool8 IsAutosaveContextSafe(void)
{
    // Tasks can change callbacks during the current overworld frame.
    if (gMain.callback1 != CB1_Overworld || gMain.callback2 != CB2_Overworld
     || gMain.inBattle || gFieldCallback != NULL || gFieldCallback2 != NULL)
        return FALSE;
    if (IsOverworldLinkActive() || InUnionRoom() || gReceivedRemoteLinkPlayers
     || IsLinkConnectionEstablished() || !IsLinkTaskFinished())
        return FALSE;
    if (ArePlayerFieldControlsLocked() || ScriptContext_IsEnabled())
        return FALSE;
    if (gPaletteFade.active
     || gWeatherPtr->palProcessingState == WEATHER_PAL_STATE_SCREEN_FADING_IN
     || gWeatherPtr->palProcessingState == WEATHER_PAL_STATE_SCREEN_FADING_OUT)
        return FALSE;
    if (gSoftResetDisabled || Save_IsOperationInProgress() || SaveDialog_IsActive()
     || FuncIsActiveTask(Task_LinkFullSave) || FuncIsActiveTask(Task_SaveDialogHandleSave))
        return FALSE;
    if (InBattlePyramid_()
     || (VarGet(VAR_FRONTIER_FACILITY) == FRONTIER_FACILITY_PYRAMID
      && gSaveBlock2Ptr->frontier.challengeStatus == CHALLENGE_STATUS_SAVING))
        return FALSE;
    return TRUE;
}

void Autosave_OnMapLoadComplete(void)
{
    Autosave_Request();
}

void Autosave_Update(void)
{
    if (!sAutosaveEnabled || !sAutosavePending || sAutosaveInProgress
     || !IsAutosaveContextSafe())
        return;

    sAutosavePending = FALSE;
    sAutosaveInProgress = TRUE;
    gSoftResetDisabled = TRUE;
    SaveMapView();
    sAutosaveLastResult = TrySavingData(SAVE_AUTOSAVE);
    gSoftResetDisabled = FALSE;
    sAutosaveInProgress = FALSE;

    if (sAutosaveLastResult == SAVE_STATUS_OK)
        PlaySE(SE_SAVE);
}
