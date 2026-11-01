#include "CQ.h"
#include <setjmp.h>
/* cq-wskg (rule 24): a longjmp reached through a defined noreturn wrapper under a quantum predicate in
   the escaping clone: a loud stop, never the wrapper called unconditionally. */
static jmp_buf jb;
__attribute__((noinline)) static void jump(void) { longjmp(jb, 1); }
__attribute__((noinline)) static int inner(int q, int k) {
    if (q > k) jump();
    return q + 1;
}
int setjmp_wrapper_error(int x0, double th, int k) {
    int x = x0;
    cq_theta(&x, th);
    int r;
    if (setjmp(jb) == 0) r = inner(x, k);
    else r = -1;
    return cq_measure(r);
}
