/* slice_control_phase_grover_loop.c — bd test_C_libtooling-3qlq Increment 1
   (PRD §6.5): the correct-oracle Grover of slice_control_phase_grover.c written
   as a classically-bounded `for` loop, K = 3.

   SOURCE INTENT:
       for (i = 0; i < 3; ++i) {
           q = cq_theta(q, 0.3);
           if (q == 5) cq_phi(PI);      O  — the oracle
           q = cq_theta(q, 0.3);
           if (q == 0) cq_phi(PI);      R0 — reflect about |0>
       }
       measure q

   THE POINT OF THIS SLICE IS THE TWIN. Its golden must be BYTE-IDENTICAL to
   slice_control_phase_grover_loop_unrolled.expected.log, which is the same body
   written out three times with no loop at all. Byte-identical is the strongest
   witness available to a project with no simulator (Rule 2): it says the ROLLED
   form emits the same unitary, gate for gate and handle for handle, as a stream
   with no back edge in it. The `cmp` gate is `e2e-phase-grover-loop-twin-identical`.

   WHY IT SHOULD ROLL. The 8h7d.5 in-loop path (`flatRegionRollableInLoop` +
   `collapseFlattenedLoopRails`) admits a NON-EXITING tainted PHASE region inside a
   reducible single-latch classically-bounded loop, and PRD §6.2 P6 keeps that path:
   the kickback needs no gate on `q` at all, so `collapseFlattenedLoopRails` has
   nothing to collapse for the phase region itself, and the "Rz is diagonal and
   exempt" clauses of `staleRailRecordRead` become vacuous rather than wrong. The
   condition register IS loop-variant here (the two `cq_theta`s rotate it every
   trip), which is the precondition CLAUDE.md's row W / drbq.12 records.

   EXPECTED TRACE SHAPE: 3 × (ry, mint, rz_i1, strip, free, ry, mint, rz_i1, strip,
   free). ONE copy of that stream in the LOWERED IR (K-independent), K copies in
   the TRACE. No cswap, no work rail, no `_controlled`, no `phi i32`.

   PRE-INCREMENT DISPOSITION: the ORACLE (pre-3qlq, commit 52d7764,
   $SP/wt/pre-3qlq/build/ir-pass/cq-opt) DECLINES exit 1 — `cq controlled lowering: nested control flow under quantum control`
   Measured 2026-09-05 with a `void cq_phi(double)` header. `opt` exit code and
   diagnostic are verbatim.
   Expected post-increment class: PRD §6.2 P6 (P1 inside the 8h7d.5 rolled loop). */

#define CQ_PI 3.14159265358979323846
#define CQ_K  3

int slice(void) {
    int q = 0;

    for (int i = 0; i < CQ_K; ++i) {
        q = cq_theta(q, 0.3);
        if (q == 5) cq_phi(CQ_PI);
        q = cq_theta(q, 0.3);
        if (q == 0) cq_phi(CQ_PI);
    }

    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
