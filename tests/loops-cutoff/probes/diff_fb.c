/* tests/loops-cutoff probe (nr-S25; CR rule 14 case 2): differential family FB (deepening): floating-point exit tests and fenv after a quantum-exit K-loop.
 * Each entry is checked against its C program. At d5e32f61 every entry passes with the rolled lowering and with the K-static-copies one (4afda23b).
 * Regenerate:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec diff_fb.c -o diff_fb.O1.ll */
#include "CQ.h"
#include <fenv.h>
/* an fcmp exit test on a carried double */
unsigned fb_fcmp(unsigned x0, double th) {
  unsigned x = x0 & 255; cq_theta(&x, th);
  double d = (double)x + 0.5;
  unsigned n = 0;
  while (d < 100.0) { d = d * 3.7 + 1.0; n++; }
  return cq_measure(n);
}
/* fenv flags read after the loop */
int fb_fenv(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  feclearexcept(FE_ALL_EXCEPT);
  double d = 1.0;
  while (x & 1) { d = d / 3.0; x >>= 1; }
  return cq_measure((int)(d * 1000.0)) + (fetestexcept(FE_INEXACT) ? 1 : 0) * 100000;
}
/* a float carried and measured, the exit on an int */
float fb_float(unsigned x0, double th) {
  unsigned x = x0; cq_theta(&x, th);
  float f = 2.0f;
  do { f = f * f - 1.0f; x >>= 1; } while (x & 1);
  return cq_measure(f);
}
/* an int converted from a carried double in the exit test */
unsigned fb_conv(unsigned x0, double th) {
  unsigned x = x0 & 1023; cq_theta(&x, th);
  double d = x;
  unsigned n = 0;
  while ((int)d & 1) { d = d * 0.5; n++; }
  return cq_measure(n);
}
