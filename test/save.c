#include "global.h"
#include "autosave.h"
#include "agb_flash.h"
#include "gba/flash_internal.h"
#include "event_data.h"
#include "field_weather.h"
#include "link.h"
#include "overworld.h"
#include "script.h"
#include "save_dialog.h"
#include "task.h"
#include "constants/battle_frontier.h"
#include "constants/layouts.h"
#include "constants/maps.h"
#include "load_save.h"
#include "main.h"
#include "malloc.h"
#include "palette.h"
#include "pokemon_storage_system.h"
#include "save.h"
#include "test/test.h"

// If you would like to ensure save compatibility, update the values below with those for your hack. You can find these through the debug menu.
// Please note that this simple check is not 100% foolproof, but should be able to catch most unintended shifts.
#define T_SAVEBLOCK1_SIZE 15596
#define T_SAVEBLOCK2_SIZE 3896
#define T_SAVEBLOCK3_SIZE 16
#define T_POKEMONSTORAGE_SIZE 34144

TEST("SaveBlock1 is backwards compatible")
{
    EXPECT_EQ(sizeof(struct SaveBlock1), T_SAVEBLOCK1_SIZE);
}

TEST("SaveBlock2 is backwards compatible")
{
    EXPECT_EQ(sizeof(struct SaveBlock2), T_SAVEBLOCK2_SIZE);
}

TEST("SaveBlock3 is backwards compatible")
{
    EXPECT_EQ(sizeof(struct SaveBlock3), T_SAVEBLOCK3_SIZE);
}

TEST("PokemonStorage is backwards compatible")
{
    EXPECT_EQ(sizeof(struct PokemonStorage), T_POKEMONSTORAGE_SIZE);
}

#undef T_SAVEBLOCK1_SIZE
#undef T_SAVEBLOCK2_SIZE
#undef T_SAVEBLOCK3_SIZE
#undef T_POKEMONSTORAGE_SIZE

// Logical save group selection (hybrid autosave foundation, see save.h)

TEST("Manual save role maps to physical group 0")
{
    EXPECT_EQ(SAVE_GROUP_MANUAL, 0);
}

TEST("Autosave save role maps to physical group 1")
{
    EXPECT_EQ(SAVE_GROUP_AUTOSAVE, 1);
}

TEST("An invalid autosave group is not recoverable")
{
    EXPECT_EQ(SelectActiveSaveGroup(SAVE_STATUS_EMPTY, SAVE_STATUS_CORRUPT), SAVE_GROUP_NONE);
    EXPECT_EQ(SelectActiveSaveGroup(SAVE_STATUS_ERROR, SAVE_STATUS_EMPTY), SAVE_GROUP_NONE);
}

TEST("A valid manual group remains preferred when both groups are valid")
{
    EXPECT_EQ(SelectActiveSaveGroup(SAVE_STATUS_OK, SAVE_STATUS_OK), SAVE_GROUP_MANUAL);
}

// Fixed-role write path (hybrid autosave, see save.c's GetWritePhysicalGroup)

TEST("Manual save writes land in the fixed manual physical group")
{
    SetSaveBlocksPointers(0);
    ClearSaveData();
    Save_ResetSaveCounters();
    gSaveBlock2Ptr->saveFormatMarker = SAVE_FORMAT_MARKER; // already-migrated
    gSaveBlock2Ptr->playerTrainerId[0] = 1;
    gSaveBlock2Ptr->playerTrainerId[1] = 2;
    gSaveBlock2Ptr->playerTrainerId[2] = 3;
    gSaveBlock2Ptr->playerTrainerId[3] = 4;

    TrySavingData(SAVE_NORMAL);

    u32 counter;
    EXPECT_EQ(GetSaveGroupStatus(SAVE_GROUP_MANUAL, gRamSaveSectorLocations, &counter), SAVE_STATUS_OK);
    EXPECT_EQ(GetSaveGroupStatus(SAVE_GROUP_AUTOSAVE, gRamSaveSectorLocations, &counter), SAVE_STATUS_EMPTY);
    EXPECT_EQ(GetSaveBlocksPointersBaseOffset(), 10);
}

