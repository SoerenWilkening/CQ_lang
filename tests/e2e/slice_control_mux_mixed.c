/* slice_control_mux_mixed.c — Phase 4 (mux.1) e2e smoke: a MIXED-ARM select
   mux, ONE tainted arm + one classical arm (PRD §2.6, IMPLEMENTATION §5.5).
   A tainted `y = (q > 0) ? (12 - q) : -3;` arrives from `clang -O1` as a
   `select i1` whose TRUE arm is a tainted expression (`12 - q`) and FALSE arm
   a classical constant (`-3`). Unlike the [classical,classical] reduction, the
   difference straddles a quantum handle, so the pass builds it with the
   UNCONTROLLED data template and a Shape::QQ controlled add:

     q > 0    -> cq_template_icmp_sgt_i32_hl(h, 0)          -> flag  (compute)
     12 - q   -> cq_template_sub_i32_lh(12, h)              -> Q     (tainted arm)
     (?:)     -> cq_template_sub_i32_hl(Q, -3)              -> delta (Q − C)
              -> cqrt_alloc_i32(-3)                         -> regC  (classical arm)
              -> cq_template_add_i32_controlled(flag, regC, delta)   (Shape::QQ)
              -> cq_template_icmp_sgt_i32_hl_inv(h, 0)              (uncompute)
     measure  -> cqrt_measure_i32(regC)

   The only test layer that LINKS — proves the mixed-arm mux's controlled
   symbols (the bare `_controlled` QQ add + the uncontrolled `_hl` delta)
   resolve. Golden captured from REAL output. cq_theta/cq_measure resolve from
   CQ.h, force-included by run_slice.sh. */
int slice(void) {
    int q = 3;
    q = cq_theta(q, 0.5);
    int y = (q > 0) ? (12 - q) : -3;  /* mixed-arm select: true tainted, false classical */
    return cq_measure(y);
}
int main(void) { (void) slice(); return 0; }
