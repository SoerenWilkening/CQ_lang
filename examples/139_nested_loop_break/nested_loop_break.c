int nested_loop_break(int x0, double th, int n, int m, int lim) {
    int x = x0;
    cq_theta(&x, th);
    int acc = 0;
    for (int i = 0; i < n; i++) {          /* classical bounds */
        for (int j = 0; j < m; j++) {
            acc += x ^ (i + j);
            if (acc > lim)
                break;                     /* quantum break out of the inner loop only */
        }
    }
    return cq_measure(acc);
}
