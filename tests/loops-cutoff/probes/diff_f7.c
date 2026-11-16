/* tests/loops-cutoff probe (nr-S25; CR rule 14 case 2): differential family F7 (deepening): exit arms, early returns, nesting and widths of a quantum-exit K-loop (no memory with multi-exit).
 * Each entry is checked against its C program. At d5e32f61 every entry passes with the rolled lowering and with the K-static-copies one (4afda23b).
 * Regenerate:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec diff_f7.c -o diff_f7.O1.ll */
#include "CQ.h"
#include <stdint.h>
/* a break arm that computes a value read after the loop */
unsigned f7_break(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned r = 0;
  while (x & 1) {
    if (x & 8) { r = x * 3; break; }
    x >>= 1;
  }
  return cq_measure(r + x);
}
/* an early return from the trip */
unsigned f7_ret(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 1;
  while (x & 1) {
    if (x & 4) return cq_measure(s);
    s += x; x >>= 1;
  }
  return cq_measure(s ^ 7);
}
/* continue */
unsigned f7_cont(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 0;
  do {
    x >>= 1;
    if (x & 2) continue;
    s += x;
  } while (x & 1);
  return cq_measure(s);
}
/* nested K-loops */
unsigned f7_nest(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 0;
  while (x & 1) {
    unsigned y = x;
    while (y & 2) { y >>= 2; s++; }
    x >>= 1;
  }
  return cq_measure(s + x);
}
/* an 8-bit carried value */
uint8_t f7_u8(uint8_t x0, double th) {
  uint8_t x = x0; cq_theta(&x, th);
  uint8_t s = 3;
  while (x & 1) { s = (uint8_t)(s * 5 + x); x >>= 1; }
  return cq_measure(s);
}
/* a 64-bit carried value */
uint64_t f7_u64(uint64_t x0, double th) {
  uint64_t x = x0; cq_theta(&x, th);
  uint64_t s = 3;
  while (x & 1) { s = s * 0x10001 + x; x >>= 1; }
  return cq_measure(s);
}
/* a switch in the trip */
unsigned f7_switch(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 0;
  do {
    switch (x & 3) { case 0: s += 1; break; case 1: s ^= 6; break; default: s += x; }
    x >>= 2;
  } while (x & 4);
  return cq_measure(s);
}
/* a value defined in the trip and read after the loop through the exit (LCSSA) plus a carried value */
unsigned f7_lcssa(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned t, s = 0;
  do { t = x * x + s; s += t & 3; x >>= 1; } while (t & 2);
  return cq_measure(t * 2 + s);
}
/* trip-local classical loop with a quantum update */
unsigned f7_inner_c(unsigned x0, unsigned c, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 1;
  while (x & 1) {
    for (unsigned i = 0; i < (c & 3); i++) s = s * 3 + x;
    x >>= 1;
  }
  return cq_measure(s);
}
/* a quantum-exit loop whose exit test reads the counter and a quantum value */
unsigned f7_mix(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned n = 0;
  while (n < 3 || (x & 1)) { x = x * 5 + 1; n++; }
  return cq_measure(x) + n;
}
/* the loop in a callee whose result is uncomputed (read only under a quantum if) */
__attribute__((noinline)) static unsigned f7_h(unsigned x) {
  unsigned s = 1;
  while (x & 1) { s = s * 3 + x; x >>= 1; }
  return s;
}
unsigned f7_call_unc(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned r = x;
  if (f7_h(x) & 2) r += 5;
  return cq_measure(r);
}
/* a carried double, measured */
double f7_dbl(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  double d = 1.0;
  while (x & 1) { d = d * 1.5 + 0.25; x >>= 1; }
  return cq_measure(d);
}
