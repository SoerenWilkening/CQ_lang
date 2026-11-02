/* tests/eff-invert probes (cq-eive): which calls are _adj (rule 17: clones as _adj).
 * p_between: a call between two regions of one block is a forward call (taint once took the first begin and
 *   the second end as one region and made it _adj: a silent inverse).
 * p_nested: a call inside an _adj body is _adj too (the adjoint of the body includes its callees'). */
#include "CQ.h"
__attribute__((noinline)) static void rot(unsigned *x, double t) { cq_theta(x, t); }
__attribute__((noinline)) static void ph(unsigned y, unsigned k, double t) {
  if (y > k)
    cq_phi(t);
}
__attribute__((noinline)) static void outer(unsigned *x, unsigned y, double t1, double t2, unsigned k) {
  cq_theta(x, t1);
  ph(y, k, t2);
}
int p_between(unsigned x0, double tx, double a, double b, double c) {
  unsigned x = x0;
  cq_theta(&x, tx);
  cq_invert_begin();
  cq_theta(&x, a);
  cq_invert_end();
  rot(&x, b);
  cq_invert_begin();
  cq_theta(&x, c);
  cq_invert_end();
  return cq_measure(x);
}
int p_nested(unsigned x0, unsigned y0, double tx, double ty, double t1, double t2, unsigned k) {
  unsigned x = x0, y = y0;
  cq_theta(&x, tx);
  cq_theta(&y, ty);
  cq_invert_begin();
  outer(&x, y, t1, t2, k);
  cq_invert_end();
  return cq_measure(x) + cq_measure(y);
}
