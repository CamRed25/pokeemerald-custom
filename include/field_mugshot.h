#ifndef GUARD_FIELD_MUGSHOT_H
#define GUARD_FIELD_MUGSHOT_H

struct ScriptContext;

void CreateFieldMugshot(struct ScriptContext *ctx);
void RemoveFieldMugshot(void);
u8 GetFieldMugshotSpriteId(void);
bool8 IsFieldMugshotActive(void);

#endif // GUARD_FIELD_MUGSHOT_H
