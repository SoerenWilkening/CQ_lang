/* slice_control_select_bool_sdagger.c — bd test_C_libtooling-r9e5 (Inc 1b-B.1):
   THE DT PRONG, as the owner's Grover cascade writes it — a data select on the
   register, then the S† `cq_theta(b, -0.5)` on that SAME register.

       int a = 5; bool b = cq_theta((bool)0, 0.5);
       if (b) a -= 3;            // select i1 %b, i32 2, i32 5
       b = cq_theta(b, -0.5);    // S† on the condition's own wire

   ON `main` 87d0699 THIS DECLINED `condition predates a non-diagonal gate`
   (probe `k3`): gate 2c's wire walk was POSITION-FREE for every seed, so a theta
   anywhere on the condition's wire refused the region — even one that runs
   strictly after the flag was minted, used, stripped and freed. It is the exact
   over-decline bd `lom0` Inc 4 removed for the flat PHASE region, arriving one
   construct later.

   Rung 3 of the rail ladder now asks a RAIL's seeds with the DT prong
   (`railCondWireDisposition`'s spelling, with the SELECT as the emit point):
   position-free clean accepts; otherwise the walk is re-asked at the select and
   a gate PROVEN to execute after every execution of it is `ProvenPostRegion`.
   The P1 argument carries: the copies read `b`'s basis label AT the select, the
   flag is minted, stripped and freed inside the stream, and nothing of the
   region survives on `b` for the S† to invalidate.

   ORDER IS THE ASSERTION in the golden: the whole merge and its `cqrt_free`,
   and only THEN `cqrt_ry_i1(h0, -0.5)`. A theta the prong cannot so prove keeps
   declining — `control_swap_reject_select_rail_stale_{chained_between,
   sibling_theta}.ll` and `..._inloop_stale_theta.ll`. STRICT stage 2b. */
#include "CQ.h"

int main(void) {
    int a = 5;
    bool b = 0;
    b = cq_theta(b, 0.5);
    if (b) a -= 3;
    b = cq_theta(b, -0.5);
    return cq_measure(b) + cq_measure(a);
}
