/* CR rule 17 (2026-11-02): an end in each arm of a quantum branch, both closing the region a begin before the
 * branch opened. Every C path pairs, but the host executes both ends; rule 17 orders ONE marker in an arm against
 * its match outside it and does not say how two merge: SPEC_ISSUES (proposed, cq-z7hz). */
#include "CQ.h"
int p_exends(int x0, double th, int k, double a, double b) {
  int x = x0; cq_theta(&x, th);
  cq_invert_begin();
  if (x == k) {
    cq_phi(a);
    cq_invert_end();
    cq_theta(&x, b);
  } else {
    cq_phi(b);
    cq_invert_end();
    cq_theta(&x, a);
  }
  return cq_measure(x);
}