TEST("Autosave writes land in the fixed autosave physical group")
{
    SetSaveBlocksPointers(0);
    ClearSaveData();
    Save_ResetSaveCounters();
    gSaveBlock2Ptr->saveFormatMarker = SAVE_FORMAT_MARKER;

    TrySavingData(SAVE_AUTOSAVE);

    u32 counter;
    EXPECT_EQ(GetSaveGroupStatus(SAVE_GROUP_AUTOSAVE, gRamSaveSectorLocations, &counter), SAVE_STATUS_OK);
    EXPECT_EQ(GetSaveGroupStatus(SAVE_GROUP_MANUAL, gRamSaveSectorLocations, &counter), SAVE_STATUS_EMPTY);
}

TEST("A legacy save has no format marker until a manual save migrates it")
{
    SetSaveBlocksPointers(0);
    ClearSaveData();
    Save_ResetSaveCounters();
    gSaveBlock2Ptr->saveFormatMarker = 0; // simulate a save predating the format marker

    TrySavingData(SAVE_NORMAL);

    // No marker is written to flash yet, so exactly one physical group ends
    // up valid, and neither carries the marker.
    EXPECT_EQ(GroupHasFormatMarker(SAVE_GROUP_MANUAL) || GroupHasFormatMarker(SAVE_GROUP_AUTOSAVE), FALSE);
    u32 counter;
    u8 manualStatus = GetSaveGroupStatus(SAVE_GROUP_MANUAL, gRamSaveSectorLocations, &counter);
    u8 autosaveStatus = GetSaveGroupStatus(SAVE_GROUP_AUTOSAVE, gRamSaveSectorLocations, &counter);
    EXPECT_EQ((manualStatus == SAVE_STATUS_OK) != (autosaveStatus == SAVE_STATUS_OK), TRUE);
}

TEST("A successful manual save migrates the format marker for the next save")
{
    SetSaveBlocksPointers(0);
    ClearSaveData();
    Save_ResetSaveCounters();
    gSaveBlock2Ptr->saveFormatMarker = 0; // simulate a save predating the format marker

    TrySavingData(SAVE_NORMAL);

    // HandleSavingData marks the RAM save block as migrated once this save
    // verifies clean, so the *next* manual save (not this one) will target
    // the fixed manual group directly instead of legacy alternation.
    EXPECT_EQ(gSaveBlock2Ptr->saveFormatMarker, SAVE_FORMAT_MARKER);
}

// Read-side routing through the selected physical group.

TEST("The Continue load reads back the manual save from its physical group")
{
    SetSaveBlocksPointers(0);
    ClearSaveData();
    Save_ResetSaveCounters();
    gSaveBlock2Ptr->saveFormatMarker = SAVE_FORMAT_MARKER;

    TrySavingData(SAVE_NORMAL);

    // Clobber RAM so a stale/wrong value can't make the read-back check pass
    // by accident; LoadGameSave has to actually copy it back from flash.
    gSaveBlock2Ptr->saveFormatMarker = 0;

    EXPECT_EQ(LoadGameSave(SAVE_NORMAL), SAVE_STATUS_OK);
    EXPECT_EQ(gSaveBlock2Ptr->saveFormatMarker, SAVE_FORMAT_MARKER);
}

TEST("Autosave recovery reads back the autosave from its physical group")
{
    SetSaveBlocksPointers(0);
    ClearSaveData();
    Save_ResetSaveCounters();
    gSaveBlock2Ptr->saveFormatMarker = SAVE_FORMAT_MARKER;

    // No manual save exists, so the only valid group is the autosave one;
    // GetSaveValidStatus's SelectActiveSaveGroup fallback must resolve the
    // read to physical group 1, not the (empty) manual group 0.
    TrySavingData(SAVE_AUTOSAVE);

    gSaveBlock2Ptr->saveFormatMarker = 0;

    EXPECT_EQ(LoadGameSave(SAVE_NORMAL), SAVE_STATUS_OK);
    EXPECT_EQ(gSaveBlock2Ptr->saveFormatMarker, SAVE_FORMAT_MARKER);
}

