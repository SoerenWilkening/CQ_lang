/* slice_control_select_bool_two_regions.c — bd test_C_libtooling-r9e5 (Inc
   1b-B.1): a 4.4 DATA SELECT and an Inc-1b PHASE KICKBACK on ONE `_Bool`
   register, in that order.

       int a = 5; bool b = (bool)0; cq_theta(&b, 0.5);
       if (b) a -= 3;        // 1b-B.1: the copy merge, on a copied flag
       int m = cq_measure(a);
       if (b) cq_phi(0.9);   // 1b:    the kickback, on the register itself

   (The `cq_measure(a)` between them is load-bearing for the SHAPE, not for the
   lowering: without it `clang -O1` SINKS the value into the phase diamond and
   hands the pass one MIXED phase+value region instead of two — measured, and
   that mixed shape is 1b-B.2's, not this one's. Rule 9.)

   THE EMISSION-ORDER TEST. Neither region leaves state on the register, so
   nothing is shared and nothing needs to be: the select's copy ancilla is
   minted, used, un-copied and freed BEFORE the kickback fires, and the kickback
   mints nothing at all (the register is its own flag there — no mint, no strip,
   no free). Exactly ONE `cqrt_free` in the trace, and the single `cqrt_rz_i1`
   is `!cq.branchphase`-recorded so the uncompute spine will not adjoint the
   user's phase (the 3qlq Inc-1 F-L7-1 class). STRICT stage 2b. */
#include "CQ.h"

int main(void) {
    int a = 5;
    bool b = 0;
    cq_theta(&b, 0.5);
    if (b) a -= 3;
    int m = cq_measure(a);
    if (b) cq_phi(0.9);
    return m + cq_measure(b);
}
