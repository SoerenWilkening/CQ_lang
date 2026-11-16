/* tests/loops-cutoff probe (nr-S27, cq-mysin; CR rules 14, 23): a nested quantum-exit K-loop whose trips change the quantum
 * floating-point environment, in a clone called under a quantum predicate (musl printf_core's format scan inside its
 * conversion loop, the flags of fmt_fp). The clone's K-loops run the K its caller passes, so each has a zero-trip guard and
 * the inner loop's exit block X merges the environment over two edges. The inner loop's carried piece takes its latch value
 * at the end of the trip, never X's merge (before cq-mysin: X's merge, read through the outer header, the previous outer
 * trip's rail, poison in outer trip 0: a bad handle).
 * Regenerate:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec nest_fenv.c -o nest_fenv.O1.ll */
#include "CQ.h"
#include <fenv.h>
#pragma STDC FENV_ACCESS ON
__attribute__((noinline)) static double scan(unsigned x) {
  double d = 1.0;
  while (x & 1) {
    unsigned y = x;
    while (y & 2) { d = d / 3.0; y >>= 2; }
    x >>= 1;
  }
  return d;
}
/* the nested loops in scan's _ctl clone; the environment is read after the call */
int nf_ctl(unsigned x0, double th) {
  unsigned x = x0 & 255; cq_theta(&x, th);
  feclearexcept(FE_ALL_EXCEPT);
  double d = 2.0;
  if (x & 128)
    d = scan(x);
  return cq_measure((int)(d * 1000.0)) + (fetestexcept(FE_INEXACT) ? 1 : 0) * 100000;
}
