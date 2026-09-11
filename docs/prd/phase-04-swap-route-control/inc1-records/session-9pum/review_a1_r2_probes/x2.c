int slice(void) {
    int q = 0; q = cq_theta(q, 0.5);
    int m = cq_measure(q);
    q = q + 7;
    if (q > 5) cq_phi(0.3);
    return m + cq_measure(q);
}
int main(void){ (void) slice(); return 0; }
