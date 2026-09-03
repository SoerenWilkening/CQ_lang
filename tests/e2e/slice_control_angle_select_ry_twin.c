/* slice_control_angle_select_ry_twin.c — the MANUAL by-difference twin of
   `slice_control_angle_select_ry.c` (bd test_C_libtooling-drbq Increment 2b).

   Same circuit, written the way the compiler now writes it: the FALSE-arm angle
   applied unconditionally, then the DIFFERENCE applied under the condition.

       r = cq_theta(r, 0.3);
       if (q == 5) r = cq_theta(r, 0.9 - 0.3);

   This is an ordinary drbq Increment-1 in-place rotation DIAMOND, and it lowered
   on the PRE-2b binary — which is exactly what makes it an oracle rather than a
   second copy of the thing under test. `e2e-angle-select-ry-twin-identical`
   compares the two goldens byte for byte.

   THE CONSTANT IS PART OF THE WITNESS. `clang` folds `0.9 - 0.3` to
   0x3FE3333333333334 at compile time; the 2b emitter folds `A - B` with
   `IRBuilder`'s APFloat subtract. Those agree bit for bit, which is why the
   comparison is EXACT and not merely close — a difference in the last ULP would
   show up as a different `%a` hex float in the trace. */
int slice(void) {
    int q = 3;
    int r = 7;
    q = cq_theta(q, 0.5);
    r = cq_theta(r, 0.25);
    r = cq_theta(r, 0.3);                   /* the unconditional FALSE-arm angle */
    if (q == 5) r = cq_theta(r, 0.9 - 0.3); /* the controlled DIFFERENCE         */
    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
