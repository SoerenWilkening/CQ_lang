int theta_quantum_angle(int x0, double tx, int r0, double tr, double c) {
    int x = x0, r = r0;
    cq_theta(&x, tx);
    cq_theta(&r, tr);
    double a = x * c;              /* angle derived from a quantum register */
    cq_theta(&r, a);
    return cq_measure(r) + cq_measure(x);
}
int phi_quantum_angle(int x0, double tx, double c, int k) {
    int x = x0;
    cq_theta(&x, tx);
    double a = x * c;
    cq_phi(a);                     /* uncontrolled: kickback onto x, not a global phase */
    if (x > k)
        cq_phi(a);                 /* under a quantum condition */
    return cq_measure(x);
}
