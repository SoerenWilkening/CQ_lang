/* defines f, no line */
int f(int x0, double th) {
    int x = x0;
    cq_theta(&x, th);
    int n = 0;
    while (x > 1) { x = (x & 1) ? 3 * x + 1 : x >> 1; n++; }
    return cq_measure(n);
}
