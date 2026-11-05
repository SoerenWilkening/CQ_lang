#include "CQ.h"
#include <setjmp.h>
/* Rule 24: outside the one pairing setjmp and longjmp are host calls as they stand; a longjmp under a quantum
   predicate is rule 16's noreturn arm. */
__attribute__((noinline)) static void leave(jmp_buf *e, int c) {
    if (c) longjmp(*e, c);
}
/* A local buffer, a classical longjmp through a host frame, a register live across. */
int p_sjh_local(int x0, double th, int c) {
    int x = x0;
    cq_theta(&x, th);
    jmp_buf e;
    int r = setjmp(e);
    if (r == 0) leave(&e, c);
    return cq_measure(x + 1) + r;
}
/* Two setjmps on one internal global: no pairing. */
static jmp_buf twice;
int p_sjh_two(int x0, double th, int c) {
    int x = x0;
    cq_theta(&x, th);
    int a = setjmp(twice);
    if (a == 0 && c == 1) longjmp(twice, 5);
    int b = setjmp(twice);
    if (b == 0 && c == 2) longjmp(twice, 7);
    return cq_measure(x) + a + b;
}
/* A longjmp under a quantum predicate outside the pairing: abort_i1. */
int p_sjh_pred(int x0, double th, int k) {
    int x = x0;
    cq_theta(&x, th);
    jmp_buf e;
    int r = setjmp(e);
    if (r == 0) {
        if (x > k) longjmp(e, 1);
    }
    return cq_measure(x) + r;
}
