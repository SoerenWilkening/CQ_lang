#include <stdio.h>
/* Rule 16: an input call behind a deferred output, its length a rail (BACKEND_ABI 1.11: performed at the call, at K2). */
int input_behind_output(unsigned n0, double tn, int x0, double tx, FILE *f) {
    unsigned n = n0;
    cq_theta(&n, tn);
    int x = x0;
    cq_theta(&x, tx);
    char buf[8] = {0};
    printf("%d\n", x);                        /* a format entry with a rail field: deferred */
    fgets(buf, n & 7, f);                     /* an effect entry: the buffer address, the length rail, the stream */
    return cq_measure(buf[0]);                /* a load of a cell the input call wrote */
}
