/* slice_control_angle_select_ry_ne_ternary.c — the `!=` polarity of
   `slice_control_angle_select_ry_ternary.c` (bd test_C_libtooling-fmt3,
   2026-09-28). Since fmt3's `nomerge` the if/else spelling
   (`slice_control_angle_select_ry_ne.c`) is no longer folded into an angle
   select; writing the select as a C conditional expression is the spelling that
   still reaches `AngleSelectEmit`'s Ry stem. ITS GOLDEN IS THE PRE-fmt3 GOLDEN
   OF THE if/else `_ne` SLICE, byte for byte (moved, not regenerated —
   measured), and `e2e-angle-select-ry-ne-twin-identical` compares it with the
   unchanged twin `slice_control_angle_select_ry_ne_twin.c`. STRICT stage 2b. */
int slice(void) {
    int q = 3;
    int r = 7;
    cq_theta(&q, 0.5);
    cq_theta(&r, 0.25);
    cq_theta(&r, (q != 5) ? 0.9 : 0.3);
    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
