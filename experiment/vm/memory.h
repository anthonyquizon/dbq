#include "types.h"

typedef struct  {
} Arena;

void *arena_alloc(Arena *a, ux size);
void arena_reset(Arena *a);
void arena_free(Arena *a);



