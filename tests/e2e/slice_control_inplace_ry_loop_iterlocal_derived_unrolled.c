/* slice_control_inplace_ry_loop_iterlocal_derived_unrolled.c — the HAND-UNROLLED
   TWIN of slice_control_inplace_ry_loop_iterlocal_derived.c at CQ_K = 2. */

int slice(void) {
    int q = cq_theta(5, 0.5);
    int s = 0;
    { int r = cq_theta(7, 0.25); if ((q >> 0) & 1) r = cq_theta(r, 0.2); s += cq_measure(r); }
    { int r = cq_theta(7, 0.25); if ((q >> 1) & 1) r = cq_theta(r, 0.2); s += cq_measure(r); }
    return s + cq_measure(q);
}
int main(void) { return slice(); }
