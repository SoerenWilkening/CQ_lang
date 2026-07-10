/* slice_branchless_fdim_qq.c — bd 3c6m.16 / 3c6m.48: the (q,q) taint mask of fdim,
   BOTH args tainted (two distinct cq_theta qubits — the general fdim(q0,q1) two-qubit
   case). The census (3c6m.48) certifies COMPILES only if every mask lowers; this pins
   the difference `q0 - q1` as the handle/handle `cq_template_fsub_f64` (neither `_hl`
   nor `_lh`) then a keep-set fmax with 0. Same bfdim body (== corpus twin
   tools/library_coverage/branchless/fdim.c) — keep textually in sync. A PURE
   value-embedding (0 controlled rotations, 2 ry + 1 measure) backing the census
   `combinations` entry. Domain/accuracy identical to slice_branchless_fdim.c. */
static double bfdim(double x, double y) {
    return __builtin_fmax(x - y, 0.0);                 /* positive difference     */
}
double slice(void) {
    double q0 = cq_theta(0.5, 0.5);
    double q1 = cq_theta(0.5, 0.5);
    return cq_measure(bfdim(q0, q1));                  /* (q,q): both tainted     */
}
int main(void) { (void) slice(); return 0; }
