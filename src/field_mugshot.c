#include "global.h"
#include "event_data.h"
#include "field_mugshot.h"
#include "field_weather.h"
#include "script.h"
#include "sprite.h"
#include "constants/field_mugshots.h"
#include "data/field_mugshots.h"

#define TAG_FIELD_MUGSHOT 0x9000
#define FIELD_MUGSHOT_X (168 + 32)
#define FIELD_MUGSHOT_Y (51 + 32)

static EWRAM_INIT u8 sFieldMugshotSpriteId = SPRITE_NONE;
static EWRAM_INIT bool8 sFieldMugshotActive = FALSE;

static const struct OamData sFieldMugshotOam =
{
    .size = SPRITE_SIZE(64x64),
    .shape = SPRITE_SHAPE(64x64),
    .priority = 0,
};

static void SpriteCB_FieldMugshot(struct Sprite *sprite)
{
    sprite->invisible = !sprite->data[0];
}

static const struct SpriteTemplate sFieldMugshotTemplate =
{
    .tileTag = TAG_FIELD_MUGSHOT,
    .paletteTag = TAG_FIELD_MUGSHOT,
    .oam = &sFieldMugshotOam,
    .callback = SpriteCB_FieldMugshot,
    .anims = gDummySpriteAnimTable,
    .affineAnims = gDummySpriteAffineAnimTable,
};

void RemoveFieldMugshot(void)
{
    ResetPreservedPalettesInWeather();
    if (sFieldMugshotSpriteId != SPRITE_NONE)
    {
        FreeSpriteTilesByTag(TAG_FIELD_MUGSHOT);
        FreeSpritePaletteByTag(TAG_FIELD_MUGSHOT);
        DestroySprite(&gSprites[sFieldMugshotSpriteId]);
        sFieldMugshotSpriteId = SPRITE_NONE;
    }
    sFieldMugshotActive = FALSE;
}

void CreateFieldMugshot(struct ScriptContext *ctx)
{
    u32 id = VarGet(ScriptReadHalfword(ctx));
    u32 emote = VarGet(ScriptReadHalfword(ctx));
    struct SpriteSheet sheet;
    struct SpritePalette palette;

    if (id >= MUGSHOT_COUNT || emote >= EMOTE_COUNT || sFieldMugshots[id][emote].gfx == NULL)
        return;

    RemoveFieldMugshot();
    sheet.data = sFieldMugshots[id][emote].gfx;
    sheet.size = 64 * 64 / 2;
    sheet.tag = TAG_FIELD_MUGSHOT;
    palette.data = sFieldMugshots[id][emote].pal;
    palette.tag = TAG_FIELD_MUGSHOT;
    LoadSpriteSheet(&sheet);
    LoadSpritePalette(&palette);

    sFieldMugshotSpriteId = CreateSprite(&sFieldMugshotTemplate, FIELD_MUGSHOT_X, FIELD_MUGSHOT_Y, 0);
    if (sFieldMugshotSpriteId == SPRITE_NONE)
    {
        FreeSpriteTilesByTag(TAG_FIELD_MUGSHOT);
        FreeSpritePaletteByTag(TAG_FIELD_MUGSHOT);
        return;
    }

    PreservePaletteInWeather(gSprites[sFieldMugshotSpriteId].oam.paletteNum + 0x10);
    gSprites[sFieldMugshotSpriteId].data[0] = FALSE;
    sFieldMugshotActive = TRUE;
}

u8 GetFieldMugshotSpriteId(void)
{
    return sFieldMugshotSpriteId;
}

bool8 IsFieldMugshotActive(void)
{
    return sFieldMugshotActive;
}
