__attribute__((noinline)) static int slice(int n) {
    int q = cq_theta(0, 0.25);
    int r = cq_theta(1, 0.5);
    if ((q > 1) & (r < 5)) cq_phi(0.3);
    if ((q > 1) & (r < 5)) cq_phi(0.3);
    if ((q > 1) & (r < 5)) cq_phi(0.3);
    return cq_measure(q) + cq_measure(r);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2); }
