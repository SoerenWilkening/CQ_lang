/* slice_control_phase_perbit_loop_mixed_unrolled.c — the HAND-UNROLLED TWIN of
   slice_control_phase_perbit_loop_mixed.c (bd test_C_libtooling-3qlq Increment 1,
   the Rule-13 CLEARANCE finding C-1).

   Same program, the loop written out. Its golden must be BYTE-IDENTICAL to the
   rolled one's — that equality is the whole witness (gate
   `e2e-phase-perbit-loop-mixed-twin-identical`), because a leaked which-path rail
   is invisible to `opt -verify`, to the golden of the rolled program ALONE, and
   to STRICT stage 2b. At 542d588 the two goldens differed by exactly the three
   `cq_template_and_i32_hl_unc` + `cqrt_free` pairs this file discharges and the
   rolled one did not (31 lines vs 37). */

int slice(int u) {
    int q = u; cq_theta(&q, 0.5);
    int r = u; cq_theta(&r, 0.3);

    if ((q >> 0) & 1) cq_phi(0.2);
    cq_theta(&r, 0.1);
    if ((q >> 1) & 1) cq_phi(0.2);
    cq_theta(&r, 0.1);
    if ((q >> 2) & 1) cq_phi(0.2);
    cq_theta(&r, 0.1);

    cq_theta(&q, 0.9);
    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(5); return 0; }
