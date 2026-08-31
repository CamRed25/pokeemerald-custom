struct FieldMugshot
{
    const u32 *gfx;
    const u16 *pal;
};

static const u32 sFieldMugshotGfx_Player[] = INCGFX_U32("graphics/trainers/front_pics/brendan.png", ".4bpp");
static const u16 sFieldMugshotPal_Player[] = INCGFX_U16("graphics/trainers/palettes/brendan.pal", ".gbapal");

static const struct FieldMugshot sFieldMugshots[MUGSHOT_COUNT][EMOTE_COUNT] =
{
    [MUGSHOT_PLAYER] =
    {
        [EMOTE_NORMAL] = { sFieldMugshotGfx_Player, sFieldMugshotPal_Player },
        [EMOTE_ALT] = { sFieldMugshotGfx_Player, sFieldMugshotPal_Player },
    },
};
