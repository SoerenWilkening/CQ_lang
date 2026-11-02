/* tests/eff-invert probes (cq-eive): clones of void functions with several returns (a region inside a clone body).
 * invert_ret.O1.ll is this file at -O1 with each callee's common return block split back into one
 * `ret void` per arm (clang -O1 merges them; the IR is the shape a callee with several returns has).
 * p_adjret: the returns sit behind a classical branch (the reverse starts from the return taken).
 * p_adjretq: the returns sit in the arms of a quantum branch (both arms run, linearized, to their returns);
 *   called inside the region only (the spine's forward clone does not lower a return under a quantum
 *   predicate). */
#include "CQ.h"
__attribute__((noinline)) static void two(unsigned *x, int c, double a, double b) {
  if (c > 0) { cq_theta(x, a); return; }
  cq_theta(x, b);
}
__attribute__((noinline)) static void twoq(unsigned *x, unsigned y, double a, double b) {
  if (y > 3) { cq_theta(x, a); return; }
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
int p_adjretq(unsigned x0, unsigned y0, double tx, double ty, double a, double b) {
  unsigned x = x0, y = y0;
  cq_theta(&x, tx);
  cq_theta(&y, ty);
  cq_invert_begin();
  twoq(&x, y, a, b);
  cq_invert_end();
  return cq_measure(x) + cq_measure(y);
}
