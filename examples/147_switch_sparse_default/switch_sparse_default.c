/* Rule 13: sparse cases on a runtime quantum scrutinee with a REACHABLE default (the complement of the case flags).
 * The value arms merge by select; the default arm computes with the scrutinee. */
int switch_sparse_default(int x0, double tx, int c) {
    int x = x0, r;
    cq_theta(&x, tx);
    switch (x) {
        case 1:  r = c + 1; break;
        case 5:  r = c * 3; break;
        case 9:  r = c - x; break;
        default: r = x * c; break;
    }
    return cq_measure(r);
}
