/* tests/loops-cutoff probe (nr-S25; CR rule 14 case 2): differential family F4: where a quantum-exit K-loop sits.
 * Each entry is checked against its C program. At d5e32f61 every entry passes with the rolled lowering and with the K-static-copies one (4afda23b).
 * Regenerate:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec diff_f4.c -o diff_f4.O1.ll */
#include "CQ.h"
/* under a quantum if */
unsigned f4_qif(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 1;
  if (x & 16) { while (x & 1) { s += x; x >>= 1; } }
  return cq_measure(s + x);
}
/* under a classical if */
unsigned f4_cif(unsigned x0, unsigned c, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 1;
  if (c & 1) { while (x & 1) { s += x; x >>= 1; } }
  return cq_measure(s + x);
}
/* inside a classical for of 2 trips */
unsigned f4_cfor(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 1;
  for (int i = 0; i < 2; i++) {
    while (x & 1) { s += x; x >>= 1; }
    x = x * 3 + 1;
  }
  return cq_measure(s + x);
}
/* inside a classical for of c & 3 trips */
unsigned f4_cforn(unsigned x0, unsigned c, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 1;
  for (unsigned i = 0; i < (c & 3); i++) {
    while (x & 1) { s += x; x >>= 1; }
    x += 3;
  }
  return cq_measure(s ^ x);
}
/* after a measurement */
unsigned f4_after_meas(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned y = x * 3; cq_theta(&y, th);
  unsigned m = cq_measure(x);
  unsigned s = m;
  while (y & 1) { s += y; y >>= 1; }
  return cq_measure(s);
}
__attribute__((noinline)) static unsigned f4_g(unsigned x) {
  unsigned s = 1;
  while (x & 1) { s += x; x >>= 1; }
  return s ^ x;
}
__attribute__((noinline)) static unsigned f4_gn(unsigned x, unsigned n) {
  unsigned s = 1;
  for (unsigned i = 0; i < n && (x & 1); i++) { s += x; x >>= 1; }
  return s ^ x;
}
/* callee called once */
unsigned f4_call1(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  return cq_measure(f4_g(x));
}
/* called twice */
unsigned f4_call2(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned a = f4_g(x);
  unsigned b = f4_g(a + 1);
  return cq_measure(a * 3 + b);
}
/* called under a quantum predicate */
unsigned f4_callq(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned r = 7;
  if (x & 32) r = f4_g(x);
  return cq_measure(r);
}
/* with a classical bound argument */
unsigned f4_calln(unsigned x0, unsigned n, double th) {
  unsigned x = x0; cq_theta(&x, th);
  return cq_measure(f4_gn(x, n & 7));
}
/* through a function pointer */
unsigned (*volatile f4_fp)(unsigned) = f4_g;
unsigned f4_fptr(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned (*p)(unsigned) = f4_fp;
  return cq_measure(p(x));
}
