/* tests/loops-cutoff probe (nr-S25; CR rule 14 case 2): differential family FC: K-loops inside a cq_invert region (CR rule 17 with rule 14).
 * Each entry is checked against its C program. At d5e32f61 fc_inv and fc_inv_do fail (cq-037u2): the rolled trip's reverse loop is placed after cqrt_invert_end;
 * the K-static-copies lowering (4afda23b) passed them. fc_inv_trip and fc_inv_cbound (nr-S26) failed in both forms: a value read after the region was read in
 * place, its reverse deferred past the end. Since cq-037u2 each such value is copied out and kept, and the reverse runs inside the region.
 * fc_inv_r6cls, fc_inv_r6bnd, fc_inv_r6k and fc_inv_r6pre (nr-S28) failed in both forms (cq-8zz4v): a carried value read after the region was
 * cleaned per trip by rule 6, whose in-place clean-up the backend's reversed replay does not undo (a dirty free). Since cq-8zz4v such a value is
 * copied out like any other and its chain undone by the reverse loop inside the region.
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
/* a rotation of a register from before the region in every trip, the loop's carried value read after the region */
unsigned fc_inv_trip(unsigned x0, unsigned r0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned r = r0; cq_theta(&r, th);
  cq_invert_begin();
  while (x & 1) { x >>= 1; cq_theta(&r, th); }
  cq_invert_end();
  return cq_measure(r) + cq_measure(x);
}
/* a classically bounded loop with a quantum exit conjunct in the region (rule 14 case 1, loops-classical) */
unsigned fc_inv_cbound(unsigned x0, unsigned n, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 1;
  cq_invert_begin();
  for (unsigned i = 0; i < (n & 7) && (x & 1); i++) { s = s * 2 + x; x >>= 1; }
  cq_invert_end();
  return cq_measure(s);
}
/* cq-8zz4v: a rule-6 accumulator (bijective update) of a classically bounded loop in the region, read after it (loops-classical) */
unsigned fc_inv_r6cls(unsigned x0, unsigned n, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 1;
  cq_invert_begin();
  for (unsigned i = 0; i < (n & 7); i++) { s = s * 3 + x; x >>= 1; }
  cq_invert_end();
  return cq_measure(s);
}
/* cq-8zz4v: the same with a quantum exit conjunct (rule 14 case 1) */
unsigned fc_inv_r6bnd(unsigned x0, unsigned n, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 1;
  cq_invert_begin();
  for (unsigned i = 0; i < (n & 7) && (x & 1); i++) { s += x; x >>= 1; }
  cq_invert_end();
  return cq_measure(s);
}
/* cq-8zz4v: a rule-6 accumulator of a K-loop in the region (loops-cutoff) */
unsigned fc_inv_r6k(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 1;
  cq_invert_begin();
  while (x & 1) { s += x; x >>= 1; }
  cq_invert_end();
  return cq_measure(s);
}
/* cq-8zz4v: the K-loop's accumulator is a register rotated before the region (trip 0's old rail made outside it) */
unsigned fc_inv_r6pre(unsigned x0, unsigned y0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = y0; cq_theta(&s, th);
  cq_invert_begin();
  while (x & 1) { s ^= x; x >>= 1; }
  cq_invert_end();
  return cq_measure(s);
}
/* cq-oyirf (owner ruling 2026-11-16, CR rule 17 "A value made in the region and read after its end"; nr-S29): a loop's value read after the
 * region's end through a computation is no kept copy; the loop is uncomputed inside the region and runs again after the end (forward, read in
 * place, then its reverse), keeping no a_K of its own. Each entry failed before (a leaked copy, or a dirty free). */
