/* slice_control_select_bool_loop.c — bd test_C_libtooling-r9e5 (Inc 1b-B.1): a
   LOOP-INVARIANT `_Bool` driving a data select inside a classically-bounded loop
   body. Its hand-unrolled twin is slice_control_select_bool_loop_unrolled.c and
   the two goldens are BYTE-IDENTICAL — gated by
   `e2e-select-bool-loop-twin-identical` (39 = 39 lines, measured).

   There is no select analogue of the d8jl in-loop decline (bd 9ymx, owner
   decision 2026-07-03 — conditionals in loops are allowed): a select has no CFG
   surgery, so the per-iteration stream is faithful by construction. Each
   activation mints a FRESH copy ancilla from the unchanged register, copies into
   a FRESH |0> out rail, un-copies and frees exactly that ancilla — so NOTHING
   accumulates across the back edge and the whole C-1 in-loop entangled-rail
   family (bd 7yd0) has no subject here. The register is loop-INVARIANT and is
   never freed.

   Note what the twin gate is worth and what it is not: byte identity proves the
   ROLLED form emits the same gate stream as three straight-line copies of the
   body, i.e. that nothing is dropped, shared or leaked per activation. It does
   NOT prove the unitary (Rule 2) — that is the analytic argument in
   `control_swap_select_rail_inloop_invariant.ll`. STRICT stage 2b. */
#include "CQ.h"

int main(void) {
    bool b = 0;
    cq_theta(&b, 0.5);
    int acc = 0;
    for (int i = 0; i < 3; ++i) {
        int a = b ? 2 + i : 5;
        acc += cq_measure(a);
    }
    return acc + cq_measure(b);
}
