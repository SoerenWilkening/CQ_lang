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
/* slice_control_angle_select_rz.c — ANGLE SELECT, `cq_phi` (Rz) stem, at the
   LINK layer (bd test_C_libtooling-drbq Increment 2b; 3qlq Inc 1 lowering).

       if (q == 5) cq_phi(0.9); else cq_phi(0.3);

   `-O1` folds the two calls into ONE `cq_phi` on `select i1 %c, double 0.9,
   double 0.3`. It lowers by kickback onto the flag, exact and with no
   subtraction: f = icmp_eq(q, 5); cqrt_x(f); cqrt_rz_i1(f, 0.3); cqrt_x(f);
   cqrt_rz_i1(f, 0.9); the compare `_unc` strip; one cqrt_free(f) — P(0.9) when
   f is 1, P(0.3) when it is 0. The X pair is on the compare ANCILLA, never on a
   user register. The 2b by-difference `cqrt_rz_i32_controlled` form is retired.

   Its twin `slice_control_angle_select_rz_twin.c` keeps its own golden; the byte
   gate between the two was removed (see the note at the top). STRICT stage 2b.
   */
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
