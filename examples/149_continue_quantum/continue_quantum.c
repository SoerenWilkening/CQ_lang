/* Rule 14: `continue` on a quantum condition inside a classically bounded loop (the trip is skipped under a flag),
 * and `continue` inside a K-loop (quantum exit), where the skip flag joins the trip predicate chain. */
int continue_classical_bound(int x0, double tx, int n, int k, int c) {
    int x = x0, acc = 0;
    cq_theta(&x, tx);
    for (int i = 0; i < n; i++) {
        if (x == i + k) continue;
        acc = acc * c + i;
    }
    return cq_measure(acc) + cq_measure(x);
}
int continue_kloop(unsigned x0, double tx, unsigned k, unsigned c) {
    unsigned x = x0, s = 0;
    cq_theta(&x, tx);
    while (x > k) {           /* [K] */
        x -= 1;
        if (x & 1) continue;
        s += c;
    }
    return cq_measure(s) + cq_measure(x);
}
