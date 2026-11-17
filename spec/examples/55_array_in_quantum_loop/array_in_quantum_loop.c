/* k_rem_pio2 shape: a local array written at the loop index inside a quantum-bounded loop, then read at a quantum index. */
int array_in_quantum_loop(int m0, double th, int c) {
    int m = m0;
    cq_theta(&m, th);
    int a[4] = {0, 0, 0, 0};
    for (int i = 0; i <= m; i++)
        a[i] = i * c;
    return cq_measure(a[m - 1]);
}
