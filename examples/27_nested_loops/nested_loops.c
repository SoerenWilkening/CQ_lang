int nested_loops(int x0, double th, int n, int m, int c) {
    int x = x0;
    cq_theta(&x, th);
    int acc = 0;
    for (int i = 0; i < n; i++)
        for (int j = 0; j < m; j++)
            acc = acc + (x ^ (i * c + j));
    return cq_measure(acc);
}
