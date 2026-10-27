int phase_in_loop(int x0, double th, int n, double phi) {
    int x = x0;
    cq_theta(&x, th);
    for (int i = 0; i < n; i++)
        if (x == i)
            cq_phi(phi);
    return cq_measure(x);
}
int phase_under_classical(int x0, double th, int flag, double phi) {
    int x = x0;
    cq_theta(&x, th);
    if (flag)
        cq_phi(phi);
    return cq_measure(x);
}
int phase_uncontrolled(int x0, double th, double phi) {
    int x = x0;
    cq_theta(&x, th);
    cq_phi(phi);
    return cq_measure(x);
}