// Save attempt status is also recorded for callers that run through the coordinator.
extern u16 gSaveAttemptStatus;

// The flash driver and test watchdog share Timer2. Give the driver its own
// interrupt handler during these real-flash scenarios, then restore the runner.
static void (*sTestTimerInterrupt)(void);
static MainCallback sTestCallback1, sTestCallback2;
static u16 sTestTimerControl, sTestTimerCount, sTestInterruptEnable;
static u16 (*sProgramSector)(u16, u8 *);
static u32 sProgramCalls;
static bool8 sReenterAutosave;
static s16 sFailSector;
static struct SaveSector *sManualSnapshot;

static u16 ProgramAutosaveTestSector(u16 sector, u8 *data)
{
    sProgramCalls++;
    if (sReenterAutosave)
    {
        Autosave_Request();
        Autosave_Update();
    }
    if (sector == sFailSector)
        return 1;
    return sProgramSector(sector, data);
}

static void BeginAutosaveTest(void)
{
    sTestTimerInterrupt = gIntrTable[7];
    sTestTimerControl = REG_TM2CNT_H;
    sTestTimerCount = REG_TM2CNT_L;
    sTestInterruptEnable = REG_IE;
    SetFlashTimerIntr(2, &gIntrTable[7]);
    sTestCallback1 = gMain.callback1;
    sTestCallback2 = gMain.callback2;
    gMain.callback1 = CB1_Overworld;
    gMain.callback2 = CB2_Overworld;
    SetSaveBlocksPointers(0);
    ClearSaveData();
    Save_ResetSaveCounters();
    gReadWriteSector = &gSaveDataBuffer;
    gSaveBlock2Ptr->saveFormatMarker = SAVE_FORMAT_MARKER;
    gSaveBlock1Ptr->pos.x = gSaveBlock1Ptr->pos.y = 0;
    gSaveBlock1Ptr->location.mapGroup = 0;
    gSaveBlock1Ptr->location.mapNum = 0;
    gSaveBlock2Ptr->frontier.challengeStatus = 0;
    gMain.inBattle = FALSE;
    gPaletteFade.active = FALSE;
    gWeatherPtr->palProcessingState = WEATHER_PAL_STATE_IDLE;
    gMapHeader.mapLayoutId = 0;
    gReceivedRemoteLinkPlayers = FALSE;
    gLinkStatus = 0;
    gWirelessCommType = 0;
    gLinkCallback = NULL;
    gFieldCallback = NULL;
    gFieldCallback2 = NULL;
    gSoftResetDisabled = FALSE;
    ScriptContext_Init();
    UnlockPlayerFieldControls();
    Autosave_SetEnabled(FALSE);
    Autosave_SetEnabled(TRUE);
    sProgramSector = ProgramFlashSector;
    ProgramFlashSector = ProgramAutosaveTestSector;
    sProgramCalls = 0;
    sFailSector = -1;
    sReenterAutosave = FALSE;
    sManualSnapshot = NULL;
}

static void EndAutosaveTest(void)
{
    FREE_AND_SET_NULL(sManualSnapshot);
    ProgramFlashSector = sProgramSector;
    Autosave_SetEnabled(FALSE);
    Autosave_SetEnabled(TRUE);
    gMain.callback1 = sTestCallback1;
    gMain.callback2 = sTestCallback2;
    REG_TM2CNT_H = 0;
    gIntrTable[7] = sTestTimerInterrupt;
    REG_TM2CNT_L = sTestTimerCount;
    REG_TM2CNT_H = sTestTimerControl;
    REG_IE = sTestInterruptEnable;
}

