/* slice_control_angle_select_ry_ne_ternary.c — the `!=` polarity of
   `slice_control_angle_select_ry_ternary.c` (bd test_C_libtooling-fmt3,
   2026-09-28). Since fmt3's `nomerge` the if/else spelling
   (`slice_control_angle_select_ry_ne.c`) is no longer folded into an angle
   select; writing the select as a C conditional expression is the spelling that
   still reaches `AngleSelectEmit`'s Ry stem. GOLDEN REGENERATED for bd dm7f.6
   (X-bracket Ry stem): the select is `(q == 5) ? 0.3 : 0.9` after `-O1`'s swap,
   so `cRy(f, r, 0.3); x(f); cRy(f, r, 0.9); x(f)` (was `ry(r, 0.9)` plus one gate
   at `fl(0.3 - 0.9)`). `e2e-angle-select-ry-ne-twin-identical` compares it with
   the if/else spelling `slice_control_angle_select_ry_ne.c`, byte for byte.
   STRICT stage 2b. */
int slice(void) {
    int q = 3;
    int r = 7;
    cq_theta(&q, 0.5);
    cq_theta(&r, 0.25);
    cq_theta(&r, (q != 5) ? 0.9 : 0.3);
    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
