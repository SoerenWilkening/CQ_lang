int break_quantum_cond(int x0, double th, int n, int k) {
    int x = x0;
    cq_theta(&x, th);
    int i;
    for (i = 0; i < n; i++) {
        if (x == i + k)
            break;
    }
    return cq_measure(i);
}
int break_with_body(int x0, double th, int n, int k, int c) {
    int x = x0;
    cq_theta(&x, th);
    int acc = 0;
    for (int i = 0; i < n; i++) {
        if (x == i + k)
            break;
        acc = acc * c + i;
    }
    return cq_measure(acc);
}
