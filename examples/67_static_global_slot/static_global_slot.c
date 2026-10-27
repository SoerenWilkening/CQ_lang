#include <stdio.h>
__attribute__((noinline)) static int bump(int v) { printf("%d\n", v); return v + 1; }
int static_global_slot(int x0, double th, int c) {
    static int saved;                               /* function-local static: a global that never escapes */
    int x = x0;
    cq_theta(&x, th);
    saved = x * c;                                  /* quantum value stored into the global */
    int y = bump(saved);                            /* a call in between keeps the global in memory at -O1 */
    return cq_measure(y + saved);                   /* read back */
}
