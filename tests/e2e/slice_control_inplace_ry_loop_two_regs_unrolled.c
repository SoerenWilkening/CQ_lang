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
/* slice_control_inplace_ry_loop_two_regs_unrolled.c — the HAND-UNROLLED TWIN of
   slice_control_inplace_ry_loop_two_regs.c (ctest
   `e2e-inplace-ry-loop-two-regs-twin-identical`). */
int slice(void) {
    int q = 0;
    int r = 7;
    int s = 9;

    q = cq_theta(q, 0.5);
    r = cq_theta(r, 0.25);
    s = cq_theta(s, 0.125);

    if (q == 5) { r = cq_theta(r, 0.9); }
    if (q == 3) { s = cq_theta(s, 0.7); }
    cq_phi(0.1);
    q = cq_theta(q, 0.05);   /* OQ-3: the loop-VARIANT maker */
    if (q == 5) { r = cq_theta(r, 0.9); }
    if (q == 3) { s = cq_theta(s, 0.7); }
    cq_phi(0.1);
    q = cq_theta(q, 0.05);   /* OQ-3: the loop-VARIANT maker */
    return cq_measure(q) + cq_measure(r) + cq_measure(s);
}
int main(void) { (void) slice(); return 0; }
