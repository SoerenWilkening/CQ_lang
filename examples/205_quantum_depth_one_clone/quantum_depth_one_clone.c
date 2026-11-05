/* Recursion with quantum depth: ONE _ctl clone and a per-function activation count, cut at K. Two cells updated in place. */
_Bool flag;
int acc = 5;
__attribute__((noinline)) static int down(int n, int a) {
    if (n <= 0) return a;
    return a - down(n - 1, a + 1);            /* a non-tail call under the quantum predicate n > 0 */
}
int quantum_depth_one_clone(int n0, double th, int a) {
    int n = n0;
    cq_theta(&n, th);
    return cq_measure(down(n, a));            /* no bound on n: the K-th activation is cut */
}
int bool_cell_rotate(double th) {
    cq_theta(&flag, th);                      /* an i8 cell rotated at width i1 */
    return cq_measure(flag);
}
int theta_add_cell(double th, int d) {
    cq_theta(&acc, th);
    acc += d;                                 /* load, rotate, add, store: one in-place form */
    return cq_measure(acc);
}
