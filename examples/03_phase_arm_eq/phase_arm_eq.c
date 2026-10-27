int phase_arm_eq(int x0, double th, int k, double phi) {
    int x = x0;
    cq_theta(&x, th);
    if (x == k)
        cq_phi(phi);
    return cq_measure(x);
}