// EXPECT exits the test immediately, so release hardware hooks before reporting
// a failed assertion. This also keeps a failing parameter from poisoning others.
#undef EXPECT
#define EXPECT(condition) do { \
    if (!(condition)) { \
        EndAutosaveTest(); \
        Test_ExitWithResult(TEST_RESULT_FAIL, __LINE__, "%s:%d: EXPECT failed", __FILE__, __LINE__); \
    } \
} while (0)
#undef EXPECT_EQ
#define EXPECT_EQ(a, b) do { \
    typeof(a) actual = (a), expected = (b); \
    if (actual != expected) { \
        EndAutosaveTest(); \
        Test_ExitWithResult(TEST_RESULT_FAIL, __LINE__, "%s:%d: EXPECT_EQ(%d, %d) failed", __FILE__, __LINE__, actual, expected); \
    } \
} while (0)

static void ExpectOneAutosave(void)
{
    u32 counter = 0;
    EXPECT_EQ(sProgramCalls, NUM_SECTORS_PER_SLOT);
    EXPECT_EQ(gSaveCounter, 1);
    EXPECT_EQ(GetSaveGroupStatus(SAVE_GROUP_AUTOSAVE, gRamSaveSectorLocations, &counter), SAVE_STATUS_OK);
    EXPECT_EQ(counter, 1);
    Autosave_Update();
    Autosave_Update();
    EXPECT_EQ(sProgramCalls, NUM_SECTORS_PER_SLOT);
    EXPECT_EQ(gSaveCounter, 1);
}

TEST("Disabled autosave drops new and already pending requests")
{
    BeginAutosaveTest();
    Autosave_Request();
    Autosave_SetEnabled(FALSE);
    Autosave_Request();
    Autosave_OnMapLoadComplete();
    Autosave_SetEnabled(TRUE);
    Autosave_Update();
    EXPECT_EQ(sProgramCalls, 0);
    EXPECT_EQ(gSaveCounter, 0);
    Autosave_Request();
    Autosave_Update();
    ExpectOneAutosave();
    EndAutosaveTest();
}

TEST("Duplicate and reentrant autosave requests produce exactly one full write")
{
    BeginAutosaveTest();
    Autosave_Request();
    Autosave_Request();
    Autosave_OnMapLoadComplete();
    Autosave_OnMapLoadComplete();
    sReenterAutosave = TRUE;
    Autosave_Update();
    ExpectOneAutosave();
    EndAutosaveTest();
}

static void PendingFieldCallback(void) {}
static bool8 PendingFieldCallback2(void) { return FALSE; }

