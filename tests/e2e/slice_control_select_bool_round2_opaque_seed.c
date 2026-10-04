/* slice_control_select_bool_round2_opaque_seed.c — bd test_C_libtooling-r9e5
   (Inc 1b-B.1, Rule-13 ROUND-2 finding F-B1R2-1): the OPAQUE-CLASSICAL-SEED
   accept, the second half of the discriminator pair.

       volatile bool gbit = false;
       bool x  = gbit;               // classical at round 1 AND STILL classical
       bool b  = x; cq_theta(&b, 0.5);
       bool b3 = x; cq_theta(&b3, 0.9);
       int a = b ? 2 : 5;

   Same two-sibling SHAPE as the round-2-window miscompile, with a seed nothing
   ever taints. Both thetas are then SOURCE thetas at FINAL taint too, so
   `lowerRotations` mints TWO SEPARATE registers (`h0`, `h1` in the golden, one
   `cqrt_ry_i1` each) and the select's copy flag is CNOT-copied from `h0` alone:
   the accept is CORRECT, and any fence that refused it — the review's option 3,
   "treat any non-`Constant` arg-0 as chained for closure purposes" — would be
   refusing a program with no shared rail in it.

   THE TWO MINTS ARE THE ASSERTION. With one rail there would be one
   `cqrt_alloc_i1(0)` before the flag's, and the `cqrt_cnot` would follow BOTH
   rotations. Lit twin: `control_swap_select_rail_round2_opaque_seed_accept.ll`
   (the same module in hand IR, with the exact-count prefixes). STRICT stage 2b;
   one `cqrt_free`, of the copy flag, and none of a user register. */
#include "CQ.h"

volatile bool gbit = false;

int main(void) {
    bool x = gbit;
    bool b = x; cq_theta(&b, 0.5);
    bool b3 = x; cq_theta(&b3, 0.9);
    int a = b ? 2 : 5;
    return cq_measure(a) + cq_measure(b3);
}
