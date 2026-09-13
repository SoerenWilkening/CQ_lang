/* Track C probe — the WITNESS twin: the owner's 22:18 file with
 * `cq_measure(b1)` dropped. Compiles on the ORACLE (15 trace lines). The
 * subject's trace for owner_2026-09-11_2218.c must be BYTE-IDENTICAL to this. */
#include "CQ.h"
int main(void) {
    int a = 5; bool b0 = 0; bool b1 = 0;
    (void)b1;
    if (a >= 3) { b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;
    return cq_measure(b0) + cq_measure(a);
}