TEST("Unsafe field contexts defer one autosave until restoration")
{
    u32 context;
    u8 taskId = TASK_NONE;
    PARAMETRIZE { context = 0; } // battle
    PARAMETRIZE { context = 1; } // non-field menu callback
    PARAMETRIZE { context = 2; } // field menu/control lock
    PARAMETRIZE { context = 3; } // script
    PARAMETRIZE { context = 4; } // palette fade
    PARAMETRIZE { context = 5; } // weather fade in
    PARAMETRIZE { context = 6; } // weather fade out
    PARAMETRIZE { context = 7; } // remote link players
    PARAMETRIZE { context = 8; } // link operation
    PARAMETRIZE { context = 9; } // Battle Pyramid floor
    PARAMETRIZE { context = 10; } // pending field callback
    PARAMETRIZE { context = 11; } // pending polling field callback
    PARAMETRIZE { context = 12; } // link save task
    PARAMETRIZE { context = 13; } // save dialog task
    PARAMETRIZE { context = 14; } // save/reset critical section
    PARAMETRIZE { context = 15; } // active Pyramid challenge outside floor
    PARAMETRIZE { context = 16; } // non-field input callback
    PARAMETRIZE { context = 17; } // Union Room
    PARAMETRIZE { context = 18; } // waiting script retains controls
    PARAMETRIZE { context = 19; } // Battle Pyramid top
    PARAMETRIZE { context = 20; } // established link before remote-player exchange
    BeginAutosaveTest();
    switch (context)
    {
    case 0: gMain.inBattle = TRUE; break;
    case 1: gMain.callback2 = PendingFieldCallback; break;
    case 2: LockPlayerFieldControls(); break;
    case 3: ScriptContext_SetupScript((const u8[]){2}); break;
    case 4: gPaletteFade.active = TRUE; break;
    case 5: gWeatherPtr->palProcessingState = WEATHER_PAL_STATE_SCREEN_FADING_IN; break;
    case 6: gWeatherPtr->palProcessingState = WEATHER_PAL_STATE_SCREEN_FADING_OUT; break;
    case 7: gReceivedRemoteLinkPlayers = TRUE; break;
    case 8: gLinkCallback = PendingFieldCallback; break;
    case 9: gMapHeader.mapLayoutId = LAYOUT_BATTLE_FRONTIER_BATTLE_PYRAMID_FLOOR; break;
    case 10: gFieldCallback = PendingFieldCallback; break;
    case 11: gFieldCallback2 = PendingFieldCallback2; break;
    case 12: taskId = CreateTask(Task_LinkFullSave, 5); break;
    case 13: taskId = CreateTask(Task_SaveDialogHandleSave, 5); break;
    case 14: gSoftResetDisabled = TRUE; break;
    case 16: gMain.callback1 = PendingFieldCallback; break;
    case 17:
        gSaveBlock1Ptr->location.mapGroup = MAP_GROUP(MAP_UNION_ROOM);
        gSaveBlock1Ptr->location.mapNum = MAP_NUM(MAP_UNION_ROOM);
        break;
    case 18:
        ScriptContext_SetupScript((const u8[]){2});
        ScriptContext_Stop();
        break;
    case 19: gMapHeader.mapLayoutId = LAYOUT_BATTLE_FRONTIER_BATTLE_PYRAMID_TOP; break;
    case 20: gLinkStatus = LINK_STAT_CONN_ESTABLISHED; break;
    case 15:
        VarSet(VAR_FRONTIER_FACILITY, FRONTIER_FACILITY_PYRAMID);
        gSaveBlock2Ptr->frontier.challengeStatus = CHALLENGE_STATUS_SAVING;
        break;
    }
    Autosave_OnMapLoadComplete();
    Autosave_Request();
    Autosave_Update();
    EXPECT_EQ(sProgramCalls, 0);
    EXPECT_EQ(gSaveCounter, 0);

    gMain.inBattle = FALSE;
    gMain.callback1 = CB1_Overworld;
    gMain.callback2 = CB2_Overworld;
    gSaveBlock1Ptr->location.mapGroup = 0;
    gSaveBlock1Ptr->location.mapNum = 0;
    UnlockPlayerFieldControls();
    ScriptContext_Init();
    gPaletteFade.active = FALSE;
    gWeatherPtr->palProcessingState = WEATHER_PAL_STATE_IDLE;
    gReceivedRemoteLinkPlayers = FALSE;
    gLinkStatus = 0;
    gLinkCallback = NULL;
    gMapHeader.mapLayoutId = 0;
    gFieldCallback = NULL;
    gFieldCallback2 = NULL;
    gSoftResetDisabled = FALSE;
    gSaveBlock2Ptr->frontier.challengeStatus = 0;
    if (taskId != TASK_NONE)
        DestroyTask(taskId);
    Autosave_Update();
    ExpectOneAutosave();
    EndAutosaveTest();
}

TEST("Map completion queues a snapshot and a stable field update writes it")
{
    BeginAutosaveTest();
    Autosave_OnMapLoadComplete();
    EXPECT_EQ(sProgramCalls, 0);
    Autosave_Update();
    ExpectOneAutosave();
    EndAutosaveTest();
}

