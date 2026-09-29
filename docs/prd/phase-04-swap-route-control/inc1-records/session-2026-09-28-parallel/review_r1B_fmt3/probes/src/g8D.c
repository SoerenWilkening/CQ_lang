int slice(void) {
    int q = cq_theta(0, 0.5);
    int r = cq_theta(7, 0.25);
    if ((q & 6) == 4) r = cq_theta(r, __builtin_inf());
    return cq_measure(q) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
