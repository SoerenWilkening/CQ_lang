/* tests/loops-cutoff probe (nr-S25; CR rule 14 case 2): differential family F8 (deepening): calls, recursion, flags and exit values defined under predicates (no memory with multi-exit).
 * Each entry is checked against its C program. At d5e32f61 every entry passes with the rolled lowering and with the K-static-copies one (4afda23b).
 * Regenerate:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec diff_f8.c -o diff_f8.O1.ll */
#include "CQ.h"
__attribute__((noinline)) static unsigned f8_g(unsigned x) {
  unsigned s = 1;
  while (x & 1) { s = s * 3 + x; x >>= 1; }
  return s;
}
/* a K-loop's trip calls a callee with its own K-loop */
unsigned f8_call_in(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 0;
  while (x & 2) { s += f8_g(x); x >>= 2; }
  return cq_measure(s);
}
/* quantum-depth recursion */
__attribute__((noinline)) static unsigned f8_rec(unsigned x) {
  if (!(x & 1)) return x;
  return f8_rec(x >> 1) + 3;
}
unsigned f8_recur(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  return cq_measure(f8_rec(x));
}
/* an exit value defined under a quantum if in the trip */
unsigned f8_arm_exit(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned t = 9;
  do { if (x & 4) t = x + 1; else t = x * 3; x >>= 1; } while (t & 2);
  return cq_measure(t);
}
/* a carried flag */
unsigned f8_flag(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  _Bool f = 0;
  while (x & 1) { f = !f; x >>= 1; }
  return cq_measure(f ? x : x + 100);
}
/* a carried value read only by the exit test */
unsigned f8_test_only(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned y = 1, n = 0;
  while ((x ^ y) & 3) { y = y * 2 + 1; n++; }
  return cq_measure(n);
}
/* pointer induction over a constant array with a quantum exit */
static const unsigned f8_tab[8] = {1, 3, 5, 0, 2, 4, 6, 0};
unsigned f8_ptr(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  const unsigned *p = f8_tab;
  unsigned s = 0;
  while ((*p ^ x) & 1) { s += *p; p++; }
  return cq_measure(s);
}
/* two K-loops in sequence on independent values, both read after */
unsigned f8_two_loops(unsigned x0, unsigned y0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned y = y0; cq_theta(&y, th);
  unsigned a = 0, b = 0;
  while (x & 1) { a += 2; x >>= 1; }
  while (y & 1) { b += a; y >>= 1; }
  return cq_measure(a * 7 + b + x + y);
}
/* a callee with a K-loop called inside a quantum if, its result read outside */
__attribute__((noinline)) static unsigned f8_h(unsigned x, unsigned c) {
  unsigned s = c;
  do { s = s * 5 + x; x >>= 1; } while (x & 1);
  return s;
}
unsigned f8_ctl_exit(unsigned x0, unsigned c, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned r = c;
  if (x & 64) r = f8_h(x, c);
  return cq_measure(r ^ x);
}
/* a rotation by a carried value's bit inside the trip (phase under the trip predicate and a value bit) */
unsigned f8_phi_val(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 0;
  while (x & 1) { s += x; if (s & 8) cq_phi(th); x >>= 1; }
  return cq_measure(s);
}
