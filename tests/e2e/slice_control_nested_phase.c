/* 3qlq Inc 1: migrated to register-free cq_phi -- the outer intervening gate and the inner arm gate lose their register.
   FLAG: the outer arm now holds ONE cq_phi + a nested tainted region. Under the new
   surface `-O1` may fold the nest to `select i1 %a, i1 %b, false` (PRD S6.1); if it
   does, this stops being the 4.3 depth-2 nest it was written for and becomes P3.
   (PRD docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md S4.1, D1/D2.) */
/* slice_control_nested_phase.c — Phase 4.3 e2e smoke (WI-4,
   test_C_libtooling-s8yf.5): the RSSA swap-routed depth-2 homogeneous-PHASE
   nest, the only test layer that LINKS — and so the only proof that the nested
   emitter's symbol set resolves and signature-matches across BOTH routing
   levels against the runtime + template libs (Rule 2, Rule 16). 4.3 adds no new
   runtime ABI; this golden proves the depth-2 stream reuses 4.1's symbols
   correctly (outer + inner cqrt_cswap, two |0> rails, the inner flag minted
   FROM rail1, both icmp `_hl_inv` strips).

   SOURCE INTENT (one-content-arm diamond whose Mid arm ends in ANOTHER tainted
   one-content-arm diamond — the §0 measured accept shape):
       q : tainted quantum handle (cq_theta == Ry, the sole taint source)
       if (q > 5) {                 // OUTER tainted condition (flag f1)
           cq_phi(0.25);     // intervening Mid gate g (Rz, PHASE) on q
           if (q < 9) {             // INNER tainted condition — reads the GATED q
               cq_phi(0.75); // inner-arm gate h (Rz, PHASE)
           }
       }
       measure q

   Neither tainted `if` is classical control over quantum state. The nest lowers
   to the §5g routed stream (IMPLEMENTATION-4.3 §0/§5g, the pinned
   control_swap_nested_phase_diamond.ll lit contract):

     1 outer mint f1 = icmp_sgt(q,5); alloc |0> rail1; cswap q -> rail1
     2 replay the intervening Rz VERBATIM on rail1
     3 inner mint f2 = icmp_slt(rail1,9) FROM RAIL1 (the value's amplitude lives
       there post-route-in — NOT from the now-stale %g register, criterion 5);
       alloc |0> rail2; cswap rail1 -> rail2; replay inner Rz; cswap back
     4 tear down LIFO: free rail2 -> STRIP f2 vs rail1 (icmp_inv) -> free f2
     5 outer route-back (cswap q <- rail1) -> free rail1 -> STRIP f1 vs q -> free f1

   The load-bearing §12.3 order: the inner strip fires BEFORE the outer
   route-back. Misordering it (strip after route-back) yields the IDENTICAL
   symbol multiset yet dirty-frees f2 = a hidden measurement that collapses q —
   invisible to `opt -verify`, caught only here and by the ordered lit CHECK.

   ZERO controlled gates, NO cqrt_toffoli, NO surviving `phi i32`, EXACTLY FOUR
   cqrt_free (rail2, f2, rail1, f1), NO added measure: every |0> rail is freed by
   its own route-back (Rz|0>=|0>, a clean reset, not a hidden measurement), and
   the phi is RAUW'd to q so the user's measure reads q, not the merge.

   The runtime is trace-only and the nest is flattened to straight-line code, so
   every emitted gate fires unconditionally; the trace is fully deterministic
   regardless of q's value. cq_theta/cq_phi/cq_measure resolve from CQ.h,
   force-included by run_slice.sh (-include CQ.h -I include). */
int slice(void) {
    int q = 3;
    cq_theta(&q, 0.5);                 /* taint q -> handle (alloc i32(3), ry_i32) */
    if (q > 5) {                       /* OUTER tainted cond -> swap-route (flag f1) */
        cq_phi(0.25);           /* intervening Mid gate (Rz) — VERBATIM on rail1 */
        if (q < 9) {                   /* INNER tainted cond -> route FROM rail1 (f2) */
            cq_phi(0.75);       /* inner-arm gate (Rz) — VERBATIM on rail2 */
        }
    }
    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
