/* slice_control_angle_select_ry_ne.c — the `!=` POLARITY of the angle select,
   at the LINK layer (bd test_C_libtooling-drbq Increment 2b).

   ⚠⚠ SINCE bd test_C_libtooling-fmt3 (2026-09-28) THIS FILE NO LONGER REACHES THE
   ANGLE SELECT; the text below about the select is HISTORY. With `nomerge` on
   `cq_theta_*` (CQ.h) the if/else stays an if/else, `-O1` still canonicalises
   the compare to `icmp eq q, 5` (so the TRUE successor is the ELSE arm), and it
   lowers through the in-place Ry arm's if/else form:
       f = (q == 5); cRy(f, r, 0.3); X f; cRy(f, r, 0.9); X f; strip; free
   — the SAME unitary (q == 5: Ry(0.3); q != 5: Ry(0.9)). There IS now a `cqrt_x`
   pair in the trace, on the compare ANCILLA only, self-inverse, so the flag is
   back to its value at the strip; the "no `cqrt_x` anywhere" assertion below
   belongs to the select form, which moved (golden byte for byte) to
   `slice_control_angle_select_ry_ne_ternary.c` together with
   `e2e-angle-select-ry-ne-twin-identical`. Golden REGENERATED deliberately,
   STRICT 2b: 2 verified, 0 violation. ⚠ SINCE bd dm7f.6 (owner ruling
   2026-10-13) the ternary angle select emits THIS X-bracket stream, so
   `e2e-angle-select-ry-ne-twin-identical` now compares the ternary golden with
   THIS one, byte for byte.

       if (q != 5) cq_theta(&r, 0.9); else cq_theta(&r, 0.3);

   `clang -O1` canonicalizes `q != 5` to `icmp eq i32 %q, 5` and then SWAPS the
   select's two arms rather than inverting the condition (measured). THE POINT OF
   THIS SLICE IS THAT NOTHING SPECIAL HAPPENS: a select always means "true value
   when the flag is 1", so the unconditional twin takes the FALSE operand — here
   0.9, the `q != 5` arm's own angle — and the controlled gate takes
   `A - B = 0.3 - 0.9 = -0.6`.

   THERE IS NO `cqrt_x` ANYWHERE IN THIS TRACE, and that is the assertion. On the
   `br`-diamond paths Rule 9's false-successor canonicalization forces a
   self-inverse `cqrt_x` bracket around the arm's gate run
   (`slice_control_inplace_ry_negated`); the angle select has no polarity case at
   all, so the bracket simply does not exist. A stray single X on those paths
   would leave the flag inverted at the strip and the free would then reset a
   rail holding |1>; here there is nothing to get wrong.

   Its twin is `slice_control_angle_select_ry_ne_twin.c`, and
   `e2e-angle-select-ry-ne-twin-identical` compares the goldens. STRICT stage 2b. */
int slice(void) {
    int q = 3;
    int r = 7;
    cq_theta(&q, 0.5);
    cq_theta(&r, 0.25);
    if (q != 5) cq_theta(&r, 0.9);
    else        cq_theta(&r, 0.3);
    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
