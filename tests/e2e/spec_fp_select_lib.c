/* spec_fp_select_lib.c — the CLASSICAL library TU for the kmdc golden. Compiles
   WITHOUT CQ.h (C18; the tripwire fails loudly if the harness force-includes it).
   `mhelper` is the canonical fabs shape: an int->int body whose fp is purely
   internal scratch — cast up, one two-arm fp select (x<0 ? -x : x), reduce back to
   i32 via the libm producer ilogb. clang -O1 -> select(icmp slt n,0, fneg x, x). */
#ifdef cq_theta
#error "C18 violation: CQ.h was -include'd into a classical lib TU (must compile without it)"
#endif

#include <math.h>

int mhelper(int n) {
    double x = (double) n;
    double a = (x < 0.0) ? -x : x;
    return ilogb(a);
}
