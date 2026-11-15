/* tests/loops-cutoff probe, cq-9kcq S6b (owner ruling Q2 of 2026-11-15, CR §0: K = 0 is legal): no trip runs, every
 * carried value keeps its entry value, a_K is the predicate of reaching trip 0 (the guard's test before the first body
 * of a while loop; the seed itself in a do-while, so a_K = 1); a table call passing K = 0; a quantum-depth recursion
 * cut at its first _ctl activation. Checked against the C program (the C oracle at the same K).
 * Regenerate:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec k_zero.c -o k_zero.O1.ll */
#include "CQ.h"
CQ_K(kz_while, 0)
CQ_K(kz_do, 0)
CQ_K(kz_tab, 0)
CQ_K(kz_rf, 0)
unsigned kz_while(unsigned x0, double th, unsigned a) {   /* body form behind its trip-0 guard (05) */
  unsigned x = x0; cq_theta(&x, th);
  unsigned n = 0;
  while (x > 9) { x = x * a + 1; n++; }
  return cq_measure(n * 64 + x);
}
unsigned kz_do(unsigned x0, double th, unsigned a) {      /* do ... while (150) */
  unsigned x = x0; cq_theta(&x, th);
  unsigned n = 0;
  do { x = x * a + 1; n += 2; } while (x > 9);
  return cq_measure(n * 64 + x);
}
__attribute__((noinline)) static unsigned kf(unsigned x, unsigned a) {
  unsigned n = 0;
  while (x > 9) { x = x * a + 1; n++; }
  return n * 64 + x;
}
unsigned (*volatile pf)(unsigned, unsigned) = kf;
unsigned kz_tab(unsigned x0, double th, unsigned a) {     /* a table clone receiving K = 0 */
  unsigned x = x0; cq_theta(&x, th);
  return cq_measure(pf(x, a));
}
__attribute__((noinline)) static unsigned kz_rf(unsigned x) { /* quantum-depth recursion */
  if (x > 9) return kz_rf(x / 3) + 1;
  return x * 16;
}
unsigned kz_rec(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  return cq_measure(kz_rf(x));
}
