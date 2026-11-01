/* tests/calls probe (cq-oocu): a pointer into the middle of an object stored into a pointer-kind cell (its fat
 * pointer's roots are interior GEPs; the clone moves it back): unimplemented. Regenerate: clang -O1 -S -emit-llvm
 * -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec ptr_cell_interior.c -o ptr_cell_interior.O1.ll */
#include "CQ.h"
#include <stdint.h>
union pl { long *p; uintptr_t v; };
__attribute__((noinline)) static void back(union pl *u) { u->v -= 8; }
int pc_interior(unsigned x0, double th, long w) {
    unsigned x = x0;
    cq_theta(&x, th);
    long a[3] = {w, 2 * w, 3}, b[3] = {5, 6, -w};
    union pl u;
    u.p = (x & 1) ? a + 2 : b + 2;
    back(&u);
    return cq_measure((int)*u.p);
}
