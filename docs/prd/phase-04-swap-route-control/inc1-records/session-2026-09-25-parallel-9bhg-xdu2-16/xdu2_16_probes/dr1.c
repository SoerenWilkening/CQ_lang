int slice(void) {
    int q = cq_theta(0, 0.25);
    int r = cq_theta(1, 0.5);
    int t = ((q > 1) & (r < 5)) ? 0 : 55;
    t = cq_theta(t, 0.7);
    return cq_measure(q) + cq_measure(r) + cq_measure(t);
}
int main(void) { (void) slice(); return 0; }
