int slice(int u) {
    int q = cq_theta(u, 0.5);
    int r = cq_theta(u + 1, 0.25);
    int m = cq_measure(r);
    if (q > r) cq_phi(0.3);
    return m + cq_measure(q);
}
int main(void){ (void) slice(2); return 0; }
