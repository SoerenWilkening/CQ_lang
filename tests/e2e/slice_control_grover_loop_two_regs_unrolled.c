/* slice_control_grover_loop_two_regs_unrolled.c — the HAND-UNROLLED TWIN of
   slice_control_grover_loop_two_regs.c: the identical body written out twice with
   no loop at all. Its golden must be BYTE-IDENTICAL to the rolled slice's
   (ctest entry e2e-grover-loop-two-regs-twin-identical), which is the strongest
   witness available to a project with no simulator (Rule 2): it says the rolled
   two-register form emits the same unitary, gate for gate and handle for handle,
   as a straight-line stream. Do not regenerate one golden without the other. */
#define CQ_PI 3.14159265358979323846
int slice(void) {
    int a = 0, b = 0;
    a = cq_theta(a, 0.5);
    b = cq_theta(b, 0.25);

    if (a == 5) { a = cq_phi(a, CQ_PI); }
    if (b == 3) { b = cq_phi(b, CQ_PI); }
    a = cq_theta(a, -0.5);
    b = cq_theta(b, -0.25);
    a = cq_theta(a, 0.5);
    b = cq_theta(b, 0.25);

    if (a == 5) { a = cq_phi(a, CQ_PI); }
    if (b == 3) { b = cq_phi(b, CQ_PI); }
    a = cq_theta(a, -0.5);
    b = cq_theta(b, -0.25);
    a = cq_theta(a, 0.5);
    b = cq_theta(b, 0.25);

    return cq_measure(a) + cq_measure(b);
}
int main(void) { (void) slice(); return 0; }
