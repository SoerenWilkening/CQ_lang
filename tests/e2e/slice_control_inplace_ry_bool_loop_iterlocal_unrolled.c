/* slice_control_inplace_ry_bool_loop_iterlocal_unrolled.c — the HAND-UNROLLED
   TWIN of slice_control_inplace_ry_bool_loop_iterlocal.c at CQ_K = 2. */

int slice(void) {
    bool b = (bool)0; cq_theta(&b, 0.5);
    int s = 0;
    { int r = 7; cq_theta(&r, 0.25); if (b) cq_theta(&r, 0.2); s += cq_measure(r); }
    { int r = 7; cq_theta(&r, 0.25); if (b) cq_theta(&r, 0.2); s += cq_measure(r); }
    return s + cq_measure(b);
}
int main(void) { return slice(); }