/* the K-loop's exit value computed from after the region */
unsigned fc_inv_add(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned y = x;
  cq_invert_begin();
  while (y & 1) { y >>= 1; }
  cq_invert_end();
  return cq_measure(y + 3);
}
/* the K-loop's exit value read inside the region, the result after it (the guard, the selects and t run again after the end) */
unsigned fc_inv_in(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 3, t;
  cq_invert_begin();
  while (x & 1) { s = s * 5 + x; x >>= 1; }
  t = s * 7 + x;
  cq_invert_end();
  return cq_measure(t);
}
/* a classically bounded loop (loops-classical), its value read after the end with a value made after it */
unsigned fc_inv_rcls(unsigned x0, unsigned n, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned z = x0 ^ 9; cq_theta(&z, th);
  unsigned s = 1;
  cq_invert_begin();
  for (unsigned i = 0; i < (n & 7); i++) { s = s * 3 + x; x >>= 1; }
  cq_invert_end();
  return cq_measure(s + cq_measure(z));
}
/* a classically bounded loop whose value the region computes from (s + 1), the merge measured after the end: s is no rule-6 register */
unsigned fc_inv_rclsin(unsigned x0, unsigned n, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 1;
  cq_invert_begin();
  for (unsigned i = 0; i < (n & 7); i++) { s = s * 3 + x; x >>= 1; }
  cq_invert_end();
  return cq_measure(s + 1);
}
/* a do-while K-loop */
unsigned fc_inv_rdo(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 3;
  cq_invert_begin();
  do { s = s * 5 + x; x >>= 1; } while (x & 1);
  cq_invert_end();
  return cq_measure(s ^ 5);
}
/* a K-loop nested in a classically bounded loop */
unsigned fc_inv_rnest(unsigned x0, unsigned n, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned y = x;
  cq_invert_begin();
  for (unsigned i = 0; i < (n & 3); i++) { while (y & 1) { y >>= 1; } y += 3; }
  cq_invert_end();
  return cq_measure(y * 3);
}
/* the exit value read by two readers after the end */
unsigned fc_inv_rtwo(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned y = x;
  cq_invert_begin();
  while (y & 1) { y >>= 1; }
  cq_invert_end();
  return cq_measure(y + 3) + cq_measure(y * 5);
}
/* a quantum exit conjunct under a classical bound 9 > K (rule 14 case 1) */
unsigned fc_inv_rbk(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned y = x, s = 0;
  cq_invert_begin();
  for (unsigned i = 0; i < 9 && (y & 1); i++) { y >>= 1; s += 2; }
  cq_invert_end();
  return cq_measure(y - s);
}
/* a value the region computes before the loop is the loop's entry value */
unsigned fc_inv_rpre(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned y;
  cq_invert_begin();
  y = x * 3;
  while (y & 1) { y >>= 1; }
  cq_invert_end();
  return cq_measure(y + 3);
}
/* a K-loop's rule-6 accumulator read after the end through a computation */
unsigned fc_inv_rr6k(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned z = x0 ^ 9; cq_theta(&z, th);
  unsigned s = 1;
  cq_invert_begin();
  while (x & 1) { s += x; x >>= 1; }
  cq_invert_end();
  return cq_measure(s ^ cq_measure(z));
}
/* the slice case: a rotation of a register from before the region in the loop body; the repeat after the end runs only the slice y and the
 * exit test depend on (the rotation is never repeated); r crosses the end as a rotated register */
unsigned fc_inv_slrot(unsigned x0, unsigned r0, double th) {
  unsigned y = x0; cq_theta(&y, th);
  unsigned r = r0; cq_theta(&r, th);
  cq_invert_begin();
  while (y & 1) { y >>= 1; cq_theta(&r, th); }
  cq_invert_end();
  return cq_measure(r) + cq_measure(y + 3);
}
/* owner ruling 2026-11-16 (cq-oyirf follow-up, CR rule 17 with rule 5): a load in the repeated slice (an array element at a quantum index, the
 * array stored before the region) is repeated when no memory version change lies between the region's begin and the repeat; the repeated
 * load is un-copied by rule 5 after its last reader. Failed before (any load blocked the repeat: the kept copy leaked). */
unsigned fc_inv_rld(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned a[4] = {x, x ^ 5, 3, x + 1};
  unsigned y = x;
  cq_invert_begin();
  while (y & 1) { y = (y >> 2) ^ (a[y & 3] & 2); }
  cq_invert_end();
  return cq_measure(y + 3);
}
