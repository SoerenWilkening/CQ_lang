/* rule 8 inside a region (cq-ja5h p8): a quantum arm whose condition has a classical conjunct needs a
 * classical guard inside the linearized segment: unimplemented, never the phase without its guard. */
#include "CQ.h"
int p_guard(int x0, double th, int c, int k, double phi) {
  int x = x0; cq_theta(&x, th);
  cq_invert_begin();
  int z = (x > k) ? 5 : c;
  if (z == 3) cq_phi(phi);
  cq_invert_end();
  return cq_measure(x);
}
