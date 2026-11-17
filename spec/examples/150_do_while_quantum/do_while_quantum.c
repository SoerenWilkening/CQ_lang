/* Rule 14: a source-level do-while with a quantum exit test: the body runs at least once unconditionally (trip 0 has
 * predicate |1>), the remaining K-1 trips run under the chain. */
int do_while_quantum(int x0, double tx, int a, int b, int k) {
    int x = x0, n = 0;
    cq_theta(&x, tx);
    do {                      /* [K] */
        x = x * a + b;
        n++;
    } while (x > k);
    return cq_measure(x) + cq_measure(n);
}
