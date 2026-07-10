/* slice_branchless_fmod_qq.c — bd 3c6m.32 / 3c6m.48: the (q,q) taint mask of fmod,
   BOTH args tainted (two distinct cq_theta qubits — the general fmod(q0,q1) two-qubit
   case). The census (3c6m.48) certifies COMPILES only if every mask lowers; this pins
   the quotient `q0 / q1` as the handle/handle `cq_template_fdiv_f64` (neither `_hl` nor
   `_lh`), trunc, then `q0 - trunc*q1` with a handle/handle fmul. Same bfmod body (==
   corpus twin tools/library_coverage/branchless/fmod.c) — keep textually in sync. A
   PURE value-embedding (0 controlled rotations, 2 ry + 1 measure) backing the census
   `combinations` entry. Domain/accuracy identical to slice_branchless_fmod.c. */
static double bfmod(double x, double y) {
    return x - __builtin_trunc(x / y) * y;             /* truncated-division rem  */
}
double slice(void) {
    double q0 = cq_theta(0.5, 0.5);
    double q1 = cq_theta(0.5, 0.5);
    return cq_measure(bfmod(q0, q1));                  /* (q,q): both tainted     */
}
int main(void) { (void) slice(); return 0; }
