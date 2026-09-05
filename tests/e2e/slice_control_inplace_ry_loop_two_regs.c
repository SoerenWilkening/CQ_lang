/* 3qlq Inc 1: migrated to register-free cq_phi -- `q = cq_phi(q, 0.1)` -> `cq_phi(0.1)` (the Ry arms are untouched -- Rz stem only).
   FLAG (the load-bearing one for this family): that Rz was NOT decoration. Its job
   was to keep the CONDITION register q loop-VARIANT (drbq PRD S13.1). A register-free
   cq_phi returns nothing, so q is the same SSA value on every trip, `-O1` LICM hoists
   `icmp eq q, 5` out of the loop, and condWireDisposition's P4 precondition declines
   `condition predates a non-diagonal gate` (CLAUDE.md row W / drbq.12). MEASURE this
   before assuming; if it holds, the shape needs a DIFFERENT variant-maker (an Ry,
   `q = cq_theta(q, 0.1)`) and that is a semantic change, not a migration.
   (PRD docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md S4.1, D1/D2.) */
/* slice_control_inplace_ry_loop_two_regs.c — TWO independent rotated registers, each with its own
   in-loop control-in-place Ry arm off ONE condition register.

   SOURCE INTENT — one activation per trip:
       if (q == 5) r = cq_theta(r, 0.9);
       if (q == 3) s = cq_theta(s, 0.7);
       cq_phi(0.1);

   WHAT IT PINS. `LoopLowering`'s rail-record fence groups chains PER ROOT MINT,
   and the grouping is load-bearing in BOTH directions: a gate on a DIFFERENT
   root's rail must NOT stale this one's record (else two independent registers in
   one loop are permanently unlowerable), while two chains sharing ONE root are one
   register wearing two SSA names and MUST interfere (Rule 8). Increment 3 makes
   the hoisted controlled Ry a chain MEMBER — a real gate in `collectRailGates` —
   so this is where a flattened grouping shows up first. It is also the per-WIRE
   half of the 8h7d.5 round-1 finding: ask the staleness question once for the
   function and the disposition starts depending on SOURCE ORDER.

   THE POINT OF THIS SLICE IS THE TWIN. Its golden must be BYTE-IDENTICAL to
   slice_control_inplace_ry_loop_two_regs_unrolled.expected.log, which is the SAME body written out
   with no loop at all — the flat shape Increment 1 shipped and an adversarial
   round already cleared. Byte-identity is the strongest witness available to a
   project with no simulator (Rule 2): it says the ROLLED form emits the same
   unitary, gate for gate and handle for handle. The `cmp` is wired into ctest
   (e2e-inplace-ry-loop-two-regs-twin-identical), so the two cannot drift apart silently.

   ⚠ THE MATRIX'S OWN BLIND SPOT APPLIES HERE TOO AND IS WORTH QUOTING WITH IT:
   the oracle IS the Increment-1 flat lowering, so a defect the flat and rolled
   paths SHARE (a wrong controlled-rotation polarity, a missed R4 aliasing, a
   freeze that should have fired on both sides) is byte-identical on both and this
   gate reports success. The flat side's own witnesses are the Inc-1 lit family and
   tests/e2e/slice_control_inplace_ry.c; nothing here replaces them.

   STRICT stage 2b (no `--allow-unproven`): the flag is the region's only ancilla
   and it is minted, stripped and freed inside its own iteration, so nothing dirty
   crosses the back edge. The rotated register is FROZEN by Increment 1's
   structural freeze — never reverse-played, never freed — and is left allocated,
   which is Rule 6's sanctioned fallback and is identical in the twin. */

int slice(void) {
    int q = 0;
    int r = 7;
    int s = 9;

    q = cq_theta(q, 0.5);
    r = cq_theta(r, 0.25);
    s = cq_theta(s, 0.125);

    for (int i = 0; i < 2; ++i) {
        if (q == 5) {
            r = cq_theta(r, 0.9);
        }
        if (q == 3) {
            s = cq_theta(s, 0.7);
        }
        cq_phi(0.1);
    }

    return cq_measure(q) + cq_measure(r) + cq_measure(s);
}
int main(void) { (void) slice(); return 0; }
