/* tests/calls probe, ruling Q5: an input call under a quantum predicate consumes nothing on a basis input where the
   predicate reads 0; the next call reads from where the stream is on that input. */
#include <stdio.h>
int stdin_pred(signed char x0) {
    signed char x = x0;
    cq_theta(&x, 0.3);
    int c1 = 0;
    if (x & 1)
        c1 = getchar();
    int c2 = getchar();
    char buf[4] = {0};
    fread(buf, 1, 3, stdin);
    return cq_measure(c1 * 7 + c2 * 3 + buf[0] + buf[2] * 5 + x);
}
