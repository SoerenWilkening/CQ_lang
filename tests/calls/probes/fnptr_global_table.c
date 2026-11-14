/* tests/calls probe (cq-yrgm, CR rule 19 "Function pointers", §1.3): a function's address stored in a global table and
 * called through it with a quantum argument; the pointer is a bus load (an address rail), so the call is rule 19's dispatch
 * over the registered functions of its type (__cq_clone_count, __cq_clone_at).
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec fnptr_global_table.c -o fnptr_global_table.O1.ll */
#include "CQ.h"
__attribute__((noinline)) static int inc(int v) { return v + 1; }
__attribute__((noinline)) static int dbl(int v) { return v * 2; }
int (*volatile vtab[2])(int) = {inc, dbl};
int gt(int x0, double th, unsigned k) {
    int x = x0;
    cq_theta(&x, th);
    int r = vtab[k & 1](x);
    return cq_measure(r);
}
