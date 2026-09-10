/* slice_control_phase_bool_diamond.c — bd test_C_libtooling-3qlq.4 (Inc 1b):
   THE BARE `_Bool` CONDITION, the owner's own program as it stood on 2026-09-10
   (`example/grover/grover_oracle_uncompute.c`, HANDOFF_controlled_cascade
   wall 3): a `bool` register driving a branch phase.

   SOURCE INTENT:
       int a = 5; bool b0 = 0;
       if (a >= 3) b0 = cq_theta(b0, 0.5);   // classical guard: always taken
       if (b0 == 1) a -= 3;                  // a becomes 2 or 5 with b0
       if (a >= 3) cq_phi(0.5);              // phase on the a==5 branch
       return cq_measure(b0);

   WHAT clang -O1 HANDS THE PASS (Rule 9): `a` is the constant 5, so the first
   guard folds away, `a` is 5 | 2 exactly as b0 is 0 | 1, and the whole cascade
   collapses to `br i1 %b0` with the phase arm on the FALSE successor — the
   condition IS the register, no compare anywhere. Before this increment that
   declined `branch phase on a bare i1 condition`; with `int b0` (the twin
   beside this file) it compiled through the ordinary flag mint.

   EXPECTED TRACE (measured, the golden): alloc_i1, ry_i1(0.5), then ONE gate
   `cqrt_rz_i1(h0, -0.5)` on the register's own rail — fires on b0 == 0, in the
   diagonal form (X·P(θ)·X = e^{iθ}·P(−θ); no cqrt_x on a user register, ever) —
   then the measure. No mint, no `_unc`, no free: the rail is the user's.

   THE TWIN WITNESS is `slice_control_phase_bool_int_twin.c`: its golden is
   this one plus the three lines a compare costs (the mint `icmp_eq_i32_hl(h0,1)
   -> h1`, the `_unc` strip, `free(h1)`), with the flag `h1` where this file has
   the register `h0`, `x(h1); rz(h1, +0.5); x(h1)` where this file has
   `rz(h0, -0.5)`, and `i32` where this file has `i1`. Reduction stated, not
   mechanized (the Inc-4 state-prep precedent: a `compare_files` gate would
   assert something false). STRICT stage 2b. */
#include "CQ.h"

int main(void) {
    int a = 5;
    bool b0 = 0;
    if (a >= 3) {
        b0 = cq_theta(b0, 0.5);
    }
    if (b0 == 1) a -= 3;
    if (a >= 3) {
        cq_phi(0.5);
    }
    return cq_measure(b0);
}
