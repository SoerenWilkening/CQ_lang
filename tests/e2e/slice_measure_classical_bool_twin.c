/* slice_measure_classical_bool_twin.c — bd test_C_libtooling-21mg: THE WITNESS.
   `slice_measure_classical_bool.c` with `cq_measure(b1)` DELETED, and NOTHING
   ELSE changed.

   This is the program the owner's file had to be reduced to in order to compile
   on `main` e96f89c (measured 2026-09-13: 15 trace lines, STRICT stage 2b clean).
   It lowers IDENTICALLY on the ORACLE and on the 21mg binary, which is what makes
   it a witness rather than a second subject: the `compare_files` gate
   `e2e-measure-classical-bool-twin-identical` byte-diffs the two goldens, so the
   claim "the classical measure emits nothing" is measured against a trace the
   previous compiler also produced — not against a trace this change invented.

   15 = 15. A rail minted for `b1`, or a `cqrt_measure_i1` on a fresh |0> rail,
   would leave a trace that is still self-consistent, still verify-clean and still
   STRICT-2b clean (`free_pairing_check.py` sees rail PAIRING, and an extra
   left-allocated rail is not a pairing violation); the only instrument in the
   tree that can see it is this diff.

   `b1` is kept DECLARED and `(void)`-cast so the two sources differ in exactly
   one token-level respect — the measure call — rather than in the variable set. */
#include "CQ.h"

int slice(void) {
    int a = 5;
    bool b0 = 0;
    bool b1 = 0;
    (void) b1;
    if (a >= 3) {
        b0 = cq_theta(b0, 0.5);
    }
    if (b0 == 1) a -= 3;
    return cq_measure(b0) + cq_measure(a);
}

int main(void) {
    (void) slice();
    return 0;
}
