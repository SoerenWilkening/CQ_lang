int cond_and(int x0, double th, int k1, int k2, double phi) {
    int x = x0; cq_theta(&x, th);
    if (x > k1 && x < k2) cq_phi(phi);
    return cq_measure(x); }
int cond_or(int x0, double th, int k1, int k2, double phi) {
    int x = x0; cq_theta(&x, th);
    if (x < k1 || x > k2) cq_phi(phi);
    return cq_measure(x); }
int cond_mixed(int x0, double th, int k, int flag, double phi) {
    int x = x0; cq_theta(&x, th);
    if (flag && x == k) cq_phi(phi);
    return cq_measure(x); }
