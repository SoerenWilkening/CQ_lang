/* slice_control_mux_handles.c — Phase 4 (mux.2) e2e smoke: a BOTH-ARMS-HANDLE
   select mux (PRD §2.6, IMPLEMENTATION §5.5). A tainted `y = (q > 0) ? (12 - q)
   : (q + 5);` arrives from `clang -O1` as a `select i1` whose BOTH value arms
   are tainted expressions over the quantum `q` (no classical arm). The mixed
   reduction (mux.1) cannot apply — `cqrt_alloc` seeds from a CLASSICAL value and
   here neither arm is classical — and an arm may be live elsewhere, so a
   consuming/in-place strategy is unsafe. The pass copies ADDITIVELY into a fresh
   ancilla, leaving both source handles untouched:

     q > 0    -> cq_template_icmp_sgt_i32_hl(h, 0)             -> flag  (compute)
     12 - q   -> cq_template_sub_i32_lh(12, h)                 -> hp    (true arm)
     q + 5    -> cq_template_add_i32_hl(h, 5)                  -> hq    (false arm)
     (?:)     -> cqrt_alloc_i32(0)                             -> regOut (fresh)
              -> cq_template_add_i32_controlled(flag, regOut, hp)   ; += flag·hp
              -> cqrt_x(flag)                                       ; ¬flag
              -> cq_template_add_i32_controlled(flag, regOut, hq)   ; += ¬flag·hq
              -> cqrt_x(flag)                                       ; restore flag
              -> cq_template_icmp_sgt_i32_hl_inv(h, 0)              (uncompute)
     measure  -> cqrt_measure_i32(regOut)

   The only test layer that LINKS — proves the both-handle mux's controlled
   symbols (two bare `_controlled` QQ adds + the cqrt_x bracket + the alloc(0)
   ancilla) resolve. Golden captured from REAL output. cq_theta/cq_measure
   resolve from CQ.h, force-included by run_slice.sh. */
int slice(void) {
    int q = 3;
    q = cq_theta(q, 0.5);
    int y = (q > 0) ? (12 - q) : (q + 5);  /* both arms depend on q -> both tainted */
    return cq_measure(y);
}
int main(void) { (void) slice(); return 0; }