TEST("A failed autosave is silent, consumed, and preserves every manual sector and Continue")
{
    u32 i, counter, calls;
    u16 lastSector;
    BeginAutosaveTest();
    gSaveBlock2Ptr->playerTrainerId[0] = 42;
    EXPECT_EQ(TrySavingData(SAVE_NORMAL), SAVE_STATUS_OK);
    sManualSnapshot = Alloc(NUM_SECTORS_PER_SLOT * SECTOR_SIZE);
    EXPECT(sManualSnapshot != NULL);
    for (i = 0; i < NUM_SECTORS_PER_SLOT; i++)
        ReadFlash(i, 0, (u8 *)&sManualSnapshot[i], SECTOR_SIZE);
    EXPECT_EQ(TrySavingData(SAVE_AUTOSAVE), SAVE_STATUS_OK);
    counter = gSaveCounter;
    lastSector = gLastWrittenSector;
    // Fail the first logical sector after a prior autosave exists.
    sFailSector = NUM_SECTORS_PER_SLOT + (lastSector + 1) % NUM_SECTORS_PER_SLOT;
    gSaveBlock2Ptr->playerTrainerId[0] = 99;
    Autosave_Request();
    Autosave_Update();
    EXPECT_EQ(gSaveAttemptStatus, SAVE_STATUS_ERROR);
    EXPECT_EQ(gMain.callback2, CB2_Overworld);
    EXPECT_EQ(gSaveCounter, counter);
    EXPECT_EQ(gLastWrittenSector, lastSector);
    EXPECT_EQ(gDamagedSaveSectors, 0);
    EXPECT_EQ(Save_IsOperationInProgress(), FALSE);
    EXPECT(sProgramCalls > 2 * NUM_SECTORS_PER_SLOT);
    calls = sProgramCalls;
    Autosave_Update();
    EXPECT_EQ(sProgramCalls, calls);
    for (i = 0; i < NUM_SECTORS_PER_SLOT; i++)
    {
        ReadFlash(i, 0, (u8 *)&gSaveDataBuffer, SECTOR_SIZE);
        EXPECT_EQ(memcmp(&gSaveDataBuffer, &sManualSnapshot[i], SECTOR_SIZE), 0);
    }
    EXPECT(GetSaveGroupStatus(SAVE_GROUP_AUTOSAVE, gRamSaveSectorLocations, &counter) != SAVE_STATUS_OK);
    EXPECT_EQ(LoadGameSave(SAVE_NORMAL), SAVE_STATUS_OK);
    EXPECT_EQ(gSaveBlock2Ptr->playerTrainerId[0], 42);
    sFailSector = -1;
    EXPECT_EQ(TrySavingData(SAVE_NORMAL), SAVE_STATUS_OK);
    EndAutosaveTest();
}

TEST("Legacy manual data in group 1 is preserved until a fixed manual save exists")
{
    u32 counter, calls;
    BeginAutosaveTest();
    gSaveBlock2Ptr->saveFormatMarker = 0;
    gSaveBlock2Ptr->playerTrainerId[0] = 42;
    EXPECT_EQ(TrySavingData(SAVE_NORMAL), SAVE_STATUS_OK);
    EXPECT_EQ(GetSaveGroupStatus(SAVE_GROUP_AUTOSAVE, gRamSaveSectorLocations, &counter), SAVE_STATUS_OK);
    calls = sProgramCalls;
    Autosave_OnMapLoadComplete();
    Autosave_Update();
    EXPECT_EQ(sProgramCalls, calls);
    EXPECT_EQ(gSaveCounter, 1);
    EXPECT_EQ(gSaveAttemptStatus, SAVE_STATUS_ERROR);
    gSaveBlock2Ptr->playerTrainerId[0] = 99;
    EXPECT_EQ(LoadGameSave(SAVE_NORMAL), SAVE_STATUS_OK);
    EXPECT_EQ(gSaveBlock2Ptr->playerTrainerId[0], 42);
    EndAutosaveTest();
}

TEST("An incremental save defers autosave until its final signature is written")
{
    u32 calls;
    BeginAutosaveTest();
    EXPECT_EQ(LinkFullSave_Init(), FALSE);
    EXPECT_EQ(Save_IsOperationInProgress(), TRUE);
    Autosave_Request();
    Autosave_Update();
    EXPECT_EQ(sProgramCalls, 0);
    while (!LinkFullSave_WriteSector())
        ;
    LinkFullSave_ReplaceLastSector();
    LinkFullSave_SetLastSectorSignature();
    EXPECT_EQ(Save_IsOperationInProgress(), FALSE);
    calls = sProgramCalls;
    Autosave_Update();
    EXPECT_EQ(sProgramCalls, calls + NUM_SECTORS_PER_SLOT);
    EXPECT_EQ(gSaveCounter, 2);
    Autosave_Update();
    EXPECT_EQ(sProgramCalls, calls + NUM_SECTORS_PER_SLOT);
    EndAutosaveTest();
}

