/* tests/loops-cutoff probe (nr-S25; CR rule 14 case 2): differential family F2: what the trip of a quantum-exit K-loop does to carried state.
 * Each entry is checked against its C program. At d5e32f61 every entry passes with the rolled lowering and with the K-static-copies one (4afda23b).
 * Regenerate:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec diff_f2.c -o diff_f2.O1.ll */
#include "CQ.h"
/* in-place bijective x ^= y */
unsigned f2_xor(unsigned x0, unsigned y0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned y = y0;
  do { x ^= y; y = y * 2 + 1; } while (x & 4);
  return cq_measure(x);
}
/* in-place bijective x += c */
unsigned f2_addc(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  while (x & 2) x += 7;
  return cq_measure(x);
}
/* non-bijective x = x*x */
unsigned f2_sq(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  do { x = x * x + 1; } while (x & 2);
  return cq_measure(x);
}
/* non-bijective x >>= 1 */
unsigned f2_shr(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  while (x & 1) x >>= 1;
  return cq_measure(x);
}
/* two carried values swapping */
unsigned f2_swap(unsigned x0, unsigned y0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned y = y0;
  do { unsigned t = x; x = y + 1; y = t; } while ((x ^ y) & 1);
  return cq_measure(x * 7 + y);
}
/* carried value updated in one arm of a quantum if */
unsigned f2_qarm(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 0;
  do { if (x & 2) s += x; x >>= 1; } while (x & 1);
  return cq_measure(s);
}
/* carried value updated in one arm of a classical if */
unsigned f2_carm(unsigned x0, unsigned c, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 1;
  do { if (c & 1) s = s * 3 + x; x >>= 1; } while (x & 1);
  return cq_measure(s);
}
/* a counter beside a quantum value */
unsigned f2_counter(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned n = 0;
  while (x & 1) { x = (x >> 1) + 4; n++; }
  return cq_measure(x) + cq_measure(n);
}
/* carried value with a constant initial value and a quantum update */
unsigned f2_const_init(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned a = 5, b = 9;
  while (x & 1) { a = a + b; b = b ^ x; x >>= 1; }
  return cq_measure(a - b);
}
