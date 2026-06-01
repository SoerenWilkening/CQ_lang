/* slice_control_gate.c — Phase 4 (WP6) e2e smoke: a quantum-CONTROLLED gate
   (PRD §7, IMPLEMENTATION §6/§7). A tainted `if (q > k) y = cq_phi(y, θ);`
   arrives from `clang -O1` as a `br`-diamond + `φ[modified, original]` — the
   opaque gate-call arm prevents `-O1` from flattening the `if` to branchless
   flag-arithmetic. The pass lowers it to a CONTROLLED rotation:

     y > 5          -> cq_template_icmp_sgt_i32_hl(h, 5)    -> flag   (compute)
     y = cq_phi(...) -> cqrt_rz_i32_controlled(flag, h, 0.25)         (gate)
                    -> cq_template_icmp_sgt_i32_hl_inv(h, 5)          (uncompute)
     return measure -> cqrt_measure_i32(h)

   This is the only test layer that LINKS — it proves every controlled symbol
   the pass emits resolves + is signature-correct against the runtime/template
   libs. The golden is captured from REAL `-O1` -> cq-lowering -> link -> run.
   cq_theta/cq_phi/cq_measure resolve from CQ.h, force-included by run_slice.sh. */
int slice(void) {
    int y = 7;
    y = cq_theta(y, 0.5);
    if (y > 5) y = cq_phi(y, 0.25);   /* controlled rotation */
    return cq_measure(y);
}
int main(void) { (void) slice(); return 0; }
