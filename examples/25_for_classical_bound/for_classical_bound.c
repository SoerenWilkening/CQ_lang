int for_classical_bound(int x0, double th, int n, int c) {
    int x = x0;
    cq_theta(&x, th);
    int acc = 0;
    for (int i = 0; i < n; i++)
        acc = acc * c + x;
    return cq_measure(acc);
}
