#include "CQ.h"
static int g;
__attribute__((noinline)) static void bump(void) { g = g + 1; }
int global_touched_error(int x0, double th) {
    int x = x0;
    cq_theta(&x, th);
    g = x;
    bump();
    return cq_measure(g);
}
