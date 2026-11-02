/* tests/calls probe (cq-ro82, CR rules 14, 19, 27): calls inside a rule-14 trip run under the trip rail. A
 * declared clone (rule 27: erf, cbrt have no body here) reached in a K-loop trip or a case-3 trip is its _ctl
 * form with the trip flag (conjoined with the block's quantum part) as pred; a lifted callee with a gate
 * (rule 19: a phase) is its _ctl clone with the same flag; a lifted pure callee is called unguarded;
 * a host effect is a tape entry under the trip rail. Regenerate: clang -O1 -S -emit-llvm -target
 * (An entry returns an integer: cq-xacd.) x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec trip_ctl.c -o trip_ctl.O1.ll */
#include "CQ.h"
int printf(const char *, ...);
double erf(double);
double cbrt(double);
__attribute__((noinline)) void tc_phase(unsigned v) {
    if (v & 1u) cq_phi(0.7);
}
__attribute__((noinline)) unsigned tc_mix(unsigned v) { return v * 5u + 1u; }
/* K-loop (rule 14 cutoff), the call in the latch block: the block's own quantum predicate is top. */
long tk_decl(double x0, double th) {
    double x = x0;
    cq_theta(&x, th);
    double s = 0;
    do {
        s += erf(x);
        x = x * 0.5;
    } while (x > 1.0);
    return (long)(cq_measure(s) * 1024.0);
}
/* K-loop, the call in an arm of the trip (its quantum part conjoined with the trip rail). */
long tk_decl_arm(double x0, double th) {
    double x = x0;
    cq_theta(&x, th);
    double s = 0;
    do {
        if (x > 3.0) s += cbrt(x);
        x = x * 0.5;
    } while (x > 1.0);
    return (long)(cq_measure(s) * 1024.0);
}
/* K-loop, a lifted clone with a gate (a phase) and a pure one. */
unsigned tk_lift(unsigned x0, double th) {
    unsigned x = x0;
    cq_theta(&x, th);
    unsigned y = 0;
    do {
        y += tc_mix(x & 7u);
        tc_phase(x);
        x >>= 1;
    } while (x != 0);
    return cq_measure(y);
}
/* K-loop, a host effect of a quantum value (rule 16: a tape entry under the trip rail). */
unsigned tk_print(unsigned x0, double th) {
    unsigned x = x0;
    cq_theta(&x, th);
    do {
        printf("%u\n", x & 3u);
        x >>= 1;
    } while (x != 0);
    return cq_measure(x);
}
/* Case 3 (classical bound, quantum exit): a declared clone and lifted clones in the trip. */
long t3_decl(double x0, double th, int n) {
    double x = x0;
    cq_theta(&x, th);
    double s = 0;
    for (int i = 0; i < n && x > 1.0; i++) {
        s += erf(x);
        x = x * 0.5;
    }
    return (long)(cq_measure(s) * 1024.0);
}
unsigned t3_lift(unsigned x0, double th, int n) {
    unsigned x = x0;
    cq_theta(&x, th);
    unsigned y = 0;
    for (int i = 0; i < n && x != 0; i++) {
        y += tc_mix(x & 7u);
        tc_phase(x);
        x >>= 1;
    }
    return cq_measure(y);
}
/* Case 3 multi-exit: a declared clone and a lifted clone with a gate in the exit arm (under the arm's flag). */
long t3_arm(double x0, double th, int n) {
    double x = x0;
    cq_theta(&x, th);
    double r = -1.0;
    for (int i = 0; i < n; i++) {
        if (x < 2.0) {
            tc_phase((unsigned)i);
            r = erf(x) + i;
            break;
        }
        x = x * 0.5;
    }
    return (long)(cq_measure(r) * 1024.0);
}
/* Case 1 (classical bound, quantum body): a declared clone per trip, undone by the reverse loop. */
long t1_decl(double x0, double th, int n) {
    double x = x0;
    cq_theta(&x, th);
    double s = 0;
    for (int i = 0; i < n; i++) s += erf(x + i);
    return (long)(cq_measure(s) * 1024.0);
}
