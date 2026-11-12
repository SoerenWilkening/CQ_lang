/* tests/calls probe, ruling Q5: two input calls in sequence on one stream; the second reads the bytes after the first.
   The second's length is a rail (x & 7): it consumes for the length's value on each basis input. */
#include <stdio.h>
int stdin_seq(signed char x0) {
    signed char x = x0;
    cq_theta(&x, 0.3);
    char a[8] = {0}, b[8] = {0};
    fgets(a, 4, stdin);
    fgets(b, (x & 7) + 1, stdin);
    int c = getchar();
    return cq_measure(a[0] + a[2] * 3 + b[0] * 5 + b[1] * 7 + b[3] * 11 + c * 13 + x);
}
