/* tests/loops-cutoff probe (nr-S25; CR rule 14 case 2): differential family FC: K-loops inside a cq_invert region (CR rule 17 with rule 14).
 * Each entry is checked against its C program. At d5e32f61 fc_inv and fc_inv_do fail (cq-037u2): the rolled trip's reverse loop is placed after cqrt_invert_end;
 * the K-static-copies lowering (4afda23b) passed them.
 * Regenerate:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec diff_fc.c -o diff_fc.O1.ll */
#include "CQ.h"
/* the K-loop's exit value read after the region */
unsigned fc_inv(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned y = x;
  cq_invert_begin();
  while (y & 1) { y >>= 1; }
  cq_invert_end();
  return cq_measure(y);
}
/* a do-while in the region */
unsigned fc_inv_do(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s;
  cq_invert_begin();
  s = 3;
  do { s = s * 5 + x; x >>= 1; } while (x & 1);
  cq_invert_end();
  return cq_measure(s);
}
__attribute__((noinline)) static unsigned fc_g(unsigned x) {
  unsigned s = 1;
  while (x & 1) { s = s * 3 + x; x >>= 1; }
  return s;
}
/* a callee's K-loop called inside the region */
unsigned fc_inv_call(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned r;
  cq_invert_begin();
  r = fc_g(x);
  cq_invert_end();
  return cq_measure(r);
}
