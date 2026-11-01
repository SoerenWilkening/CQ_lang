#include "CQ.h"
#include <setjmp.h>
/* Rule 24 (101's construction): a longjmp under a quantum predicate is an escaped-flag result merged at
   the setjmp diamond. Variants: a scalar quantum result with a different arm value, a void escaping
   clone with a pure continuation after its call, a classical result (only k), a quantum escaped-arm
   value (x itself). */
static jmp_buf jb1, jb2, jb3, jb4;
__attribute__((noinline)) static int sq(int q, int k) {
    if (q > k) longjmp(jb1, 7);
    return q * q - 3;
}
int p_sj_scalar(int x0, double th, int k) {
    int x = x0;
    cq_theta(&x, th);
    int r;
    if (setjmp(jb1) == 0) r = sq(x, k) ^ 5;
    else r = 9;
    return cq_measure(r);
}
__attribute__((noinline)) static void check(int q, int k) {
    if (q < k) longjmp(jb2, 0);
}
int p_sj_void(int x0, double th, int k) {
    int x = x0;
    cq_theta(&x, th);
    int r;
    if (setjmp(jb2) == 0) { check(x, k); r = x + 1; }
    else r = 0;
    return cq_measure(r);
}
__attribute__((noinline)) static int kk(int q, int k) {
    if (q == k) longjmp(jb3, 1);
    return k + 4;
}
int p_sj_classical(int x0, double th, int k) {
    int x = x0;
    cq_theta(&x, th);
    int r;
    if (setjmp(jb3) == 0) r = kk(x, k);
    else r = -2;
    return cq_measure(r);
}
__attribute__((noinline)) static int dbl(int q, int k) {
    if ((q & 3) == k) longjmp(jb4, 1);
    return q + q;
}
int p_sj_qarm(int x0, double th, int k) {
    int x = x0;
    cq_theta(&x, th);
    int r;
    if (setjmp(jb4) != 0) r = x;
    else r = dbl(x, k) + 1;
    return cq_measure(r);
}
