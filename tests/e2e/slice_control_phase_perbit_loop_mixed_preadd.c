/* slice_control_phase_perbit_loop_mixed_preadd.c — bd test_C_libtooling-3qlq
   Increment 1, the SECOND C-1 review round, finding **F-C1-1** (CONFIRMED
   MISCOMPILE).

   `slice_control_phase_perbit_loop_mixed.c` PLUS ONE LINE: a dtzb in-place `add`
   on the loop-INVARIANT condition register, in the loop's PREHEADER.

       int q = cq_theta(u, 0.5);            // INVARIANT: the body gates nothing on it
       int r = cq_theta(u, 0.3);            // CARRIED:   rotated once per trip
       q = q + 7;                           // <-- the only difference
       for (int i = 0; i < 3; i++) {
           if ((q >> i) & 1) cq_phi(0.2);   // D4's per-bit kickback
           r = cq_theta(r, 0.1);
       }
       q = cq_theta(q, 0.9);                // the DIFFUSION
       return cq_measure(q) + cq_measure(r);

   WHAT IT MEASURES. The C-1 fix that made the sibling slice discharge is a
   DISPATCH fix; this line breaks it on a PRECONDITION one stage over.
   `invariantRegisterRoots` peels with `AsLowered=true`, i.e. only through ops
   whose disposition is `InPlace`; a preheader `add` is in neither
   `taint.InPlaceRailOps` nor a `blockCanRepeat` block, so the peel STOPS at the
   `add`, the root is not a `CallInst`, and the whole extension refuses — while
   `lowerOps`' M-C lowers that very op IN PLACE (`cqrt_addc_i32(h0, 7)` is the
   fifth line of this slice's golden). The register the body reads IS the root
   mint's rail; only the analysis did not know it.

   MEASURED on 542d588 AND on the round-1 C-1 fix: `cq_template_and_i32_hl` 3 /
   `_unc` **0** (32-line trace) against this pair's twin at 3/3 (38 lines), at
   `opt` exit 0, verify-clean and STRICT stage 2b `0 violation(s)`. The pre-3qlq
   ORACLE on the register-surface twin discharged all three and was
   rolled == unrolled. It is PRE-EXISTING and F-L5-1-era rather than round 1's:
   the same source with NO carried register leaks identically on both binaries.

   Three live which-path records of `q`'s low bits survive into
   `cqrt_ry_i32(h0, 0.9)`, so rolled and unrolled were DIFFERENT UNITARIES
   (Rule 8) — and stage 2b is structurally blind to it (a leaked TEMPLATE-minted
   rail has no `cqrt_alloc` to count).

   THE WITNESS IS THE `cmp` GATE `e2e-phase-perbit-loop-mixed-preadd-twin-identical`,
   not this file alone: a golden regenerated on a leaking binary is
   self-consistent. `..._preadd_unrolled.c` is the twin. The lit-layer stand-in is
   `control_phase_kickback_mixed_preheader_addc_inloop.ll`, and its mirror
   `..._preheader_add_outofplace_leak_control.ll` pins the shape M-C refuses. */
int slice(int u) {
  int q = cq_theta(u, 0.5);
  int r = cq_theta(u, 0.3);
  q = q + 7;
  for (int i = 0; i < 3; i++) {
    if ((q >> i) & 1) cq_phi(0.2);
    r = cq_theta(r, 0.1);
  }
  q = cq_theta(q, 0.9);
  return cq_measure(q) + cq_measure(r);
}

int main(void) { (void)slice(5); return 0; }
