#include "CQ.h"
/* cq-a63l (CR rule 10): a prep under a classical guard merged outside it (rule 9 over the handles), and a
   theta whose merges name two registers. */
int guarded_prep(int x0, int c, int k) {
  int x = cq_theta_si32(x0, 0.9);
  int r = 3;
  if (c > 0) {
    if (x > k)
      r = cq_theta_si32(5, 0.7);
  }
  return cq_measure_si32(r) + 10 * cq_measure_si32(x);
}
int two_regs(int x0, int k1, int k2) {
  int x = cq_theta_si32(x0, 0.9);
  int r = 1;
  if (x > k1) r = cq_theta_si32(2, 0.3);
  int s = r;
  if (x < k2) s = cq_theta_si32(4, 0.5);
  if (x == k1 + k2) r = cq_theta_si32(6, 0.4);
  return cq_measure_si32(r) + 10 * cq_measure_si32(s) + 100 * cq_measure_si32(x);
}
