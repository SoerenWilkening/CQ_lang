/* Track C probe — the owner's 2026-09-11 22:18 edit of
 * example/grover/grover_oracle_uncompute.c with the SECOND region commented
 * out, reconstructed per BRIEF_C.md §0. `b1` is declared, never assigned, and
 * measured: a CLASSICAL measure. ORACLE verdict: loud decline at that measure. */
#include "CQ.h"
int main(void) {
    int a = 5; bool b0 = 0; bool b1 = 0;
    if (a >= 3) { b0 = cq_theta(b0, 0.5); }
    if (b0 == 1) a -= 3;
    return cq_measure(b0) + cq_measure(b1) + cq_measure(a);
}
