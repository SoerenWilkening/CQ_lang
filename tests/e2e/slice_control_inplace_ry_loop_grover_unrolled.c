/* slice_control_inplace_ry_loop_grover_unrolled.c — the HAND-UNROLLED TWIN of
   slice_control_inplace_ry_loop_grover.c (two Grover iterations, no loop).

   IT IS THE ORACLE **AND** IT IS ITSELF NEW CAPABILITY, which makes it unlike the
   8h7d.5 twins: this program DECLINES on the pre-Increment-3 binary, at
   `ArmClassify`'s P1 fence, with no loop anywhere in it. Part 3b (the
   `SawRotationArm` disjunct) is what compiles it, and part 3a is what makes the
   rolled form agree with it byte for byte (ctest
   `e2e-inplace-ry-loop-grover-twin-identical`). */

#define CQ_PI 3.14159265358979323846

int slice(void) {
    int q = 0;
    int r = 7;

    q = cq_theta(q, 0.5);
    r = cq_theta(r, 0.25);

    if (q == 5) { q = cq_phi(q, CQ_PI); }
    if (q == 3) { r = cq_theta(r, 0.9); }
    q = cq_theta(q, -0.5);
    q = cq_theta(q, 0.5);

    if (q == 5) { q = cq_phi(q, CQ_PI); }
    if (q == 3) { r = cq_theta(r, 0.9); }
    q = cq_theta(q, -0.5);
    q = cq_theta(q, 0.5);

    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
