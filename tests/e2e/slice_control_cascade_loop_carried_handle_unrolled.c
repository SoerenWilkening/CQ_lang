/* slice_control_cascade_loop_carried_handle_unrolled.c — bd
 * `test_C_libtooling-zujr`, THE HAND-UNROLLED TWIN of
 * `slice_control_cascade_loop_carried_handle.c`, registered so the DIVERGENCE is
 * a committed fact rather than a claim in a header.
 *
 * ⚠ IT IS 45 LINES WHERE THE ROLLED FORM IS 50, AND THE FIVE ARE ACCOUNTED FOR
 * ONE BY ONE — this is the owner's ruling (2) of 2026-09-17 in its measured
 * form.  `clang -O1` cannot fold anything in the rolled form (it stamps
 * `llvm.loop.unroll.disable` and does not peel), and folds three things here:
 *
 *   +1  the rolled form's PREHEADER `cqrt_alloc_i32(5)` — the trip-1 promotion.
 *       Here `a = 5` is a literal at every use, so the same register is
 *       materialised INSIDE the trip-1 mux instead (`cqrt_alloc_i32(5) -> h4`,
 *       golden line 9) and costs no separate line.
 *   +2  TRIP 1's compare.  `a = 5` makes `a >= 3` constant TRUE, so this form
 *       emits the unconditional `cqrt_ry_i1(h0, .5)` where the rolled form emits
 *       `icmp -> alloc -> ry_controlled -> icmp_unc -> free`.  SAME UNITARY: a
 *       control that is |1> deterministically is no control.
 *   +2  TRIP 2's compare.  `a` is 5 or 2, so `a >= 3` folds to `!b0[0]`, which
 *       `-O1` spells by ADDITIVITY (`ry(h5,.5); ry_controlled(h0,h5,-.5)` — fire
 *       Ry(.5) when `h0 == 0`) instead of minting a compare flag.
 *   0   TRIP 3 is IDENTICAL in both forms, gate for gate: golden lines 27-41
 *       here against 32-46 there.  That is the per-trip witness — the rolled
 *       form's stream IS the general trip, and the flat form only differs where
 *       `-O1` had a constant to fold.
 *
 * LEAK PARITY, measured and not asserted: SIX undischarged rails in each form.
 * Here 2 template (`h6`, `h11`) + 4 alloc (`h2`, `h3`, `h4`, `h8`); there 3 + 3.
 * The rolled form is therefore NOT worse than its twin, which is the claim
 * `declineUnmarkedRolledIterLocal`'s conjunct 2 exists to protect and the reason
 * the R7-loop grant here is sound.
 */
#include "CQ.h"

int main(void) {
    int a = 5;
    bool b0[3];

    if (a >= 3) { cq_theta(&b0[0], 0.5); }
    if (b0[0]) a -= 3;
    if (a >= 3) { cq_theta(&b0[1], 0.5); }
    if (b0[1]) a -= 3;
    if (a >= 3) { cq_theta(&b0[2], 0.5); }
    if (b0[2]) a -= 3;

    return cq_measure(b0[0]) + cq_measure(b0[1]) + cq_measure(b0[2]) + cq_measure(a);
}
