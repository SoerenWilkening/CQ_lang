/* slice_control_inplace_ry_bool_loop_grover_unrolled.c — the HAND-UNROLLED TWIN
   of slice_control_inplace_ry_bool_loop_grover.c at CQ_K = 2. */

int slice(void) {
    bool b = (bool)0; cq_theta(&b, 0.5);
    int r = 7; cq_theta(&r, 0.25);

    if (b) cq_theta(&r, 0.9);
    cq_theta(&r, -0.5);
    cq_theta(&r, 0.5);

    if (b) cq_theta(&r, 0.9);
    cq_theta(&r, -0.5);
    cq_theta(&r, 0.5);

    return cq_measure(r) + cq_measure(b);
}
int main(void) { return slice(); }
