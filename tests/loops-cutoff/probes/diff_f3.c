/* tests/loops-cutoff probe (nr-S25; CR rule 14 case 2): differential family F3: what happens after a quantum-exit K-loop.
 * Each entry is checked against its C program. At d5e32f61 every entry passes with the rolled lowering and with the K-static-copies one (4afda23b).
 * Regenerate:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec diff_f3.c -o diff_f3.O1.ll */
#include "CQ.h"
/* nothing but returning a carried value */
unsigned f3_ret(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 2;
  while (x & 1) { s = s * 5 + x; x >>= 1; }
  return s;
}
/* cq_measure of a carried value */
unsigned f3_meas(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 2;
  while (x & 1) { s = s * 5 + x; x >>= 1; }
  return cq_measure(s);
}
/* cq_measure of the counter */
unsigned f3_meas_n(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned n = 0;
  while (x & 1) { x >>= 1; n++; }
  return cq_measure(n);
}
/* a rotation on a carried value */
unsigned f3_rot(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 2;
  while (x & 1) { s = s + x; x >>= 1; }
  cq_theta(&s, th);
  return cq_measure(s);
}
/* cq_phi under a predicate on a carried value */
unsigned f3_phi(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 2;
  while (x & 1) { s = s + x; x >>= 1; }
  if (s & 4) cq_phi(th);
  return cq_measure(x);
}
/* a second K-loop reading the first one's carried value */
unsigned f3_second(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 0;
  while (x & 1) { s += 3; x >>= 1; }
  unsigned t = 0;
  while (s & 2) { s >>= 1; t += x; }
  return cq_measure(t + s);
}
/* a classical loop after it */
unsigned f3_cloop(unsigned x0, unsigned c, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 1;
  while (x & 1) { s += x; x >>= 1; }
  for (unsigned i = 0; i < (c & 3); i++) s = s * 3 + i;
  return cq_measure(s);
}
/* the exit value both measured and returned in a combination */
unsigned f3_two(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 1;
  while (x & 1) { s += x; x >>= 1; }
  unsigned m = cq_measure(s);
  return m + cq_measure(x ^ s);
}
/* a quantum if after the loop on the carried values */
unsigned f3_qif(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 1;
  while (x & 1) { s += x; x >>= 1; }
  if (s > x) s -= x; else s = x - s;
  return cq_measure(s);
}
