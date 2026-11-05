/* tests/eff-invert probes (cq-eive, cq-4593): clones of void functions with several returns, called in a region.
 * invert_ret.O1.ll is this file at -O1 with the callee's common return block split back into one `ret void`
 * per arm (clang -O1 merges them; the IR is the shape a callee with several returns has).
 * p_adjret: the returns sit behind a classical branch. invert_retq.c holds the quantum-branch case. */
#include "CQ.h"
__attribute__((noinline)) static void two(unsigned *x, int c, double a, double b) {
  if (c > 0) { cq_theta(x, a); return; }
  cq_theta(x, b);
}
int p_adjret(unsigned x0, double tx, int c, double a, double b) {
  unsigned x = x0;
  cq_theta(&x, tx);
  two(&x, c, a, b);
  cq_invert_begin();
  two(&x, c, a, b);
  cq_invert_end();
  return cq_measure(x);
}
