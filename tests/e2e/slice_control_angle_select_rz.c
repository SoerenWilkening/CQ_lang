/* ⚠ THE `cmp` TWIN GATE FOR THIS PAIR WAS REMOVED 2026-09-05 (3qlq Inc 1,
   prep-b2). `slice_control_angle_select_rz_twin.c` is still committed and still
   has its own golden, but the two goldens are NOT byte-identical any more and
   MUST NOT be: the twin's leading `cq_phi(0.3)` is UNCONTROLLED, i.e. a GLOBAL
   PHASE, and owner decision D2 DELETES it. MEASURED, the whole relation:
       this slice   cqrt_x(f); cqrt_rz_i1(f, 0x1.3333333333333p-2);   P(0.3) on !f
                    cqrt_x(f); cqrt_rz_i1(f, 0x1.ccccccccccccdp-1)    P(0.9) on  f
       the twin                cqrt_rz_i1(f, 0x1.3333333333334p-1)    P(fl(.9-.3)) on f
   Same state up to the factor e^{i0.3}. The twin's single angle is `fl(A - B)` of
   this slice's two, which a reviewer can check by hand from the two committed
   files — that IS the relation, and a byte gate would instead have asserted that
   a deleted global phase is observable. See PRD §10.2 substitution (d), and
   prep-d's OQ-15 (no byte-identity twin exists for this stem at all: the obvious
   candidate `if (q==5) cq_phi(A); if (q!=5) cq_phi(B);` is BYTE-IDENTICAL at -O1
   to the if/else, so it is the same module). */
/* 3qlq Inc 1: migrated to register-free cq_phi -- the if/else arms lose their register (P2 angle select).
   NOTE: PRD S3 retires the 2b BY-DIFFERENCE lowering for the Rz stem -- the new form
   is `x(f); rz_i1(f,B); x(f); rz_i1(f,A)`, exact, no subtraction and no 2^-40 fence.
   (PRD docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md S4.1, D1/D2.) */
/* slice_control_angle_select_rz.c — ANGLE-SELECT BY DIFFERENCE, `cq_phi` (Rz)
   stem, at the LINK layer (bd test_C_libtooling-drbq Increment 2b).

       if (q == 5) cq_phi(0.9); else cq_phi(0.3);

   The by-difference identity holds for Rz too, and EXACTLY rather than up to a
   phase: under this project's `Rz = diag(1, e^{i.theta})` convention the two
   diagonals multiply entrywise, so `Rz(0.3)·Rz(0.6) = Rz(0.9)` with no
   global-phase residue. The emitted gate is the drbq Increment-2a in-place
   `cqrt_rz_i32_controlled`, so this stem adds no frozen symbol and reuses the
   2a peephole's machinery unchanged.

   Its twin `slice_control_angle_select_rz_twin.c` is an in-place Rz DIAMOND,
   which the PRE-2b binary lowered via the 2a peephole;
   `e2e-angle-select-rz-twin-identical` compares the goldens. STRICT stage 2b. */
int slice(void) {
    int q = 3;
    int r = 7;
    cq_theta(&q, 0.5);
    cq_theta(&r, 0.25);
    if (q == 5) cq_phi(0.9);
    else        cq_phi(0.3);
    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
