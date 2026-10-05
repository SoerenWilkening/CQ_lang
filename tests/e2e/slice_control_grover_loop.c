/* 3qlq Inc 1: migrated to register-free cq_phi -- every oracle / reflection arm's `q = cq_phi(q, PI)` -> `cq_phi(PI)`.

   FINDING (PRD S1, measured 2026-09-05 at HEAD 52d7764): the PRE-3qlq golden of
   this slice encoded a CONTROLLED TENSORED Rz, which is the IDENTITY on q --
   `cqrt_rz_<W>` is "Rz on each qubit", so the marked phase is (-1)^popcount(target)
   (= +1 for |5>) and a per-qubit diagonal gate FIXES |0..0>, so the |0> reflection
   can never put -1 there. Any claim in the prose below that the oracle marks |5>,
   or that the reflection reflects about |0>, was TRUE OF THE SOURCE and FALSE OF
   THE EMITTED CIRCUIT. It becomes true only from 3qlq Inc 1 on, where the phase is
   a BRANCH phase by kickback (rz_i1 on the minted flag), not a register Rz. The
   older prose was revised on 2026-10-05 (bd 7pxe); remaining register-Rz wording is history.
   (PRD docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md S4.1, D1/D2.) */
/* slice_control_grover_loop.c — bd test_C_libtooling-8h7d.5 (Phase 7.3
   Increment 3) e2e: TWO GROVER ITERATIONS WRITTEN AS A `for` LOOP.

   THE POINT OF THIS SLICE IS THE TWIN. Its golden is BYTE-IDENTICAL to
   slice_control_grover_loop_unrolled.expected.log, which is the SAME body
   written out twice with no loop at all — the shape that has compiled since bd
   lom0 Increment 4 and was cleared then. Byte-identical is the strongest witness
   available to a project with no simulator (Rule 2): it says the rolled form
   emits the SAME UNITARY, gate for gate and handle for handle, as a stream that
   already passed an adversarial round. The `cmp` is wired into ctest (see
   e2e-grover-loop-twin-identical in tests/e2e/CMakeLists.txt), so the two cannot
   drift apart silently.

   SOURCE INTENT — one iteration per trip:
       S      cq_theta(&q, 0.5)            state preparation (before the loop)
       O      if (q == 5) cq_phi(PI)   oracle: mark |5>
       S†     cq_theta(&q, -0.5)           un-prepare
       R0     if (q == 0) cq_phi(PI)   reflect about |0>
       S      cq_theta(&q, 0.5)            re-prepare
       M      measure q                        (after the loop)

   WHAT `clang -O1` HANDS THE PASS, because none of it is obvious (Rule 9): a
   rotated loop with TWO header phis — the classical induction variable and the
   quantum register — and TWO sequential tainted-condition diamonds in the body,
   the second of whose merge blocks IS the latch. Each arm is a bare
   register-free `cq_phi(PI)` (pre-3qlq the `q == 0` arm arrived eq-folded as
   `cq_phi(0, PI)`, the register value-propagated to the literal).

   WHAT LOWERS IT. `ControlDetect::flatRegionRollableInLoop` admits both regions
   (reducible loop, one depth, single latch, no second cycle); `lowerControlRegions`
   emits them in precedence order (region 2 first — region 1's flatten erases the
   block region 2 calls `Pred`) and flattens the diamonds into the loop block;
   `collapseFlattenedLoopRails` then collapses the register's header phi to its
   root mint, which is what makes the emitted IR independent of the trip count.
   The loop stays ROLLED: ONE copy of the stream in the IR, only the trace grows.

   STRICT stage 2b (no `--allow-unproven`): every ancilla is minted, stripped and
   freed inside its own iteration, so the checker sees a matched free for each and
   the only rail left allocated is the measured register. */

#define CQ_PI 3.14159265358979323846

int slice(void) {
    int q = 0;

    cq_theta(&q, 0.5);                       /* S — before the loop */

    for (int i = 0; i < 2; ++i) {
        if (q == 5) {                        /* O  */
            cq_phi(CQ_PI);
        }
        cq_theta(&q, -0.5);                  /* S† */
        if (q == 0) {                        /* R0 */
            cq_phi(CQ_PI);
        }
        cq_theta(&q, 0.5);                   /* S  */
    }

    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
