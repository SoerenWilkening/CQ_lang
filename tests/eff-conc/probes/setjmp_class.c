#include "CQ.h"
#include <setjmp.h>
/* cq-lyzw (rule 24 over its class): setjmp/longjmp as explicit control flow. A longjmp in the setjmp's
   own frame; three frames deep with work after each call; a quantum longjmp value read on the second
   return; a cycle through the setjmp (a retry loop); two setjmps on two jmp_bufs; a jmp_buf handed down
   by pointer; an escape from inside a loop. */
static jmp_buf j1, j2, j3, j4, j5a, j5b, j6, j7;

int p_sjc_samefn(int x0, double th, int k) {
    int x = x0;
    cq_theta(&x, th);
    int r;
    if (setjmp(j1) == 0) {
        if (x > k) longjmp(j1, 2);
        r = x + 1;
    } else {
        r = 7;
    }
    return cq_measure(r);
}

__attribute__((noinline)) static int c3(int q, int k) {
    if (q > k) longjmp(j2, 1);
    return q - k;
}
__attribute__((noinline)) static int b3(int q, int k) { return c3(q, k) * 3 + q; }
__attribute__((noinline)) static int a3(int q, int k) { return b3(q + 1, k) ^ 6; }
int p_sjc_depth3(int x0, double th, int k) {
    int x = x0;
    cq_theta(&x, th);
    int r;
    if (setjmp(j2) == 0) r = a3(x, k);
    else r = -5;
    return cq_measure(r);
}

__attribute__((noinline)) static int f3(int q, int k) {
    if (q > k) longjmp(j3, q & 3);
    return q + 2;
}
int p_sjc_value(int x0, double th, int k) {
    int x = x0;
    cq_theta(&x, th);
    int r;
    int s = setjmp(j3);
    if (s == 0) r = f3(x, k);
    else r = s * 10;
    return cq_measure(r);
}

__attribute__((noinline)) static int g4(int q, int n) {
    if (q > n) longjmp(j4, n + 1);
    return q * 2;
}
int p_sjc_retry(int x0, double th, int k) {
    int x = x0;
    cq_theta(&x, th);
    int r = -1;
    int n = setjmp(j4);
    if (n < 3) r = g4(x, n) + k;
    return cq_measure(r);
}

__attribute__((noinline)) static int h5(int q, int k) {
    if (q > k) longjmp(j5a, 1);
    if (q < -k) longjmp(j5b, 1);
    return q;
}
int p_sjc_two(int x0, double th, int k) {
    int x = x0;
    cq_theta(&x, th);
    int r;
    if (setjmp(j5a) == 0) {
        if (setjmp(j5b) == 0) r = h5(x, k);
        else r = 1;
    } else {
        r = 2;
    }
    return cq_measure(r);
}

__attribute__((noinline)) static int f6(jmp_buf *e, int q, int k) {
    if (q == k) longjmp(*e, 1);
    return q + 9;
}
int p_sjc_ptr(int x0, double th, int k) {
    int x = x0;
    cq_theta(&x, th);
    int r;
    if (setjmp(j6) == 0) r = f6(&j6, x, k);
    else r = 0;
    return cq_measure(r);
}

__attribute__((noinline)) static int f7(int q) {
    int s = 0;
    for (int i = 0; i < 4; i++) {
        if (q == i) longjmp(j7, 1);
        s += q;
    }
    return s;
}
int p_sjc_loop(int x0, double th, int k) {
    int x = x0;
    cq_theta(&x, th);
    int r;
    if (setjmp(j7) == 0) r = f7(x) + k;
    else r = 3;
    return cq_measure(r);
}
