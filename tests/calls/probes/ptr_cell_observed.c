/* tests/calls probe (cq-oocu): a clone observing a pointer-kind cell's integer as a number (base[tag] would be
 * needed: not passed, rule 21): unimplemented. Regenerate: clang -O1 -S -emit-llvm -target
 * x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec ptr_cell_observed.c -o ptr_cell_observed.O1.ll */
#include "CQ.h"
#include <stdint.h>
union pv { int *p; uintptr_t v; };
__attribute__((noinline)) static int peek(union pv *u) { return (int)(u->v & 7); }
int pc_observed(unsigned x0, double th) {
    unsigned x = x0;
    cq_theta(&x, th);
    int a[2] = {1, 2}, b[2] = {3, 4};
    union pv u;
    u.p = (x & 1) ? a : b;
    return cq_measure(peek(&u));   /* the address observed as a number: unimplemented */
}
