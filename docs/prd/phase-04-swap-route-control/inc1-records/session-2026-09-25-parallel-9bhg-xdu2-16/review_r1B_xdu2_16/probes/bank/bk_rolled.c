__attribute__((noinline)) static int slice(int n, int k, int j) {
    int b[4];
    for (int x = 0; x < 4; ++x) b[x] = cq_theta(x, 0.25);
    int r = cq_theta(1, 0.5);
    int s = 0;
    for (int i = 0; i < n; ++i) { int t = ((b[k] > 1) & (r < 5)) ? i : 55; s += cq_measure(t); s += cq_measure(cq_theta(b[j], 0.3)); }
    return s + cq_measure(r);
}
int main(int argc, char **argv) { (void)argv; return slice(argc + 2, argc, argc); }
