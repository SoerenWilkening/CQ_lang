/* slice_control_select_bool_int_twin.c — bd test_C_libtooling-r9e5 (Inc 1b-B.1):
   the `int` spelling of slice_control_select_bool.c, byte-for-byte except the
   register type. It compiled BEFORE this increment (the ordinary compare flag
   mint) and is committed as the REDUCTION twin of the bool golden — see that
   file's header for the reduction, which is stated rather than mechanized
   because the two goldens differ by a substitution, not by equality (there is
   deliberately NO `compare_files` gate here; the Inc-4 state-prep precedent).

   The three lines a COMPARE costs and a RAIL does not: the mint
   `cq_template_icmp_eq_i32_hl(h0, 1) -> h1`, its `_unc` strip, and — in the
   bool file — the two `cqrt_cnot(h0, h1)` that replace them. Both spellings
   free exactly ONE rail and leave the register, %out and the materialized
   sources allocated. STRICT stage 2b. */
#include "CQ.h"

int main(void) {
    int a = 5;
    int b0 = 0;
    int b1 = 0;
    (void) b1;

    if (a >= 3) {
        b0 = cq_theta(b0, 0.5);
    }
    if (b0 == 1) a -= 3;

    return cq_measure(b0) + cq_measure(a);
}
