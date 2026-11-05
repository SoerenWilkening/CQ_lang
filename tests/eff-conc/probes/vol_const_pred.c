#include "CQ.h"
/* cq-il07 (CR rule 24): a volatile read of an internal constant under a quantum predicate (musl exp10l's
   FORCE_EVAL operand `static const volatile long double twom10000`) is the plain read, unguarded: a load
   writes nothing (LLVM's mayWriteToMemory counts a volatile load). */
static const volatile long double tiny = 0x1p-10000L;
static const volatile double small = 0x1p-1000;
__attribute__((noinline)) double p_vol_const_pred(double x) {
  double y = x;
  if (x < 1.0)
    y = x + (double)(tiny * tiny) + small;
  return y;
}
double e_vol_const_pred(double a) { cq_theta(&a, 0.3); return cq_measure(p_vol_const_pred(a)); }
