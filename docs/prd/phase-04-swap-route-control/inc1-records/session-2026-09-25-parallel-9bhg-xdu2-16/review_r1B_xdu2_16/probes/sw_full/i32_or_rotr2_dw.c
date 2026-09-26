__attribute__((noinline)) static int slice(int n, int m) {
    int q = cq_theta(0, 0.25);
    int r = cq_theta(1, 0.5);
    int s = 0;
    int i = 0;
    do { int t = ((q > 1) | (r < 5)) ? r : i; t = cq_theta(t, 0.7); s += cq_measure(t); } while (++i < n);
    return (int)cq_measure(q) + (int)cq_measure(r) + s;
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc); }
