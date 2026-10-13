/* slice_control_angle_select_ry_forward_loop_unrolled_twin.c — the hand-written
   ORACLE for `slice_control_angle_select_ry_forward_loop.c` (bd
   test_C_libtooling-3paw; RESPELLED for bd dm7f.6). The same circuit with the
   angle select written as the IF/ELSE (`slice_control_angle_select_ry.c`'s
   spelling: since fmt3's `nomerge` it stays an if/else and lowers through the
   in-place Ry arm, `cRy(f,r,.9); x(f); cRy(f,r,.3); x(f)`) and the loop's three
   trips written out, so no loop and no angle select reaches the pass. Since
   dm7f.6 (owner ruling 2026-10-13) the angle select emits exactly that X-bracket
   stream, so `e2e-angle-select-ry-forward-loop-twin-identical` requires the two
   goldens to be byte-identical. Until dm7f.6 this file wrote the by-difference
   diamond (`cq_theta(&r,.3); if (q==5) cq_theta(&r,.9-.3);`). STRICT stage 2b. */
int slice(void) {
    int q = 3;
    int r = 7;
    cq_theta(&q, 0.5);
    cq_theta(&r, 0.25);
    if (q == 5) cq_theta(&r, 0.9);          /* the in-place Ry arm, if/else */
    else        cq_theta(&r, 0.3);
    cq_theta(&r, 0.1);                      /* trip 0 */
    cq_theta(&r, 0.1);                      /* trip 1 */
    cq_theta(&r, 0.1);                      /* trip 2 */
    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
