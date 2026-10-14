/* slice_control_inplace_ry_rail_ifelse_p12_twin.c — the IF/ELSE twin of
   `slice_control_angle_select_ry_rail_p12.c` (bd dm7f.54). With `nomerge` on
   every `cq_theta_*` the two arms stay an if/else on the bare `_Bool` `a`, which
   declined `bare i1 register condition` (one content arm only on a rail). Two
   arms now take the CNOT copy flag and the X-bracket form; the golden is
   BYTE-IDENTICAL to the ternary's (`e2e-angle-select-ry-rail-twin-identical`),
   so read that slice's header for the line-by-line. Harness edit only. */
int slice(void) {
    _Bool a = 0, t = 0;
    cq_theta(&a, 1.0);
    cq_theta(&t, 0.4);
    if (a) cq_theta(&t, 0.7); else cq_theta(&t, 0.3);
    return (int) cq_measure(a) + (int) cq_measure(t);
}
int main(void) { (void) slice(); return 0; }
