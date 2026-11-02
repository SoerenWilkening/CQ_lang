/* Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../CQ_spec calls.c -o calls.O1.ll.
 * tests/loops-classical probes (cq-mgkr): rule 18 calls in a classically bounded trip (rule 14 case 1): a clone call
 * with a quantum result undone in its own trip, libm intrinsics, and a carried value made by the call (its twin in
 * the reverse loop). */
#include "CQ.h"
__attribute__((noinline)) unsigned lc_f(unsigned v) { return v * v + 3u; }
unsigned lc_call(unsigned x0, double th, int n) {
    unsigned x = x0;
    cq_theta(&x, th);
    unsigned acc = 0;
    for (int i = 0; i < n; i++) acc += lc_f(x + (unsigned)i);
    return cq_measure(acc);
}
double lc_libm(double x0, double th, int n) {
    double x = x0;
    cq_theta(&x, th);
    double acc = 0;
    for (int i = 0; i < n; i++) acc += __builtin_fabs(x - i) + __builtin_sqrt(x * x + i);
    return cq_measure(acc);
}
unsigned lc_chain(unsigned x0, double th, int n) {
    unsigned x = x0;
    cq_theta(&x, th);
    unsigned a = x;
    for (int i = 0; i < n; i++) a = lc_f(a) ^ (unsigned)i;
    return cq_measure(a);
}
