/* tests/eff-invert probes (cq-w1-eff-invert): rule 17 regions, each checked §6 against its own C program
 * (cqcheck user). Regenerate invert.O1.ll: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0
 * -I ../CQ_spec invert.c -o invert.O1.ll */
#include "CQ.h"
/* one block: the computes cancel, the phase is global (rule 12), the adjoint has no gate left */
int p_flat(int x0, double th, int c, double phi) {
  int x = x0; cq_theta(&x, th);
  cq_invert_begin();
  int y = x * c + 3;
  cq_phi(phi);
  (void)y;
  cq_invert_end();
  return cq_measure(x);
}
/* both arms phased */
int p_arms(int x0, double th, int c, int k, double a, double b) {
  int x = x0; cq_theta(&x, th);
  cq_invert_begin();
  if (x * c == k) cq_phi(a); else cq_phi(b);
  cq_invert_end();
  return cq_measure(x);
}
/* nested arms: the inner phase is on a conjunction flag */
int p_nest(int x0, double th, int k, int m, double a, double b) {
  int x = x0; cq_theta(&x, th);
  cq_invert_begin();
  if (x > k) {
    cq_phi(a);
    if (x < m) cq_phi(b);
  }
  cq_invert_end();
  return cq_measure(x);
}
/* phases before and after the region on other predicates over the same register */
int p_around(int x0, double th, int k, int m, double a, double b) {
  int x = x0; cq_theta(&x, th);
  if (x == m) cq_phi(a);
  cq_invert_begin();
  if (x == k) cq_phi(b);
  cq_invert_end();
  if (x * 3 > m) cq_phi(a);
  return cq_measure(x);
}
/* two regions in a row and a region on two registers */
int p_two(int x0, int z0, double th, double a, double b) {
  int x = x0; cq_theta(&x, th);
  int z = z0; cq_theta(&z, th);
  cq_invert_begin();
  if (x + z > 3) cq_phi(a);
  cq_invert_end();
  cq_invert_begin();
  if ((x ^ z) & 1) cq_phi(b);
  cq_invert_end();
  return cq_measure(x) + cq_measure(z);
}
