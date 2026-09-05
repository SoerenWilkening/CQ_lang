/* slice_control_phase_grover_loop.c — bd test_C_libtooling-3qlq Increment 1
   (PRD §6.5): the correct-oracle Grover of slice_control_phase_grover.c written
   as a classically-bounded `for` loop, K = 3.

   SOURCE INTENT:
       q = cq_theta(q, 0.3);            S  — the seed, OUTSIDE the loop
       for (i = 0; i < 3; ++i) {
           if (q == 5) cq_phi(PI);      O  — the oracle
           q = cq_theta(q, 0.3);
           if (q == 0) cq_phi(PI);      R0 — reflect about |0>
           q = cq_theta(q, 0.3);
       }
       measure q

   ⚠ THE SEED `cq_theta` IS OUTSIDE THE LOOP AND THAT IS LOAD-BEARING, NOT STYLE
   (3qlq Inc 1 prep-b2, finding F-B2-1, MEASURED on BOTH binaries). Written with
   `int q = 0;` and the first `cq_theta` INSIDE the body, `clang -O1` builds the
   header phi `%q = phi i32 [0, entry], [%rot, latch]` — a CLASSICAL constant
   merged with a tainted value — and `declineClassicalMuxes` refuses the module
   with `cq taint escape: tainted value muxed by a classical-condition phi`. The
   two-line probe `int q=0; for(i<3) q=cq_theta(q,.3); return cq_measure(q);`
   declines with that exact string on the pre-3qlq ORACLE and on the Increment-1
   SUBJECT alike, and adding one `cq_theta` before the loop makes BOTH accept. So
   it is a pre-existing, arm-class-independent property of the taint layer, not
   anything this increment introduced — and the shipped `slice_control_grover_loop.c`
   has always seeded outside the loop for the same reason.

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

    q = cq_theta(q, 0.3);                /* S — the SEED, outside the loop. */

    for (int i = 0; i < CQ_K; ++i) {
        if (q == 5) cq_phi(CQ_PI);       /* O  — the oracle           */
        q = cq_theta(q, 0.3);
        if (q == 0) cq_phi(CQ_PI);       /* R0 — reflect about |0>    */
        q = cq_theta(q, 0.3);
    }

    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
