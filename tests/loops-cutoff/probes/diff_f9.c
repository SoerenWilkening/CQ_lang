/* tests/loops-cutoff probe (nr-S25; CR rule 14 case 2): differential family F9 (deepening): measurements in exit arms, measured outcomes carried, received K, several latches, noreturn arms.
 * Each entry is checked against its C program. At d5e32f61 every entry passes with the rolled lowering and with the K-static-copies one (4afda23b).
 * Regenerate:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec diff_f9.c -o diff_f9.O1.ll */
#include "CQ.h"
#include <stdint.h>
#include <stdlib.h>
/* a cq_measure in the exit arm */
unsigned f9_meas_arm(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned m = 0;
  while (1) {
    if (!(x & 1)) { m = cq_measure(x * 3); break; }
    x >>= 1;
  }
  return m;
}
/* a measured outcome carried classically */
unsigned f9_meas_carry(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned acc = 0;
  while (x & 1) { acc = acc * 2 + cq_measure(x & 2); x >>= 1; }
  return acc + cq_measure(x);
}
/* a callee's K-loop at a K the caller passes (CQ_K on the caller) */
CQ_K(f9_rk, 2)
__attribute__((noinline)) static unsigned f9_g(unsigned x) {
  unsigned s = 1;
  while (x & 1) { s = s * 3 + x; x >>= 1; }
  return s;
}
unsigned f9_rk(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 0;
  while (x & 4) { s += f9_g(x); x >>= 1; }
  return cq_measure(s);
}
/* two latches (continue in a while) */
unsigned f9_latches(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 0;
  while (x & 1) {
    x = (x >> 1) | ((x & 2) << 4);
    if (x & 8) { s += 5; continue; }
    s ^= x;
  }
  return cq_measure(s + x);
}
/* 16-bit values with a signed test */
int16_t f9_i16(int16_t x0, double th) {
  int16_t x = x0; cq_theta(&x, th);
  int16_t s = 0;
  while (x > 100) { s += 7; x = (int16_t)(x / 3); }
  return cq_measure((int16_t)(s + x));
}
/* a small struct carried through a callee's loop */
struct f9_p { unsigned a, b; };
__attribute__((noinline)) static struct f9_p f9_pair(unsigned x) {
  struct f9_p p = {1, 2};
  while (x & 1) { p.a += p.b; p.b ^= x; x >>= 1; }
  return p;
}
unsigned f9_struct(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  struct f9_p p = f9_pair(x);
  return cq_measure(p.a * 3 + p.b);
}
/* a rotation on the exit value inside the arm */
unsigned f9_rot_arm(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 4;
  while (x & 1) { s += x; x >>= 1; }
  if (x & 2) cq_theta(&s, th);
  return cq_measure(s);
}
/* an i64 index into a constant table read per trip with a quantum exit on the loaded value */
static const uint16_t f9_tab[16] = {5, 3, 0, 7, 1, 9, 2, 8, 0, 4, 6, 1, 3, 0, 2, 5};
unsigned f9_chase(unsigned x0, double th) {
  unsigned x = x0 & 15; cq_theta(&x, th);
  unsigned n = 0;
  unsigned i = x & 15;
  while (f9_tab[i]) { i = (i + f9_tab[i]) & 15; n++; }
  return cq_measure(n * 16 + i);
}
/* a for loop with a quantum test and a classical step count read after */
unsigned f9_for_n(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned i;
  for (i = 0; (x >> i) & 1; i++) ;
  return cq_measure(i);
}
