/* slice_control_angle_select_ry_ne.c — the `!=` POLARITY of the angle select,
   at the LINK layer (bd test_C_libtooling-drbq Increment 2b).

       if (q != 5) r = cq_theta(r, 0.9); else r = cq_theta(r, 0.3);

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
    q = cq_theta(q, 0.5);
    r = cq_theta(r, 0.25);
    if (q != 5) r = cq_theta(r, 0.9);
    else        r = cq_theta(r, 0.3);
    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
