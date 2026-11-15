/* cq-9kcq S12 (CR rules 14, 23; ROLLED_DESIGN.md §4): the quantum floating-point environment changed in the trips of a
 * quantum-exit loop and read after it: the rolled trip carries each piece it changes in a header phi over handles
 * (cq/FenvCarry.h); a loop that only reads the state carries none. Each entry is §6-checked against its C program. Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -include CQ.h kloop_state.c */
#include <fenv.h>
#pragma STDC FENV_ACCESS ON
/* A raising op in each trip: the flags accumulate across the trips. */
int ks_div(int x0, double t, double y0) {
    int x = x0;
    cq_theta(&x, t);
    double y = y0;
    feclearexcept(FE_ALL_EXCEPT);
    while (x & 1) { y = y / 3.0; x >>= 1; }
    int f = fetestexcept(FE_INEXACT);
    return cq_measure(f) + (int)cq_measure(y);
}
/* feraiseexcept in each trip. */
int ks_raise(int x0, double t) {
    int x = x0;
    cq_theta(&x, t);
    feclearexcept(FE_ALL_EXCEPT);
    int n = 0;
    while (x & 1) { feraiseexcept(FE_OVERFLOW); x >>= 1; n++; }
    return cq_measure(fetestexcept(FE_OVERFLOW)) + cq_measure(n);
}
/* fesetround with a quantum argument in each trip; the mode read after the loop. */
int ks_round(int x0, double t) {
    int x = x0;
    cq_theta(&x, t);
    fesetround(FE_TONEAREST);
    int n = 0;
    while (x & 1) { fesetround((x & 2) ? FE_UPWARD : FE_DOWNWARD); x >>= 1; n++; }
    int r = fegetround();
    fesetround(FE_TONEAREST);
    return cq_measure(r + 16 * n);
}
/* A clone carrying the environment, called in each trip. */
__attribute__((noinline)) static double ks_third(double v) { return v / 3.0; }
int ks_clone(int x0, double t, double y0) {
    int x = x0;
    cq_theta(&x, t);
    double y = y0;
    feclearexcept(FE_ALL_EXCEPT);
    while (x & 1) { y = ks_third(y + x); x >>= 1; }
    int f = fetestexcept(FE_INEXACT);
    return cq_measure(f) + (int)cq_measure(y);
}
/* The state only read in the trips (no change): the loop rolls. */
int ks_read(int x0, double t) {
    int x = x0;
    cq_theta(&x, t);
    feclearexcept(FE_ALL_EXCEPT);
    if (x & 4)
        feraiseexcept(FE_UNDERFLOW);
    int n = 0;
    while (x & 1) { x = (x >> 1) + fetestexcept(FE_UNDERFLOW); n++; }
    return cq_measure(n);
}
