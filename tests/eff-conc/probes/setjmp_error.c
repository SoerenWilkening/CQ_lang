#include "CQ.h"
#include <setjmp.h>
static jmp_buf jb;
static int inner(int x, int k) { if (x > k) longjmp(jb, 1); return x * x; }
int setjmp_error(int x0, double th, int k) {
    int x = x0;
    cq_theta(&x, th);
    int r;
    if (setjmp(jb) == 0) r = inner(x, k) + 2; else r = -1;
    return cq_measure(r);
}
