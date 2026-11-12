/* cq-du1gw (CR rule 16, 778-787; cq-rrc52): a body the module has for fesetround (musl's shape over a no-op
   __fesetround) is never lifted for the call: on both sides the call is the host's fesetround, rule 23's.
   Lowered with cq-rrc52's pass (branch nr-E2 a64a6929); the C oracle needs that pass's cq::hostCallee. */
#include <fenv.h>
#include "CQ.h"
__attribute__((noinline)) int __fesetround(int r) { (void)r; return 0; }
__attribute__((noinline)) int fesetround(int r) { if (r & ~0xc00) return -1; return __fesetround(r); }
int f(int x0, double t) {
    int x = x0;
    cq_theta(&x, t);
    return cq_measure(fesetround(x));
}
