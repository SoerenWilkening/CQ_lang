/* specialize_libm_caller.c — the CQ translation unit for the bd 3c6m.3 golden
   (libm-in-clone specialization): a curated DIRECT-libm math.h call INSIDE a
   call-graph-specialized clone. Mirrors specialize_intrinsic_caller.c — a tainted
   value routed through a classical library helper — but the helper's body now
   contains `ilogb` (a DIRECT `@ilogb` call, a Class-2 libm producer) rather than a
   curated `@llvm.*` intrinsic.

   Because `x` is TAINTED when it reaches `ilogb_helper(x)`, the specializer lifts
   the helper into the reversible clone `__cq_q_ilogb_helper_1` (Bennett
   compute-copy-uncompute). The clone forward-computes the in-clone `sitofp` to the
   FROZEN `cq_template_sitofp_i32_to_f64` producer and the `ilogb` to
   `cq_template_ilogb_f64_to_i32`, copies out only the i32 result, then reverses
   the ilogb via its void `_unc` twin (recompute-from-live-source) and the sitofp
   via its own `_unc`, freeing each scratch rail AFTER the complete reverse. `y` is
   the basis copy the clone returns; the borrowed quantum input `x` is preserved
   read-only.

   This is the ONLY layer that LINK-proves @__cq_q_ilogb_helper_1 +
   cq_template_ilogb_f64_to_i32 + cq_template_ilogb_f64_to_i32_unc (and the sitofp
   cast + its `_unc`) resolve and signature-match across llvm-link (Rule 2,
   Rule 16). `ilogb_helper` is DECLARED (not defined) here, so opt sees an
   un-inlined visible body only after the lib is linked in (Rule 9). */
int ilogb_helper(int n);

int slice(void) {
    int x = 5;
    x = cq_theta(x, 0.5);
    int y = ilogb_helper(x);
    int z = cq_measure(y);
    return z;
}

int main(void) { (void) slice(); return 0; }
