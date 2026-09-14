/* FIX-round probe. The finding r14 pairs the undef SEED with the undef ANGLE at
   ONE type (f64), where `undef` is UNIQUED so both slots are the SAME Constant
   object. This probe asks whether the reviewer's recommended "same UndefValue
   object" conjunct UNDER-COVERS: seed `i1 undef` and angle `double undef` are
   TWO DIFFERENT uniqued constants, yet they are still TWO emitted gate slots
   (`cqrt_alloc_i1(i1 undef)` + `cqrt_ry_i1(h, double undef)`), so GUARD 1 fires
   on the oracle exactly as it does for r14. */
#include "CQ.h"
int f(void) {
  _Bool b;      /* undef SEED   at i1  */
  double th;    /* undef ANGLE  at f64 -- a DIFFERENT uniqued constant */
  b = cq_theta(b, th);
  return cq_measure(b);
}
