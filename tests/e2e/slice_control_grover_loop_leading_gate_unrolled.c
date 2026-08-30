/* slice_control_grover_loop_leading_gate_unrolled.c — the HAND-UNROLLED TWIN of
   slice_control_grover_loop_leading_gate.c (bd test_C_libtooling-8h7d.5, Rule-13
   round 4).

   Same body, twice, no loop. Its golden is the reference the rolled form is
   byte-diffed against (ctest entry e2e-grover-loop-leading-gate-twin-identical).

   THIS SIDE ALWAYS COMPILED CORRECTLY, and that is exactly what makes it the
   witness: the straight-line stream discharges both condition rails between the
   flag strip and the flag free, so the two traces differing was never a question
   of what the source asks for — it was the rolled form emitting a different
   circuit. Before the fix the rolled golden was SHORTER than this one by the two
   `cq_template_and_i32_hl_unc` / `cqrt_free` lines per iteration. */

#define CQ_LEADING_GATE_ITER                              \
    a = cq_theta(a, 0.25);                                \
    if ((a & 3) == 1) {                                   \
        a = cq_phi(a, 3.14159265358979323846);            \
    }                                                     \
    a = cq_theta(a, -0.5);

int slice(void) {
    int a = 0;

    a = cq_theta(a, 0.5);

    CQ_LEADING_GATE_ITER
    CQ_LEADING_GATE_ITER

    return cq_measure(a);
}
int main(void) { (void) slice(); return 0; }
