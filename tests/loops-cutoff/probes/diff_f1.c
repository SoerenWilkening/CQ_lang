/* tests/loops-cutoff probe (nr-S25; CR rule 14 case 2): differential family F1: exit test kinds of a quantum-exit K-loop (CR rule 14 case 2).
 * Each entry is checked against its C program. At d5e32f61 every entry passes with the rolled lowering and with the K-static-copies one (4afda23b).
 * Regenerate:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec diff_f1.c -o diff_f1.O1.ll */
#include "CQ.h"
/* while on a carried value */
unsigned f1_while(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned n = 0;
  while (x & 1) { x >>= 1; n += 3; }
  return cq_measure(x + n);
}
/* do-while on a carried value */
unsigned f1_do(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  do { x = (x >> 1) ^ 5; } while (x & 2);
  return cq_measure(x);
}
/* for with a quantum test on the induction-like carried value */
unsigned f1_for(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 0;
  for (unsigned v = x; v > 3; v >>= 2) s += v;
  return cq_measure(s);
}
/* test on a value computed in the trip */
unsigned f1_comp(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned t;
  do { t = x * 3 + 1; x >>= 1; } while (t & 4);
  return cq_measure(x);
}
/* test on a loaded value (constant table at a quantum index) */
static const unsigned char f1_tab[8] = {1, 1, 0, 1, 0, 0, 1, 0};
unsigned f1_load(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned n = 0;
  while (f1_tab[x & 7]) { x += 3; n++; }
  return cq_measure(n);
}
/* compound a && b, one classical conjunct (c bounds the count) */
unsigned f1_and(unsigned x0, unsigned c, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned i = 0;
  while (i < c && (x & 1)) { x >>= 1; i++; }
  return cq_measure(x ^ i);
}
/* compound with the quantum conjunct first */
unsigned f1_and2(unsigned x0, unsigned c, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned i = 0;
  while ((x & 1) && i != c) { x >>= 1; i++; }
  return cq_measure(x + i);
}
/* comparison of two carried values */
unsigned f1_cmp2(unsigned x0, unsigned y0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned y = y0 & 15;
  while (x < y) { x += 2; y -= 1; }
  return cq_measure(x * 16 + y);
}
/* compound a || b, both quantum */
unsigned f1_or(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned n = 0;
  while ((x & 1) || (x & 8)) { x >>= 1; n++; }
  return cq_measure(n);
}
