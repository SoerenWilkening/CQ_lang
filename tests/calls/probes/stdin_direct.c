/* tests/calls probe, ruling Q5 (cq-cyjua second half): qpart's getchar under a quantum predicate moves the one stream on
   some basis inputs only; the fgets after it then reads bytes that depend on the quantum inputs. cq-lower makes that
   fgets a tape entry; stdin_direct.direct.ll is the same lowering with it a direct host call (fx_call.h on the lowered
   side), which must be §6-equal too: both paths share the one stream's state, and the direct call's stores go to the bus
   as quantum stores once the position depends on the quantum inputs. */
#include <stdio.h>
__attribute__((noinline)) int qpart(signed char x0) {
    signed char x = x0;
    cq_theta(&x, 0.3);
    int c = 0;
    if (x & 1) c = getchar();
    return cq_measure(c + x);
}
int stdin_direct(signed char x0) {
    int m = qpart(x0);
    char b[8] = {0};
    int ok = fgets(b, 4, stdin) != 0;
    return m + ok * 3 + b[0] * 5 + b[1] * 7;
}
