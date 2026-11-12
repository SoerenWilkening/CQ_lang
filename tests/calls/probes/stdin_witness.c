/* tests/calls probe, ruling Q5 (DECISIONS 2026-11-11): the witness of the stdin question. Under a §6 comparison both sides
   read one finite input stream with state (checker/rt/fx_standin.h), so a loop until end of file ends, on both sides. */
#include <stdio.h>
int count_then_rotate(double th) {
    int n = 0, c;
    while ((c = getchar()) != EOF) n += (c == 'a');   /* must end */
    int x = n; cq_theta(&x, th);
    return cq_measure(x);
}
