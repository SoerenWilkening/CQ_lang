/* slice_control_select_compound.c — 3c6m.12 (L4) e2e golden: compound
 * (`||` / `&&`) conditions on tainted-data selects. The only layer that LINKS
 * — proves the `cqrt_cnot` / `cqrt_toffoli` conjunction-network symbols and
 * the `cqrt_alloc_i1` ancilla resolve against libcq_runtime, alongside the
 * per-leaf compare templates and the controlled copies.
 *
 *   r1: fp OR   — (q < 0.25 || q > 0.75) ? q : 2.5   (f64 data, literal arm)
 *   r2: int AND — (n > 5 && n < 100)     ? n : 7     (i32 data, literal arm)
 */
int main(void) {
    double q = 0.0; cq_theta(&q, 0.5);
    double r1 = (q < 0.25 || q > 0.75) ? q : 2.5;
    cq_measure(r1);

    int n = 0; cq_theta(&n, 0.5);
    int r2 = (n > 5 && n < 100) ? n : 7;
    cq_measure(r2);
    return 0;
}
