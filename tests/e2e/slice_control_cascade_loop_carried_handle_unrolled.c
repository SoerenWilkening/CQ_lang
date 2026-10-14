/* slice_control_cascade_loop_carried_handle_unrolled.c — bd
 * `test_C_libtooling-zujr`, THE HAND-UNROLLED TWIN of
 * `slice_control_cascade_loop_carried_handle.c`, registered so the DIVERGENCE is
 * a committed fact rather than a claim in a header.
 *
 * ⚠ IT IS 55 LINES WHERE THE ROLLED FORM IS 50 (re-measured 2026-10-15 after bd
 * r2j3.32; it was 45 vs 50 before). `clang -O1` cannot fold anything in the
 * rolled form (it stamps `llvm.loop.unroll.disable` and does not peel), and
 * folds three things here, while bd r2j3.32 adds two merge-rail reversals here
 * that the rolled form cannot make:
 *
 *   -1  the rolled form's PREHEADER `cqrt_alloc_i32(5)` — the trip-1 promotion.
 *       Here `a = 5` is a literal at every use, so the same register is
 *       materialised INSIDE the trip-1 mux instead (`cqrt_alloc_i32(5) -> h4`,
 *       golden line 9) and costs no separate line.
 *   -2  TRIP 1's compare.  `a = 5` makes `a >= 3` constant TRUE, so this form
 *       emits the unconditional `cqrt_ry_i1(h0, .5)` where the rolled form emits
 *       `icmp -> alloc -> ry_controlled -> icmp_unc -> free`.  SAME UNITARY: a
 *       control that is |1> deterministically is no control.
 *   -2  TRIP 2's compare.  `a` is 5 or 2, so `a >= 3` folds to `!b0[0]`, which
 *       `-O1` spells by ADDITIVITY (`ry(h5,.5); ry_controlled(h0,h5,-.5)` — fire
 *       Ry(.5) when `h0 == 0`) instead of minting a compare flag.
 *   +10 bd r2j3.32: the trip-1 and trip-2 `a`-mux rails `h2` and `h8` are each
 *       read only by the NEXT trip's merge (as its copy source) and its compare,
 *       so both are REVERSED after the trip-3 core, LIFO (`h8` first, golden
 *       lines 36-42; then `h2`, lines 43-49): each merge's two copies re-applied
 *       under its still-live flag, the flag's deferred strip, the rail freed.
 *       Each trip-k merge's strip moves with it.
 *
 * TRIP 3 is gate-for-gate the rolled form's general trip up to its core (golden
 * lines 28-35 here against the rolled form's last trip).
 *
 * ⚠ LEAK PARITY NO LONGER HOLDS, measured from the goldens (live at exit, never
 * freed nor measured):
 *   here    4 — the classical selects' constant loads `h3` (= 2) and `h4`
 *               (= 5), and the hoisted chain rails `h6` and `h11`;
 *   rolled  6 — the promoted seed `h0` (= 5), the chain rails `h3`, `h8`,
 *               `h13`, and the trip-1/trip-2 `a`-mux rails `h5` and `h10`.
 * `h5`/`h10` are ENTANGLED records of `b0[0]`/`b0[1]` that this twin reverses.
 * The rolled form cannot reverse them per trip: `a`-mux k is read by trip k+1's
 * merge, whose own reversal needs `a`-mux k-1 still live — the reversal is LIFO
 * ACROSS trips, i.e. a reverse loop after the forward one, which the compiler
 * does not emit yet. Until it does, the rolled form IS worse than its twin by
 * two entangled rails, and the premise `declineUnmarkedRolledIterLocal`'s
 * conjunct 2 rests on (the R7-loop grant) is FALSE for this shape — conjunct 2
 * does not see it, because a merge rail is not a spine discharge candidate.
 * Before bd r2j3.32 both forms leaked six (here 2 template + 4 alloc, the four
 * including `h2` and `h8`; there 3 + 3).
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
