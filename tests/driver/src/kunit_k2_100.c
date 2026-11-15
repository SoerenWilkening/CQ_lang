/* a static mk with its own CQ_K2(mk, 100) (cq-z9vt) */
#include <stdlib.h>
CQ_K2(mk, 100)
__attribute__((noinline)) static int mk(int n) { char *p = malloc(n); if (!p) return 0; ((volatile char *)p)[0] = 1; int r = ((volatile char *)p)[0]; free(p); return r; }
int e100(int x0, double th) { int x = x0 & 255; cq_theta(&x, th); return cq_measure(mk(x)); }
