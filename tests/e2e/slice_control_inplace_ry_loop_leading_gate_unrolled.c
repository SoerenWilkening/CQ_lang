/* 3qlq Inc 1: migrated to register-free cq_phi -- `q = cq_phi(q, 0.1)` -> `cq_phi(0.1)` (the Ry arms are untouched -- Rz stem only).
   FLAG (the load-bearing one for this family): that Rz was NOT decoration. Its job
   was to keep the CONDITION register q loop-VARIANT (drbq PRD S13.1). A register-free
   cq_phi returns nothing, so q is the same SSA value on every trip, `-O1` LICM hoists
   `icmp eq q, 5` out of the loop, and condWireDisposition's P4 precondition declines
   `condition predates a non-diagonal gate` (CLAUDE.md row W / drbq.12). MEASURE this
   before assuming; if it holds, the shape needs a DIFFERENT variant-maker (an Ry,
   `q = cq_theta(q, 0.1)`) and that is a semantic change, not a migration.
   (PRD docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md S4.1, D1/D2.) */
/* slice_control_inplace_ry_loop_leading_gate_unrolled.c — the HAND-UNROLLED TWIN
   of slice_control_inplace_ry_loop_leading_gate.c (ctest
   `e2e-inplace-ry-loop-leading-gate-twin-identical`). */
int slice(void) {
    int q = 0;
    int r = 7;

    q = cq_theta(q, 0.5);
    r = cq_theta(r, 0.25);

    r = cq_theta(r, 0.25);
    if (q == 5) { r = cq_theta(r, 0.9); }
    cq_phi(0.1);

    r = cq_theta(r, 0.25);
    if (q == 5) { r = cq_theta(r, 0.9); }
    cq_phi(0.1);

    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
