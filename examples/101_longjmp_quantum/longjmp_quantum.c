#include <setjmp.h>
static jmp_buf jb;
__attribute__((noinline)) static int inner(int q, int k) {
    if (q > k) longjmp(jb, 1);           /* non-local exit under a quantum condition */
    return q * q + 1;
}
int longjmp_quantum(int x0, double th, int k) {
    int x = x0;
    cq_theta(&x, th);
    int r;
    if (setjmp(jb) == 0)
        r = inner(x, k) + 2;             /* normal continuation */
    else
        r = -1;                          /* the escaped continuation (setjmp's second return) */
    return cq_measure(r);
}
