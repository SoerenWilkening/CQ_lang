#include "CQ.h"
/* cq-nyto (1), review b7: the clone rotates the caller's cell in place (T3 cellsRotated) and the cell holds a
   classical value's seed at the call. The rotating call is a write of the cell for forwarding: the read after
   it is a run-time read of the cell (the object's cells are registers, as 124's r), never the seed itself,
   which rule 2's classical re-read would fold to r0 (and whose free would precede the call). */
__attribute__((noinline)) static void step(int *r, int x, int k, double t) { if (x > k) cq_theta(r, t); }
int clone_rotate_classical_cell(int x0, double tx, int r0, int k, double t) {
  int x = x0; cq_theta(&x, tx); int r = r0; step(&r, x, k, t); return cq_measure(r) + cq_measure(x);
}
