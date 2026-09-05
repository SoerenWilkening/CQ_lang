/* ⚠ REWRITTEN PROGRAM (3qlq Inc 1, OQ-3 / prep-b2): one statement ADDED —
   `q = cq_theta(q, 0.05);` immediately after each `cq_phi(0.1);`. The golden
   below is therefore a NEW PROGRAM's trace, not an audit substitution of the
   old one, and it is recorded as such in
   docs/prd/phase-04-swap-route-control/inc1-records/GOLDEN_REGEN.md.

   WHY (MEASURED, prep-b PROBE 1 + prep-b2 step 2). On the retired surface the
   trailing statement was `q = cq_phi(q, 0.1);` — an in-place gate on the
   CONDITION register, which is what made `q` loop-VARIANT. Register-free,
   `cq_phi(0.1)` reads nothing, `q` becomes loop-INVARIANT, `clang -O1` LICM-hoists
   `icmp eq i32 %q, 5` into the entry block, and `condWireDisposition`'s P4
   precondition declines the whole slice with
   `cq controlled lowering: condition predates a non-diagonal gate under quantum control`
   — on the pre-3qlq ORACLE and on the Increment-1 SUBJECT alike (both measured;
   the decline is the drbq.12 / CLAUDE.md "row W" over-decline and is not
   anything Increment 1 introduced). `cq_theta` is the only primitive that both
   READS the register and relabels its wire, so it is the replacement
   variant-maker, and it is exactly the shape the drbq Inc-3 Grover customer has.
   The uncontrolled `cq_phi(0.1)` is KEPT where it stood: under D2 it is a global
   phase and the pass deletes it, so it documents the original intent and costs
   the trace nothing (audit substitution class (c)). */
/* 3qlq Inc 1: migrated to register-free cq_phi -- `q = cq_phi(q, 0.1)` -> `cq_phi(0.1)` (the Ry arms are untouched -- Rz stem only).
   FLAG (the load-bearing one for this family): that Rz was NOT decoration. Its job
   was to keep the CONDITION register q loop-VARIANT (drbq PRD S13.1). A register-free
   cq_phi returns nothing, so q is the same SSA value on every trip, `-O1` LICM hoists
   `icmp eq q, 5` out of the loop, and condWireDisposition's P4 precondition declines
   `condition predates a non-diagonal gate` (CLAUDE.md row W / drbq.12). MEASURE this
   before assuming; if it holds, the shape needs a DIFFERENT variant-maker (an Ry,
   `q = cq_theta(q, 0.1)`) and that is a semantic change, not a migration.
   (PRD docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md S4.1, D1/D2.) */
/* slice_control_inplace_ry_loop.c — a CONTROL-IN-PLACE Ry ARM IN A ROLLED LOOP (bd
   test_C_libtooling-drbq Increment 3, PRD §13).

   SOURCE INTENT — one activation per trip:
       if (q == 5) r = cq_theta(r, 0.9);   the controlled Ry on a DISJOINT rail
       cq_phi(0.1);                 an Rz on the condition register

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
        cq_phi(0.1);
        q = cq_theta(q, 0.05);   /* OQ-3: the loop-VARIANT maker */
    }

    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
