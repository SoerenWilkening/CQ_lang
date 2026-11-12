/* tests/bus-alloc: calloc(n, s) is the size n * s as the EXACT product (rule 16; owner 2026-11-12, cq-mrdkr).
   clang -O1 -fno-builtin -S -emit-llvm -include CQ.h of this file (with builtins LLVM folds the allocation away). */
#include <stdlib.h>

/* two rail operands, any values: K2 bytes, the kept or_i1(overflow, n * s > K2) */
int c_rails(unsigned long n0, unsigned long s0) {
    unsigned long n = n0, s = s0;
    cq_theta(&n, 0.3);
    cq_theta(&s, 0.3);
    char *p = calloc(n, s);
    return cq_measure(p != 0);
}
/* a rail count and a classical size that overflows past 2^64 / 8 */
int c_rail_count(unsigned long n0) {
    unsigned long n = n0;
    cq_theta(&n, 0.3);
    long *p = calloc(n, 8);
    return cq_measure(p != 0);
}
/* classical operands: an overflowing product is NULL, no allocation */
int c_classical(unsigned long n, unsigned long s, unsigned x0) {
    unsigned x = x0;
    cq_theta(&x, 0.3);
    char *p = calloc(n, s);
    if (!p)
        return cq_measure(x + 7);
    p[0] = 1;
    return cq_measure(x + p[0]);
}
