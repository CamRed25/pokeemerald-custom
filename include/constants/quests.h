#ifndef GUARD_CONSTANTS_QUESTS_H
#define GUARD_CONSTANTS_QUESTS_H

// Quest number defines. Only two placeholder quests exist so far - add more
// here (and in src/quests.c's "QUEST CUSTOMIZATION" section) as real quest
// content is authored.
#define QUEST_PLACEHOLDER_1  0
#define QUEST_PLACEHOLDER_2  1
#define QUEST_COUNT          2

#define SUB_QUEST_1          0
#define SUB_QUEST_2          1

#define QUEST_1_SUB_COUNT 2
#define SUB_QUEST_COUNT (QUEST_1_SUB_COUNT)

#define QUEST_ARRAY_COUNT (SUB_QUEST_COUNT > QUEST_COUNT ? SUB_QUEST_COUNT : QUEST_COUNT)

// Number of different quest states tracked in the saveblock (unlocked,
// inactive, active, reward, completed).
#define QUEST_STATES 5

#endif // GUARD_CONSTANTS_QUESTS_H
