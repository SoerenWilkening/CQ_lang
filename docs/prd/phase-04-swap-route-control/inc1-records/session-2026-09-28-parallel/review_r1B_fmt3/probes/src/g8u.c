int slice(void) {
    int r = cq_theta(7, 0.25);
    r = cq_theta(r, __builtin_inf());
    return cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
