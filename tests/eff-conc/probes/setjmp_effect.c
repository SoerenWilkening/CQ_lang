#include "CQ.h"
#include <setjmp.h>
/* cq-jwdf (rule 24, cq-lyzw): an effect after the longjmp's branch in the escaping callee runs under
   not-escaped (the escape is an early return of the callee). Formerly an error probe. */
static jmp_buf jb;
__attribute__((noinline)) static int inner(int q, int k) {
    if (q > k) longjmp(jb, 1);
    cq_phi(0.5);
    return q + 1;
}
int setjmp_effect_error(int x0, double th, int k) {
    int x = x0;
    cq_theta(&x, th);
    int r;
    if (setjmp(jb) == 0) r = inner(x, k);
    else r = -1;
    return cq_measure(r);
}
