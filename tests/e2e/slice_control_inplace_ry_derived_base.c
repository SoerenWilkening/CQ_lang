/* slice_control_inplace_ry_derived_base.c — the LINK-layer regression pin for a
   CONFIRMED silent miscompile found by the round-1 Rule-13 review of bd
   test_C_libtooling-drbq Inc 1 (reviewer lenses L3 §1 and L5 §1, independently).

   SHAPE: the increment's own §4b probe `a1` — an in-place controlled Ry whose
   rotated base is an OUT-OF-PLACE DERIVED rail (`r = p * 5`, which always mints
   a fresh `cq_template_mul_i32_hl` rail, so R4's wire-disjointness holds and the
   region ACCEPTS) — crossed with a POST-REGION USER of that register, which is
   what gives the whole-DAG uncompute spine something to reverse. Each axis was
   probed while building Inc 1; the CROSS was not.

   THE DEFECT this slice pins (measured, `opt` exit 0, `opt -verify` clean, all
   37 committed lit fixtures of the family GREEN):

       cq_template_icmp_eq_i32_hl_unc(h3, h0, 5)
       cqrt_free(h3)                             <-- the control flag is reclaimed
       cqrt_addc_i32(h2, 1) ; cqrt_addc_i32(h2, -1)
       cqrt_ry_i32_controlled(h3, h2, -0.9)      <-- USE AFTER FREE
       cq_template_mul_i32_hl_unc(h2, h1, 5)
       cqrt_free(h2)                             <-- DIRTY FREE
       cqrt_ry_i32(h1, -0.25) ; cqrt_free(h1)    <-- a SECOND dirty free

   A `cqrt_free` is a hardware reset, so the adjoint's control is |0> and the
   adjoint NEVER FIRES: the register is still carrying Ry(0.9) entangled with q
   when the spine frees it — a hidden measurement that collapses q (Rules 6/8).

   ROOT CAUSE: the "this register is FROZEN" fact was keyed on the theta's arg-0
   AT `lowerRotations` TIME. For a derived base that is the raw `mul`
   INSTRUCTION, which `lowerOps` — the very next pipeline stage — RAUWs to the
   template result and ERASES, leaving a dangling pointer that no query site
   could match against the live rail. The freeze is now asked STRUCTURALLY of the
   emitted gate (`ChainWalk::railCarriesControlledRotation`), which derives the
   rail from the gate's own arg-1 use and cannot go stale.

   WHY AN e2e SLICE AND NOT ONLY A FIXTURE: this is the only layer that LINKS,
   and it is the layer that runs stage 2b STRICT — `free_pairing_check.py` is
   what reported `VIOLATION F2-use-after-free` + `T3-rail-written-before-reversal`
   on the pre-fix stream. No slice in the tree had a derived base under a
   rotation arm, which is why nothing was red.

   EXPECTED, and the whole assertion: the frozen rail is LEFT ALLOCATED (Rule 6's
   documented fallback in the qubits-not-scarce regime). The golden's LAST four
   lines are forward gates and a measurement; there is no adjoint of anything and
   exactly ONE `cqrt_free` — the flag's.

   NOTE the M-A live-record WARNING (`non-diagonal gate over a live derived
   record`, bd lyyf) is EXPECTED on stderr here and does not fail the slice:
   `p`'s rail is a live ancestor record of the rotated `mul` rail, so the
   controlled Ry dephases the user's own answer. That is the user's circuit and
   the user's call — a DS_Warning, `opt` exits 0. */
int slice(void) {
    int q = 3, p = 7;
    q = cq_theta(q, 0.5);          /* taint q -> alloc i32(3), ry_i32           */
    p = cq_theta(p, 0.25);         /* taint p -> a second, disjoint rail        */
    int r = p * 5;                 /* an OUT-OF-PLACE derived rail (fresh mint) */
    if (q == 5) {                  /* tainted condition -> flag mint at the icmp */
        r = cq_theta(r, 0.9);      /* the arm Ry — CONTROLLED, IN PLACE on r    */
    }
    int s = r + 1;                 /* a POST-REGION user (M-C in-place addc)    */
    (void) cq_theta(s, 0.125);     /* keeps `s` alive under -O1                 */
    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
