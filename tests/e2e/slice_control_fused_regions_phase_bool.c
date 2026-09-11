/* slice_control_fused_regions_phase_bool.c — bd test_C_libtooling-b6ap: THE
   MULTI-PHI MERGE PEEL on a BARE `_Bool` RAIL condition with a register-free
   PHASE arm — the `bool` half of the owner's shape that DOES compile with this
   increment alone (its state-prep half needs bd `l4x4`; see
   `slice_control_fused_regions_int.c`).

   SOURCE INTENT, as typed:
       int a = 5; int c = 11; bool b0 = 0;
       if (a >= 3) b0 = cq_theta(b0, 0.5);        // classical guard, always taken
       if (b0 == 1) { cq_phi(0.7); a -= 3; c -= 4; }
       return cq_measure(b0) + cq_measure(a) + cq_measure(c);

   WHAT clang -O1 HANDS THE PASS. The guard folds, `b0 == 1` on a `_Bool` becomes
   `br i1 %b0` with NO COMPARE AT ALL (the Inc-1b bare-rail condition), and the
   arm — whose only content is `call void @cq_phi(double)` — defines NOTHING. So
   the merge holds TWO phis, BOTH pure data muxes:
       %amux = phi i32 [ 2, %arm ], [ 5, %entry ]
       %cmux = phi i32 [ 7, %arm ], [ 11, %entry ]
   and `phaseAngleTail` refuses a second phi, so `classifyPhaseKickback` returns
   NotApplicable and the program declines `control flow under quantum control` on
   `main` 0c7380c.

   The peel takes BOTH: P4 peels every P1-P9-passing phi, so the merge ends
   EMPTY, which is precisely the flat-kickback shape (`classifyPhaseKickback`
   asks `MergeBB->hasNPredecessors(2)`, not for a phi).

   ⚠ TWO PHIS, NOT ONE, AND THAT IS THE CONTAINMENT GATE SHOWING (SCOPE OQ-5).
   Drop `c` and the merge holds ONE phi; the peel REFUSES it and the program
   still declines, because relaxing the gate to ">= 1 phi the region does not
   define" means deciding WHICH phi is the region's — and on a one-phi merge
   getting that wrong peels a rotation ANGLE (see the lit control
   `control_peel_angle_tail_unchanged_control.ll`). That widening is its own
   increment row.

   EXPECTED TRACE (measured, the golden — 28 lines):
       alloc_i1(0) -> h0 ; ry_i1(h0, 0.5)          the `_Bool` register
       rz_i1(h0, 0.7)                              THE BRANCH PHASE, kicked back
                                                   onto the register's OWN rail:
                                                   the register IS the condition
                                                   (Inc 1b), so the diagonal goes
                                                   straight on it — no flag, no
                                                   `cqrt_x` on a user register.
       alloc_i1(0) -> h1 ; cnot(h0, h1)            mux 1: a CNOT COPY of the rail
       alloc_i32(0) -> h2                          the |0> out rail
       alloc_i32(2) -> h3 ; copy_i32_controlled(h1, h3, h2)
       x(h1) ; alloc_i32(5) -> h4 ; copy_i32_controlled(h1, h4, h2) ; x(h1)
       cnot(h0, h1) ; free(h1)                     h1 back to |0>: proven-|0> free
       alloc_i1(0) -> h5 ; cnot(h0, h5)            mux 2: its OWN copy flag
       alloc_i32(0) -> h6
       alloc_i32(7) -> h7 ; copy_i32_controlled(h5, h7, h6)
       x(h5) ; alloc_i32(11) -> h8 ; copy_i32_controlled(h5, h8, h6) ; x(h5)
       cnot(h0, h5) ; free(h5)
       measure_i1(h0) ; measure_i32(h2) ; measure_i32(h6)

   Both `cqrt_x` brackets sit on the COPIED ANCILLAE, never on `h0` — the r9e5
   `CopyRailRoot` discipline, which the peel inherits unchanged by handing the
   select to `SelectMergeEmit` (bd memory [diagonal-only-on-user-registers-3qlq4]).
   EXACTLY TWO frees (the two copy flags); the register, both out rails and all
   four materialized sources are LEFT ALLOCATED (Rules 6/8). STRICT stage 2b.

   ⚠ NO `compare_files` GATE, deliberately (the drbq Inc-4 / r9e5 precedent):
   there is no program in the tree whose golden is provably IDENTICAL to this
   one, so a byte-identity gate would assert something false. The byte-identity
   witness for this increment lives in lit, where it is real — the fixture pair
   `control_peel_stateprep_datamux.ll` and
   `control_peel_stateprep_datamux_peeled_control.ll` lower to the same module
   and `diff` them on a RUN line. */
#include "CQ.h"

int main(void) {
    int a = 5;
    int c = 11;
    bool b0 = 0;

    if (a >= 3) {
        b0 = cq_theta(b0, 0.5);
    }
    if (b0 == 1) {
        cq_phi(0.7);
        a -= 3;
        c -= 4;
    }

    return cq_measure(b0) + cq_measure(a) + cq_measure(c);
}
