int depth3_phase_nest(int x0, double th, int k1, int k2, int k3, double p1, double p2, double p3) {
    int x = x0;
    cq_theta(&x, th);
    if (x > k1) {
        cq_phi(p1);
        if (x < k2) {
            cq_phi(p2);
            if (x != k3)
                cq_phi(p3);                /* depth 3 */
        }
    }
    return cq_measure(x);
}
int nine_leaf_tree(int x0, double th, int k1, int k2, int k3, int k4, int k5, int k6, int k7, int k8, int k9, double p) {
    int x = x0;
    cq_theta(&x, th);
    if (x > k1 && x < k2 && x != k3 && x > k4 && x < k5 && x != k6 && x > k7 && x < k8 && x != k9)
        cq_phi(p);                         /* nine compare leaves in one condition */
    return cq_measure(x);
}
