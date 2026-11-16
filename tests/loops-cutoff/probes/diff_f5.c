/* tests/loops-cutoff probe (nr-S25; CR rule 14 case 2): differential family F5: effects in the trip of a quantum-exit K-loop (single exit only; no memory with multi-exit).
 * Each entry is checked against its C program. At d5e32f61 every entry passes with the rolled lowering and with the K-static-copies one (4afda23b).
 * Regenerate:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec diff_f5.c -o diff_f5.O1.ll */
#include "CQ.h"
#include <stdio.h>
/* cq_phi per trip under the trip's predicate */
unsigned f5_phi(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  while (x & 1) { cq_phi(th); x >>= 1; }
  return cq_measure(x);
}
/* cq_phi under a quantum if inside the trip */
unsigned f5_phi_if(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  do { if (x & 4) cq_phi(th); x >>= 1; } while (x & 1);
  return cq_measure(x);
}
/* cq_theta per trip on a carried value */
unsigned f5_theta(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 1;
  while (x & 1) { s += 2; cq_theta(&s, th); x >>= 1; }
  return cq_measure(s);
}
/* cq_theta per trip on the exit-tested value */
unsigned f5_theta_x(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned n = 0;
  while (x & 1) { x >>= 1; cq_theta(&x, th); n++; }
  return cq_measure(n);
}
/* printf of a quantum value per trip */
unsigned f5_printf(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  while (x & 1) { printf("%u\n", x); x >>= 1; }
  return cq_measure(x);
}
/* a store to a local array at a classical index */
unsigned f5_store(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  volatile unsigned a[4] = {0, 0, 0, 0};
  unsigned i = 0;
  while (x & 1) { a[i & 3] = x; x >>= 1; i++; }
  return cq_measure(a[0] + a[1] + x);
}
/* a load from a constant table at a quantum index */
static const unsigned f5_tab[8] = {3, 1, 4, 1, 5, 9, 2, 6};
unsigned f5_load(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 0;
  while (x & 1) { s += f5_tab[x & 7]; x >>= 1; }
  return cq_measure(s);
}
/* a store to a global per trip (single exit) */
unsigned f5_G;
unsigned f5_gstore(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  while (x & 1) { f5_G += x; x >>= 1; }
  return cq_measure(x + f5_G);
}
/* a measurement per trip */
unsigned f5_meas(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned s = 0;
  while (x & 1) { s += cq_measure(x & 6); x >>= 1; }
  return s + cq_measure(x);
}
