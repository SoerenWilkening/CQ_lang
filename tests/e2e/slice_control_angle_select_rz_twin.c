/* ⚠ NO LONGER A BYTE-IDENTITY TWIN, and the `cmp` gate that claimed it was
   REMOVED 2026-09-05 (3qlq Inc 1, prep-b2). This program's leading `cq_phi(0.3)`
   is UNCONTROLLED — a GLOBAL PHASE — and owner decision D2 deletes it, so this
   golden holds ONE `cqrt_rz_i1(f, fl(0.9 - 0.3))` where
   `slice_control_angle_select_rz.expected.log` holds the four-line
   `x(f); rz_i1(f, 0.3); x(f); rz_i1(f, 0.9)`. The two are the same state up to
   e^{i0.3}. The slice is KEPT because it is a real customer in its own right —
   a D2 global-phase deletion sitting beside a kickback on the SAME compare (P7 +
   P1 in one module) — and because the `fl(A - B)` relation between the two
   committed goldens is hand-checkable. It is NOT evidence of byte identity and
   must not be quoted as such. */
/* 3qlq Inc 1: migrated to register-free cq_phi -- the unconditional and the conditional gate lose their register.
   NOTE: the twin RELATION survives the surface change. `cq_phi(0.3)` unconditional is
   now a GLOBAL phase and is DELETED (D2); what remains is `e^{i*0.6}` on the q==5
   branch, which equals the subject's {e^{i*0.9} on true, e^{i*0.3} on false} up to
   exactly that deleted global phase. The twin is still a twin, for a NEW reason.
   (PRD docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md S4.1, D1/D2.) */
/* slice_control_angle_select_rz_twin.c — the MANUAL by-difference twin of
   `slice_control_angle_select_rz.c` (bd test_C_libtooling-drbq Increment 2b).

       cq_phi(0.3);
       if (q == 5) cq_phi(0.9 - 0.3);

   An ordinary in-place Rz diamond — the drbq Increment-2a peephole's own shape,
   which lowered on the pre-2b binary. */
int slice(void) {
    int q = 3;
    int r = 7;
    cq_theta(&q, 0.5);
    cq_theta(&r, 0.25);
    cq_phi(0.3);
    if (q == 5) cq_phi(0.9 - 0.3);
    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
