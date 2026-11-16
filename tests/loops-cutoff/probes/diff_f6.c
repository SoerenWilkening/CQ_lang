/* tests/loops-cutoff probe (nr-S25; CR rule 14 case 2): differential family F6: K edges of a quantum-exit K-loop.
 * Each entry is checked against its C program. At d5e32f61 every entry passes with the rolled lowering and with the K-static-copies one (4afda23b).
 * Regenerate:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec diff_f6.c -o diff_f6.O1.ll */
#include "CQ.h"
CQ_K(f6_k1, 1)
CQ_K(f6_k2, 2)
CQ_K(f6_k7, 7)
CQ_K(f6_k1n, 1)
unsigned f6_k1(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 1;
  while (x & 1) { s = s * 3 + x; x >>= 1; }
  return cq_measure(s);
}
unsigned f6_k2(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 1;
  while (x & 1) { s = s * 3 + x; x >>= 1; }
  return cq_measure(s);
}
unsigned f6_k7(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 1;
  while (x & 1) { s = s * 3 + x; x >>= 1; }
  return cq_measure(s);
}
/* the default K 4 */
unsigned f6_k4(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 1;
  while (x & 1) { s = s * 3 + x; x >>= 1; }
  return cq_measure(s);
}
/* classical bound n with a quantum conjunct */
unsigned f6_bound(unsigned x0, unsigned n, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 1;
  for (unsigned i = 0; i < n && (x & 1); i++) { s = s * 3 + x; x >>= 1; }
  return cq_measure(s);
}
/* the same at K 1 */
unsigned f6_k1n(unsigned x0, unsigned n, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 1;
  for (unsigned i = 0; i < n && (x & 1); i++) { s = s * 3 + x; x >>= 1; }
  return cq_measure(s);
}
/* do-while at K 4: the first trip always runs */
unsigned f6_do(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 1;
  do { s = s * 3 + x; x >>= 1; } while (x & 1);
  return cq_measure(s);
}
/* an always-long loop (cut at K for every input) */
unsigned f6_long(unsigned x0, double th) {
  unsigned x = x0 | 0xff; cq_theta(&x, th);
  unsigned s = 1;
  while (x & 1) { s = s * 3 + x; x >>= 1; }
  return cq_measure(s);
}
