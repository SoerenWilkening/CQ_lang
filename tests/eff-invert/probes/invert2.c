/* tests/eff-invert probes (cq-w2b-invert): rule 17 regions with classical control flow and in-place
 * outputs, each checked §6 against its own C program (cqcheck user). Regenerate invert2.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../CQ_spec invert2.c -o invert2.O1.ll */
#include "CQ.h"
/* the register is rotated in place inside the region and read after it (61's invert_theta) */
int p_inplace(int x0, double th, double t2, double t3) {
  int x = x0; cq_theta(&x, th);
  cq_invert_begin();
  cq_theta(&x, t2);
  cq_theta(&x, t3);
  cq_invert_end();
  return cq_measure(x);
}
/* a classical branch inside the region, quantum arms under each side (a phase, a rotation of z) */
int p_cbr(int x0, int z0, double th, int c, int k, double a, double b) {
  int x = x0; cq_theta(&x, th);
  int z = z0; cq_theta(&z, th);
  cq_invert_begin();
  if (c > 0) {
    if (x * c == k) cq_phi(a);
  } else {
    if (x + c > k) cq_theta(&z, b);
  }
  cq_invert_end();
  return cq_measure(x) + cq_measure(z);
}
/* a second register rotated under control on both sides of a classical branch */
int p_reg(int x0, double th, int r0, int c, int k, double t, double a) {
  int x = x0; cq_theta(&x, th);
  int r = r0; cq_theta(&r, t);
  cq_invert_begin();
  if (c > 3) {
    if (x > k) { cq_theta(&r, t); cq_phi(a); }
  } else {
    if (x < k - c) cq_theta(&r, a);
  }
  cq_invert_end();
  return cq_measure(r) + cq_measure(x);
}
/* a classical switch, a rail computed before it and read in two of its cases */
int p_cswitch(int x0, int z0, double th, int c, int k, double a, double b) {
  int x = x0; cq_theta(&x, th);
  int z = z0; cq_theta(&z, th);
  cq_invert_begin();
  int y = x * 3 + k;
  switch (c) {
  case 0: if (y == 7) cq_phi(a); break;
  case 1: if (y < 2) cq_theta(&z, b); break;
  case 5: break;
  default: if (x & 1) cq_theta(&z, a); break;
  }
  cq_invert_end();
  return cq_measure(x) + cq_measure(z);
}
