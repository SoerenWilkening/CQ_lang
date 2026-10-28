/* A phase on a quantum branch and a value computed after the rotation. */
int phase_if(int x0, double th, int t) {
    int x = x0;
    cq_theta(&x, th);
    if (x > t)
        cq_phi(0.25);
    return cq_measure(x ^ t);
}
