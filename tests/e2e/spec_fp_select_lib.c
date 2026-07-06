/* spec_fp_select_lib.c — the CLASSICAL library TU for the kmdc golden. Compiles
   WITHOUT CQ.h (C18; the tripwire fails loudly if the harness force-includes it).
   `mhelper` is the canonical fabs shape: an int->int body whose fp is purely
   internal scratch — cast up, one two-arm fp select (x<0 ? -x : x), reduce back to
   i32. clang -O1 -> select(icmp slt n,0, fneg x, x). p119: the terminal reducer is
   a stock `fcmp ogt`+`zext` (was the removed libm producer ilogb) — it keeps the
   i32 return (an i64-returning lrint would trip the non-i32-return spec gate) and
   lifts the clone-fp-select identically. */
#ifdef cq_theta
#error "C18 violation: CQ.h was -include'd into a classical lib TU (must compile without it)"
#endif

int mhelper(int n) {
    double x = (double) n;
    double a = (x < 0.0) ? -x : x;
    return a > 1.0;            /* fcmp ogt a, 1.0 -> zext i1->i32 (was ilogb(a)) */
}
