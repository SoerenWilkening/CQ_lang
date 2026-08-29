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
       S      q = cq_theta(q, 0.5)            state preparation (before the loop)
       O      if (q == 5) q = cq_phi(q, PI)   oracle: mark |5>
       S†     q = cq_theta(q, -0.5)           un-prepare
       R0     if (q == 0) q = cq_phi(q, PI)   reflect about |0>
       S      q = cq_theta(q, 0.5)            re-prepare
       M      measure q                        (after the loop)

   WHAT `clang -O1` HANDS THE PASS, because none of it is obvious (Rule 9): a
   rotated loop with TWO header phis — the classical induction variable and the
   quantum register — and TWO sequential tainted-condition diamonds in the body,
   the second of whose merge blocks IS the latch. The `q == 0` arm arrives as
   `cq_phi(0, PI)` because clang value-propagated the register to the literal
   inside the arm (the eq-folded diamond).

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

    q = cq_theta(q, 0.5);                    /* S — before the loop */

    for (int i = 0; i < 2; ++i) {
        if (q == 5) {                        /* O  */
            q = cq_phi(q, CQ_PI);
        }
        q = cq_theta(q, -0.5);               /* S† */
        if (q == 0) {                        /* R0 */
            q = cq_phi(q, CQ_PI);
        }
        q = cq_theta(q, 0.5);                /* S  */
    }

    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
