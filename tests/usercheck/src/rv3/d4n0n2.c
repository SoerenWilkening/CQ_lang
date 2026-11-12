/* cq-d4n0n (ruling Q5): getchar_unlocked, the POSIX function, unconditional: it reads c = '7' (0x37) and getchar
   d = ' ' (0x20) from the default stream "7 ab\n...", on both sides; the mutant gives c the stand-in's hash, which both
   sides read before the fix. */
#include <stdio.h>
#include "CQ.h"
int f(int x0, double t) {
    int x = x0;
    cq_theta(&x, t);
    int c = (getchar_unlocked)();
    int d = getchar();
    return cq_measure(x & 1) | c << 8 | d << 16;
}
