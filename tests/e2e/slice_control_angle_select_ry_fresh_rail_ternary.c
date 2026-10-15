/* slice_control_angle_select_ry_fresh_rail_ternary.c — the TERNARY twin of
   `slice_control_inplace_ry_stateprep_rail_ifelse_fresh.c` (bd dm7f.54 item B).
   Read that header for the line-by-line; the goldens are byte-identical. */
int slice(void) {
    _Bool q = 0, t = 0;
    cq_theta(&q, 1.0);
    cq_theta(&t, q ? 0.3 : 0.7);
    return (int) cq_measure(q) + (int) cq_measure(t);
}
int main(void) { (void) slice(); return 0; }
