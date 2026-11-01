#include "CQ.h"
/* cq-nyto (1), review b4q: the caller's cell holds a rotated rail at the call, the clone rotates it in place
   under x > k (124's shape): built; the caller measures the cell's rail after the call. */
__attribute__((noinline)) static int step(int *r, int x, int k, double t) { int out; if (x > k) { cq_theta(r, t); out = 1; } else { out = *r + 2; } return out; }
int clone_rotate_quantum_cell(int x0, double tx, int r0, int k, double t) {
  int x = x0; cq_theta(&x, tx); int r = r0; cq_theta(&r, tx); int o = step(&r, x, k, t);
  return cq_measure(r) + cq_measure(x) + cq_measure(o);
}
