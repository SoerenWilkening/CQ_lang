/* 3qlq Inc 1: migrated to register-free cq_phi -- the outer intervening gate and the inner arm gate lose their register.
   FLAG: the outer arm now holds ONE cq_phi + a nested tainted region. Under the new
   surface `-O1` may fold the nest to `select i1 %a, i1 %b, false` (PRD S6.1); if it
   does, this stops being the 4.3 depth-2 nest it was written for and becomes P3.
   (PRD docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md S4.1, D1/D2.) */
/* slice_control_nested_phase.c — Phase 4.3 e2e smoke (WI-4,
   test_C_libtooling-s8yf.5): the depth-2 homogeneous-PHASE nest lowered by
   kickback, the only test layer that LINKS — and so the only proof that the
   nested emitter's symbol set resolves and signature-matches at BOTH levels
   against the runtime + template libs (Rule 2, Rule 16). This golden proves the
   depth-2 stream: two compare flags minted from q, the outer Rz on f1, the inner
   Rz on a cqrt_toffoli-computed AND ancilla, and both compare `_unc` strips
   before their frees.

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
   by kickback (control_swap_nested_phase_diamond.ll pins the same ordered
   stream in lit):

     1 outer mint f1 = icmp_sgt(q,5) into a fresh |0> ancilla
     2 the intervening Rz fires UNCONTROLLED on f1 (cqrt_rz_i1)
     3 inner mint f2 = icmp_slt(q,9), also read from q (an Rz never changes
       q's basis value)
     4 alloc a |0> i1 ancilla a; cqrt_toffoli(f1, f2, a) computes f1 AND f2; the
       inner Rz fires UNCONTROLLED on a; a second cqrt_toffoli returns a to |0>
     5 tear down LIFO: free a -> STRIP f2 (`_unc`) -> free f2 -> STRIP f1 -> free f1

   The load-bearing order: a is freed only after the second Toffoli, and each
   flag only after its own `_unc` strip. A free moved ahead of its uncompute has
   the IDENTICAL symbol multiset yet frees a dirty rail = a hidden measurement —
   invisible to `opt -verify`, caught only here and by the ordered lit CHECK.

   ZERO controlled rotations, ONE cqrt_toffoli pair, NO `phi i32`, EXACTLY THREE
   cqrt_free (a, f2, f1), NO added measure: every freed rail is back at |0>
   (Toffoli pair, compare strips), a clean reset, not a hidden measurement, and
   the user's measure reads q (h0).

   The runtime is trace-only and the nest is flattened to straight-line code, so
   every emitted gate fires unconditionally; the trace is fully deterministic
   regardless of q's value. cq_theta/cq_phi/cq_measure resolve from CQ.h,
   force-included by run_slice.sh (-include CQ.h -I include). */
int slice(void) {
    int q = 3;
    cq_theta(&q, 0.5);                 /* taint q -> handle (alloc i32(3), ry_i32) */
    if (q > 5) {                       /* OUTER tainted cond -> flag f1 (kickback)   */
        cq_phi(0.25);           /* intervening Mid gate (Rz) — cqrt_rz_i1 on f1  */
        if (q < 9) {                   /* INNER tainted cond -> flag f2 from q         */
            cq_phi(0.75);       /* inner-arm gate (Rz) — rz_i1 on f1 AND f2  */
        }
    }
    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
