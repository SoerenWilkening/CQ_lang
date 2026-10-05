/* slice_control_phase_perbit_loop.c — bd test_C_libtooling-3qlq Increment 1
   (PRD §6.5, owner decision D4): THE REPLACEMENT FOR A DELETED CAPABILITY.

   3qlq removes the multi-bit `cqrt_rz_<W>` from the emitted set (D3: the two
   frontend concepts — per-qubit Rz and branch phase — would be redundant, and
   only the branch phase survives). The documented idiom for a register-wide Z
   rotation is therefore a CLASSICAL loop over the bits:

       for (i = 0; i < 4; ++i)
           if ((q >> i) & 1) cq_phi(0.3);

   which is exactly `Rz(0.3)` applied to each of the four low qubits, spelled in
   the language rather than in the ABI. "Rz directly on qubit i" is a BACKEND
   peephole over this fixed gate idiom; the width-only ABI cannot address a qubit
   and gets no symbol for it (Rule 15).

   THE CLAIM THIS SLICE MEASURES is D4's: the idiom lowers ROLLED, with lowered-IR
   size INDEPENDENT of K. `i` is the classical induction variable; -O1 rewrites
   `(q >> i) & 1` as `q & (1 << i)`, a tainted `and` against a classical mask
   (cq_template_and_i32_hl) tested `== 0`, and the compare is loop-VARIANT — LICM
   cannot hoist it, which is the precondition CLAUDE.md's row W records.

   GOLDEN TRACE SHAPE, per trip: and_hl -> icmp_eq_hl(.., 0) mint -> cqrt_x ->
   cqrt_rz_i1(flag, 0.3) -> cqrt_x (the arm is the `!= 0` edge) -> icmp_eq_hl_unc
   strip -> and_hl_unc -> cqrt_free(and rail), cqrt_free(flag). Four trips. No
   cswap, no work rail, no `_controlled`, and the ONLY Rz width is i1.

   Its golden must be BYTE-IDENTICAL to slice_control_phase_perbit_loop_unrolled;
   the gate is `e2e-phase-perbit-loop-twin-identical`.

   PRE-INCREMENT DISPOSITION: the ORACLE (pre-3qlq, commit 52d7764,
   $SP/wt/pre-3qlq/build/ir-pass/cq-opt) DECLINES exit 1 — `cq controlled lowering: control flow under quantum control`
   Measured 2026-09-05 with a `void cq_phi(double)` header. `opt` exit code and
   diagnostic are verbatim.
   Expected post-increment class: PRD §6.2 P6 (P1 inside the 8h7d.5 rolled loop). */

#define CQ_W 4

int slice(void) {
    int q = 0;
    cq_theta(&q, 0.5);

    for (int i = 0; i < CQ_W; ++i)
        if ((q >> i) & 1) cq_phi(0.3);

    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
