/* slice_control_angle_select_ry_forward_loop_unrolled_twin.c — the hand-written
   ORACLE for `slice_control_angle_select_ry_forward_loop.c` (bd
   test_C_libtooling-3paw). The same circuit with the angle select written as its
   by-difference diamond (`slice_control_angle_select_ry_twin.c`'s spelling) and
   the loop's three trips written out, so no loop and no angle select reaches the
   pass: an Inc-1 in-place controlled-Ry arm followed by three chained rotations,
   which the compiler lowered before 3paw. The twin gate
   `e2e-angle-select-ry-forward-loop-twin-identical` requires the two goldens to
   be byte-identical. STRICT stage 2b. */
int slice(void) {
    int q = 3;
    int r = 7;
    cq_theta(&q, 0.5);
    cq_theta(&r, 0.25);
    cq_theta(&r, 0.3);                      /* the unconditional FALSE-arm angle */
    if (q == 5) cq_theta(&r, 0.9 - 0.3);    /* the controlled DIFFERENCE         */
    cq_theta(&r, 0.1);                      /* trip 0 */
    cq_theta(&r, 0.1);                      /* trip 1 */
    cq_theta(&r, 0.1);                      /* trip 2 */
    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
