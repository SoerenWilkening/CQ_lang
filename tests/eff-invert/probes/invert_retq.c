/* tests/eff-invert probes (cq-eive, cq-4593): a clone of a void function whose returns sit in the arms of a
 * quantum branch (both arms run, linearized, to their returns), called inside a cq_invert region.
 * invert_retq.O1.ll is this file at -O1 with the callee's common return block split back into one
 * `ret void` per arm. Split from invert_ret.c so the classical case is checked on its own. */
#include "CQ.h"
__attribute__((noinline)) static void twoq(unsigned *x, unsigned y, double a, double b) {
  if (y > 3) { cq_theta(x, a); return; }
  cq_theta(x, b);
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
