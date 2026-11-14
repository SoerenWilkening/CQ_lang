/* tests/calls probe (cq-yrgm, cq-95tw, CR rule 19): a function pointer that is an entry parameter; the host may pass any
 * function, so the call resolves at run time through __cq_clone_resolve and a null row is rule 16's host boundary (ep_host:
 * abs has no body in the module, so no row; with a quantum actual the call is an effect entry with a null name).
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec fnptr_entry_param.c -o fnptr_entry_param.O1.ll */
#include <stdlib.h>
#include "CQ.h"
__attribute__((noinline)) int sq(int v) { return v * v; }
__attribute__((noinline)) static int neg(int v) { return -v; }
__attribute__((noinline)) int ep(int (*f)(int), int x0, double th) {
    int x = x0;
    cq_theta(&x, th);
    return cq_measure(f(x));
}
int ep_drv(int x0, double th, int k) { return ep(k ? sq : neg, x0, th); }
int ep_host(int x0, double th) { return ep(abs, x0, th); }
