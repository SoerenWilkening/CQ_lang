#include "CQ.h"
#include <setjmp.h>
/* Nested frames: the escaping clone is called from a clone, not from the setjmp's arm. */
static jmp_buf jb;
__attribute__((noinline)) static int inner(int q, int k) {
    if (q > k) longjmp(jb, 1);
    return q + 1;
}
__attribute__((noinline)) static int mid(int q, int k) { return inner(q, k) * 2; }
int setjmp_nested_error(int x0, double th, int k) {
    int x = x0;
    cq_theta(&x, th);
    int r;
    if (setjmp(jb) == 0) r = mid(x, k);
    else r = -1;
    return cq_measure(r);
}
