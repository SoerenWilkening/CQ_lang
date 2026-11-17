int measure_then_reuse(int x0, double th, int k, double t) {
    int x = x0;
    cq_theta(&x, th);
    int m = cq_measure(x);    /* x keeps naming the (now collapsed) register */
    if (m > k)                /* classical control on the outcome */
        cq_theta(&x, t);
    else
        x += 1;
    return cq_measure(x) + m;
}
int measure_entangled_rotate_other(int x0, double th, int c, int k, double t) {
    int x = x0;
    cq_theta(&x, th);
    int y = x + c;            /* y entangled with x */
    int m = cq_measure(y);    /* collapses x to m - c as well */
    if (m > k)
        cq_theta(&x, t);
    return cq_measure(x) + m;
}
