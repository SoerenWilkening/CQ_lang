#include "CQ.h"
/* cq-nyto (1), review b7: the clone rotates the caller's cell in place (T3 cellsRotated) but the cell holds a
   classical value's seed at the call; rule 2's classical re-read after the call would read r0 and the seed
   would be freed before the call. Unimplemented until the rotation makes the rail opaque to that re-read. */
__attribute__((noinline)) static void step(int *r, int x, int k, double t) { if (x > k) cq_theta(r, t); }
int clone_rotate_classical_cell(int x0, double tx, int r0, int k, double t) {
  int x = x0; cq_theta(&x, tx); int r = r0; step(&r, x, k, t); return cq_measure(r) + cq_measure(x);
}
