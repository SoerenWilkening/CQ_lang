#include "CQ.h"
/* GMP's own __gmpn_jacobi_base (experiments/repro-round9/gmpn_jacobi_base.ll, linked in: gmpjac.O1.ll) called with only
 * `bit` quantum: its 001 arrangement's body as a clone. */
int __gmpn_jacobi_base(unsigned long a, unsigned long b, int bit);
int gmpjac(unsigned long a, unsigned long b, int bit0, double th) {
  int bit = bit0; cq_theta(&bit, th);
  return __gmpn_jacobi_base(a, b, bit);
}
