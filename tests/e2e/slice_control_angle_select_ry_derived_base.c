/* slice_control_angle_select_ry_derived_base.c — THE FREEZE, at the LINK layer
   (bd test_C_libtooling-drbq Increment 2b; the angle-select form of Increment 1's
   finding L, a CONFIRMED silent miscompile that shipped through a green suite).

   ⚠⚠ SINCE bd test_C_libtooling-fmt3 (2026-09-28) THIS FILE NO LONGER REACHES THE
   ANGLE SELECT. With `nomerge` on `cq_theta_*` (CQ.h) the if/else stays an
   if/else and lowers through the in-place Ry arm's if/else form on the `mul`
   rail: `cRy(f, r, 0.9); X f; cRy(f, r, 0.3); X f` — the SAME unitary, the X pair
   on the compare ANCILLA only. The FREEZE this file probes still holds on that
   path and the golden shows it (one `cqrt_free`, the flag's; the `mul` rail left
   allocated; the two M-A warnings unchanged). Golden REGENERATED deliberately,
   STRICT 2b: 1 verified, 0 violation. The select-path probe moved, golden byte
   for byte, to `slice_control_angle_select_ry_derived_base_ternary.c`.

       int p = cq_theta(7, 0.25);
       int r = p * 5;                                     // an OUT-OF-PLACE rail
       if (q == 5) r = cq_theta(r, 0.9); else r = cq_theta(r, 0.3);
       int s = r + 1;                                     // a post-gate user
       return cq_measure(q) + cq_measure(s);

   The rotated base is a `cq_template_mul_i32_hl` rail and there IS a post-gate
   user, so the whole-DAG uncompute spine has something to reverse — and a
   register a `cqrt_ry_<W>_controlled` fired on must be FROZEN: never
   reverse-played, never freed. A controlled gate's adjoint needs its CONTROL and
   the flag is stripped and freed inside this very stream, so reversing would
   emit an adjoint naming a FREED flag and then `cqrt_free` a still-dirty,
   condition-entangled register (Rules 6/8).

   INCREMENT 2b ADDS NO CODE FOR THAT, WHICH IS WHY THIS SLICE EXISTS. Since Inc
   1's round-1 fix the freeze is asked STRUCTURALLY of the emitted gate
   (`ChainWalk::railCarriesControlledRotation` derives the rail from the gate's
   own arg-1 use), so it applies to a 2b gate for free. Inc 1 originally recorded
   a `Value *` instead — and for a DERIVED base that value is a raw LLVM
   instruction `lowerOps`, the very next stage, RAUWs and ERASES, so the set went
   stale and the use-after-free returned verbatim. This slice is the link-layer
   probe of the claim rather than an argument for it.

   The golden shows exactly one `cqrt_free` (the flag); the `mul` rail is LEFT
   ALLOCATED, Rule 6's leak-rather-than-dirty-free fallback. STRICT stage 2b,
   deliberately: the checker sees rail identities the trace cannot.

   Two `cq rotation lowering: non-diagonal gate over a live derived record`
   WARNINGS are expected and are not failures (M-A is a `DS_Warning` since bd
   `lyyf`; `opt` exits 0). The manual by-difference twin of this shape emits the
   identical stream and the identical two warnings — verified by hand. */
int slice(void) {
    int q = 3;
    int p = 7;
    q = cq_theta(q, 0.5);
    p = cq_theta(p, 0.25);
    int r = p * 5;
    if (q == 5) r = cq_theta(r, 0.9);
    else        r = cq_theta(r, 0.3);
    int s = r + 1;
    return cq_measure(q) + cq_measure(s);
}
int main(void) { (void) slice(); return 0; }
