/* e1 rolled — the GUARDED loop (runtime trip bound) with a TRAILING NON-DIAGONAL
 * gate on the carried register, then a measure.  CLAUDE.md §4d G-13: "an
 * accept-direction widening of a CONDITION fence owes one rolled-vs-unrolled probe
 * with a trailing non-diagonal gate on every register the condition reads."  The
 * per-trip which-path rails (`h`, `h_op`) are left allocated and entangled with
 * `acc`; a later `cq_theta` on `acc` is the bd `s82e` dephasing shape. */
#include "CQ.h"
int main(int argc, char **argv) {
    (void)argv;
    int n = argc;               /* RUNTIME trip bound -> zero-trip guard */
    int acc = 5;
    for (int i = 0; i < n; ++i) {
        bool t = 0;
        t = cq_theta(t, 0.5);
        if (t) acc = 1;
    }
    acc = cq_theta(acc, 0.9);   /* TRAILING NON-DIAGONAL GATE */
    return cq_measure(acc);
}
