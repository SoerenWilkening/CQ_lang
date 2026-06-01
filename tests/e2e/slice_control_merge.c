/* slice_control_merge.c — Phase 4 (WP6) e2e smoke: a classical-arm MERGE
   reduction (PRD §7, §2.6, IMPLEMENTATION §6/§7). A tainted `y = (q > 0) ? 10
   : 20;` arrives from `clang -O1` as a `select i1` over two CONSTANTS (the
   ternary-of-constants is cheap/speculatable, so `-O1` picks `select`, not a
   diamond). The pass dissolves the merge into a single controlled add onto a
   register initialized to the false-arm:

     q > 0   -> cq_template_icmp_sgt_i32_hl(h, 0)              -> flag  (compute)
     (?:)    -> cqrt_alloc_i32(20)                             -> regB  (false arm)
             -> cq_template_add_i32_hl_controlled(flag, regB, -10)     (A-B = 10-20)
             -> cq_template_icmp_sgt_i32_hl_inv(h, 0)                  (uncompute)
     measure -> cqrt_measure_i32(regB)

   The only test layer that LINKS — proves the classical-arm reduction's
   controlled symbols resolve. Golden captured from REAL output.
   cq_theta/cq_measure resolve from CQ.h, force-included by run_slice.sh. */
int slice(void) {
    int q = 3;
    q = cq_theta(q, 0.5);
    int y = (q > 0) ? 10 : 20;        /* classical-arm select reduction */
    return cq_measure(y);
}
int main(void) { (void) slice(); return 0; }
