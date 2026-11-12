/* cq-d4n0n (ruling Q5): getchar_unlocked, the POSIX function (parenthesized: not the macOS macro), is an INPUT call with
   getchar's model: under a quantum predicate it consumes one byte of the input stream where the predicate reads 1, and
   getchar then reads the next. Default stream "7 ab\n...": c = 0x37 on odd x, d = 0x20 there, 0x37 elsewhere. */
#include <stdio.h>
#include "CQ.h"
int f(int x0, double t) {
    int x = x0;
    cq_theta(&x, t);
    int c = -7, d = -9;
    if (x & 1)
        c = (getchar_unlocked)();
    d = getchar();
    cq_measure(c);
    return cq_measure(d);
}
