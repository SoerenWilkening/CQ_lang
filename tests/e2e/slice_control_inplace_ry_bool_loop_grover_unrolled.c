/* slice_control_inplace_ry_bool_loop_grover_unrolled.c — the HAND-UNROLLED TWIN
   of slice_control_inplace_ry_bool_loop_grover.c at CQ_K = 2. */

int slice(void) {
    bool b = cq_theta((bool)0, 0.5);
    int r = cq_theta(7, 0.25);

    if (b) r = cq_theta(r, 0.9);
    r = cq_theta(r, -0.5);
    r = cq_theta(r, 0.5);

    if (b) r = cq_theta(r, 0.9);
    r = cq_theta(r, -0.5);
    r = cq_theta(r, 0.5);

    return cq_measure(r) + cq_measure(b);
}
int main(void) { return slice(); }
