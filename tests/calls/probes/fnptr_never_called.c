/* tests/calls probe (cq-yrgm, CR rule 19, §1.3): functions whose address escapes but which nothing in the module calls: an
 * externally visible one and a static one stored in a global. Each has its registered row (_t, _t_ctl and their twins)
 * defined with no call site.
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec fnptr_never_called.c -o fnptr_never_called.O1.ll */
#include "CQ.h"
int ext_add(int a, int b) { return a + b; }
__attribute__((noinline)) static long rot(long v, double th) { long x = v; cq_theta(&x, th); return x ^ 3; }
long (*volatile esc)(long, double) = rot;
int nc(int x0, double th) {
    int x = x0;
    cq_theta(&x, th);
    return cq_measure(x + 1);
}
/* rot is called only through the pointer: its row is what the call resolves. */
long nc_esc(long v, double th) { return cq_measure(esc(v, th)); }
