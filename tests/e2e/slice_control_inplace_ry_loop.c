/* slice_control_inplace_ry_loop.c — a CONTROL-IN-PLACE Ry ARM IN A ROLLED LOOP (bd
   test_C_libtooling-drbq Increment 3, PRD §13).

   SOURCE INTENT — one activation per trip:
       if (q == 5) r = cq_theta(r, 0.9);   the controlled Ry on a DISJOINT rail
       q = cq_phi(q, 0.1);                 an Rz on the condition register

   WHY THE `cq_phi` ON `q` IS NOT DECORATION (PRD §13.1). From C the condition
   register MUST be loop-VARIANT or `clang -O1` LICM-hoists the compare into the
   preheader, `condWireDisposition`'s P4 precondition fires
   (`Cond->getParent() != R.Pred`) and BOTH sides decline `condition predates a
   non-diagonal gate` — PRD §13.2 row W, a recorded over-decline pinned by
   ir-pass/test/control_inplace_ry_reject_inloop_invariant_cond_hoisted.ll. An Rz
   is the cheapest gate that defeats the hoist, and it is DIAGONAL, so
   `condWireDisposition` still returns `None` and the P1 fence is never consulted.
   (The `Ry` reflection is the Grover customer and needs §13.4b — see
   slice_control_inplace_ry_loop_grover.c.)

   THE POINT OF THIS SLICE IS THE TWIN. Its golden must be BYTE-IDENTICAL to
   slice_control_inplace_ry_loop_unrolled.expected.log, which is the SAME body written out
   with no loop at all — the flat shape Increment 1 shipped and an adversarial
   round already cleared. Byte-identity is the strongest witness available to a
   project with no simulator (Rule 2): it says the ROLLED form emits the same
   unitary, gate for gate and handle for handle. The `cmp` is wired into ctest
   (e2e-inplace-ry-loop-twin-identical), so the two cannot drift apart silently.

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

    q = cq_theta(q, 0.5);
    r = cq_theta(r, 0.25);

    for (int i = 0; i < 2; ++i) {
        if (q == 5) {
            r = cq_theta(r, 0.9);
        }
        q = cq_phi(q, 0.1);
    }

    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