TEST("Autosave preserves the manual rotation for a later partial link save")
{
    u32 counter;
    u16 manualSector;
    BeginAutosaveTest();
    EXPECT_EQ(TrySavingData(SAVE_NORMAL), SAVE_STATUS_OK);
    manualSector = gLastWrittenSector;
    Autosave_OnMapLoadComplete();
    Autosave_Update();
    EXPECT_EQ(gSaveCounter, 2);
    EXPECT_EQ(gLastWrittenSector, manualSector);
    EXPECT_EQ(WriteSaveBlock2(), FALSE);
    EXPECT_EQ(Save_IsOperationInProgress(), TRUE);
    while (!WriteSaveBlock1Sector())
        ;
    EXPECT_EQ(Save_IsOperationInProgress(), FALSE);
    EXPECT_EQ(GetSaveGroupStatus(SAVE_GROUP_MANUAL, gRamSaveSectorLocations, &counter), SAVE_STATUS_OK);
    EXPECT_EQ(GetSaveGroupStatus(SAVE_GROUP_AUTOSAVE, gRamSaveSectorLocations, &counter), SAVE_STATUS_OK);
    EndAutosaveTest();
}

TEST("Repeated autosaves advance every sector counter and preserve manual rotation and bytes")
{
    u32 iteration, sector, counter;
    u32 manualRollbackCounter;
    u16 manualRotation;
    BeginAutosaveTest();
    EXPECT_EQ(TrySavingData(SAVE_NORMAL), SAVE_STATUS_OK);
    manualRotation = gLastWrittenSector;
    manualRollbackCounter = gLastSaveCounter;
    sManualSnapshot = Alloc(NUM_SECTORS_PER_SLOT * SECTOR_SIZE);
    EXPECT(sManualSnapshot != NULL);
    for (sector = 0; sector < NUM_SECTORS_PER_SLOT; sector++)
        ReadFlash(sector, 0, (u8 *)&sManualSnapshot[sector], SECTOR_SIZE);

    for (iteration = 0; iteration < 3; iteration++)
    {
        Autosave_Request();
        Autosave_OnMapLoadComplete();
        Autosave_Update();
        EXPECT_EQ(gSaveAttemptStatus, SAVE_STATUS_OK);
        EXPECT_EQ(gSaveCounter, iteration + 2);
        EXPECT_EQ(gLastWrittenSector, manualRotation);
        EXPECT_EQ(gLastSaveCounter, manualRollbackCounter);
        EXPECT_EQ(sProgramCalls, (iteration + 2) * NUM_SECTORS_PER_SLOT);
        EXPECT_EQ(GetSaveGroupStatus(SAVE_GROUP_AUTOSAVE, gRamSaveSectorLocations, &counter), SAVE_STATUS_OK);
        EXPECT_EQ(counter, iteration + 2);
        for (sector = 0; sector < NUM_SECTORS_PER_SLOT; sector++)
        {
            ReadFlash(NUM_SECTORS_PER_SLOT + sector, 0, (u8 *)&gSaveDataBuffer, SECTOR_SIZE);
            EXPECT_EQ(gSaveDataBuffer.counter, iteration + 2);
            ReadFlash(sector, 0, (u8 *)&gSaveDataBuffer, SECTOR_SIZE);
            EXPECT_EQ(memcmp(&gSaveDataBuffer, &sManualSnapshot[sector], SECTOR_SIZE), 0);
        }
        Autosave_Update();
        EXPECT_EQ(sProgramCalls, (iteration + 2) * NUM_SECTORS_PER_SLOT);
        EXPECT_EQ(gSaveCounter, iteration + 2);
    }
    EndAutosaveTest();
}
